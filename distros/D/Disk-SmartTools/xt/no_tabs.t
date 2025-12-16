#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::NoTabs';
use Test::NoTabs;

all_perl_files_ok( grep { -e $_ } qw( bin lib t xt examples Makefile.PL ) );

done_testing;
