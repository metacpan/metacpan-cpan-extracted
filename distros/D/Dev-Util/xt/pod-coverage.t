#!/usr/bin/env perl

use 5.018;
use Test2::V0;
use Test2::Require::AuthorTesting;

use Test2::Require::Module 'Test::Pod::Coverage' => '1.08';
use Test::Pod::Coverage 1.08;

use Test2::Require::Module 'Pod::Coverage' => '0.18';
use Pod::Coverage 0.18;

all_pod_coverage_ok();
