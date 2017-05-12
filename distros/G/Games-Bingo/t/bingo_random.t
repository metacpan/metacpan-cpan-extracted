#!/usr/bin/perl -w



use strict;
use Test::More tests => 2;

#test 1
use_ok( 'Games::Bingo' );

my $bingo = Games::Bingo->new();

like($bingo->random(90), qr/\d+/);
