#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(
	no_plan
	);
use List::oo qw(L);

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);

sub fx {
	return(($_[0] || '') . 'x');
}
sub fy {
	return(($_[0] || '') . 'y');
}
sub that_function {
	my @vals = @_;
	# trivial example of why you *might* need the whole list
	my $vl = length(@vals);
	return(map({$vl . $_} @vals));
}

{
	my @expect = map({fx($_)} @a0);
	my $l = L(@a0)->map(\&fx);
	is_deeply($l, \@expect, 'a0 map');
}
{
	my @expect = map({fx($_)} @a1);
	my $l = L(@a1)->map(\&fx);
	is_deeply($l, \@expect, 'a1 map');
}
{
	my @expect = map({fy($_)} map({fx($_)} @a0));
	my $l = L(@a0)->map(\&fx)->map(\&fy);
	is_deeply($l, \@expect, 'a0 map2');
}
{
	my @expect = map({fy($_)} map({fx($_)} @a1));
	my $l = L(@a1)->map(\&fx)->map(\&fy);
	is_deeply($l, \@expect, 'a1 map2');
}
{
	my @expect = map({fy($_)} that_function(map({fx($_)} @a0)));
	my $l = L(@a0)->map(\&fx)->dice(\&that_function)->map(\&fy);
	is_deeply($l, \@expect, 'a0 map2/dice');
}
{
	my @expect = map({fy($_)} that_function(map({fx($_)} @a1)));
	my $l = L(@a1)->map(\&fx)->dice(\&that_function)->map(\&fy);
	is_deeply($l, \@expect, 'a1 map2/dice');
}
