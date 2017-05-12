#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(:hireswallclock cmpthese);

# Make sure we use a sensible priority-queue implementation for timers
use Heap;
use IO::Async::Loop;
use IO::AsyncX::SharedTimer;

use constant CALLS_PER_LOOP => 100;
use constant RESOLUTION => 0.001;
use constant LOOP_WAIT => 0;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $timer = IO::AsyncX::SharedTimer->new(
		resolution => RESOLUTION,
	)
);

# We want consistent results between runs, I think?
srand 1234;

my @times = map rand, 1..100;
cmpthese -5, {
	normal => sub {
		my $f = Future->needs_all(
			$loop->delay_future(after => 1),
			map $loop->delay_future(after => $_ / 10), @times
		)
	},
	shared => sub {
		my $f = Future->needs_all(
			$loop->delay_future(after => 1),
			map $timer->delay_future(after => $_ / 10), @times
		)
	},
};

