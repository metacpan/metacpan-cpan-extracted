#!/usr/bin/env perl

# NOTE: this test expects a $HOME/.perltidyrc file containing:
#   -pbp -nst -nse

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::PerlTidy';
use Test::PerlTidy;

run_tests();
