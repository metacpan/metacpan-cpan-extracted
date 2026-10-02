#!/usr/bin/env perl
# ABSTRACT: cancel_raider escalates a SIGINT that did not end the raider to SIGTERM, then SIGKILL, after cancel_grace

use strict;
use warnings;
use Test2::V0;
use Time::HiRes qw( time );
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::Hall qw( fake_hall hall_events wait_until );

clear_engine_env();

# A stand-in for bin/raider that logs each signal it gets to FAKE_RELEASE.signals:
#   deaf-int - ignores SIGINT, dies of SIGTERM
#   deaf     - ignores SIGINT and SIGTERM, only SIGKILL ends it
#   *        - dies of SIGINT
# FAKE_RELEASE is touched once the handlers are in place.
my $FAKE = <<'PERL';
use strict;
use warnings;
my $mission = $ARGV[-1];
my $log = $ENV{FAKE_RELEASE}.'.signals';
my $note = sub { open my $fh, '>>', $log or die $!; print $fh $_[0], "\n"; close $fh };
for my $sig (qw( INT TERM )) {
  my $deaf = $mission eq 'deaf' || ( $mission eq 'deaf-int' && $sig eq 'INT' );
  $SIG{$sig} = sub {
    $note->($sig);
    return if $deaf;
    # Perl blocks the signal while its handler runs: it kills once this returns.
    $SIG{$sig} = 'DEFAULT';
    kill $sig, $$;
  };
}
open my $r, '>', $ENV{FAKE_RELEASE} or die $!;
close $r;
sleep 1 for 1 .. 60;
exit 1;
PERL

# Spawns bjorn with $mission on a hall with $yml, cancels it once it is
# ready, turns the loop until it is reaped (or $seconds passed). Returns the
# signals it logged, its raider.done and the seconds from cancel to reap.
sub cancelled {
  my ( $yml, $mission, $seconds ) = @_;
  my ( $hall ) = fake_hall( script => $FAKE, yml => "raiders:\n  bjorn: {}\n".$yml );
  my $events = hall_events($hall);
  my $spawn = $hall->spawn( name => 'bjorn', mission => $mission );
  ok( wait_until( $hall, sub { -e $ENV{FAKE_RELEASE} } ), 'the raider is ready' );
  my $t0 = time;
  is( $hall->cancel_raider( $spawn->{id} ), { cancelled => 1, id => $spawn->{id} }, 'cancel_raider answers' );
  wait_until( $hall, sub { !%{ $hall->raiders } }, $seconds );
  my $took = time - $t0;
  my ($done) = map { $_->[1] } grep { $_->[0] eq 'raider.done' } @$events;
  return ( signals(), $done, $took, $hall );
}

# The signals the fake raider logged so far.
sub signals {
  my $file = $ENV{FAKE_RELEASE}.'.signals';
  return [] unless -e $file;
  open my $fh, '<', $file or die $!;
  return [ map { chomp; $_ } <$fh> ];
}

subtest 'a raider that ignores SIGINT gets SIGTERM after cancel_grace' => sub {
  my ( $signals, $done, $took ) = cancelled( "cancel_grace: 0.5\n", 'deaf-int', 10 );
  is( $signals, [qw( INT TERM )], 'SIGINT, then SIGTERM' );
  like( $done, { signaled => 1 }, 'reaped, dead by the signal' );
  ok( $took >= 0.5, 'not before the grace period ('.sprintf('%.2f', $took).'s)' );
};

subtest 'one that ignores SIGTERM too gets SIGKILL after another cancel_grace' => sub {
  my ( $signals, $done, $took ) = cancelled( "cancel_grace: 0.5\n", 'deaf', 10 );
  is( $signals, [qw( INT TERM )], 'SIGINT, SIGTERM, nothing it could catch after that' );
  like( $done, { signaled => 1, status => 'failed', error => qr/killed by signal 9/ }, 'killed' );
  ok( $took >= 1, 'after two grace periods ('.sprintf('%.2f', $took).'s)' );
};

subtest 'a raider that ends on SIGINT gets nothing more' => sub {
  my ( $signals, $done, $took, $hall ) = cancelled( "cancel_grace: 0.5\n", 'obedient', 10 );
  is( $signals, [ 'INT' ], 'SIGINT only' );
  like( $done, { signaled => 1 }, 'reaped' );
  $hall->loop->loop_once(0.1) for 1 .. 10;   # past the grace period
  is( signals(), [ 'INT' ], 'still SIGINT only' );
};

subtest 'cancel_grace 0 never escalates' => sub {
  my ( $signals, $done, $took, $hall ) = cancelled( "cancel_grace: 0\n", 'deaf-int', 1.5 );
  is( $signals, [ 'INT' ], 'SIGINT only' );
  is( $done, undef, 'the raider still runs' );
  $hall->loop->loop_once(0.1) for 1 .. 10;
  is( signals(), [ 'INT' ], 'and got nothing more' );
};

subtest 'cancel_grace defaults to 5 seconds' => sub {
  my ( $hall ) = fake_hall( script => $FAKE );
  is( $hall->cancel_grace, 5, 'default' );
  ( $hall ) = fake_hall( script => $FAKE, yml => "cancel_grace: 2\n" );
  is( $hall->cancel_grace, 2, 'from .raider-hall.yml' );
};

done_testing;
