#!/usr/bin/env perl

use t::setup;

my @Overloads = qw(
    ""  0+
    ==  !=
    eq  ne
);

use_ok my $Class = __TEST_PACKAGE__;

sub overload_tests {
    for my $op (@Overloads) {
        ok $Class->can("($op"), "$Class has an overloaded $op operator";
    }

}


run_tests();

