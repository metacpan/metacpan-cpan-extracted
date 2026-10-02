package Langertha::Knarr::PSGI;
# ABSTRACT: PSGI adapter for Langertha::Knarr (buffered, no streaming)
our $VERSION = '1.102';
use Moose;
use Future;
use JSON::MaybeXS;
use Langertha::Knarr::Request;
use Langertha::Knarr::PSGI::FakeReq;


# Wraps a Langertha::Knarr instance and returns a PSGI app coderef.
# Streaming requests are coerced into buffered responses: the full body is
# assembled (open + chunks + close + done) before being returned to the
# PSGI server. Use the native Net::Async::HTTP::Server entrypoint
# (Langertha::Knarr->run) if you need real streaming.

has knarr => ( is => 'ro', required => 1 );

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
  my $sb = $self->knarr;
  my $method = $env->{REQUEST_METHOD};
  my $path   = $env->{PATH_INFO} // '/';

  my $route = $sb->_match_route( $method, $path );
  unless ( $route ) {
    return [ 404, [ 'Content-Type' => 'application/json' ],
      [ $self->_json->encode({ error => { message => "no route for $method $path" } }) ] ];
  }

  my $proto = $route->{protocol};
  my $action = $route->{action};

  # Same auth decision and 401 as the native server (k25), before any
  # handler work, so a rejected streaming request never starts its stream.
  my $fake_http = Langertha::Knarr::PSGI::FakeReq->new( $env );
  unless ( $sb->_check_auth( $fake_http, $action ) ) {
    my ($status, $ctype, $body) = $sb->_unauthorized;
    return [ $status, [ 'Content-Type' => $ctype ], [ $body ] ];
  }

  if ( $action eq 'models' || $action eq 'acp_agents' ) {
    my $models = $sb->handler->list_models;
    my ($status, $headers, $body) = $proto->format_models_response($models);
    return [ $status, [ %$headers ], [ $body ] ];
  }
  if ( $action eq 'manifest' ) {
    my ($status, $body) = $sb->manifest_response(
      scheme => $env->{'psgi.url_scheme'} // 'http',
      host   => $env->{HTTP_HOST}
        // ( defined $env->{SERVER_NAME} ? $env->{SERVER_NAME} . ':' . ( $env->{SERVER_PORT} // 80 ) : undef ),
      prefix => $env->{SCRIPT_NAME} // '',
    );
    return [ $status, [ 'Content-Type' => 'application/json' ], [ $body ] ];
  }
  # The same table and methods as the native server (k29).
  if ( my $simple = $sb->_simple_action($action) ) {
    my ($status, $headers, $body) = $sb->$simple( $proto, $self->_read_body($env) );
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
  my $sb_req = $sb->_parse_chat_request( $proto, $fake_http, \$body );

  # Raw passthrough, decided and prepared by the same Knarr code as on the
  # native server (k26): the client's bytes go 1:1 to the upstream and its
  # answer comes back unchanged. A streaming answer is buffered, like every
  # stream under this adapter. A discovered model the upstream refuses the
  # client's key for falls through to the handler chain below, to its
  # engine (k66).
  if ( $sb->_is_raw_passthrough($sb_req) ) {
    my ($http_req, $trace, $trace_from) = $sb->_raw_passthrough_request(
      $sb_req, [ $fake_http->headers ], $body, $path );
    # The failure as the future carries it, as the native on_fail sees it.
    # A buffered stream still gets the stall timeout, not the total one: a
    # long steady stream is legitimate (k35).
    my ($resp, $err, $category) = $sb->raw_passthrough->_upstream_request_f(
      request => $http_req, stream => $sb_req->stream ? 1 : 0 )
      ->else( sub { Future->done( undef, @_[0, 1] ) } )->get;
    unless ( $resp && $sb->_raw_passthrough_falls_back( $sb_req, $resp ) ) {
      $trace = $sb->_raw_passthrough_trace( $sb_req, $trace_from ) if $trace_from;
      my ($status, $ctype, $obody, $oheaders) = $resp
        ? $sb->_raw_passthrough_answer( $sb_req, $trace, $resp )
        : $sb->_raw_passthrough_failed( $proto, $sb_req, $trace, $err // 'unknown error', $category );
      return [ $status, [ 'Content-Type' => $ctype, map { @$_ } @{ $oheaders // [] } ], [ $obody ] ];
    }
  }

  my $session = $sb->session( $sb_req->session_id );
  my $handler = $sb->handler;

  # An upstream timeout in the handler chain answers 504 in the protocol's
  # error shape, as the native server does (k36), a model nothing serves
  # 404 (k41). A buffered stream has sent nothing yet, so it gets the same
  # answer, like the raw passthrough under this adapter. Any other failure
  # dies as before.
  my @answer;
  my $answered = sub {
    my ($e) = @_;
    return 0 unless ref $e && eval { $e->isa('Future::Exception') };
    @answer = $sb->_handler_failure_answer( $proto, $e->message, $e->category );
    return scalar @answer;
  };
  # A read the upstream has not fed yet is a plain pending Future (the
  # stream's own queue), which cannot ->get by itself: run the loop until
  # it is ready.
  my $get = sub {
    my ($f) = @_;
    $sb->loop->await($f) unless $f->is_ready;
    return $f->get;
  };

  if ( $sb_req->stream ) {
    # Buffered streaming: drive the stream to completion, concatenate frames.
    my $out = eval {
      my $stream = $get->( $handler->handle_stream_f( $session, $sb_req ) );
      my $out = $proto->format_stream_open($sb_req);
      while ( defined( my $delta = $get->( $stream->next_chunk_f ) ) ) {
        $out .= $proto->format_stream_chunk( $delta, $sb_req );
      }
      my $finish_reason = $stream->can('finish_reason') ? $stream->finish_reason : undef;
      my $tool_calls    = $stream->can('tool_calls')    ? $stream->tool_calls    : [];
      my $usage         = $stream->can('usage')         ? $stream->usage         : undef;
      $out .= $proto->format_stream_close( $sb_req, $finish_reason, $tool_calls, $usage );
      $out .= $proto->format_stream_done( $sb_req, $finish_reason, $tool_calls, $usage );
      $out;
    };
    if ( my $e = $@ ) {
      return [ $answer[0], [ 'Content-Type' => $answer[1] ], [ $answer[2] ] ] if $answered->($e);
      die $e;
    }
    return [ 200, [ 'Content-Type' => $proto->stream_content_type ], [ $out ] ];
  }

  my $response = eval { $get->( $handler->handle_chat_f( $session, $sb_req ) ) };
  if ( my $e = $@ ) {
    return [ $answer[0], [ 'Content-Type' => $answer[1] ], [ $answer[2] ] ] if $answered->($e);
    die $e;
  }
  my ($status, $headers, $obody) = $proto->format_chat_response( $response, $sb_req );
  return [ $status, [ %$headers ], [ $obody ] ];
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::PSGI - PSGI adapter for Langertha::Knarr (buffered, no streaming)

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Knarr;
    use Langertha::Knarr::PSGI;

    my $knarr = Langertha::Knarr->new( handler => $handler );
    my $app = Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app;
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

Raw passthrough works as on the native server: with a
C<raw_passthrough> handler and a C<router> set on the Knarr, a chat request for a
model the router does not configure is sent to the upstream byte for byte
with the client's headers (minus the proxy key, see
L<Langertha::Knarr/auth_token>), and the upstream's status, headers and body
come back unchanged (see L<Langertha::Knarr/raw_passthrough>). A streamed
passthrough answer is buffered like any other stream here; its
C<Content-Encoding> is handled as on the native server. A discovered
model's C<401> falls back to its engine as there, streamed or not.

One limit is the PSGI server's: it hands over a request header the client
sent twice as one value joined with C<, > (one C<HTTP_*> key), so the
upstream gets that header once, as that joined value. The native server
forwards each line. The same holds for the auth headers a
L<Langertha::Knarr::Handler::Passthrough> in the handler chain forwards
(C<forward_headers>, see L<Langertha::Knarr::Request/forward_header_pairs>).

Requests are authenticated exactly like on the native server: with
L<Langertha::Knarr/auth_token> set, every route except the A2A agent card
needs the key as C<Authorization: Bearer> or C<x-api-key>, and a missing
or wrong key gets the same C<401> JSON error.

=head2 knarr

Required. The L<Langertha::Knarr> instance to expose.

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
