package Langertha::Knarr;
# ABSTRACT: Universal LLM hub - proxy, server, and translator across OpenAI/Anthropic/Ollama/A2A/ACP/AG-UI
our $VERSION = '1.103';
use Moose;
use Future;
use Future::AsyncAwait;
use Future::Exception;
use IO::Async::Loop;
use IO::Async::Resolver;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use HTTP::Response;
use JSON::MaybeXS;
use Data::UUID;
use Module::Runtime qw( use_module );
use Scalar::Util qw( blessed );
use Time::HiRes ();
use Try::Tiny;
use Carp ();
use POSIX ();
use Socket ();
use Log::Any qw( $log );
use Langertha::Knarr::Session;
use Langertha::Knarr::Authorizer::StaticKey;
use Langertha::Knarr::Manifest;
use Langertha::Knarr::PassthroughUsage;
use Langertha::Knarr::Role::UpstreamHTTP ();



# Required, unless an admin brings it with its stack (k75). Replaced as a
# whole by _apply_stack.
has handler => (
  is => 'ro',
  writer => '_set_handler',
  predicate => '_has_handler',
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

# Serving processes (k51): 1 is this one, more are forked by run().
has workers => (
  is => 'ro',
  isa => 'Int',
  default => 1,
  trigger => sub {
    Carp::croak( "workers '$_[1]' must be 1 or more" ) unless $_[1] >= 1;
  },
);

has protocols => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [qw( OpenAI Anthropic Ollama A2A ACP AGUI )] },
);

has protocol_args => (
  is => 'ro',
  isa => 'HashRef[HashRef]',
  default => sub { {} },
);

# Optional shared secret. When set, every incoming request must present it
# either as 'Authorization: Bearer <key>' or 'x-api-key: <key>'. The agent
# card and well-known discovery routes are exempt because they need to be
# anonymously fetchable.
has router => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
  writer => '_set_router',
);

has raw_passthrough => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
  writer => '_set_raw_passthrough',
);

has tracing => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
  writer => '_set_tracing',
);

has auth_token => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
  writer => '_set_auth_token',
  # The default authorizer is built over the key: a new key (admin push,
  # k75) needs a new one.
  trigger => sub { $_[0]->_clear_static_authorizer },
);

# Who may use this Knarr and with which model (k82). A given authorizer
# stays for the Knarr's life; without one, a StaticKey over auth_token.
has _authorizer => (
  is => 'ro',
  isa => 'Maybe[Object]',
  init_arg => 'authorizer',
  default => sub { undef },
  writer => '_set_authorizer',
);

has _static_authorizer => (
  is => 'ro',
  lazy => 1,
  builder => '_build_static_authorizer',
  clearer => '_clear_static_authorizer',
);

# The class of the default authorizer, named once (override point).
sub static_authorizer_class { 'Langertha::Knarr::Authorizer::StaticKey' }

sub _build_static_authorizer {
  my ($self) = @_;
  return $self->static_authorizer_class->new( key => $self->auth_token );
}

sub authorizer {
  my ($self) = @_;
  return $self->_authorizer // $self->_static_authorizer;
}

# Admin routes and the setup they deliver (k75): a Langertha::Knarr::Admin.
has admin => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

has public_url => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

# What GET /api/version answers (k27): the Ollama version the Ollama
# endpoints are compatible with, not Knarr's own. Current Ollama release
# (k28); it must stay >= 0.6.4 (Copilot BYOK floor) and digits-and-dots only
# (Open WebUI int()s each part).
has ollama_compat_version => (
  is => 'ro',
  isa => 'Str',
  default => '0.34.4',
  trigger => sub { _check_ollama_compat_version( $_[1] ) },
);

sub _check_ollama_compat_version {
  my ($version) = @_;
  Carp::croak( "ollama_compat_version '$version' must be three dot-separated"
    . " numbers like 0.34.4 (Ollama clients parse each part as an integer)" )
    unless $version =~ /\A\d+\.\d+\.\d+\z/;
  return $version;
}

