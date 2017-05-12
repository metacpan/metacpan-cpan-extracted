#!/usr/bin/perl -w



use strict;
use Test::More tests => 12;

#test 1
use_ok( 'Games::Bingo::Column' );

my @numbers;
my $column;

{
	@numbers = qw(1 2 3 4 5 6 7 8 9);
	$column = Games::Bingo::Column->new(1, @numbers);
	
	for(my $i = scalar(@numbers)-1; $i >= 0; $i--) {
		my $j = $i + 1;
		is($column->get_highest_number(1), $numbers[$i], "expecting $j");
	}
}

{
	@numbers = qw(1 2);
	$column = Games::Bingo::Column->new(1, @numbers);
	
	for(my $i = scalar(@numbers)-1; $i >= 0; $i--) {
		my $j = $i + 1;
		is($column->get_highest_number(0), 2, "expecting 2");
	}
}