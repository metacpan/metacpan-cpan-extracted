#!/usr/bin/perl -w



use strict;
use Test::More tests => 4;

use_ok( 'Games::Bingo::ColumnCollection' );

my $c1 = Games::Bingo::Column->new(0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
my $c2 = Games::Bingo::Column->new(1, 11, 12, 13, 14, 15, 16, 17, 18, 19);
my $c3 = Games::Bingo::Column->new(2, 21, 22, 23, 24, 25, 26, 27, 28, 29);

my $col = Games::Bingo::ColumnCollection->new($c1, $c2, $c3);

#test 1
is(scalar @{$col}, 3);

#test 2
ok($col->get_random_column(1));

#test 3
is(scalar @{$col}, 2);
