#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
use Time::HiRes qw(gettimeofday usleep);

use IO::Tail;

plan tests => 8 + 5;

&test_timeout; # 8.
&test_timeout_remove; # 5.

sub test_timeout
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	my @timeout;
	$tail->add_timeout(sub{
		push(@timeout, scalar gettimeofday());
	}, 1);
	pass('add_timeout(1sec)');
	
	ok($tail->check(), 'check results something exists');
	
	my $st = gettimeofday();
	$tail->loop();
	my $ed = gettimeofday();
	my $elapsed = sprintf('%.2f', $ed-$st);
	cmp_ok($elapsed, '>', '0.9', "return from loop (elapsed:$elapsed>0.9)");
	cmp_ok($elapsed, '<', '1.8', "return from loop (elapsed:$elapsed<1.8)");
	
	is(0+@timeout, 1, "1 timeout was done");
	my $when = sprintf('%.2f', $timeout[0]-$st);
	cmp_ok($when, '>', '0.9', "tiemouted at $when (>0.9)");
	cmp_ok($when, '<', '1.8', "tiemouted at $when (<1.8)");
	
	alarm(0);
}

sub test_timeout_remove
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	my $timeout = sub{
		die "timeout invoked";
	};
	$tail->add_timeout($timeout, 1);
	pass('add_timeout(1sec)');
	
	ok($tail->check(), 'check results something exists');
	
	$tail->remove_timeout($timeout);
	ok(!$tail->check(), 'check results nothing exists');
	
	my $st = gettimeofday();
	$tail->loop();
	my $ed = gettimeofday();
	my $elapsed = sprintf('%.2f', $ed-$st);
	cmp_ok($elapsed, '<', '0.1', 'loop returns immediately');
	
	alarm(0);
}
