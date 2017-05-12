#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
use Time::HiRes qw(gettimeofday usleep);

use IO::Tail;

plan tests => 5;

&test_loop_timeout; # 5.

sub test_loop_timeout
{
	alarm(5);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	ok(pipe(my $rd, my $wr), 'pipe(2)');
	
	$tail->add($rd, sub{ die "not reach here" });
	pass('add($rd)');
	
	ok($tail->check(), 'check results something exists');
	
	my $st = gettimeofday();
	$tail->loop(2);
	my $ed = gettimeofday();
	cmp_ok($ed-$st, '>', '1', 'loop can timeout');
	
	alarm(0);
}
