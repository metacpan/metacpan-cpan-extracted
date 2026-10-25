package Langertha::Knarr::PSGI;
# ABSTRACT: PSGI adapter for Langertha::Knarr (buffered, no streaming)
our $VERSION = '1.103';
use Moose;
use Future;
use JSON::MaybeXS;
use Log::Any qw( $log );
use Scalar::Util qw( blessed );
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

# The body is read once and kept in the environment: an error answer may
# need it (_error_body) before the action reads it.
sub _read_body {
  my ($self, $env) = @_;
  return $env->{'knarr.body'} //= $self->_slurp_body($env);
}

sub _slurp_body {
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

# The request body for an error answer, read only for a protocol that
# addresses its errors with it (A2A's JSON-RPC id, k80); undef for any other.
sub _error_body {
  my ($self, $env, $proto) = @_;
  return unless $proto && $proto->error_uses_body;
  return $self->_read_body($env);
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
  my $fake_http = Langertha::Knarr::PSGI::FakeReq->new( $env );

  # The admin routes, answered by the same admin as on the native server
  # (k75). The body is read only once the key was checked and its
  # Content-Length is within the limit; a prefork server gets 501, as each
  # of its processes would hold a setup of its own.
  if ( $route->{admin} ) {
    my ($status, $ctype, $body, $headers) = $sb->admin->handle(
      knarr          => $sb,
      action         => $action,
      request        => $fake_http,
      content_length => $env->{CONTENT_LENGTH} // 0,
      body           => sub { $self->_read_body($env) },
      peer           => $env->{REMOTE_ADDR},
      multiprocess   => $env->{'psgi.multiprocess'} ? 1 : 0,
    );
    return [ $status, [ 'Content-Type' => $ctype, map { @$_ } @{ $headers // [] } ], [ $body ] ];
  }

  # Same identify decision and 401/503 as the native server (k25, k82), in
  # the route's protocol's error shape (k78), before any handler work and
  # before the body is parsed, so a rejected streaming request never starts
  # its stream. The check may block here.
  my $identified = $sb->_identify( $fake_http, $action );
  if ( my ($status, $ctype, $body) = $sb->_identify_refusal( $proto, $identified, $self->_error_body( $env, $proto ) ) ) {
    return [ $status, [ 'Content-Type' => $ctype ], [ $body ] ];
  }
  my $identity = $identified->{identity} // {};

  # No setup delivered yet (remote_config): 503, as on the native server (k75).
  if ( my ($status, $ctype, $body) = $sb->_not_configured_answer( $proto, $self->_error_body( $env, $proto ) ) ) {
    return [ $status, [ 'Content-Type' => $ctype ], [ $body ] ];
  }

  # Whatever fails from here is answered like the native server answers
  # it, in the protocol's error shape: a handler failure with the status
  # of its category (504 for an upstream timeout, k36; 404 for a model
  # nothing serves, k41), anything else 500 (k78). A stream is buffered, so
  # nothing has gone out yet when its handler fails, mid-stream included.
  my ( $res, $sb_req, $raw_body );
  return $res if eval { $res = $self->_handle_action( $env, $route, $fake_http, \$sb_req, \$raw_body, $identity ); 1 };
  my $e = $@;
  my ( $message, $category ) = blessed($e) && $e->isa('Future::Exception')
    ? ( $e->message, $e->category ) : ( $e );
  # The client gets the cleaned text; the log keeps the whole message (k79).
  $log->errorf( 'Request error (%s): %s', $route->{action}, $message );
  my ($status, $ctype, $body) = $sb->_handler_failure_answer( $proto, $message, $category, $sb_req, $raw_body );
  return [ $status, [ 'Content-Type' => $ctype ], [ $body ] ];
}

# A request past the auth and setup checks, answered as a PSGI response.
# Dies on any failure; _handle_psgi answers it. The parsed request is put
# into $$request_slot as soon as it exists, so the error answer can address it.
sub _handle_action {
  my ($self, $env, $route, $fake_http, $request_slot, $body_slot, $identity) = @_;
  my $sb = $self->knarr;
  my $path   = $env->{PATH_INFO} // '/';
  my $proto  = $route->{protocol};
  my $action = $route->{action};

  if ( $action eq 'models' || $action eq 'acp_agents' ) {
    my $models = $sb->_visible_models($identity);
    my ($status, $headers, $body) = $proto->format_models_response($models);
    return [ $status, [ %$headers ], [ $body ] ];
  }
  if ( $action eq 'manifest' ) {
    if ( my ($status, $ctype, $body) = $sb->_authorize_refusal( $proto, $identity, 'manifest', undef ) ) {
      return [ $status, [ 'Content-Type' => $ctype ], [ $body ] ];
    }
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
    my ($status, $headers, $body) = $sb->$simple( $proto, $self->_read_body($env), $identity );
    return [ $status, [ %$headers ], [ $body ] ];
  }
  if ( $action eq 'a2a_card' ) {
    my ($status, $headers, $body) = $proto->format_agent_card;
    return [ $status, [ %$headers ], [ $body ] ];
  }
  if ( $action ne 'chat' ) {
    my ($status, $ctype, $body) = $sb->_error_answer( $proto, 500, "unknown action $action",
      undef, $self->_error_body( $env, $proto ) );
    return [ $status, [ 'Content-Type' => $ctype ], [ $body ] ];
  }

  my $body = $self->_read_body($env);
  $$body_slot = $body if $body_slot;
  my $sb_req = $sb->_parse_chat_request( $proto, $fake_http, \$body, $identity );
  $$request_slot = $sb_req if $request_slot;
  # The model is known now (k82): refused before any handler work.
  if ( my ($status, $ctype, $obody) = $sb->_authorize_refusal( $proto, $identity, 'chat', $sb_req->model, $sb_req, $body ) ) {
    return [ $status, [ 'Content-Type' => $ctype ], [ $obody ] ];
  }

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
    return [ 200, [ 'Content-Type' => $proto->stream_content_type ], [ $out ] ];
  }

  my $response = $get->( $handler->handle_chat_f( $session, $sb_req ) );
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

version 1.103

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

Requests are authenticated exactly like on the native server, by the same
L<Langertha::Knarr/authorizer>: with L<Langertha::Knarr/auth_token> set,
every route except the A2A agent card needs the key as
C<Authorization: Bearer> or C<x-api-key>, and a missing or wrong key gets
the same C<401>, in the route's protocol's error shape. Under token auth
(L<Langertha::Knarr::Authorizer::Token>) the same C<401>, C<403> and
C<503> come back as on the native server; the token check blocks the
request here (L<Langertha::Knarr::Authorizer/identify>) and asks the token
store every time, without the native server's cache.
Every other error is answered as on the native server too (see
L<Langertha::Knarr/ERRORS>): a failed handler or backend with its status
in the protocol's error shape. As a stream is buffered here, a stream
that fails at any point gets that status, not a C<200>.

The admin routes (see L<Langertha::Knarr/ADMIN ROUTES> and
L<Langertha::Knarr::Admin>) work as on the native server, with one more
rule each: the request body is read only once the admin key was checked and
the C<Content-Length> is within the limit, and under a PSGI server that
sets C<psgi.multiprocess> (a prefork server such as Starman) every admin
route answers C<501> -- each of its processes would hold a setup of its
own, and a push would reach one of them. Run such a Knarr on a
single-process server. Without a delivered setup, every other route answers
C<503> as on the native server.

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
