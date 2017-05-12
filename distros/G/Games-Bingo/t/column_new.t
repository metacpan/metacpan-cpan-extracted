#!/usr/bin/perl -w



use strict;
use Test::More tests => 5;

#test 1-2
use_ok( 'Games::Bingo::Column' );

my @ary = qw(1 2 3 4 5 6 7 8 9);
my $c = Games::Bingo::Column->new(1, @ary);

#test 3
is(ref $c, 'Games::Bingo::Column', 'Testing constructor with parameter');

#test 4
is($c->count_numbers, 9, 'Testing the initialized array');

#test 5
is($c->{label}, 1);

#test 6
my $c2 = Games::Bingo::Column->new();

is($c2->count_numbers, 0, 'Testing the initialized array');
