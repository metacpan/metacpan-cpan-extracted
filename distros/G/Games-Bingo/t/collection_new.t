#!/usr/bin/perl -w



use strict;
use Test::More tests => 4;

#tests 1-2
use_ok( 'Games::Bingo::ColumnCollection' );

#test 3
my $col = Games::Bingo::ColumnCollection->new();
like($col, qr/Games::Bingo::ColumnCollection/, 'Testing the constructor');

my $c1 = Games::Bingo::Column->new(0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
my $c2 = Games::Bingo::Column->new(1, 11, 12, 13, 14, 15, 16, 17, 18, 19);
my $c3 = Games::Bingo::Column->new(2, 21, 22, 23, 24, 25, 26, 27, 28, 29);

my $col2 = Games::Bingo::ColumnCollection->new($c1, $c2, $c3);
like($col2, qr/Games::Bingo::ColumnCollection/, 'Testing the constructor');

is(scalar @{$col2}, 3);
