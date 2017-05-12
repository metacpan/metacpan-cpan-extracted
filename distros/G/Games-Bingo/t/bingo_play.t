#!/usr/bin/perl -w



use strict;
use Test::More tests => 21;

#test 1
use_ok( 'Games::Bingo' );

my $bingo;

$bingo = Games::Bingo->new(10);

for (my $i = 10; $i > 0; $i--) {
	ok($bingo->play());
}

$bingo = Games::Bingo->new();

for (my $i = 10; $i > 0; $i--) {
	ok($bingo->play([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
}
