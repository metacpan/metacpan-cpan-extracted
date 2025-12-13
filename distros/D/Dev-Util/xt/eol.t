#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::EOL';
use Test::EOL;

all_perl_files_ok( grep { -e $_ } qw( bin lib t examples Makefile.PL ) );

done_testing;
