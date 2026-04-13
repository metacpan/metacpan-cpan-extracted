package Langertha::Knarr::PSGI;
# ABSTRACT: PSGI adapter for Langertha::Knarr (buffered, no streaming)
our $VERSION = '1.001';
use Moose;
use JSON::MaybeXS;
use Langertha::Knarr::Request;


# Wraps a Langertha::Knarr instance and returns a PSGI app coderef.
# Streaming requests are coerced into buffered responses: the full body is
# assembled (open + chunks + close + done) before being returned to the
# PSGI server. Use the native Net::Async::HTTP::Server entrypoint
# (Steerboard->run) if you need real streaming.

has steerboard => ( is => 'ro', required => 1 );

has _json => (
  is => 'ro',
  default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) },
);

sub to_app {
  my ($self) = @_;
  return sub {
    my ($env) = @_;
    return $self->_handle_psgi($env);
  };
}

sub _read_body {
  my ($self, $env) = @_;
  my $input = $env->{'psgi.input'} or return '';
  my $len = $env->{CONTENT_LENGTH} // 0;
  return '' unless $len;
  my $body = '';
  my $read = 0;
  while ( $read < $len ) {
    my $chunk;
    my $n = $input->read( $chunk, $len - $read );
    last unless $n;
    $body .= $chunk;
    $read += $n;
  }
  return $body;
}

sub _handle_psgi {
  my ($self, $env) = @_;
  my $sb = $self->steerboard;
  my $method = $env->{REQUEST_METHOD};
  my $path   = $env->{PATH_INFO} // '/';

  my $route = $sb->_match_route( $method, $path );
  unless ( $route ) {
    return [ 404, [ 'Content-Type' => 'application/json' ],
      [ $self->_json->encode({ error => { message => "no route for $method $path" } }) ] ];
  }

  my $proto = $route->{protocol};
  my $action = $route->{action};

  if ( $action eq 'models' || $action eq 'acp_agents' ) {
    my $models = $sb->handler->list_models;
    my ($status, $headers, $body) = $proto->format_models_response($models);
    return [ $status, [ %$headers ], [ $body ] ];
  }
  if ( $action eq 'a2a_card' ) {
    my ($status, $headers, $body) = $proto->format_agent_card;
    return [ $status, [ %$headers ], [ $body ] ];
  }
  if ( $action ne 'chat' ) {
    return [ 500, [ 'Content-Type' => 'application/json' ],
      [ $self->_json->encode({ error => { message => "unknown action $action" } }) ] ];
  }

  my $body = $self->_read_body($env);
  my $fake_http = Langertha::Knarr::PSGI::FakeReq->new( $env );
  my $sb_req = $proto->parse_chat_request( $fake_http, \$body );
  my $session = $sb->session( $sb_req->session_id );
  my $handler = $sb->handler;

  if ( $sb_req->stream ) {
    # Buffered streaming: drive the stream to completion, concatenate frames.
    my $stream = $handler->handle_stream_f( $session, $sb_req )->get;
    my $out = $proto->format_stream_open($sb_req);
    while ( defined( my $delta = $stream->next_chunk_f->get ) ) {
      $out .= $proto->format_stream_chunk( $delta, $sb_req );
    }
    $out .= $proto->format_stream_close($sb_req);
    $out .= $proto->format_stream_done($sb_req);
    return [ 200, [ 'Content-Type' => $proto->stream_content_type ], [ $out ] ];
  }

  my $response = $handler->handle_chat_f( $session, $sb_req )->get;
  my ($status, $headers, $obody) = $proto->format_chat_response( $response, $sb_req );
  return [ $status, [ %$headers ], [ $obody ] ];
}

package Langertha::Knarr::PSGI::FakeReq;
sub new {
  my ($class, $env) = @_;
  return bless { env => $env }, $class;
}
sub header {
  my ($self, $name) = @_;
  ( my $key = uc $name ) =~ tr/-/_/;
  return $self->{env}{"HTTP_$key"};
}

package Langertha::Knarr::PSGI;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::PSGI - PSGI adapter for Langertha::Knarr (buffered, no streaming)

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use Langertha::Knarr;
    use Langertha::Knarr::PSGI;

    my $knarr = Langertha::Knarr->new( handler => $handler );
    my $app = Langertha::Knarr::PSGI->new( steerboard => $knarr )->to_app;
    # $app is now a Plack-compatible coderef

    # Run with any PSGI server:
    #   plackup -s Starman -p 8088 app.psgi

=head1 DESCRIPTION

Adapter that wraps a L<Langertha::Knarr> instance and exposes it as a
PSGI app, so you can deploy Knarr behind any Plack server (Starman,
Twiggy, Gazelle, mod_perl, etc.) instead of running its native
L<Net::Async::HTTP::Server> loop.

B<Streaming responses are buffered.> The PSGI streaming protocol's
delayed-response form does work in theory but mixes badly with
L<IO::Async> in the same process; for honesty's sake this adapter
just drives the inner stream to completion in a blocking loop and
returns the full assembled body. Use the native
L<Langertha::Knarr/run> entry point if you need real-time streaming.

=head2 steerboard

Required. The L<Langertha::Knarr> instance to expose. (Attribute name
preserved from the upstream Steerboard prototype.)

=head2 to_app

Returns the PSGI coderef.

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
