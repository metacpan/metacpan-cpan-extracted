#!/usr/local/bin/perl -w



use strict;
use Test::More tests => 17;

use_ok( 'Games::Bingo::Card' );

my $card = Games::Bingo::Card->new();
my $fcc = $card->_init();

#test 1
is(scalar @{$fcc}, 9, 'Number of Columns');

#test 2-6
my $t = 9;

for (1..9) {
	my $c = $fcc->get_column(--$t);
	isa_ok($c, 'Games::Bingo::Column', 'Testing column');
}

#test 7
is($t, 0, 'Testing the number of numbers generated');

my $c1 = Games::Bingo::Column->new(0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
my $c2 = Games::Bingo::Column->new(1, 11, 12, 13, 14, 15, 16, 17, 18, 19);
my $c3 = Games::Bingo::Column->new(2, 21, 22, 23, 24, 25, 26, 27, 28, 29);

my $col = Games::Bingo::ColumnCollection->new($c1, $c2, $c3);

is($col->get_column(), undef);

is($col->get_column(-1), undef);

ok($col->get_column(1));

is($col->get_column(4), undef);

ok($col->get_column(1));
