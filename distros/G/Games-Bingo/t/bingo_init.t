#!/usr/bin/perl -w



use strict;
use Test::More tests => 3;

#test 1
use_ok( 'Games::Bingo' );

my $bingo = Games::Bingo->new();

#test 2
my @numbers;
ok($bingo->init(\@numbers, 10));

#test 3
is(scalar @numbers, 10);
