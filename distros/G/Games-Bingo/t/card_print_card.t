#!/usr/bin/perl -w



use strict;
use Test::More tests => 2;

use_ok( 'Games::Bingo::Card' );

my $card = Games::Bingo::Card->new();
$card->populate();

ok($card->_print_card());
