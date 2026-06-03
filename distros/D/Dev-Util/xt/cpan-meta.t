#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::CPAN::Meta::YAML';
use Test::CPAN::Meta::YAML;

meta_yaml_ok();

done_testing;
