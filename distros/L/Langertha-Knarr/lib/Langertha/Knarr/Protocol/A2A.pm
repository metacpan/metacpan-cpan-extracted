package Langertha::Knarr::Protocol::A2A;
# ABSTRACT: Google Agent2Agent (A2A) wire protocol for Knarr

our $VERSION = '1.103';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;
use Data::UUID;
use Time::HiRes qw( time );
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr ();

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

has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );
has _uuid => ( is => 'ro', default => sub { Data::UUID->new } );

has agent_name => (
  is => 'ro',
  isa => 'Str',
  default => 'Langertha Knarr Agent',
);

has agent_description => (
  is => 'ro',
  isa => 'Str',
  default => 'LLM agent served through Langertha Knarr',
);

has agent_card => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_agent_card',
);

sub _build_agent_card {
  my ($self) = @_;
  return {
    name => $self->agent_name,
    description => $self->agent_description,
    url => '/',
    # Knarr's own version, as knarr --version prints it; 'dev' only for a
    # tree whose Langertha::Knarr carries no $VERSION.
    version => $Langertha::Knarr::VERSION // 'dev',
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

# A2A puts everything through JSON-RPC; we surface a normalized Knarr
# request from the "tasks/send" or "tasks/sendSubscribe" method params.
sub parse_chat_request {
  my ($self, $http_req, $body_ref) = @_;
  my $env = $self->_json->decode( $$body_ref || '{}' );
  # JSON that is no object (null would pass as an empty request): -32600.
  croak('request is not a JSON object') unless ref $env eq 'HASH';
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
  my $content = Langertha::Knarr::Response->coerce($response)->content;
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

# JSON-RPC's error object (k79): -32603 Internal error for a server-side
# status, -32600 Invalid Request for a client-side one; the HTTP status in
# data. The id is the request's: from the parsed request, else read off the
# raw body (the 401 comes before the parse), else null -- JSON-RPC 2.0: null
# when the id could not be detected. A body that is not JSON at all is the
# failure of the parse: 400, -32700 Parse error, id null, the decoder's own
# text kept out of the answer (k80).
sub _rpc_error {
  my ($self, $status, $message, $request, $body) = @_;
  my ($id, $code) = ( undef, $status >= 500 ? -32603 : -32600 );
  if ( $request ) {
    $id = $request->extra->{jsonrpc_id};
  }
  elsif ( defined $body && length $body ) {
    my $env;
    my $decoded = eval { $env = $self->_json->decode($body); 1 };
    if ( !$decoded && $status == 500 ) {
      ( $status, $code, $message ) = ( 400, -32700, 'Parse error' );
    }
    elsif ( ref $env eq 'HASH' ) {
      $id = $env->{id} if defined $env->{id} && !ref $env->{id};
    }
    elsif ( $status == 500 ) {
      ( $status, $code, $message ) = ( 400, -32600, 'Invalid Request' );
    }
  }
  return {
    jsonrpc => '2.0',
    id      => $id,
    error   => {
      code    => $code,
      message => "$message",
      data    => { status => $status + 0 },
    },
  };
}

sub error_uses_body { 1 }

# A body that is not JSON is answered by _rpc_error as -32700 / -32600 (k80).
sub request_body_error { return }


sub format_error_response {
  my ($self, $status, $message, $request, $body) = @_;
  my $error = $self->_rpc_error( $status, $message, $request, $body );
  return ( $error->{error}{data}{status}, { 'Content-Type' => 'application/json' },
    $self->_json->encode($error) );
}


sub format_stream_error {
  my ($self, $status, $message, $request) = @_;
  return "data: " . $self->_json->encode( $self->_rpc_error( $status, $message, $request ) ) . "\n\n";
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol::A2A - Google Agent2Agent (A2A) wire protocol for Knarr

=head1 VERSION

version 1.103

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

=head2 agent_name

The C<name> in the default L</agent_card>. Default
C<Langertha Knarr Agent>. Configured as C<a2a.name> in the config file or
C<KNARR_A2A_NAME> (see L<Langertha::Knarr::Config/a2a_name>); C<knarr start>
passes it through L<Langertha::Knarr/protocol_args>.

=head2 agent_description

The C<description> in the default L</agent_card>. Default
C<LLM agent served through Langertha Knarr>. Configured as
C<a2a.description> or C<KNARR_A2A_DESCRIPTION>.

=head2 agent_card

The HashRef returned by the discovery endpoint. Defaults to a card with
L</agent_name>, L</agent_description>, Knarr's own version
(C<$Langertha::Knarr::VERSION>, C<dev> when it has none) and
C<streaming: true>; pass a whole
card to advertise specific skills, version, etc. (L</agent_name> and
L</agent_description> are then not used).

=head2 format_error_response

    my ($status, $headers, $body) = $proto->format_error_response( 500, 'boom', $request, $raw_body );

A2A answers an error as a JSON-RPC response with an C<error> object (C<code>,
C<message>, C<data.status>) and the C<id> of the request, not the OpenAI
wire's C<{"error":{"message":...}}>. The HTTP status is kept. The C<id> comes
from the parsed request, else from the raw body (a C<401> is decided before
the parse), else it is C<null>. A 500 whose body is not JSON was a failed
parse: it becomes 400 with C<-32700> C<Parse error>, and C<id> C<null>, as
JSON-RPC 2.0 requires when the id cannot be detected.

=head2 format_stream_error

The same JSON-RPC error response as an SSE event; it ends the stream.

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
