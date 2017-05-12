#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(:hireswallclock cmpthese);

use IO::Async::Loop;
use IO::AsyncX::SharedTimer;

use constant CALLS_PER_LOOP => 100;
use constant RESOLUTION => 0.001;
use constant LOOP_WAIT => 0.001;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $timer = IO::AsyncX::SharedTimer->new(
		resolution => RESOLUTION,
	)
);

cmpthese -5, {
	now_coalesced => sub {
		my $x;
		$x = $timer->now for 1..CALLS_PER_LOOP;
		$loop->loop_once(LOOP_WAIT);
	},
	now_normal => sub {
		my $x;
		$x = $loop->time for 1..CALLS_PER_LOOP;
		$loop->loop_once(LOOP_WAIT);
	},
	now_hires => sub {
		my $x;
		$x = Time::HiRes::time for 1..CALLS_PER_LOOP;
		$loop->loop_once(LOOP_WAIT);
	},
};

