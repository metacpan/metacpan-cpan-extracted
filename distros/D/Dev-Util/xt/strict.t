#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Strict';
use Test::Strict;

unshift @Test::Strict::MODULES_ENABLING_STRICT,
    'Dev::Util::Syntax',
    'Test2::V0',
    'Test2::Bundle::SIPS',
    'Test2::Bundle::Extended';

note "enabling strict = $_" for @Test::Strict::MODULES_ENABLING_STRICT;

all_perl_files_ok( grep { -e $_ } qw( bin lib t xt examples Makefile.PL ) );

done_testing;
