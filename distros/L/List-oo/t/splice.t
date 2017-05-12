#!/usr/bin/perl

use Test::More qw(
	no_plan
	);

use warnings;
use strict;

use List::oo qw(L);

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);

{
	my @a = @a0;
	my $l = L(@a)->isplice(0,2);
	splice(@a, 0,2);
	is_deeply($l, \@a);
}

{
	my @a = @a0;
	my $l = L(@a)->isplice(0);
	splice(@a, 0);
	is_deeply($l, \@a);
}
{
	my @a = @a0;
	my $l = L(@a)->isplice(0, 3, qw(foo bar baz));
	splice(@a, 0, 3, qw(foo bar baz));
	is_deeply($l, \@a);
}
