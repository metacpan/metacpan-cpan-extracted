#!perl

use strict;
use warnings;
use Test::More 0.98;

use Eval::Util qw(inside_eval);

my $val1 = inside_eval();
my $val2; eval { $val2 = inside_eval() };
my $val3; eval q[$val3 = inside_eval()];

subtest inside_eval => sub {
    ok(!$val1);
    ok( $val2);
    ok( $val3);
};

DONE_TESTING:
done_testing;
