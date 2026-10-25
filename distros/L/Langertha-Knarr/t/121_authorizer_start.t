use strict;
use warnings;
use Test2::V0;
use POSIX ();
use Time::HiRes qw( sleep time );
use File::Temp qw( tempdir );
use Path::Tiny;
use HTTP::Request;
use JSON::MaybeXS;

# k82: the process that serves starts the authorizer once its loop is set up,
# so a token store connects before the first request instead of on it:
# Knarr->start with one worker, each forked worker with more -- never the
# prefork supervisor, whose connection every worker would share (k51). A
# second start in the same process (an admin push handing the same
# authorizer over) does nothing. The store here counts its starts per
# process in a file; nothing leaves 127.0.0.1.

plan skip_all => 'needs a real fork()' if $^O eq 'MSWin32';

use IO::Async::Loop;
use Net::Async::HTTP;
use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Authorizer::Token;
use Langertha::Knarr::TokenStore::Memory;

{
  package Test::CountingStore;
  use Moose;
  extends 'Langertha::Knarr::TokenStore::Memory';
  has log_file => ( is => 'ro', required => 1 );
  sub start {
    my ($self) = @_;
    Path::Tiny::path( $self->log_file )->append("start:$$\n");
    return;
  }
  __PACKAGE__->meta->make_immutable;
}

{
  # What Knarr::_apply_stack reads off a Langertha::Knarr::Stack.
  package Test::Stack;
  use Moose;
  has [qw( handler authorizer )] => ( is => 'ro' );
  sub router          { undef }
  sub raw_passthrough { undef }
  sub auth_token      { undef }
  sub tracing         { undef }
  __PACKAGE__->meta->make_immutable;
}

my $json  = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $TOKEN = 'tok-start-0123456789';
my $dir   = tempdir( CLEANUP => 1 );

sub free_port {
  require IO::Socket::INET;
  my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 )
    or die "free_port: $!";
  my $p = $s->sockport;
  $s->close;
  return $p;
}

sub lines_of {
  my ($file) = @_;
  return () unless -e $file;
  return path($file)->lines( { chomp => 1 } );
}

sub make_store {
  my ($file) = @_;
  my $store = Test::CountingStore->new( log_file => $file );
  $store->add( token => $TOKEN, model => 'm', provider => 'p', expires => time + 900 );
  return $store;
}

sub make_handler {
  my ($file) = @_;
  return Langertha::Knarr::Handler::Code->new( code => sub {
    path($file)->append("req:$$\n");
    sleep 0.3;   # holds this worker, so a parallel request needs another
    return "pid:$$";
  } );
}

subtest 'Authorizer::Token->start starts its store once per process' => sub {
  my $file = "$dir/direct.log";
  my $authorizer = Langertha::Knarr::Authorizer::Token->new( store => make_store($file) );
  is( [ lines_of($file) ], [], 'building the authorizer starts nothing' );
  $authorizer->start;
  $authorizer->start;
  is( [ lines_of($file) ], [ "start:$$" ], 'two starts, the store started once' );

  my $pid = fork // die "fork: $!";
  unless ($pid) {
    $authorizer->start;
    $authorizer->start;
    POSIX::_exit(0);
  }
  waitpid( $pid, 0 );
  is( [ lines_of($file) ], [ "start:$$", "start:$pid" ],
    'a forked process starts it again, once' );
};

