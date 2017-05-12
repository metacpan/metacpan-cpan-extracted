#!/usr/bin/perl -w



use strict;
use Test::More tests => 3;

#test 1
use_ok( 'Games::Bingo' );

my $bingo = Games::Bingo->new();

my $number = $bingo->play();
ok($bingo->pull($number));

my @pulled = $bingo->_all_pulled();
is(scalar @pulled, 1); 