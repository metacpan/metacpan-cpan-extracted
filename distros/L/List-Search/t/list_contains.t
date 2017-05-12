use strict;
use warnings;

use Test::More 'no_plan';

use List::Search qw( list_contains nlist_contains );

my @numbers = 0 .. 10;
my @floats  = map { $_ / 10 } @numbers;
my @words   = qw( alpha bravo charlie delta foxtrot );

foreach my $word (@words) {
    ok list_contains( $word, \@words ), "found $word";
    ok !list_contains( "$word BANG", \@words ), "not found '$word BANG'";
}

foreach my $number (@numbers) {
    ok nlist_contains( $number, \@numbers ), "found $number";
    ok !nlist_contains( $number + 0.5, \@numbers ), "not found '$number + 0.5'";
}

