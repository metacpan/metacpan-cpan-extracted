package Langertha::Knarr::Protocol::ACP;
# ABSTRACT: BeeAI/IBM Agent Communication Protocol (ACP) for Knarr

our $VERSION = '1.000';
use Moose;
use JSON::MaybeXS;
use Data::UUID;
use Time::HiRes qw( time );
use Langertha::Knarr::Request;

with 'Langertha::Knarr::Protocol';

# --- ACP overview ---
# REST-style, oriented around "agents" and "runs":
#   GET  /agents                       — list agents
#   POST /runs                         — create a run (sync or stream)
#   GET  /runs/{run_id}                — fetch run
#   POST /runs/{run_id}/cancel
#
# POST /runs body:
#   { "agent_name": "...",
#     "input": [ { "parts": [ { "content_type":"text/plain", "content":"..." } ] } ],
#     "mode": "sync" | "stream" | "async" }
#
# Streaming model: when mode=stream, response is SSE with named events:
#   event: run.created
#   event: message.created
#   event: message.part         data: { "part": { "content_type":"text/plain","content":"Hi" } }
#   event: message.completed
#   event: run.completed
# ---------------------------------------------------------------------------

has steerboard => ( is => 'ro', weak_ref => 1 );
has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );
has _uuid => ( is => 'ro', default => sub { Data::UUID->new } );

sub protocol_name { 'acp' }

sub protocol_routes {
  return [
    { method => 'GET',  path => '/agents', action => 'acp_agents' },
    { method => 'POST', path => '/runs',   action => 'chat'       },
  ];
}

sub parse_chat_request {
  my ($self, $http_req, $body_ref) = @_;
  my $data = $self->_json->decode( $$body_ref || '{}' );
  my @msgs;
  for my $turn ( @{ $data->{input} || [] } ) {
    my $text = join '', map { $_->{content} // '' } @{ $turn->{parts} || [] };
    push @msgs, { role => 'user', content => $text };
  }
  my $mode = $data->{mode} // 'sync';
  return Langertha::Knarr::Request->new(
    protocol => 'acp',
    raw      => $data,
    model    => $data->{agent_name},
    messages => \@msgs,
    stream   => $mode eq 'stream' ? 1 : 0,
    extra    => {
      run_id => $self->_uuid->create_str,
      mode   => $mode,
      agent_name => $data->{agent_name},
    },
  );
}

sub format_chat_response {
  my ($self, $response, $request) = @_;
  my $content = ref $response eq 'HASH' ? $response->{content} : "$response";
  my $payload = {
    run_id => $request->extra->{run_id},
    agent_name => $request->extra->{agent_name},
    status => 'completed',
    output => [
      { parts => [ { content_type => 'text/plain', content => $content } ] },
    ],
  };
  return ( 200, { 'Content-Type' => 'application/json' }, $self->_json->encode($payload) );
}

sub format_models_response {
  my ($self, $models) = @_;
  my @agents = map {
    my $id = ref $_ eq 'HASH' ? $_->{id} : "$_";
    { name => $id, description => '', metadata => {} }
  } @$models;
  return ( 200, { 'Content-Type' => 'application/json' },
    $self->_json->encode({ agents => \@agents }) );
}

sub _sse_event {
  my ($self, $event, $data) = @_;
  return "event: $event\ndata: " . $self->_json->encode($data) . "\n\n";
}

sub format_stream_open {
  my ($self, $request) = @_;
  return join( '',
    $self->_sse_event( 'run.created'     => { run_id => $request->extra->{run_id}, status => 'in_progress' } ),
    $self->_sse_event( 'message.created' => { run_id => $request->extra->{run_id} } ),
  );
}

sub format_stream_chunk {
  my ($self, $delta_text, $request) = @_;
  return $self->_sse_event( 'message.part' => {
    run_id => $request->extra->{run_id},
    part   => { content_type => 'text/plain', content => $delta_text },
  });
}

sub format_stream_close {
  my ($self, $request) = @_;
  return join( '',
    $self->_sse_event( 'message.completed' => { run_id => $request->extra->{run_id} } ),
    $self->_sse_event( 'run.completed'     => { run_id => $request->extra->{run_id}, status => 'completed' } ),
  );
}

sub format_stream_done { '' }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol::ACP - BeeAI/IBM Agent Communication Protocol (ACP) for Knarr

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Implements the IBM/BeeAI Linux Foundation ACP protocol on top of
L<Langertha::Knarr::Protocol>. Loaded by default.

=over

=item * C<GET /agents> — list agents

=item * C<POST /runs> — create a run (C<sync> or C<stream> mode)

=back

Streaming mode emits the standard ACP event sequence:
C<run.created>, C<message.created>, C<message.part>×N,
C<message.completed>, C<run.completed>.

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
