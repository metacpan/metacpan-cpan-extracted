#!/usr/local/bin/perl -w



use strict;
use Test::More tests => 3;

use_ok( 'Games::Bingo::Card' );

#test 1
my $card = Games::Bingo::Card->new();
ok($card->populate());

#test 2
is($card->_integrity_check(), 1, 'Testing our card integrity');