has _manifest => (
  is => 'ro',
  lazy => 1,
  default => sub { Langertha::Knarr::Manifest->new( knarr => $_[0] ) },
  clearer => '_clear_manifest',
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

# The startup capability probe (k37), held until it is ready.
has _capability_probe => (
  is => 'rw',
);

# The process that serves requests: set by start() with one worker and by
# each forked worker, never in the prefork supervisor (k82).
has _serving_pid => (
  is => 'rw',
  default => 0,
);

has _servers => (
  is => 'rw',
  default => sub { [] },
);

sub BUILD {
  my ($self) = @_;
  if ( my $admin = $self->admin ) {
    # Every process holds its own delivered setup: a push would reach one
    # worker of several (k75).
    Carp::croak( "workers '".$self->workers."' cannot be combined with admin routes:"
      . " each worker would hold its own setup" ) if $self->workers > 1;
    # A tracing given to the constructor stays when the stack has none.
    my $tracing = $self->tracing;
    $self->_apply_stack( $admin->stack );
    $self->_set_tracing($tracing) if $tracing && !$admin->stack->tracing;
  }
  Carp::croak( 'Attribute (handler) is required' ) unless $self->_has_handler;
}

# The parts of a Langertha::Knarr::Stack that serve requests, swapped in at
# once (k75): no event loop turn between them, so a request sees either the
# old parts or the new ones. A request already running keeps the objects it
# holds -- a stream goes on with its engine. The manifest and the capability
# probe belong to the router and start over with the new one.
sub _apply_stack {
  my ($self, $stack) = @_;
  $self->_set_handler( $stack->handler );
  $self->_set_router( $stack->router );
  $self->_set_raw_passthrough( $stack->raw_passthrough );
  $self->_set_auth_token( $stack->auth_token );
  # A token_auth stack brings its authorizer (the same object across pushes,
  # k82); otherwise the proxy key keeps being checked.
  $self->_set_authorizer( $stack->authorizer ) if $stack->authorizer;
  # A delivered langfuse section brings its own tracing (k75).
  $self->_set_tracing( $stack->tracing );
  # A serving process starts an authorizer it got from a push; the one it
  # already had ignores the second start.
  $self->_start_authorizer if $self->_serving_pid == $$;
  $self->_clear_manifest;
  if ( $self->_server ) {
    if ( my $probe = $self->_capability_probe ) {
      $probe->cancel unless $probe->is_ready;
    }
    $self->_capability_probe(undef);
    $self->_start_capability_probe;
  }
  return;
}

sub _build_protocol_objects {
  my ($self) = @_;
  my @objs;
  for my $name ( @{ $self->protocols } ) {
    my $class = $name =~ /::/ ? $name : "Langertha::Knarr::Protocol::$name";
    use_module($class);
    push @objs, $class->new( %{ $self->protocol_args->{$name} // {} } );
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
  # Knarr's own route, not a protocol's (k14).
  push @routes, { method => 'GET', path => '/.well-known/langertha.json',
    action => 'manifest', protocol => undef };
  # The admin routes exist only with an admin (k75): without one they are a
  # path like any unknown one.
  if ( my $admin = $self->admin ) {
    push @routes, map { { %$_, protocol => undef, admin => 1 } } $admin->routes;
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
  $self->_listen;
  $self->_start_capability_probe;
  # With workers, the supervisor only binds: each worker starts serving.
  $self->_start_serving unless $self->workers > 1;
  return $self;
}

# This process serves from now on: its loop is set up, so the authorizer
# can open its connection (k82) -- once per process, never in the
# supervisor of prefork workers, whose connection every worker would share.
sub _start_serving {
  my ($self) = @_;
  $self->_serving_pid($$);
  $self->_start_authorizer;
  return;
}

# Authorizer->start does not wait for its connection. A failure to start is
# logged: the authorizer still answers every request (503 while its store
# is not available).
sub _start_authorizer {
  my ($self) = @_;
  my $authorizer = $self->authorizer;
  return unless $authorizer && $authorizer->can('start');
  eval { $authorizer->start( $self->loop ); 1 }
    or $log->errorf( 'Authorizer start failed: %s', _error_text($@) );
  return;
}

sub _listen {
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
      queuesize => $self->_listen_backlog,
    )->get;
    push @servers, $server;
  }
  $self->_servers(\@servers);
  $self->_server( $servers[0] );
  return;
}

# Connections the kernel queues until a process accepts them (k51): the
# system maximum, not IO::Async's default of 3 -- with workers, connections
# wait here while the probe runs before the fork. The kernel caps it at
# net.core.somaxconn.
sub _listen_backlog {
  my ($self) = @_;
  my $max = eval { Socket::SOMAXCONN() };
  return $max && $max > 0 ? $max : 128;
}

# k37: once the server listens, ask each routed engine for its model's
# capabilities (Router->probe_capabilities_f). Deferred to the running loop
# so start() does not block on discovery; the Future is held here until it
# is ready. It never fails: probe errors are logged by the router.
sub _start_capability_probe {
  my ($self) = @_;
  my $router = $self->router;
  return unless $router && $router->can('probe_capabilities_f');
  return if $self->_capability_probe;
  my $loop = $self->loop;
  $self->_capability_probe( $loop->delay_future( after => 0 )->then(sub {
    $router->probe_capabilities_f( loop => $loop );
  })->else(sub {
    $log->warnf( "Capability probe failed: %s", $_[0] );
    Future->done(0);
  }) );
  return;
}

sub run {
  my ($self) = @_;
  return $self->_run_workers if $self->workers > 1;
  $self->start unless $self->_server;
  $self->loop->run;
}

# k51: prefork. This process binds, discovers and probes once, forks the
# workers -- which inherit all of it -- and supervises them until SIGTERM or
# SIGINT. It serves no request itself.
sub _run_workers {
  my ($self) = @_;
  $self->_prepare_workers;

  my %workers;   # pid => start time
  my $stopping = 0;
  my $stop = sub {
    my ($signal) = @_;
    $log->infof( "SIG%s: stopping %d worker(s)", $signal, scalar keys %workers )
      unless $stopping;
    $stopping = 1;
    kill TERM => keys %workers;
  };
  local $SIG{TERM} = $stop;
  local $SIG{INT}  = $stop;

  my $spawn = sub {
    my $pid = $self->_fork_worker;
    $workers{$pid} = time;
    kill TERM => $pid if $stopping;   # the signal came in during the fork
    $log->infof( "Worker %d started", $pid );
  };

  try {
    # Only these first forks must succeed: without them nothing serves.
    $spawn->() for 1 .. $self->workers;
    my $delay = 0;
    while ( %workers || !$stopping ) {
      my $missing = $stopping ? 0 : $self->workers - keys %workers;
      if ( $missing > 0 ) {
        sleep $delay if $delay;   # a signal ends it early
        next if $stopping;
        next if eval { $spawn->(); 1 };
        # A replacement that cannot be forked (EAGAIN, ENOMEM) is treated
        # like a crashing worker: the others keep serving, and it is tried
        # again after a pause (k64).
        $delay = $self->_restart_delay($delay);
        $log->errorf( "%s; trying again in %ds", _error_text($@), $delay );
      }
      # While a worker is missing, only look: the retry must not wait for
      # the next death.
      my $pid = waitpid( -1, $missing > 0 ? POSIX::WNOHANG() : 0 );
      next if $pid == 0;
      if ( $pid < 0 ) {   # no children left
        last unless $missing > 0;
        next;
      }
      my $started = delete $workers{$pid} // next;
      next if $stopping;
      my $status = $?;
      # A worker that dies within 5s of its start is crashing: pause before
      # the next one, so it cannot spin.
      $delay = time - $started < 5 ? $self->_restart_delay($delay) : 0;
      $log->warnf( "Worker %d %s, starting a new one%s", $pid,
        $self->_exit_text($status), $delay ? " in ${delay}s" : '' );
    }
  } catch {
    my $err = $_;
    kill TERM => keys %workers;
    waitpid( $_, 0 ) for keys %workers;
    die $err;
  };
  return;
}

# The pause before the next restart: 1, 2, 4 ... 30 seconds.
sub _restart_delay {
  my ($self, $delay) = @_;
  $delay = $delay ? $delay * 2 : 1;
  return $delay > 30 ? 30 : $delay;
}

sub _prepare_workers {
  my ($self) = @_;
  $self->_listen unless $self->_server;
  my $loop = $self->loop;
  # The sockets stay bound here for the workers, but this process accepts
  # nothing on them.
  $loop->remove($_) for grep { $_->loop } @{ $self->_servers };
  if ( my $router = $self->router ) {
    $router->list_models if $router->can('list_models');   # auto-discovery
    $self->_start_capability_probe;
    $self->_capability_probe->get if $self->_capability_probe;
  }
  $self->_drop_upstream_connections;
  $self->_drop_resolver;
  return;
}

# Keep-alive upstream connections (the probe's) must not reach the workers:
# two processes on one socket read each other's responses. A
# Net::Async::HTTP closes its pooled connections when it leaves the loop and
# connects anew once it is back.
sub _drop_upstream_connections {
  my ($self) = @_;
  my $loop = $self->loop;
  for my $http ( grep { $_->isa('Net::Async::HTTP') } $loop->notifiers ) {
    if ( my $parent = $http->parent ) {
      $parent->remove_child($http);
      $parent->add_child($http);
    }
    else {
      $loop->remove($http);
      $loop->add($http);
    }
  }
  return;
}

# The loop's resolver looks names up in helper processes, started by the
# first connect to a hostname -- the probe's. Workers that inherited them
# would share their pipes and read each other's answers: a request would go
# to another request's upstream, or hang (k63). The helpers exit here, and
# the loop gets a fresh resolver, for which every worker starts its own.
# Waiting for their exit also clears the loop's watch on their pids, which
# a worker's own helper could otherwise reuse.
sub _drop_resolver {
  my ($self) = @_;
  my $loop = $self->loop;
  my @resolvers = grep { $_->isa('IO::Async::Resolver') && !$_->parent } $loop->notifiers
    or return;
  for my $resolver (@resolvers) {
    my $stopped = $resolver->stop;
    Future->wait_any( $stopped, $loop->delay_future( after => 10 ) )->get;
    $log->warn("Resolver helpers did not exit within 10s") unless $stopped->is_ready;
    $loop->remove($resolver);
  }
  $loop->set_resolver( IO::Async::Resolver->new );
  return;
}

# Returns the worker's pid in the supervisor; the worker itself never
# returns. It drops the supervisor's signal handlers, rebuilds the loop's
# kernel state (epoll/kqueue fd, signal pipe) and accepts on the inherited
# sockets. POSIX::_exit: the supervisor's END blocks and destructors are not
# the worker's to run.
#
# SIGTERM and SIGINT stay blocked from before the fork until the worker has
# dropped the supervisor's handlers (k64): one that reached the worker in
# between would run the supervisor's stop -- killing the other workers --
# and the worker would serve on. Blocked, it waits and then ends the worker;
# in the supervisor it runs once the fork is done.
sub _fork_worker {
  my ($self) = @_;
  my $signals = POSIX::SigSet->new( POSIX::SIGTERM(), POSIX::SIGINT() );
  my $mask = POSIX::SigSet->new;
  POSIX::sigprocmask( POSIX::SIG_BLOCK(), $signals, $mask )
    or Carp::croak( "Cannot block signals for the fork: $!" );
  my $pid = $self->_fork;
  my $error = $!;
  if ( defined $pid && !$pid ) {
    $SIG{$_} = 'DEFAULT' for qw( TERM INT );
  }
  POSIX::sigprocmask( POSIX::SIG_SETMASK(), $mask );
  Carp::croak( "Cannot fork a worker: $error" ) unless defined $pid;
  return $pid if $pid;
  my $ok = eval {
    my $loop = $self->loop;
    $loop->post_fork;
    $loop->add($_) for @{ $self->_servers };
    $self->_start_serving;
    $loop->run;
    1;
  };
  $log->errorf( "Worker %d failed: %s", $$, $@ ) unless $ok;
  POSIX::_exit( $ok ? 0 : 1 );
}

# The fork itself, apart so a test can make it fail.
sub _fork { fork }

sub _exit_text {
  my ($self, $status) = @_;
  return 'was killed by signal ' . ( $status & 127 ) if $status & 127;
  return 'exited with status ' . ( $status >> 8 );
}

sub _match_route {
  my ($self, $method, $path) = @_;
  for my $r ( @{ $self->_routes } ) {
    next unless $r->{method} eq $method;
    return $r if $r->{path} eq $path;
  }
  return undef;
}

# The identify phase (k82), as a Future that is done with
# { identity => \%identity } or { status, message } and never fails. The
# admin key opens the admin routes and nothing else: it must never reach a
# handler or an upstream, whatever the authorizer (k75). An authorizer that
# fails anyway is a check that could not be made: 503, never a way in.
sub _identify_f {
  my ($self, $req, $action) = @_;
  return Future->done( $self->_unauthorized_result ) if $self->_presents_admin_key($req);
  my $f = eval { $self->authorizer->identify_f( $req, $action ) }
    // Future->fail( $@ || 'identify_f returned nothing' );
  return $f->else( sub {
    $log->errorf( 'Authorizer failed: %s', $_[0] );
    Future->done( $self->_unavailable_result );
  } );
}

# The same, synchronously (Langertha::Knarr::PSGI).
sub _identify {
  my ($self, $req, $action) = @_;
  return $self->_unauthorized_result if $self->_presents_admin_key($req);
  my $result = eval { $self->authorizer->identify( $req, $action ) };
  return $result if $result;
  $log->errorf( 'Authorizer failed: %s', $@ || 'identify returned nothing' );
  return $self->_unavailable_result;
}

sub _unauthorized_result { return { status => 401, message => 'unauthorized' } }
sub _unavailable_result  { return { status => 503, message => 'token check unavailable' } }

# The answer to a refused identify result, ( status, content type, body ) in
# the route's protocol's error shape (k78); empty for an identity.
sub _identify_refusal {
  my ($self, $proto, $result, $body) = @_;
  return unless defined $result->{status};
  return $self->_error_answer( $proto, $result->{status},
    $result->{message} // 'unauthorized', undef, $body );
}

# The authorize phase (k82): empty when the identity may do $action with
# $model, else the refusal as ( status, content type, body ) in the
# protocol's error shape. Shared by the native server and the PSGI adapter.
sub _authorize_refusal {
  my ($self, $proto, $identity, $action, $model, $sb_req, $body) = @_;
  my ($status, $message) = $self->authorizer->authorize( $identity // {}, $action, $model );
  return unless defined $status;
  $log->debugf( 'Authorization refused (%s): %s', $action, $status );
  return $self->_error_answer( $proto, $status, $message // 'forbidden', $sb_req, $body );
}

# Equal keys, compared in constant time (k76); see
# Langertha::Knarr::Authorizer::StaticKey.
sub _same_key {
  my ($given, $want) = @_;
  return __PACKAGE__->static_authorizer_class->_same_key( $given, $want );
}

# True when any element of Authorization or x-api-key is the admin key.
sub _presents_admin_key {
  my ($self, $req) = @_;
  my $admin = $self->admin or return 0;
  for my $name ( 'Authorization', 'x-api-key' ) {
    my $value = scalar $req->header($name);
    next unless defined $value;
    for my $element ( split /,/, $value ) {
      $element =~ s/\A\s+|\s+\z//g;
      $element =~ s/\ABearer\s+//i;
      return 1 if $admin->is_key($element);
    }
  }
  return 0;
}

# The answer to every route but the admin routes while an admin has no
# setup to serve from (remote_config without a start setup, before the first push, k75): 503 in the
# protocol's error shape. Empty when Knarr can serve.
sub _not_configured_answer {
  my ($self, $proto, $body) = @_;
  my $admin = $self->admin or return;
  return if $admin->configured;
  return $self->_error_answer( $proto, 503, 'not configured: Knarr has no setup yet', undef, $body );
}

# An error Knarr answers itself, as ( status, content type, body ) in the
# client protocol's error shape (format_error_response): Anthropic's typed
# error object, Ollama's plain string. A route of Knarr's own, without a
# protocol, gets the OpenAI wire's {"error":{"message":...}}. Every such
# answer goes through here -- 401, 404, 500, 502-504 alike (k78) -- on the
# native server and the PSGI adapter. $sb_req, when the request was parsed,
# lets a protocol address the error to it (A2A's JSON-RPC id); $body, the
# request's raw body, does so for an error that came before the parse (401,
# 503) or because of it -- only for a protocol that reads it
# (Protocol::error_uses_body, k80).
sub _error_answer {
  my ($self, $proto, $code, $message, $sb_req, $raw_body) = @_;
  return ( $code, 'application/json',
    $self->_json->encode({ error => { message => "$message" } }) ) unless $proto;
  my ($status, $headers, $body) = $proto->format_error_response( $code, $message, $sb_req, $raw_body );
  return ( $status, $headers->{'Content-Type'} // 'application/json', $body );
}

# An admin request, answered by the admin for both transports (k75).
sub _dispatch_admin {
  my ($self, $req, $action) = @_;
  my $body = $req->body;
  my $peer = eval { $req->stream->read_handle->peerhost };
  return $self->_send_simple( $req, $self->admin->handle(
    knarr          => $self,
    action         => $action,
    request        => $req,
    content_length => length( $body // '' ),
    body           => sub { $body },
    peer           => $peer,
  ) );
}

# Headers Knarr reads its own key (auth_token) from.
my %PROXY_KEY_HEADER = ( 'authorization' => 1, 'x-api-key' => 1 );

# A client header's value as it may leave Knarr (k44, k53). In Authorization
# and x-api-key, every comma-separated element that is Knarr's key -- bare
# or as 'Bearer <key>', in either header -- is removed: a header sent twice
# arrives as one value joined with ', ' under PSGI (one HTTP_* key), and
# a client may join them itself. Returns the value unchanged, byte for
# byte, when no element carries the key; the remaining elements joined with
# ', ' when some do; nothing when only the key was there, so the header is
# dropped.
# Every path that forwards client headers goes through here: the raw
# passthrough and the forward_headers of the protocol parsers. Under an
# authorizer that does not forward the client's key (token auth, k82) both
# headers carry nothing but Knarr's credential and are dropped whole.
sub _without_proxy_key {
  my ($self, $name, $value) = @_;
  return if $PROXY_KEY_HEADER{ lc $name } && !$self->authorizer->forwards_client_key;
  my $key = $self->auth_token;
  return $value unless defined $key && length $key && defined $value
    && $PROXY_KEY_HEADER{ lc $name };
  my ( @kept, $dropped );
  for my $element ( split /,/, $value ) {
    ( my $token = $element ) =~ s/\A\s+|\s+\z//g;
    next unless length $token;
    ( my $bare = $token ) =~ s/\ABearer\s+//i;
    if ( $bare eq $key ) { $dropped = 1; next }
    push @kept, $token;
  }
  return $value unless $dropped;
  return @kept ? join( ', ', @kept ) : ();
}

# The protocol's parse, with Knarr's key taken out of the headers a
# passthrough handler in the chain forwards (forward_headers, k44), and the
# identity of the identify phase on the request (grant, k82). Shared by the
# native server and the PSGI adapter.
sub _parse_chat_request {
  my ($self, $proto, $req, $body_ref, $identity) = @_;
  # A body that is no JSON object is the client's mistake: 400 in the
  # protocol's shape, a fixed text (k81). Checked before the parse, which
  # alone would die with the decoder's message and become a 500.
  if ( defined( my $reason = $proto->request_body_error($body_ref) ) ) {
    die Future::Exception->new( $reason, 'bad_request' );
  }
  my $sb_req = $proto->parse_chat_request( $req, $body_ref );
  # One header line at a time, as the parser recorded them (k60): a line
  # that was only the key is dropped, the others keep their order.
  my $extra = $sb_req->extra;
  if ( $extra && $extra->{forward_headers} ) {
    my @kept;
    for my $pair ( $sb_req->forward_header_pairs ) {
      my ($value) = $self->_without_proxy_key(@$pair);
      push @kept, [ $pair->[0], $value ] if defined $value;
    }
    $extra->{forward_headers} = \@kept;
  }
  # A request that names no model gets the identity's (a token is for one).
  $sb_req->apply_grant($identity) if $identity;
  return $sb_req;
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
  return $self->_dispatch_admin( $req, $action ) if $route->{admin};
  # Who asks, before the body is read (k82). A check that has to ask a
  # store answers later; the loop serves on meanwhile.
  my $identified = $self->_identify_f( $req, $action );
  return $self->_dispatch_identified( $req, $route, $identified->get )
    if $identified->is_ready;
  $identified->on_done( sub {
    my ($result) = @_;
    return if $req->is_closed;
    $self->_dispatch_identified( $req, $route, $result );
  } )->retain;
  return;
}

sub _dispatch_identified {
  my ($self, $req, $route, $result) = @_;
  my $action = $route->{action};
  my $proto  = $route->{protocol};
  if ( my @refused = $self->_identify_refusal( $proto, $result, $req->body ) ) {
    return $self->_send_simple( $req, @refused );
  }
  my $identity = $result->{identity} // {};
  if ( my @answer = $self->_not_configured_answer( $proto, $req->body ) ) {
    return $self->_send_simple( $req, @answer );
  }
  my $simple = $self->_simple_action($action);
  my $code = $simple ? undef : $self->can("_action_$action");
  unless ( $simple || $code ) {
    return $self->_send_simple( $req,
      $self->_error_answer( $proto, 500, "unknown action $action", undef, $req->body ) );
  }
  try {
    if ( $simple ) {
      my ($status, $headers, $body) = $self->$simple( $proto, $req->body, $identity );
      $self->_send_simple( $req, $status, $headers->{'Content-Type'} // 'application/json', $body );
    }
    else {
      $self->$code( $proto, $req, $identity );
    }
  } catch {
    my $err = $_;
    my ( $message, $category ) = blessed($err) && $err->isa('Future::Exception')
      ? ( $err->message, $err->category ) : ( $err );
    $log->errorf("Request error (%s): %s", $action, $message);
    $self->_send_simple( $req,
      $self->_handler_failure_answer( $proto, $message, $category, undef, $req->body ) );
  };
}

sub _action_chat {
  my ($self, $proto, $req, $identity) = @_;
  my $body = $req->body;
  my $sb_req = $self->_parse_chat_request( $proto, $req, \$body, $identity );
  # The model is known now (k82): a 403 before any handler work, so a
  # refused stream never sends its 200.
  if ( my @refused = $self->_authorize_refusal( $proto, $identity, 'chat', $sb_req->model, $sb_req, $body ) ) {
    return $self->_send_simple( $req, @refused );
  }

  # Raw passthrough: pipe bytes 1:1 to upstream, skip handler chain
  if ( $self->_is_raw_passthrough($sb_req) ) {
    return $self->_handle_raw_passthrough( $proto, $req, $sb_req );
  }
  return $self->_handle_chat( $proto, $req, $sb_req );
}

# A parsed chat request answered through the handler chain -- also a raw
# passthrough that falls back to its engine (k66).
sub _handle_chat {
  my ($self, $proto, $req, $sb_req) = @_;
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
      $self->_send_simple( $req, $self->_error_answer( $proto, 500, _error_text($err), $sb_req ) );
    };
  });
  $f->on_fail( sub {
    my ($err, $category) = @_;
    $log->errorf("Chat handler error: %s", $err);
    $self->_send_simple( $req, $self->_handler_failure_answer( $proto, $err, $category, $sb_req ) );
  });
  $f->retain;
}

sub _handle_stream {
  my ($self, $proto, $req, $sb_req, $session, $handler) = @_;

  # The stream's 200 goes out with its first event -- its first chunk, or
  # its end -- not before. Until then the status is still free: a handler
  # that fails (nothing serves the model, k41; an upstream timeout, k36; any
  # backend failure, k78) is answered like a non-streaming request, in the
  # protocol's error shape. Only a failure after that ends the started
  # stream.
  my $started = 0;

  my $write = sub {
    my ($bytes) = @_;
    return unless defined $bytes && length $bytes;
    return if $req->is_closed;
    $req->write_chunk( $bytes );
  };

  my $start = sub {
    return if $started++;
    my $header = HTTP::Response->new( 200 );
    $header->protocol('HTTP/1.1');
    $header->header( 'Content-Type'  => $proto->stream_content_type );
    $header->header( 'Cache-Control' => 'no-cache' );
    $req->respond_chunk_header( $header );
    $write->( $proto->format_stream_open($sb_req) );
  };

  my $refuse = sub {
    my ($err, $category) = @_;
    return if $req->is_closed;
    $self->_send_simple( $req, $self->_handler_failure_answer( $proto, $err, $category, $sb_req ) );
  };

  my $f = $handler->handle_stream_f( $session, $sb_req );
  $f->on_done( sub {
    my ($stream) = @_;
    my $pump; $pump = sub {
      if ( $req->is_closed ) { undef $pump; return }
      $stream->next_chunk_f->on_done( sub {
        my ($delta) = @_;
        if ( $req->is_closed ) { undef $pump; return }
        $start->();
        if ( defined $delta ) {
          $write->( $proto->format_stream_chunk( $delta, $sb_req ) );
          $pump->();
        }
        else {
          # The backend's terminal reason, its complete tool calls and its
          # token usage are known only now; the protocol maps the reason into
          # its own vocabulary (k18) and frames the calls (k19) and the usage.
          my $finish_reason = $stream->can('finish_reason') ? $stream->finish_reason : undef;
          my $tool_calls    = $stream->can('tool_calls')    ? $stream->tool_calls    : [];
          my $usage         = $stream->can('usage')         ? $stream->usage         : undef;
          $write->( $proto->format_stream_close( $sb_req, $finish_reason, $tool_calls, $usage ) );
          $write->( $proto->format_stream_done( $sb_req, $finish_reason, $tool_calls, $usage ) );
          $req->write_chunk_eof;
          undef $pump;
        }
      })->on_fail( sub {
        my ($err, $category) = @_;
        $log->errorf("Stream chunk error: %s", $err);
        undef $pump;
        return $refuse->( $err, $category ) unless $started;
        return if $self->_stream_failure_frame( $proto, $req, $err, $category, $sb_req );
        $write->( $proto->format_stream_chunk( '[error: '._error_text($err).']', $sb_req ) );
        $write->( $proto->format_stream_close($sb_req) );
        $req->write_chunk_eof;
      })->retain;
      # Held until ready: a decorator's chained read (Tracing, RequestLog)
      # is referenced by nothing else while the upstream is silent (k36).
    };
    $pump->();
  });
  $f->on_fail( sub {
    my ($err, $category) = @_;
    $log->errorf("Stream handler error: %s", $err);
    $refuse->( $err, $category );
  });
  $f->retain;
}

# The status a handler failure answers with, from its category (the second
# failure value). A Net::Async::HTTP timeout category (core's k278 engine
# timeouts, the UpstreamHTTP role's) is an upstream that did not answer in
# time: 504, as on the raw passthrough (k35, k36). 'model_not_found' is
# Handler::Router finding nothing to serve the model -- not configured, no
# passthrough for the protocol, no default engine: 404 (k41). Undef for any
# other failure, and for a core that sets no category.
sub _handler_failure_status {
  my ($self, $category) = @_;
  return 504 if Langertha::Knarr::Role::UpstreamHTTP->is_upstream_timeout($category);
  return 404 if defined $category && $category eq 'model_not_found';
  return 400 if defined $category && $category eq 'bad_request';
  # A handler that refuses the request's grant (Handler::TokenRoutes: no
  # route for its provider), or lacks what it needs to serve it (its key
  # variable unset), k82.
  return 403 if defined $category && $category eq 'forbidden';
  return 503 if defined $category && $category eq 'unavailable';
  return;
}

# A handler failure as ( status, content type, body ) in the client
# protocol's error shape: the status of its category, else 500 -- a backend
# that failed is answered in the client's own shape too (k78).
sub _handler_failure_answer {
  my ($self, $proto, $err, $category, $sb_req, $body) = @_;
  return $self->_error_answer( $proto,
    $self->_handler_failure_status($category) // 500, _error_text($err), $sb_req, $body );
}

# The same for a stream whose headers are out: the protocol's error frame
# (status of the category, else 500), then the end of the stream; the frame
# is the stream's end, no success marker follows it (k79). False (nothing
# written) only when the protocol has no error frame, so the caller answers
# as before.
sub _stream_failure_frame {
  my ($self, $proto, $req, $err, $category, $sb_req) = @_;
  my $code = $self->_handler_failure_status($category) // 500;
  my $frame = $proto->format_stream_error( $code, _error_text($err), $sb_req );
  return 0 unless length $frame;
  return 1 if $req->is_closed;
  $req->write_chunk($frame);
  $req->write_chunk_eof;
  return 1;
}

sub _handle_raw_passthrough {
  my ($self, $proto, $req, $sb_req) = @_;
  my ($http_req, $trace, $trace_from) = $self->_raw_passthrough_request(
    $sb_req, [ $req->headers ], $req->body, $req->path );
  my $pt = $self->raw_passthrough;
  my $model = $sb_req->model // 'unknown';

  if ($sb_req->stream) {
    # The upstream may go silent before its headers (answered like a
    # non-streaming failure: 504 or 502 in the protocol's shape) or in the
    # middle of the stream (the headers are out: the protocol's error frame,
    # then the end of the stream). stall_timeout covers both (k35).
    my $headers_sent = 0;
    my $fell_back = 0;
    my $tail = '';
    my $f = $pt->_upstream_request_f(
      request   => $http_req,
      on_header => sub {
        my ($response) = @_;
        # The status is known before any byte goes to the client: a refused
        # discovered model is answered by its engine instead, and the
        # upstream's refusal is read and dropped (k66).
        if ( $self->_raw_passthrough_falls_back( $sb_req, $response ) ) {
          $fell_back = 1;
          $self->_raw_passthrough_fall_back( $proto, $req, $sb_req );
          return sub { };
        }
        $trace = $self->_raw_passthrough_trace( $sb_req, $trace_from ) if $trace_from;
        # The upstream's headers go back with it (k56).
        my $header = HTTP::Response->new($response->code);
        $header->protocol('HTTP/1.1');
        $header->header('Content-Type'  => scalar $response->header('Content-Type'));
        $header->push_header(@$_) for @{ $self->_raw_passthrough_response_headers($response) };
        $header->header('Cache-Control' => 'no-cache') unless defined $header->header('Cache-Control');
        $req->respond_chunk_header($header);
        $headers_sent = 1;
        # The trace reads its usage off a copy of the bytes (k61).
        my $usage = $self->_raw_passthrough_usage_reader( $trace, $response );

        return sub {
          my ($data) = @_;
          if (!defined $data) {
            $req->write_chunk_eof unless $req->is_closed;
            $self->tracing->end_trace( $trace, output => '[stream]',
              $usage ? $usage->trace_args : () ) if $trace;
            return;
          }
          return unless length $data;
          $tail = substr( $tail . $data, -2 );
          $req->write_chunk($data) unless $req->is_closed;
          $usage->add_chunk($data) if $usage;
        };
      },
    );
    $f->on_fail(sub {
      my ($err, $category) = @_;
      # The engine answers; the dropped refusal has nothing left to say.
      return if $fell_back;
      unless ($headers_sent) {
        $trace = $self->_raw_passthrough_trace( $sb_req, $trace_from ) if $trace_from;
        return $self->_send_simple( $req,
          $self->_raw_passthrough_failed( $proto, $sb_req, $trace, $err, $category ) );
      }
      $log->errorf("Passthrough stream error [%s]: %s", $model, $err);
      $self->tracing->end_trace($trace, error => "$err") if $trace;
      return if $req->is_closed;
      my $frame = $proto->format_stream_error(
        $self->_raw_passthrough_status($category), _error_text($err) );
      if ( length $frame ) {
        # A frame cut off by the stall is ended first, so the error frame
        # stands on its own: a blank line for SSE, a newline for NDJSON.
        my $pad = $proto->stream_content_type =~ /ndjson/
          ? ( $tail eq '' || $tail =~ /\n\z/ ? '' : "\n" )
          : ( $tail eq '' || $tail eq "\n\n" ? '' : $tail =~ /\n\z/ ? "\n" : "\n\n" );
        $req->write_chunk( $pad . $frame );
      }
      $req->write_chunk_eof;
    });
    $f->retain;
  } else {
    my $f = $pt->_upstream_request_f(request => $http_req);
    $f->on_done(sub {
      my ($resp) = @_;
      return $self->_raw_passthrough_fall_back( $proto, $req, $sb_req )
        if $self->_raw_passthrough_falls_back( $sb_req, $resp );
      $trace = $self->_raw_passthrough_trace( $sb_req, $trace_from ) if $trace_from;
      $self->_send_simple( $req,
        $self->_raw_passthrough_answer( $sb_req, $trace, $resp ) );
    });
    $f->on_fail(sub {
      $trace = $self->_raw_passthrough_trace( $sb_req, $trace_from ) if $trace_from;
      $self->_send_simple( $req,
        $self->_raw_passthrough_failed( $proto, $sb_req, $trace, @_[0, 1] ) );
    });
    $f->retain;
  }
}

# Raw passthrough is decided and prepared here for both transports, the
# native server and Langertha::Knarr::PSGI (k26), so they cannot drift:
# which requests bypass the handler chain, which client headers reach the
# upstream, what the upstream request and its trace look like, and how an
# answer or a failure is returned. Only the byte pumping differs -- the
# native server streams chunks as they arrive, PSGI buffers.
sub _is_raw_passthrough {
  my ($self, $sb_req) = @_;
  my $pt = $self->raw_passthrough;
  my $router = $self->router;
  # Only for a protocol the passthrough has an upstream for: a request in
  # any other protocol goes through the handler chain, to the default
  # engine or to a 404 in the protocol's error shape (k41).
  return 0 unless $pt && $router && $pt->serves_protocol( $sb_req->protocol );
  # The client's key never goes upstream under an authorizer that keeps it
  # (token auth, k82).
  return 0 unless $self->authorizer->forwards_client_key;
  return 1 if $router->is_passthrough_model( $sb_req->model );
  # A model only auto-discovery knows, listed by this very upstream, goes
  # there byte for byte too; discovery then only feeds the model lists
  # (k47). One listed by another provider stays with its engine.
  my $url = $router->can('discovered_url') ? $router->discovered_url( $sb_req->model ) : undef;
  return 0 unless defined $url && $pt->can('is_upstream_for')
    && $pt->is_upstream_for( $sb_req->protocol, $url );
  # ...but only with the client's own provider key: without one the upstream
  # would answer 401, while the engine that listed the model holds Knarr's
  # key (k52).
  return $self->_carries_provider_key($sb_req);
}

# The headers a protocol's upstream takes its key from. A protocol not listed
# (Ollama) needs none.
my %PROVIDER_KEY_HEADERS = (
  openai    => [ 'authorization' ],
  anthropic => [ 'x-api-key', 'authorization' ],
);

# True when the request carries a provider key for its protocol's upstream,
# after Knarr's proxy key was taken out: the parser's forward_headers, as
# _parse_chat_request left them (k52).
sub _carries_provider_key {
  my ($self, $sb_req) = @_;
  my $names = $PROVIDER_KEY_HEADERS{ $sb_req->protocol // '' } or return 1;
  return ( grep { length } map { $sb_req->forward_header($_) } @$names ) ? 1 : 0;
}

# $headers: the client's request headers as [ name, value ] pairs; $path:
# the path the client asked for (Ollama /api/chat or /api/generate, k46).
sub _raw_passthrough_request {
  my ($self, $sb_req, $headers, $body, $path) = @_;
  my $model = $sb_req->model // 'unknown';
  my $protocol = $sb_req->protocol;

  # Build upstream URL from passthrough config
  my $url = $self->raw_passthrough->_upstream_url( $protocol, $path );
  my $http_req = HTTP::Request->new(POST => $url);

  # Forward all client headers except hop-by-hop / connection-specific
  # ones, with Knarr's own key taken out of each line (k44, k53). Every line
  # is added, not set: a header sent twice reaches the upstream twice, in
  # its order (k56).
  my %skip = map { lc($_) => 1 } qw( host content-length connection transfer-encoding );
  for my $pair (@$headers) {
    my ($name, $value) = @$pair;
    next if $skip{lc($name)};
    ($value) = $self->_without_proxy_key( $name, $value );
    next unless defined $value;
    $http_req->push_header($name => $value);
  }
  $http_req->content($body);

  $log->infof("Passthrough %s [%s] -> %s", $model, $protocol, $url);

  # Lightweight tracing for passthrough requests. The trace of a request
  # that may still fall back to its engine waits for the upstream's status,
  # so a fallback is traced once, by the handler chain (k66); $trace_from
  # is then the time the request goes out, for _raw_passthrough_trace.
  my ( $trace, $trace_from );
  if ( $self->_raw_passthrough_may_fall_back($sb_req) ) {
    $trace_from = [ Time::HiRes::gettimeofday() ] if $self->tracing;
  }
  else {
    $trace = $self->_raw_passthrough_trace($sb_req);
  }

  return ( $http_req, $trace, $trace_from );
}

# The raw passthrough's trace, started now or, with $trace_from, dated back
# to it. Undef without tracing.
sub _raw_passthrough_trace {
  my ($self, $sb_req, $trace_from) = @_;
  my $tracing = $self->tracing or return;
  return $tracing->start_trace(
    model    => $sb_req->model // 'unknown',
    engine   => 'passthrough',
    format   => $sb_req->protocol,
    messages => $sb_req->messages,
    $trace_from ? ( start_hires => $trace_from ) : (),
  );
}

# True for a raw passthrough that falls back to its engine should the
# upstream refuse the client's key (k66): one of a model only auto-discovery
# knows, which the router resolves -- every other raw passthrough is of a
# model it does not know, and has no engine to fall back to.
sub _raw_passthrough_may_fall_back {
  my ($self, $sb_req) = @_;
  my $router = $self->router or return 0;
  return $router->is_passthrough_model( $sb_req->model ) ? 0 : 1;
}

# True when the upstream's answer sends a raw passthrough to its engine
# instead (k66): a 401 -- the client's key refused, a placeholder an SDK
# sent -- for a request that may fall back. Notes the fallback on the
# request, for the handler chain's trace. Any other status, 403 and 429
# included, goes back to the client as before.
sub _raw_passthrough_falls_back {
  my ($self, $sb_req, $resp) = @_;
  return 0 unless $resp->code == 401 && $self->_raw_passthrough_may_fall_back($sb_req);
  $log->infof("Passthrough %s refused the client's key (401), answering through its engine",
    $sb_req->model // 'unknown');
  $sb_req->extra->{passthrough_fallback} = 401;
  return 1;
}

# The native server's fallback: the parsed request through the handler
# chain, where Handler::Router sends it to the engine that listed the
# model, with that engine's key. Nothing has gone to the client yet. It
# runs in the upstream's callback, outside _dispatch's catch, so it answers
# an error itself.
sub _raw_passthrough_fall_back {
  my ($self, $proto, $req, $sb_req) = @_;
  try {
    $self->_handle_chat( $proto, $req, $sb_req );
  } catch {
    my $err = $_;
    $log->errorf("Passthrough fallback error [%s]: %s", $sb_req->model // 'unknown', $err);
    $self->_send_simple( $req, $self->_error_answer( $proto, 500, _error_text($err), $sb_req ) );
  };
  return;
}

# The upstream's answer as ( status, content type, body bytes, its other
# headers ). A buffered stream (PSGI) is traced as a stream, like the
# native one. The body goes back as Net::Async::HTTP handed it over, like a
# stream: decoded when it knew the encoding, otherwise the upstream's bytes
# with their Content-Encoding -- never decoded again here, where an
# encoding HTTP::Message cannot decode (br without IO::Uncompress::Brotli,
# anything unknown) came back as an empty body (k59).
sub _raw_passthrough_answer {
  my ($self, $sb_req, $trace, $resp) = @_;
  if ($trace) {
    my $usage = $self->_raw_passthrough_usage_reader( $trace, $resp );
    $usage->read_body( $resp->content ) if $usage;
    $self->tracing->end_trace( $trace,
      output => $sb_req->stream ? '[stream]' : '[passthrough]',
      $usage ? $usage->trace_args : () );
  }
  return ( $resp->code,
    scalar $resp->header('Content-Type') // 'application/json',
    $resp->content // '',
    $self->_raw_passthrough_response_headers($resp) );
}

# Upstream response headers that stay behind: connection-level ones, the
# framing Knarr sets for what it sends itself, Content-Type, which the
# callers set, and the note Net::Async::HTTP leaves on a body it decoded.
my %RESPONSE_HEADER_SKIP = map { $_ => 1 } qw(
  connection keep-alive proxy-connection te trailer upgrade
  transfer-encoding content-length content-type x-original-content-encoding );

# The upstream's response headers that go back to the client, as [ name,
# value ] pairs: every line, a repeated header (Set-Cookie) repeated in its
# order (k56). Content-Encoding goes along only while the bytes still carry
# it: Net::Async::HTTP decodes every encoding it knows (gzip, deflate)
# before Knarr sees a byte, buffered or streamed, and passes any other as
# it came (k59). The decision is its own: the whole header value, repeated
# lines joined, is what it looks up -- in on_header it has not removed the
# header yet, on a finished response it has.
sub _raw_passthrough_response_headers {
  my ($self, $resp) = @_;
  my $encoding = $resp->header('Content-Encoding');
  my $decoded = defined $encoding && Net::Async::HTTP->can_decode($encoding);
  my @pairs;
  $resp->headers->scan( sub {
    my ($name, $value) = @_;
    my $lc = lc $name;
    return if $RESPONSE_HEADER_SKIP{$lc};
    return if $lc eq 'content-encoding' && $decoded;
    push @pairs, [ $name, $value ];
  });
  return \@pairs;
}

# What reads the token usage and model off a copy of the upstream's answer
# for its trace (k61): nothing without a trace, and nothing for bytes that
# still carry a Content-Encoding -- Net::Async::HTTP decodes the ones it
# knows, the same decision as in _raw_passthrough_response_headers.
sub _raw_passthrough_usage_reader {
  my ($self, $trace, $resp) = @_;
  return unless $trace;
  my $encoding = $resp->header('Content-Encoding');
  return if defined $encoding && !Net::Async::HTTP->can_decode($encoding);
  return Langertha::Knarr::PassthroughUsage->new;
}

# An upstream that did not answer in time is a 504, any other failure to
# reach it a 502, in the client protocol's error shape (k35).
sub _raw_passthrough_failed {
  my ($self, $proto, $sb_req, $trace, $err, $category) = @_;
  $log->errorf("Passthrough error [%s]: %s", $sb_req->model // 'unknown', $err);
  $self->tracing->end_trace($trace, error => "$err") if $trace;
  return $self->_error_answer( $proto,
    $self->_raw_passthrough_status($category), 'passthrough failed: ' . _error_text($err) );
}

sub _raw_passthrough_status {
  my ($self, $category) = @_;
  return Langertha::Knarr::Role::UpstreamHTTP->is_upstream_timeout($category) ? 504 : 502;
}

# What a client may be told of a failure (k79): the message without where
# Perl died -- " at /path/Module.pm line 12." and "<$fh> line 3", the stack
# frames of a confess, the @INC list of a missing module, any remaining
# source path. The full text goes to the log and the request log, not here.
# A message that is nothing but a location becomes "internal error".
sub _error_text {
  my ($err) = @_;
  my $text = "$err";
  $text = join "\n", grep { !/^\s+\S.*\bcalled at\b/ && !/^\t/ } split /\n/, $text;
  $text =~ s/\s*\(\@INC[^)]*\)//g;
  $text =~ s/,?\s*\bat (?:\S+|\((?:re_)?eval \d+\)) line \d+(?:, <[^>]*> (?:line|chunk) \d+)?\.?//g;
  $text =~ s{(?<![\w.])/(?:[\w.\-]+/)*[\w.\-]+\.(?:pm|pl|t|xs)\b}{<file>}g;
  $text =~ s/\s+\z//;
  $text =~ s/\A\s+//;
  return length $text ? $text : 'internal error';
}

sub _action_acp_agents { goto &_action_models }
sub _action_a2a_card {
  my ($self, $proto, $req) = @_;
  my ($status, $headers, $body) = $proto->format_agent_card;
  $self->_send_simple( $req, $status, $headers->{'Content-Type'} // 'application/json', $body );
}

# Actions answered with one buffered response from the request body alone.
# The native server and the PSGI adapter both dispatch through this table,
# so the two cannot drift: action => method( $proto, $body_bytes ) returning
# ( status, \%headers, body ).
my %SIMPLE_ACTIONS = (
  version => '_simple_version',
  show    => '_simple_show',
);

sub _simple_action {
  my ($self, $action) = @_;
  return $SIMPLE_ACTIONS{$action};
}

sub _simple_version {
  my ($self, $proto) = @_;
  return $proto->format_version_response( $self->ollama_compat_version );
}

# POST /api/show (k29). VS Code Copilot calls it for every model and reads
# tools/vision from capabilities; Continue reads it too. Only a model Knarr
# lists (the /api/tags surface) is shown, anything else gets Ollama's 404.
# capabilities never carry "thinking": Knarr drops think on the Ollama wire.
sub _simple_show {
  my ($self, $proto, $body, $identity) = @_;
  my $data = eval { $self->_json->decode( defined $body && length $body ? $body : '{}' ) };
  $data = {} unless ref $data eq 'HASH';
  my $model = $data->{model};
  $model = $data->{name} unless defined $model && length $model;   # Ollama's legacy field
  return $proto->format_error_response( 400, 'model is required' )
    unless defined $model && !ref $model && length $model;
  # May this identity see the model at all (k82)?
  my ($refused, $message) = $self->authorizer->authorize( $identity // {}, 'show', $model );
  return $proto->format_error_response( $refused, $message // 'forbidden' ) if defined $refused;

  my $router = $self->router;
  my $listed = $self->authorizer->visible_models( $identity // {},
    $router ? $router->list_models : $self->handler->list_models );
  my ($known) = grep { $_ eq $model }
    map { ref $_ eq 'HASH' ? $_->{id} // '' : "$_" } @{ $listed || [] };
  return $proto->format_error_response( 404, "model '$model' not found" )
    unless defined $known;

  # The engine the router sends this model to, when it can build one; a
  # model it cannot build (key variable unset) or a custom handler without
  # a router leaves the capabilities at what the Ollama endpoint forwards.
  my $engine = $router
    ? eval { ( $router->resolve( $model, skip_default => 1 ) )[0] } : undef;
  my $caps = blessed($engine) && $engine->can('supports') ? $engine : undef;

  my @capabilities = ('completion');
  push @capabilities, 'tools'
    if !$caps || $caps->supports('tools_native') || $caps->supports('tools_hermes');
  # "vision" from core's model-scoped image_input (core k266, ADR 0019),
  # evaluated for the upstream model: the router builds one engine per model,
  # so its chat_model is the model this name is sent to. A core without the
  # flag (0.503) cannot tell, so no claim; nor without a routed engine.
  push @capabilities, 'vision'
    if $caps && _image_input_known() && eval { $caps->supports('image_input') };
  my $context_length = blessed($engine) && $engine->can('get_context_size')
    ? eval { $engine->get_context_size } : undef;

  return $proto->format_show_response( $model, {
    capabilities => \@capabilities,
    ( defined $context_length ? ( context_length => $context_length ) : () ),
  } );
}

# True when the installed Langertha core knows the image_input capability
# (Langertha::Role::ImageInput contributes it). Checked once per process.
my $IMAGE_INPUT_KNOWN;
sub _image_input_known {
  $IMAGE_INPUT_KNOWN //= eval { require Langertha::Role::ImageInput; 1 } ? 1 : 0;
  return $IMAGE_INPUT_KNOWN;
}

sub _action_manifest {
  my ($self, $proto, $req, $identity) = @_;
  if ( my @refused = $self->_authorize_refusal( $proto, $identity, 'manifest', undef ) ) {
    return $self->_send_simple( $req, @refused );
  }
  my $proto_header = lc( scalar( $req->header('X-Forwarded-Proto') ) // '' );
  my ($status, $body) = $self->manifest_response(
    scheme => ( $proto_header =~ /\A(https?)\z/ ? $1 : 'http' ),
    host   => scalar $req->header('Host'),
  );
  $self->_send_simple( $req, $status, 'application/json', $body );
}

sub manifest_response {
  my ($self, %request) = @_;
  my $error = sub {
    my ($status, $message) = @_;
    return ( $status, $self->_json->encode({ error => { message => $message } }) );
  };
  return $error->( 404, 'provider manifest not available: the installed Langertha'
    . ' has no Langertha::Manifest::Builder' )
    unless Langertha::Knarr::Manifest->available;

  my $base_url = $self->public_url;
  unless ( defined $base_url && length $base_url ) {
    my $host = $request{host} // '';
    # A hostname or bracketed IPv6 address, optional port; nothing else can
    # reach the published URLs.
    return $error->( 400, 'cannot derive the public URL: no valid Host header'
      . ' (set public_url)' )
      unless $host =~ /\A(?:[A-Za-z0-9](?:[A-Za-z0-9.\-]*[A-Za-z0-9])?|\[[0-9A-Fa-f:.]+\])(?::[0-9]{1,5})?\z/;
    $base_url = ( $request{scheme} // 'http' ) . '://' . $host . ( $request{prefix} // '' );
  }

  my $manifest = eval { $self->_manifest->build($base_url) };
  unless ( $manifest ) {
    my $err = $@ || 'unknown error';
    $err =~ s/ at \S+ line \d+\.?\n?\z//;
    $log->errorf("Manifest error: %s", $err);
    return $error->( 500, "provider manifest failed: $err" );
  }
  return ( 200, $manifest->to_json );
}

sub _action_models {
  my ($self, $proto, $req, $identity) = @_;
  my $models = $self->_visible_models($identity);
  my ($status, $headers, $body) = $proto->format_models_response( $models );
  $self->_send_simple( $req, $status, $headers->{'Content-Type'} // 'application/json', $body );
}

# What a model list shows this identity (k82): the handler's models,
# narrowed by the authorizer. Shared by the native server and the PSGI
# adapter.
sub _visible_models {
  my ($self, $identity) = @_;
  return $self->authorizer->visible_models( $identity // {}, $self->handler->list_models );
}

# $headers: optional further [ name, value ] pairs, each line added (the
# raw passthrough's upstream headers, k56).
sub _send_simple {
  my ($self, $req, $status, $ctype, $body, $headers) = @_;
  my $resp = HTTP::Response->new( $status );
  $resp->protocol('HTTP/1.1');
  $resp->push_header(@$_) for @{ $headers // [] };
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

Langertha::Knarr - Universal LLM hub - proxy, server, and translator across OpenAI/Anthropic/Ollama/A2A/ACP/AG-UI

=head1 VERSION

version 1.103

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
        router  => $router,
        loop    => $loop,
        listen  => $config->listen,
    );
    $knarr->run;   # blocks; OpenWebUI etc. can now connect

C<knarr start> (see L<knarr>) builds exactly this from a config file, plus
the raw passthrough, the tracing and request-log decorators, the proxy key
and the other settings of L<Langertha::Knarr::Config>.

=head1 DESCRIPTION

Langertha::Knarr is a universal LLM hub that exposes any backend — a
L<Langertha::Raider>, a raw L<Langertha::Engine>, a remote A2A or ACP
agent, or any custom L<Langertha::Knarr::Handler> — over the standard
LLM HTTP wire protocols spoken by OpenWebUI, the OpenAI / Anthropic /
Ollama SDKs, and the agent ecosystems around A2A, ACP, and AG-UI.

By default a single running Knarr answers all of these simultaneously on
every listening port, driven by the same handler implementation:

=over

=item * OpenAI: C<POST /v1/chat/completions>, C<GET /v1/models>

=item * Anthropic: C<POST /v1/messages>

=item * Ollama: C<POST /api/chat>, C<POST /api/generate>, C<GET /api/tags>,
C<GET /api/version>, C<POST /api/show>

=item * A2A: C<GET /.well-known/agent.json> and JSON-RPC C<POST />

=item * ACP: C<GET /agents>, C<POST /runs>

=item * AG-UI: C<POST /awp>

=item * Knarr's own C<GET /.well-known/langertha.json> (see L</MANIFEST>)

=item * With an L</admin>: C<GET /knarr/admin/status>,
C<PUT>/C<DELETE /knarr/admin/config>, C<PATCH /knarr/admin/keys> (see
L</ADMIN ROUTES>)

=back

Knarr is built on L<IO::Async> and L<Net::Async::HTTP::Server>
with native L<Future::AsyncAwait> integration into Langertha engines,
so streaming works end-to-end token-by-token without any thread or
event-loop bridges.

=head1 MANIFEST

C<GET /.well-known/langertha.json> serves a Langertha provider manifest
(schema v1, see L<Langertha::Manifest>) so a client such as
C<raider --provider HOST> can configure itself. It is built by
L<Langertha::Knarr::Manifest> from what this Knarr exposes: one endpoint
per protocol with a manifest dialect (OpenAI C</v1> as C<openai-chat>,
Anthropic as C<anthropic-compat>, Ollama as C<ollama>), every listed model
(configured aliases and auto-discovered ids) on each of them, with the
serving engine's model-scoped capabilities narrowed to what that protocol
forwards, and an C<api_key> auth entry when L</auth_token> is set. The
route is protected by L</auth_token> like C<GET /v1/models>. It never
carries configuration: no upstream URL, key, key variable name, engine
class or passthrough target. Under token auth
(L<Langertha::Knarr::Authorizer::Token>) it answers C<403>: it describes
every model of the Knarr, and a token is for one.

The manifest needs a Langertha that ships L<Langertha::Manifest::Builder>;
with an older one the route answers C<404> with a JSON error.

=head1 ADMIN ROUTES

With an L</admin> (C<knarr start> with C<KNARR_ADMIN_KEY>), a central
service can deliver the routing setup -- models, default engine,
passthrough upstreams, proxy key, provider keys and the Langfuse section --
as JSON, swap keys, read the status and drop the delivered setup again, all
under C</knarr/admin/> and only with the admin key. What arrives lies as a
layer over the start setup (config file) and is held in memory only.
Without an
admin these paths do not exist (C<404>). The routes, their answers and
their limits are described in L<Langertha::Knarr::Admin>.

The admin key opens only the admin routes: a request that presents it to
any other route gets C<401>, so it never reaches a handler or an upstream;
L</auth_token> in turn never opens an admin route. While the admin has no
setup (L<Langertha::Knarr::Config/remote_config> without a start setup,
before the first push), every
other route answers C<503> (C<not configured>) in its protocol's error
shape, after the L</auth_token> check.

A delivered setup replaces L</handler>, L</router>, L</raw_passthrough>,
L</auth_token> and, with a delivered C<langfuse> section, L</tracing> in one
step. Requests already running, streams
included, finish with what they started with; the provider manifest and
the capability probe start over with the new router.

=head1 ERRORS

Every error Knarr answers itself -- C<401> for a missing or wrong
L</auth_token> or token, C<403> for a model the client's token is not for
or a token without a route (see L</authorizer>), C<404> for a model nothing
serves, C<500> for a backend that failed, C<503> without a setup or while
the token check is unavailable, C<502>/C<504> for an upstream that failed
or timed out -- is in the error shape of the protocol the client
spoke (L<Langertha::Knarr::Protocol/format_error_response>): Anthropic's
C<{"type":"error","error":{"type":...,"message":...}}> with the error type
of the status (C<authentication_error>, C<api_error>, ...), Ollama's
C<{"error":"..."}>, A2A's JSON-RPC response with an C<error> object and
the request's C<id> (C<null> for a body that is not JSON, which is a
C<400> C<-32700> Parse error), ACP's C<{"code":...,"message":...}>
(C<server_error>, C<not_found>, C<invalid_input>), AG-UI's C<RUN_ERROR>
event as JSON, the OpenAI wire's C<{"error":{"message":...}}> for
OpenAI. The message is the cause without where Perl died:
no file path, line number, stack frame or C<@INC> list ever reaches a
client; the log and the request log keep the full text. Only an unknown path and Knarr's own manifest
route, which have no protocol, answer in the OpenAI wire's shape. The
native server and L<Langertha::Knarr::PSGI> answer alike.

A routed stream sends its C<200> with its first chunk (or its end, for a
stream without one), not before: a handler that fails before that is
answered like a non-streaming request, with a status in that shape. Once
the stream has started, a failure ends it with the protocol's error frame
(OpenAI C<data:> error object, Anthropic C<event: error>, Ollama
C<{"error":...}> line, A2A JSON-RPC error event, ACP C<run.failed>, AG-UI
C<RUN_ERROR>), the status of the failure's category (500 without one); the
frame replaces the end marker. The client therefore sees no response headers until
the backend's first token.

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

Required, unless an L</admin> is given. An object consuming
L<Langertha::Knarr::Handler>.

=head2 admin

Optional L<Langertha::Knarr::Admin>. Enables the L</ADMIN ROUTES>. Its
stack then supplies L</handler>, L</router>, L</raw_passthrough> and
L</auth_token> (given values are replaced), and each admin push replaces
them. Croaks with L</workers> above C<1>: every process would hold a setup
of its own.

=head2 listen

ArrayRef of C<host:port> strings or C<< { host => ..., port => ... } >>
hashes. Defaults to a single entry composed from L</host> and L</port>.

=head2 host

Default C<127.0.0.1>. Used when L</listen> is not given.

=head2 port

Default C<8088>. Used when L</listen> is not given.

=head2 loop

Optional L<IO::Async::Loop> instance. Defaults to a fresh one.

=head2 workers

Number of processes that serve requests. Default C<1>: L</run> serves from
the calling process, nothing is forked. With more, L</run> binds the listen
sockets, runs auto-discovery and the capability probe once (see L</run>),
then forks that many workers that all accept on the same sockets, and stays
behind as their supervisor, serving no request itself. Must be C<1> or more;
anything else croaks at construction, and so does more than C<1> together
with an L</admin>. C<knarr start> sets it from C<-w N>,
else from L<Langertha::Knarr::Config/workers> (C<workers:> or
C<KNARR_WORKERS>), and to C<1> with a warning when the admin key is set.

Every worker has its own state: L<Langertha::Knarr::Session>s (so a
L<Langertha::Knarr::Handler::Raider> conversation is only continued when
its next request reaches the same worker -- nothing routes it there), the
engine cache, and its own Langfuse batches, flushed by that worker. Request
log lines from all workers go to the same C<logging.file>, one whole line
per write. L<Langertha::Knarr::PSGI> never calls L</run>; there the PSGI
server decides about processes.

=head2 protocols

ArrayRef of protocol class basenames to load. Defaults to all six
shipped protocols.

=head2 protocol_args

Optional HashRef of constructor arguments per protocol, keyed by the name
as it appears in L</protocols>. The A2A agent card name and description:

    protocol_args => { A2A => {
      agent_name        => 'Support Agent',
      agent_description => 'Answers support questions',
    } },

C<knarr start> passes L<Langertha::Knarr::Config/protocol_args>.

=head2 auth_token

Optional shared secret. When set, every incoming request must present
it as C<Authorization: Bearer> or C<x-api-key>. Discovery routes
(C</.well-known/agent.json>) stay anonymous. A missing or wrong key gets
C<401> in the error shape of the route's protocol (see L</ERRORS>).

A header sent twice counts as one value of comma-separated elements (that
is how a PSGI server and C<< HTTP::Headers->header >> merge it), and the key
may be any one of them.

The key never leaves Knarr: it is taken out of a request to a passthrough
upstream (the L</raw_passthrough> and a
L<Langertha::Knarr::Handler::Passthrough> in the handler chain alike).
From C<Authorization> and C<x-api-key>, every element that is the key --
bare or as C<Bearer> I<key>, in either header -- is removed, the others are
kept, and a header left with nothing is dropped; a header without the key
goes through unchanged. Every other header is forwarded, so a passthrough
client sends its own provider key in the other header -- the proxy key in
C<x-api-key> and the OpenAI key as C<Authorization: Bearer>, or the proxy
key as C<Authorization: Bearer> and the Anthropic key in C<x-api-key>.

=head2 authorizer

Optional L<Langertha::Knarr::Authorizer>: who may use this Knarr, and with
which model. Default: a L<Langertha::Knarr::Authorizer::StaticKey> over
L</auth_token>, built anew when the C<auth_token> changes (an admin push);
a given authorizer stays for the Knarr's life. An admin push applies the
authorizer of its L<Langertha::Knarr::Stack> when that has one
(C<token_auth>: the stack keeps the same authorizer across pushes).

The process that serves calls its L<Langertha::Knarr::Authorizer/start>
once its loop is set up -- L</start> with one L</workers>, each forked
worker otherwise, never the prefork supervisor -- so a token store connects
before the first request instead of on it. Starting does not wait for the
connection; a second start in the same process (an admin push handing the
same authorizer over) does nothing.

It is asked twice per request, on the native server and under
L<Langertha::Knarr::PSGI> alike:

=over

=item 1. B<Identify>, once the route is known and before the body is read
(and before the C<503> of a Knarr without a setup): a missing, unknown or
expired credential gets C<401>, a check that cannot be made C<503>, so a
client that cannot identify itself learns no C<400>, C<404> or model name.
The native server waits for the answer without holding the event loop
(L<Langertha::Knarr::Authorizer/identify_f>). A request that presents the
L</admin> key to any other route gets C<401> before the authorizer is
asked.

=item 2. B<Authorize>, once action and model are known: a chat request
after it was parsed (sync and streaming, every protocol; a refused stream
gets its status, never a C<200>), C<POST /api/show> with the body's model,
the manifest. The identity of step 1 travels with the request as
L<Langertha::Knarr::Request/grant>, and a request that names no model gets
the identity's (L<Langertha::Knarr::Request/apply_grant>).

=back

The model lists (C<GET /v1/models>, C<GET /api/tags>, ACP C<GET /agents>)
and C<POST /api/show> show what
L<Langertha::Knarr::Authorizer/visible_models> leaves. An authorizer whose
L<Langertha::Knarr::Authorizer/forwards_client_key> is false
(L<Langertha::Knarr::Authorizer::Token>) turns the L</raw_passthrough> off
and drops C<Authorization> and C<x-api-key> from every header set Knarr
forwards: the client's credential never reaches an upstream.

=head2 ollama_compat_version

The Ollama version reported at C<GET /api/version> as
C<{"version":"..."}>. Default C<0.34.4>, the current Ollama release when
it was chosen (2026-09-23). It is a compatibility claim, not Knarr's own
version: Ollama clients read it as the server's Ollama version. Two
clients set its limits:

=over

=item * VS Code Copilot (BYOK Ollama) refuses a server below C<0.6.4>.

=item * Open WebUI parses every dotted part with C<int()>, so anything but
digits and dots (C<0.34.4-knarr>, C<v0.34>) breaks its connection check.

=back

The value must therefore be three dot-separated numbers
(C</^\d+\.\d+\.\d+$/>); anything else croaks at construction. No
surveyed client gates C<think>, tools or C<format> on the version -- they
read C</api/show> capabilities per model -- so raising it enables nothing
Knarr lacks. Configured as C<ollama_compat_version> in the config file or
C<KNARR_OLLAMA_COMPAT_VERSION>.

=head2 public_url

Optional public base URL (e.g. C<https://knarr.example>) used in the
provider manifest. When unset, the base URL is taken from the request
(C<Host>, and C<X-Forwarded-Proto> when it is C<http> or C<https>).

=head2 raw_passthrough

Optional L<Langertha::Knarr::Handler::Passthrough>. Together with a
L</router>, a chat request for a model the router does not configure -- or
knows only from auto-discovery on that same upstream
(L<Langertha::Knarr::Router/discovered_url>,
L<Langertha::Knarr::Handler::Passthrough/is_upstream_for>), when the
request carries the client's own provider key -- is
piped byte for byte to the upstream for the client's protocol (an Ollama
C</api/generate> to the upstream's C</api/generate>, any other Ollama chat
to C</api/chat>), bypassing the handler chain -- but only when that
protocol has an upstream
(L<Langertha::Knarr::Handler::Passthrough/serves_protocol>), and only while
the L</authorizer> lets the client's key go upstream. A request in
any other protocol (Ollama without an C<ollama> upstream, A2A, ACP, AG-UI)
goes through the handler, where L<Langertha::Knarr::Handler::Router> hands
it to the default engine, or answers C<404> in the protocol's error shape
when there is none.

Every client header line goes to the upstream as a line of its own, in
its order -- a header sent twice arrives twice -- with the proxy key taken
out of each line (see
L</auth_token>) and without C<Host>, C<Content-Length>, C<Connection> and
C<Transfer-Encoding>. The upstream's response headers come back the same
way, repeats included (C<Set-Cookie> twice), except the connection-level
ones and the framing Knarr sets itself (C<Transfer-Encoding>,
C<Content-Length>). A body compressed with an encoding Knarr's HTTP client
decodes (C<gzip>, C<deflate>) goes back decoded, without its
C<Content-Encoding>; a body in any other encoding (C<br>, C<zstd>, several
stacked), buffered or streamed, goes back as the upstream sent it, with
it. A stream gets
C<Cache-Control: no-cache> when the upstream sent none.

The provider key is looked for once the proxy key is taken out (see
L</auth_token>): C<Authorization> for OpenAI, C<x-api-key> or
C<Authorization> for Anthropic; Ollama needs none. A discovered model
requested without one goes through the handler instead, to the engine
that listed it, with that engine's key -- the upstream would only answer
C<401>. A model nobody configured or discovered passes through either way.

A discovered model's request that does carry a key the upstream refuses
with C<401> -- the placeholder key an SDK sends when it has none -- is
answered the same way: through the handler, by the engine that listed the
model, with that engine's key. The client never sees the C<401>, streaming
or not: the upstream's status is known before any byte goes to the client.
The upstream is asked once, its refusal is dropped, and the request is
traced once, by L<Langertha::Knarr::Handler::Tracing>, with
C<passthrough_fallback: 401> in the trace's metadata. Any other status
(C<403>, C<429>, C<5xx>) goes back unchanged, and so does the C<401> for a
model nobody configured or discovered, which has no engine to fall back
to.

=head2 router

Optional L<Langertha::Knarr::Router>, usually the one the
L<Langertha::Knarr::Handler::Router> handler wraps. Knarr itself uses it
to decide which requests go to the L</raw_passthrough> (models it does not
configure, and models it only discovered on that upstream when the client
sends its own key), to answer
C<POST /api/show> from the routed engine's
capabilities (without a router it falls back to the handler's
C<list_models> and claims no C<vision>), and to start the capability probe
in L</start>.

=head2 tracing

Optional L<Langertha::Knarr::Tracing>. Only the L</raw_passthrough> uses
it: a request that bypasses the handler chain gets a lightweight Langfuse
trace from here. Its generation carries the token usage and the model the
upstream reported, read off a copy of the answer by
L<Langertha::Knarr::PassthroughUsage> -- the JSON body, or the frames of a
stream that carry them (OpenAI's final usage chunk, which the client asks
for with C<stream_options.include_usage>; Anthropic's C<message_start> and
C<message_delta>; Ollama's C<done> frame). The bytes the client gets are
never touched; nothing is read without an active trace, nor from bytes
that still carry a C<Content-Encoding>. Requests through the handler chain are traced by the
L<Langertha::Knarr::Handler::Tracing> decorator instead -- so is a raw
passthrough that falls back to its engine after a C<401> (see
L</raw_passthrough>); the trace of a request that may fall back is
therefore opened only once the upstream's status is known, dated back to
when the request went out. Raw passthrough requests are not written to the
request log; a fallback is, by the handler chain.

=head2 start

    $knarr->start;

Binds all listen sockets and registers the dispatcher. Returns
C<$self>. Does not enter the event loop. Each socket queues up to
C<SOMAXCONN> pending connections (C<128> where L<Socket> does not know it;
the kernel caps it at its own limit, C<net.core.somaxconn> on Linux).

Once the sockets listen, it starts
L<Langertha::Knarr::Router/probe_capabilities_f> on the L</loop> when a
L</router> that has it is set (see
L<Langertha::Knarr::Config/probe_capabilities>). The probe runs in the
background; until it has finished, C<POST /api/show> and the manifest answer
from Langertha's static capability tables. L<Langertha::Knarr::PSGI> does not
call L</start>, so under PSGI the probe runs only when you call it.

With one L</workers> it then starts the L</authorizer>
(L<Langertha::Knarr::Authorizer/start>): a token store opens its connection
in the background. With more, this process only binds; every worker starts
the authorizer for itself (see L</run>).

=head2 run

    $knarr->run;   # blocks

With one L</workers> (the default): calls L</start> if needed, then enters
the L</loop> and blocks.

With more, it prefork-serves and returns only once all workers are gone:

=over

=item 1. The listen sockets are bound here (L</start> may have done it),
and this process stops accepting on them.

=item 2. Auto-discovery and the capability probe run here, once, to the
end, before any worker exists -- each worker inherits the discovered models
and the learned capabilities instead of asking the upstreams again. Until
the probe is done (each probe gives up after
L<Langertha::Knarr::Config/probe_timeout>), connections wait in the
sockets' backlog. Upstream connections the probe kept open are closed, and
the helper processes of the loop's resolver end, so no two workers share
one: each worker starts its own resolver helpers.

=item 3. L</workers> processes are forked; each rebuilds the loop's kernel
state (L<IO::Async::Loop/post_fork>), accepts on the inherited sockets and
starts the L</authorizer> (L<Langertha::Knarr::Authorizer/start>): each
worker opens its own token store connection, the supervisor none.

=item 4. This process supervises them: a worker that exits is replaced --
one that dies within five seconds of its start after a pause of 1, 2, 4
... up to 30 seconds, so a worker that cannot start does not spin. A
replacement that cannot be forked (out of processes or memory) is tried
again the same way while the other workers serve on; only a failed fork of
the first workers makes L</run> die, after stopping those already started.
C<SIGTERM> or C<SIGINT> is passed on to the workers as C<SIGTERM>; once
they have exited, L</run> returns.

=back

=head2 session

    my $session = $knarr->session($id);

Returns the L<Langertha::Knarr::Session> for the given id, creating
one on demand. Used internally by the dispatcher.

=head2 manifest_response

    my ($status, $json_body) = $knarr->manifest_response(
        scheme => 'https', host => 'knarr.example', prefix => '' );

Builds the provider manifest (see L</MANIFEST>) and returns the HTTP
status and JSON body. The base URL is L</public_url>, else
C<scheme://host> plus C<prefix> from the request. C<404> when core has no
manifest builder, C<400> when no base URL can be derived, C<500> when the
manifest cannot be built. Used by the native server and
L<Langertha::Knarr::PSGI>.

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
