#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event::Loop;

# Regression: stop() must prevent entering backend wait when running is cleared
# during callback dispatch in the same iteration.
#
# This test uses only the public loop API. In the new selector-based structure,
# poking $loop->{running} directly is no longer reliable.

{
  package t::MockClock;
  sub new { bless { now => 0 }, shift }
  sub tick { return }
  sub now_ns { return 0 }
  sub deadline_in_ns ($self, $delta) { return int($delta) }
  sub remaining_ns ($self, $deadline) { return int($deadline) }
}

{
  package t::MockTimer;
  sub new {
    my ($class) = @_;
    pipe(my $r, my $w) or die "pipe: $!";
    return bless { fh => $r }, $class;
  }
  sub fh { return $_[0]{fh} }
  sub after { return 1 }
  sub disarm { return 1 }
  sub read_ticks { return 0 }
}

{
  package t::MockBackend;
  sub new { bless { run_once_calls => 0, watched => 0 }, shift }
  sub watch   { $_[0]{watched}++; return 1 }
  sub unwatch { return 1 }
  sub run_once ($self, $loop, $timeout_s = undef) {
    $self->{run_once_calls}++;
    die "backend wait entered after stop()";
  }
  sub run_once_calls { return $_[0]{run_once_calls} }
}

my $backend = t::MockBackend->new;
my $loop = Linux::Event::Loop->new(
  model   => 'reactor',
  backend => $backend,
  clock   => t::MockClock->new,
  timer   => t::MockTimer->new,
);

my $fired = 0;

# Schedule an immediate timer that stops the loop before any backend wait.
$loop->after(0, sub ($loop) {
  $fired++;
  $loop->stop;
});

ok(eval { $loop->run; 1 }, 'run does not enter backend wait after stop() in due callback')
or diag($@);

is($fired, 1, 'immediate timer callback fired');
is($backend->run_once_calls, 0, 'backend run_once was not called');

done_testing;
