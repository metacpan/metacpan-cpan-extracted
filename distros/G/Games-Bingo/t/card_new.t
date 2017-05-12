#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

#test 1
use_ok( 'Games::Bingo::Card' );

#test 2-3
ok(my $card = Games::Bingo::Card->new());
isa_ok($card, 'Games::Bingo::Card', 'Testing the object');