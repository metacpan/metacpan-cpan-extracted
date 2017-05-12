#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
use Time::HiRes qw(gettimeofday);

use IO::Tail;

plan tests => 3;

&test_empty; # 3.

sub test_empty
{
	alarm(3);
	
	my $tail = IO::Tail->new();
	isa_ok($tail, 'IO::Tail');
	
	ok(!$tail->check(), 'check results no more items');
	
	my $st = gettimeofday();
	$tail->loop();
	my $ed = gettimeofday();
	cmp_ok($ed-$st, '<', '0.1', 'loop returns immediately');
	
	alarm(0);
}


