#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Pod::Coverage' => '1.08';
use Test::Pod::Coverage;

use Test2::Require::Module 'Pod::Coverage' => '0.18';
use Pod::Coverage;

all_pod_coverage_ok();
