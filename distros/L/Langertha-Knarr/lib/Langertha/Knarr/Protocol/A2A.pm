package Langertha::Knarr::Protocol::A2A;
# ABSTRACT: Google Agent2Agent (A2A) wire protocol for Knarr

our $VERSION = '1.000';
use Moose;
use JSON::MaybeXS;
use Data::UUID;
use Time::HiRes qw( time );
use Langertha::Knarr::Request;

with 'Langertha::Knarr::Protocol';

# --- A2A overview ---
# Discovery: GET /.well-known/agent.json -> AgentCard JSON
# Method bus: POST /        body: JSON-RPC 2.0 envelope
#   methods: "tasks/send", "tasks/sendSubscribe", "tasks/get",
#            "tasks/cancel", "tasks/pushNotification/set", ...
#
# tasks/send (sync): returns Task JSON in JSON-RPC result
# tasks/sendSubscribe (streaming): returns SSE stream of JSON-RPC responses
#   Each event is a full JSON-RPC response wrapping a TaskStatusUpdateEvent or
#   TaskArtifactUpdateEvent. Final event has status.state = "completed".
#
# Streaming model on the wire:
#   data: {"jsonrpc":"2.0","id":<reqid>,"result":{"id":"<task>","status":{"state":"working","message":{...}}, "final":false}}\n\n
#   data: {"jsonrpc":"2.0","id":<reqid>,"result":{"id":"<task>","artifact":{"parts":[{"type":"text","text":"Hi"}], "index":0,"append":true}, "final":false}}\n\n
#   data: {"jsonrpc":"2.0","id":<reqid>,"result":{"id":"<task>","status":{"state":"completed"},"final":true}}\n\n
# ---------------------------------------------------------------------------

has steerboard => ( is => 'ro', weak_ref => 1 );
has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );
has _uuid => ( is => 'ro', default => sub { Data::UUID->new } );

has agent_card => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_agent_card',
);

sub _build_agent_card {
  my ($self) = @_;
  return {
    name => 'Langertha Steerboard Agent',
    description => 'Steerboard-exposed agent',
    url => '/',
    version => '0.0.1',
    capabilities => {
      streaming => JSON::MaybeXS::true(),
      pushNotifications => JSON::MaybeXS::false(),
      stateTransitionHistory => JSON::MaybeXS::false(),
    },
    defaultInputModes  => ['text'],
    defaultOutputModes => ['text'],
    skills => [],
  };
}

sub protocol_name { 'a2a' }

sub protocol_routes {
  return [
    { method => 'GET',  path => '/.well-known/agent.json', action => 'a2a_card' },
    { method => 'POST', path => '/',                       action => 'chat'     },
  ];
}

# A2A puts everything through JSON-RPC; we surface a normalized Steerboard
# request from the "tasks/send" or "tasks/sendSubscribe" method params.
sub parse_chat_request {
  my ($self, $http_req, $body_ref) = @_;
  my $env = $self->_json->decode( $$body_ref || '{}' );
  my $method = $env->{method} // '';
  my $params = $env->{params} // {};
  my $stream = $method eq 'tasks/sendSubscribe' ? 1 : 0;

  my $msg = $params->{message} // {};
  my @parts = @{ $msg->{parts} || [] };
  my $text  = join '', map { ($_->{type} // '') eq 'text' ? ($_->{text} // '') : '' } @parts;

  return Langertha::Knarr::Request->new(
    protocol => 'a2a',
    raw      => $env,
    messages => [ { role => 'user', content => $text } ],
    stream   => $stream,
    session_id => $params->{sessionId} // $params->{id},
    extra => {
      jsonrpc_id => $env->{id},
      task_id    => $params->{id} // $self->_uuid->create_str,
      a2a_method => $method,
    },
  );
}

sub format_chat_response {
  my ($self, $response, $request) = @_;
  my $content = ref $response eq 'HASH' ? $response->{content} : "$response";
  my $task = {
    id => $request->extra->{task_id},
    sessionId => $request->session_id,
    status => {
      state => 'completed',
      message => {
        role => 'agent',
        parts => [ { type => 'text', text => $content } ],
      },
    },
    artifacts => [
      { parts => [ { type => 'text', text => $content } ], index => 0, append => JSON::MaybeXS::false() },
    ],
  };
  my $envelope = {
    jsonrpc => '2.0',
    id      => $request->extra->{jsonrpc_id},
    result  => $task,
  };
  return ( 200, { 'Content-Type' => 'application/json' }, $self->_json->encode($envelope) );
}

# Card endpoint helper — called via a custom action.
sub format_agent_card {
  my ($self) = @_;
  return ( 200, { 'Content-Type' => 'application/json' }, $self->_json->encode($self->agent_card) );
}

sub _rpc_event {
  my ($self, $request, $result) = @_;
  my $env = {
    jsonrpc => '2.0',
    id      => $request->extra->{jsonrpc_id},
    result  => $result,
  };
  return "data: " . $self->_json->encode($env) . "\n\n";
}

sub format_stream_open {
  my ($self, $request) = @_;
  return $self->_rpc_event( $request, {
    id => $request->extra->{task_id},
    status => { state => 'working' },
    final => JSON::MaybeXS::false(),
  });
}

sub format_stream_chunk {
  my ($self, $delta_text, $request) = @_;
  return $self->_rpc_event( $request, {
    id => $request->extra->{task_id},
    artifact => {
      parts => [ { type => 'text', text => $delta_text } ],
      index => 0,
      append => JSON::MaybeXS::true(),
    },
    final => JSON::MaybeXS::false(),
  });
}

sub format_stream_close {
  my ($self, $request) = @_;
  return $self->_rpc_event( $request, {
    id => $request->extra->{task_id},
    status => { state => 'completed' },
    final => JSON::MaybeXS::true(),
  });
}

sub format_stream_done { '' }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol::A2A - Google Agent2Agent (A2A) wire protocol for Knarr

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Implements the Google A2A protocol on top of
L<Langertha::Knarr::Protocol>. Loaded by default.

=over

=item * C<GET /.well-known/agent.json> — agent card discovery (anonymous)

=item * C<POST /> — JSON-RPC 2.0 method bus

=back

Supported methods: C<tasks/send> (sync) and C<tasks/sendSubscribe>
(streaming). Streaming wraps every chunk in a JSON-RPC envelope with
the original C<id> preserved, transitions C<status.state> from
C<working> to C<completed>, and emits artifact append events for the
text deltas.

=head2 agent_card

The HashRef returned by the discovery endpoint. Defaults to a generic
"Knarr Agent" card with C<streaming: true>; override to advertise
specific skills, version, etc.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
