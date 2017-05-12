#!/usr/bin/perl -w



use strict;
use Test::More tests => 4;

#test 1
use_ok( 'Games::Bingo::Column' );

my @ary = qw(1 2 3 4 5 6 7 8 9);
my $c = Games::Bingo::Column->new(undef, @ary);

my $n = $c->get_random_number();

#test 1
like($n, qr/\d+/, 'Testing the random function');

#test 2
is($c->count_numbers(), 9, 'Testing the length of the array');

#test 3 
$n = $c->get_random_number(1);
is($c->count_numbers(), 8, 'Testing the length of the array');

__END__

We are currently not testing the randomness of the method
