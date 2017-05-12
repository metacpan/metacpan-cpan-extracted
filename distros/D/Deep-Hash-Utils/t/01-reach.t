#!perl

use strict;
use warnings;
use Test::More 0.88 tests => 1;

use Deep::Hash::Utils qw/ reach /;

my %hash = (
    A => {
        F => 'pineapple',
        D => 'orange',
    },
    B => {
        E => 'banana',
        C => 'apple',
    },
);

my @results;
my $expected = <<'END_EXPECTED';
A:D:orange
A:F:pineapple
B:C:apple
B:E:banana
END_EXPECTED

while (my @list = reach(\%hash)) {
    push(@results, join(':', @list));
}

my $result_string = join("\n", sort @results)."\n";
is($result_string, $expected, "do we get all the tuples expected");
