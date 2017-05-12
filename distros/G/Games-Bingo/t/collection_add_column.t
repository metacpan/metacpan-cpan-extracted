#!/usr/bin/perl -w



use strict;
use Test::More tests => 5;

use_ok( 'Games::Bingo::ColumnCollection' );

my $col = Games::Bingo::ColumnCollection->new();

my $c1 = Games::Bingo::Column->new(0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
my $c2 = Games::Bingo::Column->new(1, 11, 12, 13, 14, 15, 16, 17, 18, 19);
my $c3 = Games::Bingo::Column->new(2, 21, 22, 23, 24, 25, 26, 27, 28, 29);

#test 1
$col->add_column($c1);
is(scalar @{$col}, 1, 
	'Testing the contents of the collection after addition, we should have 1 element');

#test 2
$col->add_column($c2);
is(scalar @{$col}, 2, 
	'Testing the contents of the collection after addition, we should have 2 elements');

#test 3
$col->add_column($c3);
is(scalar @{$col}, 3, 
	'Testing the contents of the collection after addition, we should have 3 elements');

#test 4
$col->add_column($c3, 2);
is(scalar @{$col}, 3, 
	'Testing the contents of the collection after addition, we should have 3 elements');