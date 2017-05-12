#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
use Time::HiRes qw(gettimeofday usleep);

use IO::Tail;

plan tests => 5 + 7;

&test_interval_remove; # 5.
&test_interval; # 7.

sub test_interval_remove
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	my $interval = sub{
		die "interval invoked";
	};
	$tail->add_interval($interval, 1);
	pass('add_interval(1sec)');
	
	ok($tail->check(), 'check results something exists');
	
	$tail->remove_interval($interval);
	ok(!$tail->check(), 'check results nothing exists');
	
	my $st = gettimeofday();
	$tail->loop();
	my $ed = gettimeofday();
	my $elapsed = sprintf('%.2f', $ed-$st);
	cmp_ok($elapsed, '<', '0.1', 'loop returns immediately');
	
	alarm(0);
}

sub test_interval
{
	alarm(10);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	my @interval;
	my $sub = sub{
		push(@interval, scalar gettimeofday());
		pass("iter ".@interval);
		@interval==3 and $tail->remove(my$item=$_[3]);
	};
	$tail->add_interval($sub, 1);
	pass('add_interval(1sec)');
	
	ok($tail->check(), 'check results something exists');
	
	my $st = gettimeofday();
	$tail->loop();
	my $ed = gettimeofday();
	my $elapsed = sprintf('%.2f', $ed-$st);
	
	is(0+@interval, 3, "3 timeout was done");
	
	alarm(0);
}

