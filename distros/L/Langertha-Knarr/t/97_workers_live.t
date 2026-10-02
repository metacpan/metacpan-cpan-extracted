use strict;
use warnings;
use Test2::V0;
use POSIX ();
use Time::HiRes qw( sleep time );
use Scalar::Util qw( refaddr );
use HTTP::Request;
use JSON::MaybeXS;
use File::Temp qw( tempdir );
use Path::Tiny;

# k51: knarr start -w N is real prefork. The supervisor binds the listen
# sockets, forks N workers that accept on them, replaces a worker that dies,
# and on SIGTERM stops them all and exits. workers => 1 forks nothing. Every
# server here is a local Handler::Code fake answering with its own pid; no
# test touches a network beyond 127.0.0.1.

plan skip_all => 'needs a real fork()' if $^O eq 'MSWin32';

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub free_port {
  require IO::Socket::INET;
  my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 )
    or die "free_port: $!";
  my $p = $s->sockport;
  $s->close;
  return $p;
}

# One request on a fresh connection (HTTP::Tiny without keep-alive), so
# each one is accepted anew by whichever worker wins it.
sub ask {
  my ($port) = @_;
  my ($pid) = ( answer($port) // '' ) =~ /\Apid:(\d+)/;
  return $pid;
}

sub answer {
  my ($port) = @_;
  require HTTP::Tiny;
  my $res = HTTP::Tiny->new( keep_alive => 0, timeout => 5 )->post(
    "http://127.0.0.1:$port/v1/chat/completions",
    { headers => { 'Content-Type' => 'application/json' },
      content => $json->encode({ model => 'm', messages => [ { role => 'user', content => 'pid?' } ] }) },
  );
  return unless $res->{success};
  my $d = eval { $json->decode( $res->{content} ) } or return;
  return $d->{choices}[0]{message}{content};
}

# $n requests at once, each from its own short-lived client process: while
# one worker sleeps in its handler, the others must take the next ones.
sub ask_parallel {
  my ($port, $n) = @_;
  my @kids;
  for ( 1 .. $n ) {
    pipe( my $r, my $w ) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    unless ($pid) {
      close $r;
      print {$w} ( ask($port) // '' );
      close $w;
      POSIX::_exit(0);
    }
    close $w;
    push @kids, [ $pid, $r ];
  }
  my @pids;
  for my $k (@kids) {
    my $fh = $k->[1];
    my $got = do { local $/; <$fh> };
    waitpid( $k->[0], 0 );
    push @pids, $got if defined $got && length $got;
  }
  return @pids;
}

sub wait_until {
  my ($timeout, $cond) = @_;
  my $end = time + $timeout;
  while ( time < $end ) {
    my @r = $cond->();
    return wantarray ? @r : $r[0] if @r && defined $r[0];
    sleep 0.1;
  }
  return;
}

sub alive { kill 0, $_[0] }

# Wait for $pid to exit; its $? or undef on timeout.
sub reap {
  my ($pid, $timeout) = @_;
  my $end = time + $timeout;
  while ( time < $end ) {
    my $r = waitpid( $pid, POSIX::WNOHANG() );
    return $? if $r == $pid;
    return undef if $r < 0;
    sleep 0.05;
  }
  return undef;
}

# The server runs in its own process, forked before any loop exists here.
# $args{ready}, when given, tells from the port when the server is up
# (default: ask answers); $args{class} replaces Langertha::Knarr.
sub start_server {
  my (%args) = @_;
  my $ready = delete $args{ready} // \&ask;
  my $class = delete $args{class} // 'Langertha::Knarr';
  my $port = free_port();
  my $pid = fork // die "fork: $!";
  unless ($pid) {
    my $ok = eval {
      $class->new(
        handler => Langertha::Knarr::Handler::Code->new( code => sub {
          sleep 0.3;   # holds this worker, so a parallel request needs another
          return "pid:$$";
        } ),
        listen  => [ "127.0.0.1:$port" ],
        %args,
      )->run;
      1;
    };
    warn "server failed: $@" unless $ok;
    POSIX::_exit( $ok ? 0 : 1 );
  }
  my $up = wait_until( 15, sub { $ready->($port) } );
  return ( $pid, $port, $up );
}

subtest 'workers must be 1 or more' => sub {
  my $h = Langertha::Knarr::Handler::Code->new( code => sub { 'x' } );
  is( Langertha::Knarr->new( handler => $h )->workers, 1, 'default 1' );
  like( dies { Langertha::Knarr->new( handler => $h, workers => 0 ) },
    qr/workers '0' must be 1 or more/, '0 croaks' );
  like( dies { Langertha::Knarr->new( handler => $h, workers => -2 ) },
    qr/must be 1 or more/, 'negative croaks' );
};

subtest 'workers => 1 serves from the process that runs it' => sub {
  my ($server, $port, $up) = start_server();
  ok( $up, 'server answers' ) or return;
  is( $up, $server, 'the answer comes from the run() process itself: no fork' );
  my %seen = map { $_ => 1 } ask_parallel( $port, 4 );
  is( [ keys %seen ], [ $server ], 'parallel requests: still that one process' );
  kill TERM => $server;
  ok( defined reap( $server, 10 ), 'SIGTERM ends it' );
};

subtest 'workers => 2: prefork, restart, SIGTERM' => sub {
  my ($super, $port, $up) = start_server( workers => 2 );
  ok( $up, 'server answers' ) or do { kill KILL => $super; return };

  my %workers;
  wait_until( 30, sub {
    $workers{$_}++ for ask_parallel( $port, 4 );
    keys %workers >= 2 ? 1 : ();
  } );
  is( scalar keys %workers, 2, 'two distinct workers answered' )
    or diag 'seen: ' . join ',', keys %workers;
  ok( !$workers{$super}, 'the supervisor answers nothing itself' );
  ok( alive($_), "worker $_ is alive" ) for keys %workers;

  my ($victim) = sort keys %workers;
  kill KILL => $victim;
  ok( wait_until( 5, sub { alive($victim) ? () : 1 } ), 'killed worker is gone (reaped)' );

  my %after;
  my ($new) = wait_until( 30, sub {
    $after{$_}++ for ask_parallel( $port, 4 );
    my @fresh = grep { !$workers{$_} } keys %after;
    @fresh ? $fresh[0] : ();
  } );
  ok( $new, 'a new worker replaced the killed one' );
  ok( !$after{$victim}, 'the killed worker answers no more' );
  ok( alive($super), 'the supervisor survived the worker death' );

  my %all = map { $_ => 1 } keys %workers, keys %after;
  delete $all{$victim};
  my @all = sort keys %all;
  kill TERM => $super;
  my $status = reap( $super, 15 );
  ok( defined $status, 'supervisor exits on SIGTERM' );
  is( $status, 0, 'with status 0' );
  ok( !alive($_), "worker $_ exited too" ) for @all;
  ok( !ask($port), 'nothing answers on the port any more' );
};

# Stands in for Langertha::Knarr::Router: logs who discovers and probes,
# and learns only once the probe's Future is done.
{
  package TestProbeRouter;
  use Future;
  use Path::Tiny;
  sub new { my ($class, %a) = @_; bless { %a, learned => 0 }, $class }
  sub list_models {
    my ($self) = @_;
    path( $self->{log} )->append("discover $$\n");
    return [];
  }
  sub probe_capabilities_f {
    my ($self, %args) = @_;
    path( $self->{log} )->append("probe $$\n");
    $self->list_models;
    return $args{loop}->delay_future( after => 0.5 )
      ->then( sub { $self->{learned} = 1; Future->done(1) } );
  }
}

subtest 'workers => 2: discovery and probe run once, before the fork' => sub {
  my $log = path( tempdir( CLEANUP => 1 ), 'calls' );
  $log->touch;
  my $router = TestProbeRouter->new( log => "$log" );
  my ($super, $port, $up) = start_server(
    workers => 2,
    router  => $router,
    handler => Langertha::Knarr::Handler::Code->new( code => sub {
      sleep 0.3;
      return "pid:$$ learned:$router->{learned}";
    } ),
  );
  ok( $up, 'server answers' ) or do { kill KILL => $super; return };

  my %learned;
  wait_until( 30, sub {
    for ( 1 .. 4 ) {
      my ($pid, $l) = ( answer($port) // '' ) =~ /\Apid:(\d+) learned:(\d)/ or next;
      $learned{$pid} = $l;
    }
    keys %learned >= 2 ? 1 : ();
  } );
  is( scalar keys %learned, 2, 'two workers answered' );
  ok( !exists $learned{$super}, 'neither is the supervisor' );
  is( [ values %learned ], [ 1, 1 ], 'both workers start with the probe result' );
  is( [ $log->lines( { chomp => 1 } ) ],
    [ "discover $super", "probe $super", "discover $super" ],
    'discovery and probe ran in the supervisor only, once each (the second discover is the probe\'s own)' );

  kill TERM => $super;
  is( reap( $super, 15 ), 0, 'SIGTERM: supervisor exits with status 0' );
};

# Stands in for Langertha::Knarr::Router in the raw passthrough: every model
# is a passthrough model, and the probe looks up "localhost" -- a hostname,
# so IO::Async starts its resolver helper process in the supervisor, as a
# real probe's first connect does.
{
  package TestResolveRouter;
  sub new { my ($class, %a) = @_; bless { %a }, $class }
  sub list_models { [] }
  sub is_passthrough_model { 1 }
  sub probe_capabilities_f {
    my ($self, %args) = @_;
    return $args{loop}->resolver->getaddrinfo(
      host => 'localhost', service => $self->{port}, socktype => 'stream',
    )->then( sub { Future->done(1) } );
  }
}

# A local upstream that answers every request with its own name.
sub fake_upstream {
  my ($name) = @_;
  my $port = free_port();
  my $pid = fork // die "fork: $!";
  unless ($pid) {
    require IO::Async::Loop;
    require HTTP::Response;
    require Net::Async::HTTP::Server;
    my $loop = IO::Async::Loop->really_new;
    my $srv = Net::Async::HTTP::Server->new( on_request => sub {
      my ($srv, $req) = @_;
      my $resp = HTTP::Response->new(200);
      $resp->header( 'Content-Type' => 'application/json' );
      $resp->content( $json->encode({ upstream => $name }) );
      $resp->content_length( length $resp->content );
      $req->respond($resp);
    } );
    $loop->add($srv);
    $srv->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => $port } )->get;
    $loop->run;
    POSIX::_exit(0);
  }
  return ( $pid, $port );
}

subtest 'workers do not share the supervisor\'s resolver helper' => sub {
  require Langertha::Knarr::Handler::Passthrough;
  my ($openai, $oport)    = fake_upstream('openai');
  my ($anthropic, $aport) = fake_upstream('anthropic');
  my ($super, $port, $up) = start_server(
    workers         => 4,
    router          => TestResolveRouter->new( port => $oport ),
    raw_passthrough => Langertha::Knarr::Handler::Passthrough->new(
      upstreams => { openai => "http://localhost:$oport", anthropic => "http://localhost:$aport" },
      timeout   => 20,
    ),
    ready => sub {
      require HTTP::Tiny;
      HTTP::Tiny->new( keep_alive => 0, timeout => 2 )
        ->get("http://127.0.0.1:$_[0]/api/version")->{success} ? 1 : ();
    },
  );
  ok( $up, 'server answers' ) or do { kill KILL => $super, $openai, $anthropic; return };

  # 40 requests at once, alternating protocols, each on its own connection:
  # every worker resolves "localhost" for both upstreams concurrently. With
  # a shared helper, a worker reads another's answer and connects to the
  # wrong upstream -- or waits for an answer that never comes.
  my @kids;
  for my $i ( 1 .. 40 ) {
    my $proto = $i % 2 ? 'openai' : 'anthropic';
    pipe( my $r, my $w ) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    unless ($pid) {
      close $r;
      require HTTP::Tiny;
      my ($path, $body) = $proto eq 'openai'
        ? ( '/v1/chat/completions', { model => 'gpt-x', messages => [ { role => 'user', content => 'hi' } ] } )
        : ( '/v1/messages', { model => 'claude-x', max_tokens => 5, messages => [ { role => 'user', content => 'hi' } ] } );
      my $res = HTTP::Tiny->new( keep_alive => 0, timeout => 30 )->post( "http://127.0.0.1:$port$path", {
        headers => { 'Content-Type' => 'application/json', 'x-api-key' => 'k', 'Authorization' => 'Bearer k' },
        content => $json->encode($body),
      } );
      my $got = $res->{success}
        ? ( eval { $json->decode( $res->{content} )->{upstream} } // 'garbled' )
        : 'HTTP ' . $res->{status};
      print {$w} "$proto -> $got";
      close $w;
      POSIX::_exit(0);
    }
    close $w;
    push @kids, [ $pid, $r ];
  }
  my %tally;
  for my $k (@kids) {
    my $fh = $k->[1];
    my $got = do { local $/; <$fh> };
    waitpid( $k->[0], 0 );
    $tally{$got}++;
  }
  is( \%tally, { 'openai -> openai' => 20, 'anthropic -> anthropic' => 20 },
    'every request reached its own protocol\'s upstream' );

  kill TERM => $super;
  is( reap( $super, 15 ), 0, 'SIGTERM: supervisor exits with status 0' );
  kill TERM => $openai, $anthropic;
  waitpid( $_, 0 ) for $openai, $anthropic;
};

subtest 'the supervisor ends its resolver helpers before the fork' => sub {
  require IO::Async::Loop;
  my $loop = IO::Async::Loop->really_new;
  my $knarr = Langertha::Knarr->new(
    handler => Langertha::Knarr::Handler::Code->new( code => sub { 'x' } ),
    router  => TestResolveRouter->new( port => 1 ),
    listen  => [ '127.0.0.1:' . free_port() ],
    loop    => $loop,
    workers => 2,
  );
  my $before = $loop->resolver;
  $knarr->_prepare_workers;
  isnt( refaddr $loop->resolver, refaddr $before, 'the loop has a fresh resolver' );
  ok( !$before->loop, 'the probe\'s resolver left the loop' );
  is( $before->workers, 0, '... with its helper processes' );
  is( $loop->resolver->workers, 0, 'the fresh one starts none until a worker needs it' );
  is( [ keys %{ $loop->{childwatches} } ], [], 'no watch on a helper pid is inherited' );
  my @addrs = $loop->resolver->getaddrinfo(
    host => 'localhost', service => 1, socktype => 'stream' )->get;
  ok( scalar @addrs, 'the fresh resolver resolves' );
  $loop->resolver->stop;
};

# Makes the supervisor's forks misbehave on cue, by call number: 'fail'
# fails it with EAGAIN, 'term' sends the new worker SIGTERM the moment it
# exists (while the worker still dawdles in the fork for 0.3s). Every fork
# is logged as "<n> <pid>" or "fail <n>".
{
  package TestForkKnarr;
  use Moose;
  use Path::Tiny;
  use Time::HiRes ();
  extends 'Langertha::Knarr';
  has fork_plan => ( is => 'ro', default => sub { {} } );
  has fork_log  => ( is => 'ro', required => 1 );
  has _forks    => ( is => 'rw', default => 0 );
  sub _fork {
    my ($self) = @_;
    my $n = $self->_forks( $self->_forks + 1 );
    my $plan = $self->fork_plan->{$n} // '';
    if ( $plan eq 'fail' ) {
      path( $self->fork_log )->append("fail $n\n");
      $! = POSIX::EAGAIN();
      return undef;
    }
    my $pid = $self->SUPER::_fork;
    return $pid unless defined $pid;
    if ($pid) {
      path( $self->fork_log )->append("$n $pid\n");
      kill TERM => $pid if $plan eq 'term';
    }
    elsif ( $plan eq 'term' ) {
      Time::HiRes::sleep(0.3);
    }
    return $pid;
  }
  __PACKAGE__->meta->make_immutable;
}

# The forks the supervisor logged: n => pid (0 for a failed one).
sub forks {
  my ($log) = @_;
  my %forks;
  for ( $log->lines( { chomp => 1 } ) ) {
    /\Afail (\d+)\z/ ? ( $forks{$1} = 0 ) : /\A(\d+) (\d+)\z/ ? ( $forks{$1} = $2 ) : ();
  }
  return \%forks;
}

subtest 'a restart that cannot fork is retried, the others keep serving' => sub {
  my $log = path( tempdir( CLEANUP => 1 ), 'forks' );
  $log->touch;
  my ($super, $port, $up) = start_server(
    class     => 'TestForkKnarr',
    workers   => 2,
    fork_log  => "$log",
    fork_plan => { 3 => 'fail' },
  );
  ok( $up, 'server answers' ) or do { kill KILL => $super; return };
  my ( $first, $second ) = @{ forks($log) }{ 1, 2 };

  kill KILL => $first;
  ok( wait_until( 20, sub { forks($log)->{4} } ), 'after a failed fork, the next one is tried' );
  is( forks($log)->{3}, 0, '... the failed one was the first restart' );
  is( reap( $super, 1 ), undef, 'the supervisor survived the failed fork' );
  ok( alive($second), 'so did the other worker' );
  my %seen;
  wait_until( 20, sub {
    $seen{$_}++ for ask_parallel( $port, 4 );
    keys %seen >= 2 ? 1 : ();
  } );
  is( [ sort keys %seen ], [ sort $second, forks($log)->{4} ],
    'the other worker and the new one serve' );

  kill TERM => $super;
  is( reap( $super, 15 ), 0, 'SIGTERM: supervisor exits with status 0' );
};

subtest 'a first worker that cannot fork is fatal' => sub {
  my $log = path( tempdir( CLEANUP => 1 ), 'forks' );
  $log->touch;
  my ($super) = start_server(
    class     => 'TestForkKnarr',
    workers   => 2,
    fork_log  => "$log",
    fork_plan => { 2 => 'fail' },
    ready     => sub { 1 },
  );
  my $status = reap( $super, 20 );
  is( defined $status ? $status >> 8 : undef, 1, 'run() dies, the server exits with status 1' );
  my $first = forks($log)->{1};
  ok( $first, 'the first worker had started' );
  ok( !alive($first), '... and was stopped' ) if $first;
};

subtest 'SIGTERM right after the fork ends only that worker' => sub {
  my $log = path( tempdir( CLEANUP => 1 ), 'forks' );
  $log->touch;
  my ($super, $port, $up) = start_server(
    class     => 'TestForkKnarr',
    workers   => 2,
    fork_log  => "$log",
    fork_plan => { 2 => 'term' },
    ready     => sub { 1 },
  );
  # The worker TERMed in the fork dies; the supervisor replaces it.
  ok( wait_until( 20, sub { forks($log)->{3} } ), 'the TERMed worker was replaced' );
  my ( $first, $termed ) = @{ forks($log) }{ 1, 2 };
  ok( wait_until( 5, sub { alive($termed) ? () : 1 } ), 'the TERMed worker is gone' );
  ok( alive($first), 'the first worker was not touched' );
  is( reap( $super, 1 ), undef, 'the supervisor serves on' );
  ok( wait_until( 15, sub { ask($port) } ), 'the server answers' );

  kill TERM => $super;
  is( reap( $super, 15 ), 0, 'SIGTERM: supervisor exits with status 0' );
};

subtest 'upstream connections are not inherited by workers' => sub {
  require IO::Async::Loop;
  require HTTP::Response;
  require Net::Async::HTTP;
  require Net::Async::HTTP::Server;
  my $loop = IO::Async::Loop->really_new;
  my %streams;
  my $upstream = Net::Async::HTTP::Server->new( on_request => sub {
    my ($srv, $req) = @_;
    $streams{ refaddr $req->stream } = 1;
    my $resp = HTTP::Response->new(200);
    $resp->content('ok');
    $resp->content_length(2);
    $req->respond($resp);
  } );
  $loop->add($upstream);
  my $port = free_port();
  $upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => $port } )->get;

  my $http = Net::Async::HTTP->new;
  $loop->add($http);
  my $get = sub { $http->GET("http://127.0.0.1:$port/")->get->content };
  is( $get->(), 'ok', 'first upstream request' );
  is( $get->(), 'ok', 'second upstream request' );
  is( scalar keys %streams, 1, 'keep-alive: both on one connection' );

  my $knarr = Langertha::Knarr->new(
    handler => Langertha::Knarr::Handler::Code->new( code => sub { 'x' } ),
    loop    => $loop,
  );
  $knarr->_drop_upstream_connections;
  is( [ grep { $_->isa('Net::Async::HTTP::Connection') } $http->children ], [],
    'the pooled connection is closed before any fork' );
  ok( $http->loop, 'the client is back in the loop' );
  is( $get->(), 'ok', 'the client still works' );
  is( scalar keys %streams, 2, '... on a new connection' );
};

