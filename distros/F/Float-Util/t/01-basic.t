#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Float::Util qw(is_exact);

subtest is_exact => sub {
    ok( is_exact("1"));
    ok( is_exact("1.5"));
    ok(!is_exact("0.1"));
    ok(!is_exact("0.15"));
};

DONE_TESTING:
done_testing;
