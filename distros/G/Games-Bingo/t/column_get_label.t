#!/usr/bin/perl -w



use strict;
use Test::More tests => 2;

#test 1
use_ok( 'Games::Bingo::Column' );

my @ary = qw(1 2 3 4 5 6 7 8 9);
my $c = Games::Bingo::Column->new(1, @ary);

#test 3
is($c->get_label(), 1);