# Runs bin/knarr start on a free port with a config of one never-asked model
# (nothing leaves 127.0.0.1) plus $yaml, KNARR_WORKERS from $env (unset
# without), and @argv. Returns the pid, the port and the stderr file.
sub cli_start {
  my (%a) = @_;
  my $dir  = tempdir( CLEANUP => 1 );
  my $cfg  = path( $dir, 'knarr.yaml' );
  $cfg->spew_utf8( "probe_capabilities: 0\nmodels:\n  local:\n"
    . "    engine: OllamaOpenAI\n    url: http://127.0.0.1:9/v1\n" . ( $a{yaml} // '' ) );
  my $err  = path( $dir, 'stderr' );
  my $port = free_port();
  my $bin  = path(__FILE__)->parent->parent->child( 'bin', 'knarr' );
  my $pid = fork // die "fork: $!";
  unless ($pid) {
    defined $a{env} ? ( $ENV{KNARR_WORKERS} = $a{env} ) : delete $ENV{KNARR_WORKERS};
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', "$err";
    exec( $^X, ( map { '-I' . $_ } grep { !ref } @INC ), "$bin",
      'start', '-c', ( $a{config} // "$cfg" ), '-H', '127.0.0.1', '-p', $port, @{ $a{argv} // [] } )
      or POSIX::_exit(127);
  }
  return ( $pid, $port, $err );
}

subtest 'knarr start: worker count from -w, workers: and KNARR_WORKERS' => sub {
  plan skip_all => 'needs /proc to count the workers' unless -d '/proc';
  require HTTP::Tiny;
  for my $case (
    [ '-w 2',                          2, argv => [ '-w', 2 ] ],
    [ 'workers: 2 in the config',      2, yaml => "workers: 2\n" ],
    [ 'KNARR_WORKERS=3',               3, env  => 3 ],
    [ 'KNARR_WORKERS=3, -w 2 wins',    2, env  => 3, argv => [ '-w', 2 ] ],
    [ 'workers: 3 in the config, -w 2 wins', 2, yaml => "workers: 3\n", argv => [ '-w', 2 ] ],
  ) {
    my ( $name, $want, %a ) = @$case;
    my ($super, $port) = cli_start(%a);
    my $up = wait_until( 20, sub {
      HTTP::Tiny->new( keep_alive => 0, timeout => 2 )
        ->get("http://127.0.0.1:$port/api/version")->{status} == 200 ? 1 : ();
    } );
    ok( $up, "$name: knarr answers" );
    my @kids = wait_until( 10, sub {
      my @k = children_of($super);
      @k == $want ? @k : ();
    } );
    is( scalar @kids, $want, "$name: $want worker children" );
    kill TERM => $super;
    is( reap( $super, 15 ), 0, "$name: SIGTERM, exit status 0" );
    ok( !alive($_), "$name: worker $_ exited too" ) for @kids;
  }
};

subtest 'knarr start: a bad worker count stops it before the banner' => sub {
  for my $case (
    [ '-w 0',              qr{-w/--workers must be 1 or more, got 0}, argv => [ '-w', 0 ] ],
    [ 'workers: 0',        qr{workers '0' must be a whole number of 1 or more}, yaml => "workers: 0\n" ],
    [ 'KNARR_WORKERS=many under --from-env',
      qr{workers 'many' must be a whole number of 1 or more},
      env => 'many', config => '/nonexistent/knarr.yaml', argv => ['--from-env'] ],
  ) {
    my ( $name, $error, %a ) = @$case;
    my ($pid, $port, $err) = cli_start(%a);
    my $status = reap( $pid, 20 );
    is( defined $status ? $status >> 8 : undef, 1, "$name: exits with status 1" );
    my $stderr = $err->slurp_utf8;
    like( $stderr, $error, "$name: says why" );
    unlike( $stderr, qr/Knarr LLM Proxy starting/, "$name: before the banner" );
    ok( !ask($port), "$name: nothing listens" );
  }
};

sub children_of {
  my ($ppid) = @_;
  my @kids;
  for my $stat ( glob '/proc/[0-9]*/stat' ) {
    my $line = eval { path($stat)->slurp } // next;
    # pid (comm) state ppid ...; comm may hold spaces and parens.
    my ($pid, $parent) = $line =~ /\A(\d+) \(.*\) \S+ (\d+) / or next;
    push @kids, $pid if $parent == $ppid;
  }
  return @kids;
}

done_testing;