# Prefork first: the server process is forked before any loop exists here.
subtest 'workers => 2: every worker starts it, the supervisor never' => sub {
  my $file = "$dir/workers.log";
  my $port = free_port();
  my $super = fork // die "fork: $!";
  unless ($super) {
    my $ok = eval {
      my $knarr = Langertha::Knarr->new(
        handler    => make_handler($file),
        authorizer => Langertha::Knarr::Authorizer::Token->new( store => make_store($file) ),
        listen     => [ "127.0.0.1:$port" ],
        workers    => 2,
      );
      $knarr->start;   # binds here; documented as allowed before run
      $knarr->run;
      1;
    };
    warn "server failed: $@" unless $ok;
    POSIX::_exit( $ok ? 0 : 1 );
  }

  require HTTP::Tiny;
  my $ask = sub {
    my $res = HTTP::Tiny->new( keep_alive => 0, timeout => 5 )->post(
      "http://127.0.0.1:$port/v1/chat/completions",
      { headers => { 'Content-Type' => 'application/json', Authorization => "Bearer $TOKEN" },
        content => $json->encode( { model => 'm', messages => [ { role => 'user', content => 'x' } ] } ) },
    );
    return unless $res->{success};
    my $d = eval { $json->decode( $res->{content} ) } or return;
    my ($pid) = ( $d->{choices}[0]{message}{content} // '' ) =~ /\Apid:(\d+)/;
    return $pid;
  };
  my $parallel = sub {
    my @kids;
    for ( 1 .. 4 ) {
      pipe( my $r, my $w ) or die "pipe: $!";
      my $pid = fork // die "fork: $!";
      unless ($pid) { close $r; print {$w} ( $ask->() // '' ); close $w; POSIX::_exit(0) }
      close $w;
      push @kids, [ $pid, $r ];
    }
    my @pids;
    for my $k (@kids) {
      my $fh = $k->[1];
      my $got = do { local $/; <$fh> };
      waitpid( $k->[0], 0 );
      push @pids, $got if length $got;
    }
    return @pids;
  };

  my %workers;
  my $end = time + 30;
  while ( time < $end && keys %workers < 2 ) {
    $workers{$_}++ for $parallel->();
    sleep 0.1 if keys %workers < 2;
  }
  is( scalar keys %workers, 2, 'two workers answered token requests' )
    or diag 'seen: ' . join ',', keys %workers;

  my @lines = lines_of($file);
  my %starts;
  $starts{$_}++ for map { /^start:(\d+)/ ? $1 : () } @lines;
  ok( !$starts{$super}, 'the supervisor never started the authorizer' );
  for my $w ( sort keys %workers ) {
    is( $starts{$w}, 1, "worker $w started it once" );
    my ($first) = grep { /:$w\z/ } @lines;
    is( $first, "start:$w", "worker $w started it before its first request" );
  }
  is( [ sort keys %starts ], [ sort keys %workers ], 'only the workers started it' );

  kill TERM => $super;
  waitpid( $super, 0 );
};

subtest 'one worker: start() starts the authorizer, before any request' => sub {
  my $file = "$dir/single.log";
  my $loop = IO::Async::Loop->new;
  my $authorizer = Langertha::Knarr::Authorizer::Token->new( store => make_store($file) );
  my $port = free_port();
  my $knarr = Langertha::Knarr->new(
    handler    => make_handler($file),
    authorizer => $authorizer,
    loop       => $loop,
    listen     => [ "127.0.0.1:$port" ],
  );
  is( [ lines_of($file) ], [], 'not started by the constructor' );
  $knarr->start;
  is( [ lines_of($file) ], [ "start:$$" ], 'started by start(), no request yet' );

  my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
  $loop->add($http);
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions",
    [ 'Content-Type' => 'application/json', Authorization => "Bearer $TOKEN" ],
    $json->encode( { model => 'm', messages => [ { role => 'user', content => 'hi' } ] } ) );
  my $res = $http->do_request( request => $req )->get;
  is( $res->code, 200, 'a token request is served' );
  is( [ lines_of($file) ], [ "start:$$", "req:$$" ], 'the request did not start it again' );

  # An admin push hands the same authorizer over: no second start.
  $knarr->_apply_stack( Test::Stack->new(
    handler => $knarr->handler, authorizer => $authorizer ) );
  is( [ grep { /^start:/ } lines_of($file) ], [ "start:$$" ], 'a push of the same authorizer: still once' );

  # A push that brings another authorizer starts that one in the serving process.
  my $file2 = "$dir/single2.log";
  my $other = Langertha::Knarr::Authorizer::Token->new( store => make_store($file2) );
  $knarr->_apply_stack( Test::Stack->new( handler => $knarr->handler, authorizer => $other ) );
  is( [ lines_of($file2) ], [ "start:$$" ], 'a new authorizer from a push is started' );

  $loop->remove($http);
  $loop->remove($_) for @{ $knarr->_servers };
};

subtest 'a Knarr that is not started does not start its authorizer' => sub {
  my $file = "$dir/psgi.log";
  my $knarr = Langertha::Knarr->new(
    handler    => make_handler($file),
    authorizer => Langertha::Knarr::Authorizer::Token->new( store => make_store($file) ),
  );
  $knarr->_apply_stack( Test::Stack->new(
    handler => $knarr->handler, authorizer => $knarr->authorizer ) );
  is( [ lines_of($file) ], [], 'constructor and push alone start nothing (PSGI never calls start)' );
};

done_testing;
