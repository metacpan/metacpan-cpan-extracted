package Langertha::Knarr;
# ABSTRACT: Universal LLM hub — proxy, server, and translator across OpenAI/Anthropic/Ollama/A2A/ACP/AG-UI
our $VERSION = '1.100';
use Moose;
use Future::AsyncAwait;
use IO::Async::Loop;
use Net::Async::HTTP::Server;
use HTTP::Response;
use JSON::MaybeXS;
use Data::UUID;
use Module::Runtime qw( use_module );
use Scalar::Util qw( blessed );
use Try::Tiny;
use Log::Any qw( $log );
use Langertha::Knarr::Session;



has handler => (
  is => 'ro',
  required => 1,
);

has host => (
  is => 'ro',
  isa => 'Str',
  default => '127.0.0.1',
);

has port => (
  is => 'ro',
  isa => 'Int',
  default => 8088,
);

# Listen on one or more addresses. Each entry is either "host:port" or
# { host => ..., port => ... }. Defaults to a single entry composed from
# the host/port attributes above.
has listen => (
  is => 'ro',
  isa => 'ArrayRef',
  lazy => 1,
  builder => '_build_listen',
);

sub _build_listen {
  my ($self) = @_;
  return [ { host => $self->host, port => $self->port + 0 } ];
}

has loop => (
  is => 'ro',
  lazy => 1,
  builder => '_build_loop',
);
sub _build_loop { IO::Async::Loop->new }

has protocols => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [qw( OpenAI Anthropic Ollama A2A ACP AGUI )] },
);

# Optional shared secret. When set, every incoming request must present it
# either as 'Authorization: Bearer <key>' or 'x-api-key: <key>'. The agent
# card and well-known discovery routes are exempt because they need to be
# anonymously fetchable.
has router => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

has raw_passthrough => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

has tracing => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

has auth_token => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has _protocol_objects => (
  is => 'ro',
  lazy => 1,
  builder => '_build_protocol_objects',
);

has _routes => (
  is => 'ro',
  lazy => 1,
  builder => '_build_routes',
);

has _sessions => (
  is => 'ro',
  default => sub { {} },
);

has _uuid => (
  is => 'ro',
  default => sub { Data::UUID->new },
);

has _json => (
  is => 'ro',
  default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) },
);

has _server => (
  is => 'rw',
);

has _servers => (
  is => 'rw',
  default => sub { [] },
);

sub _build_protocol_objects {
  my ($self) = @_;
  my @objs;
  for my $name ( @{ $self->protocols } ) {
    my $class = $name =~ /::/ ? $name : "Langertha::Knarr::Protocol::$name";
    use_module($class);
    push @objs, $class->new;
  }
  return \@objs;
}

sub _build_routes {
  my ($self) = @_;
  my @routes;
  for my $proto ( @{ $self->_protocol_objects } ) {
    for my $r ( @{ $proto->protocol_routes } ) {
      push @routes, { %$r, protocol => $proto };
    }
  }
  return \@routes;
}

sub session {
  my ($self, $id) = @_;
  $id //= $self->_uuid->create_str;
  $self->_sessions->{$id} //= Langertha::Knarr::Session->new( id => $id );
  $self->_sessions->{$id}->touch;
  return $self->_sessions->{$id};
}

