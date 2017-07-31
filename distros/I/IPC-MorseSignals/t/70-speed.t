#!perl -T

use strict;
use warnings;

use utf8;

my $n;
use Test::More tests => 1 + ($n = 5);

use lib 't/lib';
use IPC::MorseSignals::TestSuite qw<bench init cleanup>;

*IPC::MorseSignals::TestSuite::diag = *Test::More::diag;

my @res;

init 2 * $n;

TODO: {
 local $TODO = 'This is just to give you a measure of which speed you should use';
 ok(bench(2 ** ($n - $_),  2 ** $_, \@res)) for 0 .. $n;
}

cleanup;

diag '=== Summary ===';
diag $_ for sort {
 my ($l1, $n1) = $a =~ /(\d+)\D+(\d+)/;
 my ($l2, $n2) = $b =~ /(\d+)\D+(\d+)/;
 $l1 <=> $l2 || $n1 <=> $n2
} @res;
