#!/usr/bin/perl -w



use strict;
use Test::More tests => 10;

#test 1
use_ok( 'Games::Bingo::Column' );

my @ary = qw(1 2 3 4 5 6 7 8 9);
my $c = Games::Bingo::Column->new(1, @ary);

while(scalar @{$c->{_array}}) {
	my $n = $c->get_highest_number(1);
	is($n, (pop(@ary)), 'Testing whether we have been sorted'); 
}
