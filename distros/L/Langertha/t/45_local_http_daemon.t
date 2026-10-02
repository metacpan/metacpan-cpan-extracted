#!/usr/bin/env perl
# ABSTRACT: the forked test HTTP daemon never leaks a process, never lets a dying handler escape, and reaps what it kills
use strict; use warnings;
use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
}

use File::Spec;
use File::Temp ();
use IO::Socket::INET;
use HTTP::Response;
use POSIX ();
use Test::LocalHTTPDaemon;

# Test::LocalHTTPDaemon backs the transport tests (t/45_*). They run under
# prove -j4, so the helper has to be deterministic and leak nothing (karr k203,
# from the k199 review): a handler that dies must end the forked process that
# ran it instead of unwinding out of start() and running the rest of the test
# script as a clone; a keep-alive connection child must not hold the listening
# socket; and tearing the daemon down must reap the connection children it
# kills, so none outlives the server object (an init-less container would
# collect them as zombies).

my $parent = $$;
my $escape = File::Temp->new;

# Whatever runs past start() in a forked copy lands here: it records itself and
# leaves without touching the parent's TAP stream.
sub start_daemon {
  my ( $handler, %opts ) = @_;
  # The eval catches a die unwinding out of start() in a forked copy.
  my $server = eval { Test::LocalHTTPDaemon->start( $handler, %opts ) };
  if ( $$ != $parent ) {
    if ( open my $fh, '>>', $escape->filename ) { print {$fh} "escaped $$\n"; close $fh }
    POSIX::_exit(0);
  }
  die $@ unless $server;
  return $server;
}

sub escaped {
  open my $fh, '<', $escape->filename or return '';
  local $/;
  return scalar <$fh>;
}

# A raw HTTP/1.1 client that keeps its connection open after the response.
sub open_request {
  my ($server) = @_;
  my ($port) = $server->url =~ /:(\d+)\z/;
  my $sock = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => $port, Timeout => 5 )
    or die "connect: $!";
  print {$sock} "GET / HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n";
  return ( $sock, $port );
}

sub read_response {
  my ($sock) = @_;
  my $buf = '';
  while ( $buf !~ /\r\n\r\n/ ) {
    my $n = sysread $sock, $buf, 4096, length $buf;
    last unless $n;
  }
  return $buf;
}

sub gone { my ($pid) = @_; return !kill 0, $pid }

sub quiet_stderr {
  my ($code) = @_;
  open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
  open STDERR, '>', File::Spec->devnull or die "reopen STDERR: $!";
  my @ret = eval { $code->() };
  my $err = $@;
  open STDERR, '>&', $saved or die "restore STDERR: $!";
  die $err if $err;
  return @ret;
}

for my $mode ( [ default => () ], [ 'keep-alive' => ( keep_alive => 1 ) ] ) {
  my ( $name, %opts ) = @$mode;
  subtest "a handler that dies ends its process ($name mode)" => sub {
    my ($server) = quiet_stderr( sub { start_daemon( sub { die "handler boom\n" }, %opts ) } );
    my ($sock) = open_request($server);
    my $answer = read_response($sock);
    close $sock;
    is( $answer, '', 'the client got no response, just the hang-up' );
    undef $server;
    is( escaped(), '', 'no forked copy ran on past start()' );
  };
}

subtest 'a keep-alive connection child does not hold the listening socket' => sub {
  my $server = start_daemon( sub {
    HTTP::Response->new( 200, 'OK', [ 'X-Pid' => $$, 'Content-Length' => 2 ], 'ok' );
  }, keep_alive => 1 );
  my ( $sock, $port ) = open_request($server);
  my ($child) = read_response($sock) =~ /^X-Pid: (\d+)/mi;
  ok( $child, 'the connection is served by its own child' );

  # Take the daemon away while the connection child still lives: with nobody
  # else holding the listening socket, the port is closed.
  kill 'KILL', $server->{pid};
  waitpid $server->{pid}, 0;
  my $probe = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => $port, Timeout => 2 );
  ok( !$probe, 'the port stops accepting once the daemon is gone' );

  close $sock;
  kill 'KILL', $child;
  delete $server->{pid};
};

subtest 'teardown reaps the keep-alive connection children it kills' => sub {
  my $server = start_daemon( sub {
    HTTP::Response->new( 200, 'OK', [ 'X-Pid' => $$, 'Content-Length' => 2 ], 'ok' );
  }, keep_alive => 1 );
  my @held;
  for ( 1 .. 3 ) {
    my ($sock) = open_request($server);
    my ($child) = read_response($sock) =~ /^X-Pid: (\d+)/mi;
    push @held, [ $sock, $child ];
  }
  is( scalar( grep { $_->[1] } @held ), 3, 'three connection children hold their connections open' );

  undef $server;
  ok( gone( $_->[1] ), "connection child $_->[1] is gone (not even a zombie) once the server object is" )
    for @held;
  close $_->[0] for @held;
};

done_testing;
