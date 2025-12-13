#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Version' => '2.09';
use Test::Version;
use Test2::Require::Module 'YAML' => '1.30';
use YAML qw( LoadFile );

version_all_ok();

done_testing;

