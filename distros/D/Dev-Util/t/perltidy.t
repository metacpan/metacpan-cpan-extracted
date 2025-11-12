#!/usr/bin/env perl

# NOTE: this test expects a $HOME/.perltidyrc file containing:
#   -pbp -nst -nse

use Test2::V0;
use lib 'lib';

use Dev::Util::Syntax;

eval {
    require Test::PerlTidy;
    import Test::PerlTidy;
    1;
} or do {
    plan( skip_all => 'Test::PerlTidy required to check code' );
};

run_tests();
