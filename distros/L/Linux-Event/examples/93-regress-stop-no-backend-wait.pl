#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event::Loop;

# Manual regression runner for:
#   stop() must prevent entering backend wait when running is cleared during callback dispatch.

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
    die "FAIL: backend wait entered after stop()\n" if !$loop->{running};
    return 0;
  }
}

my $backend = t::MockBackend->new;
my $loop = Linux::Event::Loop->new(
  backend => $backend,
  clock   => t::MockClock->new,
  timer   => t::MockTimer->new,
);

$loop->{running} = 1;
$loop->sched->after_ns(0, sub ($loop) { $loop->stop });

eval { $loop->run_once(10); 1 } or die $@;

print "OK: stop() prevented backend wait; backend run_once calls=$backend->{run_once_calls}\n";