sub _listen_addrs {
  my ($self) = @_;
  my @out;
  for my $entry ( @{ $self->listen } ) {
    if ( ref $entry eq 'HASH' ) {
      push @out, { host => $entry->{host} // '127.0.0.1', port => $entry->{port} + 0 };
    } else {
      my ($h, $p) = split /:/, $entry, 2;
      $h ||= '127.0.0.1';
      push @out, { host => $h, port => ($p // 8088) + 0 };
    }
  }
  return @out;
}

sub start {
  my ($self) = @_;
  my @servers;
  for my $a ( $self->_listen_addrs ) {
    my $server = Net::Async::HTTP::Server->new(
      on_request => sub {
        my ($srv, $req) = @_;
        $self->_dispatch($req);
      },
    );
    $self->loop->add($server);
    $server->listen(
      addr => {
        family   => 'inet',
        socktype => 'stream',
        port     => $a->{port},
        ip       => $a->{host},
      },
    )->get;
    push @servers, $server;
  }
  $self->_servers(\@servers);
  $self->_server( $servers[0] );
  return $self;
}

sub run {
  my ($self) = @_;
  $self->start unless $self->_server;
  $self->loop->run;
}

sub _match_route {
  my ($self, $method, $path) = @_;
  for my $r ( @{ $self->_routes } ) {
    next unless $r->{method} eq $method;
    return $r if $r->{path} eq $path;
  }
  return undef;
}

sub _check_auth {
  my ($self, $req, $action) = @_;
  return 1 unless defined $self->auth_token && length $self->auth_token;
  # Discovery endpoints stay anonymous so clients can introspect.
  return 1 if $action eq 'a2a_card';
  my $expected = $self->auth_token;
  my $auth = scalar( $req->header('Authorization') ) // '';
  if ( $auth =~ /^Bearer\s+(.+)$/i && $1 eq $expected ) {
    return 1;
  }
  my $api_key = scalar( $req->header('x-api-key') ) // '';
  return 1 if $api_key eq $expected && length $api_key;
  return 0;
}

sub _dispatch {
  my ($self, $req) = @_;
  my $method = $req->method;
  my $path   = $req->path;
  my $route  = $self->_match_route( $method, $path );
  unless ( $route ) {
    return $self->_send_simple( $req, 404, 'application/json',
      $self->_json->encode({ error => { message => "no route for $method $path" } }) );
  }
  my $action = $route->{action};
  unless ( $self->_check_auth( $req, $action ) ) {
    return $self->_send_simple( $req, 401, 'application/json',
      $self->_json->encode({ error => { message => 'unauthorized' } }) );
  }
  my $proto  = $route->{protocol};
  my $code = $self->can("_action_$action");
  unless ( $code ) {
    return $self->_send_simple( $req, 500, 'application/json',
      $self->_json->encode({ error => { message => "unknown action $action" } }) );
  }
  try {
    $self->$code( $proto, $req );
  } catch {
    my $err = $_;
    $log->errorf("Request error (%s): %s", $action, $err);
    $self->_send_simple( $req, 500, 'application/json',
      $self->_json->encode({ error => { message => "$err" } }) );
  };
}

sub _action_chat {
  my ($self, $proto, $req) = @_;
  my $body = $req->body;
  my $sb_req = $proto->parse_chat_request( $req, \$body );

  # Raw passthrough: pipe bytes 1:1 to upstream, skip handler chain
  if ($self->raw_passthrough && $self->router
      && $self->router->is_passthrough_model($sb_req->model)) {
    return $self->_handle_raw_passthrough( $proto, $req, $sb_req );
  }

  my $session = $self->session( $sb_req->session_id );
  my $handler = $self->handler;

  if ( $sb_req->stream ) {
    return $self->_handle_stream( $proto, $req, $sb_req, $session, $handler );
  }

  my $f = $handler->handle_chat_f( $session, $sb_req );
  $f->on_done( sub {
    my ($response) = @_;
    try {
      my ($status, $headers, $body) = $proto->format_chat_response( $response, $sb_req );
      $self->_send_simple( $req, $status, $headers->{'Content-Type'} // 'application/json', $body );
    } catch {
      my $err = $_;
      $log->errorf("Chat response error: %s", $err);
      $self->_send_simple( $req, 500, 'application/json',
        $self->_json->encode({ error => { message => "$err" } }) );
    };
  });
  $f->on_fail( sub {
    my ($err) = @_;
    $log->errorf("Chat handler error: %s", $err);
    $self->_send_simple( $req, 500, 'application/json',
      $self->_json->encode({ error => { message => "$err" } }) );
  });
  $f->retain;
}

sub _handle_stream {
  my ($self, $proto, $req, $sb_req, $session, $handler) = @_;

  my $header = HTTP::Response->new( 200 );
  $header->protocol('HTTP/1.1');
  $header->header( 'Content-Type'  => $proto->stream_content_type );
  $header->header( 'Cache-Control' => 'no-cache' );
  $req->respond_chunk_header( $header );

  my $write = sub {
    my ($bytes) = @_;
    return unless defined $bytes && length $bytes;
    return if $req->is_closed;
    $req->write_chunk( $bytes );
  };

  my $f = $handler->handle_stream_f( $session, $sb_req );
  $f->on_done( sub {
    my ($stream) = @_;
    $write->( $proto->format_stream_open($sb_req) );
    my $pump; $pump = sub {
      if ( $req->is_closed ) { undef $pump; return }
      $stream->next_chunk_f->on_done( sub {
        my ($delta) = @_;
        if ( $req->is_closed ) { undef $pump; return }
        if ( defined $delta ) {
          $write->( $proto->format_stream_chunk( $delta, $sb_req ) );
          $pump->();
        }
        else {
          $write->( $proto->format_stream_close($sb_req) );
          $write->( $proto->format_stream_done($sb_req) );
          $req->write_chunk_eof;
          undef $pump;
        }
      })->on_fail( sub {
        my ($err) = @_;
        $log->errorf("Stream chunk error: %s", $err);
        $write->( $proto->format_stream_chunk( "[error: $err]", $sb_req ) );
        $write->( $proto->format_stream_close($sb_req) );
        $req->write_chunk_eof;
        undef $pump;
      });
    };
    $pump->();
  });
  $f->on_fail( sub {
    my ($err) = @_;
    $log->errorf("Stream handler error: %s", $err);
    $write->( $proto->format_stream_chunk( "[error: $err]", $sb_req ) );
    $req->write_chunk_eof;
  });
  $f->retain;
}

sub _handle_raw_passthrough {
  my ($self, $proto, $req, $sb_req) = @_;
  my $pt = $self->raw_passthrough;
  my $model = $sb_req->model // 'unknown';
  my $protocol = $sb_req->protocol;

  # Build upstream URL from passthrough config
  my $url = $pt->_upstream_url($protocol);
  my $http_req = HTTP::Request->new(POST => $url);

  # Forward all client headers except hop-by-hop / connection-specific
  my %skip = map { lc($_) => 1 } qw( host content-length connection transfer-encoding );
  for my $pair ($req->headers) {
    my ($name, $value) = @$pair;
    next if $skip{lc($name)};
    $http_req->header($name => $value);
  }
  $http_req->content($req->body);

  $log->infof("Passthrough %s [%s] -> %s", $model, $protocol, $url);

  # Lightweight tracing for passthrough requests
  my $trace = $self->tracing ? $self->tracing->start_trace(
    model    => $model,
    engine   => 'passthrough',
    format   => $protocol,
    messages => $sb_req->messages,
  ) : undef;

  if ($sb_req->stream) {
    my $f = $pt->_http->do_request(
      request   => $http_req,
      on_header => sub {
        my ($response) = @_;
        my $header = HTTP::Response->new($response->code);
        $header->protocol('HTTP/1.1');
        $header->header('Content-Type'  => scalar $response->header('Content-Type'));
        $header->header('Cache-Control' => 'no-cache');
        $req->respond_chunk_header($header);

        return sub {
          my ($data) = @_;
          if (!defined $data) {
            $req->write_chunk_eof unless $req->is_closed;
            $self->tracing->end_trace($trace, output => '[stream]') if $trace;
            return;
          }
          $req->write_chunk($data) unless $req->is_closed;
        };
      },
    );
    $f->on_fail(sub {
      my ($err) = @_;
      $log->errorf("Passthrough stream error [%s]: %s", $model, $err);
      $self->tracing->end_trace($trace, error => "$err") if $trace;
      $req->write_chunk_eof unless $req->is_closed;
    });
    $f->retain;
  } else {
    my $f = $pt->_http->do_request(request => $http_req);
    $f->on_done(sub {
      my ($resp) = @_;
      $self->_send_simple($req, $resp->code,
        scalar $resp->header('Content-Type') // 'application/json',
        $resp->decoded_content);
      $self->tracing->end_trace($trace, output => '[passthrough]') if $trace;
    });
    $f->on_fail(sub {
      my ($err) = @_;
      $log->errorf("Passthrough error [%s]: %s", $model, $err);
      $self->tracing->end_trace($trace, error => "$err") if $trace;
      $self->_send_simple($req, 502, 'application/json',
        $self->_json->encode({ error => { message => "passthrough failed: $err" } }));
    });
    $f->retain;
  }
}

sub _action_acp_agents { goto &_action_models }
sub _action_a2a_card {
  my ($self, $proto, $req) = @_;
  my ($status, $headers, $body) = $proto->format_agent_card;
  $self->_send_simple( $req, $status, $headers->{'Content-Type'} // 'application/json', $body );
}

sub _action_models {
  my ($self, $proto, $req) = @_;
  my $models = $self->handler->list_models;
  my ($status, $headers, $body) = $proto->format_models_response( $models );
  $self->_send_simple( $req, $status, $headers->{'Content-Type'} // 'application/json', $body );
}

sub _send_simple {
  my ($self, $req, $status, $ctype, $body) = @_;
  my $resp = HTTP::Response->new( $status );
  $resp->protocol('HTTP/1.1');
  $resp->header( 'Content-Type'   => $ctype );
  $resp->header( 'Content-Length' => length($body) );
  $resp->content($body);
  $req->respond($resp);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr - Universal LLM hub — proxy, server, and translator across OpenAI/Anthropic/Ollama/A2A/ACP/AG-UI

=head1 VERSION

version 1.100

=head1 SYNOPSIS

The fastest way to use Knarr is the Docker image:

    docker run -e ANTHROPIC_API_KEY -p 8080:8080 raudssus/langertha-knarr
    ANTHROPIC_BASE_URL=http://localhost:8080 claude

The Perl API behind it:

    use IO::Async::Loop;
    use Langertha::Knarr;
    use Langertha::Knarr::Config;
    use Langertha::Knarr::Router;
    use Langertha::Knarr::Handler::Router;

    my $loop   = IO::Async::Loop->new;
    my $config = Langertha::Knarr::Config->new(file => 'knarr.yaml');
    my $router = Langertha::Knarr::Router->new(config => $config);

    my $knarr = Langertha::Knarr->new(
        handler => Langertha::Knarr::Handler::Router->new(router => $router),
        loop    => $loop,
        listen  => $config->listen,
    );
    $knarr->run;   # blocks; OpenWebUI etc. can now connect

=head1 DESCRIPTION

Langertha::Knarr is a universal LLM hub that exposes any backend — a
L<Langertha::Raider>, a raw L<Langertha::Engine>, a remote A2A or ACP
agent, or any custom L<Langertha::Knarr::Handler> — over the standard
LLM HTTP wire protocols spoken by OpenWebUI, the OpenAI / Anthropic /
Ollama SDKs, and the agent ecosystems around A2A, ACP, and AG-UI.

By default a single running Knarr answers OpenAI
C</v1/chat/completions>, Anthropic C</v1/messages>, Ollama
C</api/chat>, A2A's C</.well-known/agent.json> plus JSON-RPC C</>,
ACP's C</runs>, and AG-UI's C</awp> simultaneously on every listening
port. The same handler implementation drives all of them.

Knarr 1.000 is built on L<IO::Async> and L<Net::Async::HTTP::Server>
with native L<Future::AsyncAwait> integration into Langertha engines,
so streaming works end-to-end token-by-token without any thread or
event-loop bridges.

=head1 ARCHITECTURE

Three pluggable layers:

=over

=item B<Protocols>

Wire formats live in C<Langertha::Knarr::Protocol::*>. Each consumes
L<Langertha::Knarr::Protocol> and is loaded by default. See
L<Langertha::Knarr::Protocol::OpenAI>,
L<Langertha::Knarr::Protocol::Anthropic>,
L<Langertha::Knarr::Protocol::Ollama>,
L<Langertha::Knarr::Protocol::A2A>,
L<Langertha::Knarr::Protocol::ACP>,
L<Langertha::Knarr::Protocol::AGUI>.

=item B<Handlers>

Backend logic — what answers the request. Knarr ships with
L<Langertha::Knarr::Handler::Router> (the default, model→engine via
L<Langertha::Knarr::Router>), L<Langertha::Knarr::Handler::Engine>
(single engine), L<Langertha::Knarr::Handler::Raider> (per-session
agent), L<Langertha::Knarr::Handler::Passthrough> (raw HTTP forward),
L<Langertha::Knarr::Handler::A2AClient> /
L<Langertha::Knarr::Handler::ACPClient> (consume remote agents), and
L<Langertha::Knarr::Handler::Code> (coderef-backed for tests). Implement
L<Langertha::Knarr::Handler> to write your own. Decorators
(L<Langertha::Knarr::Handler::Tracing>,
L<Langertha::Knarr::Handler::RequestLog>) wrap any inner handler and
add behavior on top — they themselves consume the Handler role and
compose freely.

=item B<Transport>

Default is L<Net::Async::HTTP::Server> with chunked SSE / NDJSON
streaming on one or more listen sockets. For Plack deployments,
L<Langertha::Knarr::PSGI> wraps the same Knarr instance into a PSGI
app (buffered — see its docs for the streaming caveat).

=back

=head2 handler

Required. An object consuming L<Langertha::Knarr::Handler>.

=head2 listen

ArrayRef of C<host:port> strings or C<< { host => ..., port => ... } >>
hashes. Defaults to a single entry composed from L</host> and L</port>.

=head2 host

Default C<127.0.0.1>. Used when L</listen> is not given.

=head2 port

Default C<8088>. Used when L</listen> is not given.

=head2 loop

Optional L<IO::Async::Loop> instance. Defaults to a fresh one.

=head2 protocols

ArrayRef of protocol class basenames to load. Defaults to all six
shipped protocols.

=head2 auth_token

Optional shared secret. When set, every incoming request must present
it as C<Authorization: Bearer> or C<x-api-key>. Discovery routes
(C</.well-known/agent.json>) stay anonymous.

=head2 start

    $knarr->start;

Binds all listen sockets and registers the dispatcher. Returns
C<$self>. Does not enter the event loop.

=head2 run

    $knarr->run;   # blocks

Calls L</start> if needed, then enters the L</loop> and blocks.

=head2 session

    my $session = $knarr->session($id);

Returns the L<Langertha::Knarr::Session> for the given id, creating
one on demand. Used internally by the dispatcher.

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
