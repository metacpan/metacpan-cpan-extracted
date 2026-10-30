#!/usr/bin/env perl
# ABSTRACT: The hall's permission channel: raider-side client and hall-side server; every failure is "no" (ADR 0021 Nachtrag P2, k158)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use IO::Socket::UNIX;
use JSON::MaybeXS;
use POSIX qw( WNOHANG );
use Path::Tiny;
use Langertha::Raider::PermissionChannel;
use Langertha::Raider::Hall::PermissionChannel;

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

# Runs $code in a child process (the client blocks) while the loop serves;
# returns what the child printed, decoded.
sub in_child {
  my ( $code ) = @_;
  pipe( my $r, my $w ) or die $!;
  my $pid = fork // die $!;
  if ( !$pid ) {
    close $r;
    my @out = eval { $code->() };
    print {$w} $JSON->encode( [ @out ] );
    close $w;
    POSIX::_exit(0);
  }
  close $w;
  my $deadline = time + 30;
  my $reaped;
  until ( $reaped ) {
    $loop->loop_once(0.05);
    $reaped = waitpid( $pid, WNOHANG ) == $pid;
    last if time > $deadline;
  }
  local $/;
  my $text = <$r>;
  return @{ $JSON->decode( $text // '[]' ) };
}

sub server {
  my ( %arg ) = @_;
  my $s = Langertha::Raider::Hall::PermissionChannel->new( loop => $loop, timeout => 5, %arg );
  $s->start;
  return $s;
}

my $q = { tool => 'write_file', source => 'raider', arguments => { path => 'a.txt' }, reason => 'asks', rule => 'Edit(/**)' };

subtest 'answers and the question that arrives' => sub {
  my @seen;
  my @answers = ( { answer => 'once' }, { answer => 'session' }, { answer => 'no', reason => 'not now' } );
  my $s = server( handler => sub { push @seen, $_[0]; Future->done( shift @answers ) } );
  ok -S $s->path, 'a socket';
  my ( $got ) = in_child( sub {
    my $c = Langertha::Raider::PermissionChannel->new( path => $s->path );
    return [ map { $c->request($q) } 1 .. 3 ];
  } );
  is $got, [ { answer => 'once' }, { answer => 'session' }, { answer => 'no', reason => 'not now' } ], 'three answers over one connection';
  like \@seen, [ { id => 1, tool => 'write_file', source => 'raider', arguments => { path => 'a.txt' }, reason => 'asks', rule => 'Edit(/**)' }, { id => 2 }, { id => 3 } ],
    'the hall saw the questions';
  my $dir = path( $s->path )->parent;
  is( ( stat "$dir" )[2] & 0777, 0700, 'the directory is private' );
  $s->close;
  ok !$dir->exists, 'close removes the socket directory';
};

subtest 'the hall side says no' => sub {
  my %case = (
    dies      => sub { die "boom\n" },
    fails     => sub { Future->fail('nope') },
    garbage   => sub { Future->done({ answer => 'yes' }) },
    undefined => sub { Future->done(undef) },
    not_future => sub { 'once' },
  );
  for my $name ( sort keys %case ) {
    my $s = server( handler => $case{$name} );
    my ( $got ) = in_child( sub { Langertha::Raider::PermissionChannel->new( path => $s->path )->request($q) } );
    is $got->{answer}, 'no', "$name: no";
    $s->close;
  }
  my $s = server( handler => sub { Future->new }, timeout => 0.5 );
  my ( $got ) = in_child( sub { Langertha::Raider::PermissionChannel->new( path => $s->path )->request($q) } );
  is $got->{answer}, 'no', 'no answer within the timeout: no';
  like $got->{reason}, qr/within 0\.5 seconds/, '... and why';
  $s->close;
};

subtest 'the raider side says no' => sub {
  my ( $got ) = in_child( sub { Langertha::Raider::PermissionChannel->new( path => '/nonexistent/p.sock' )->request($q) } );
  is $got->{answer}, 'no', 'unreachable socket: no';

  my $s = server( handler => sub { Future->new }, timeout => 30 );
  ( $got ) = in_child( sub { Langertha::Raider::PermissionChannel->new( path => $s->path, timeout => 1 )->request($q) } );
  is $got->{answer}, 'no', 'the raider stops waiting by itself';
  like $got->{reason}, qr/no answer within 1 seconds/, '... and why';

  ( $got ) = in_child( sub {
    my $n = 0;
    Langertha::Raider::PermissionChannel->new( path => $s->path, cancelled => sub { ++$n > 2 } )->request($q);
  } );
  is $got->{answer}, 'no', 'a cancelled run stops waiting';
  like $got->{reason}, qr/cancelled/, '... and why';

  my $closer = server( handler => sub { Future->new }, timeout => 30 );
  my $timer = $loop->delay_future( after => 0.5 )->on_done( sub { $closer->close } );
  ( $got ) = in_child( sub { Langertha::Raider::PermissionChannel->new( path => $closer->path )->request($q) } );
  is $got->{answer}, 'no', 'the hall closing the channel mid-question: no';
  $s->close;
};

done_testing;
