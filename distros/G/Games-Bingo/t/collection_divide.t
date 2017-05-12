#!/usr/local/bin/perl -w



use strict;
use Test::More tests => 4;

use_ok( 'Games::Bingo' );
use_ok( 'Games::Bingo::ColumnCollection' );

my $bingo = Games::Bingo->new();

my @numbers;
$bingo->init(\@numbers, 90);

is(scalar @numbers, 90, 'Testing the initialized numbers array');

my $collection = Games::Bingo::ColumnCollection->new();
$collection->divide(9, @numbers);

is(scalar @{$collection}, 9, 'Testing the number of divided arrays');
