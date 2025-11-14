#!/usr/bin/env perl

use 5.018;
use Test2::V0;
use Test2::Require::AuthorTesting;

use Test2::Require::Module 'Test::Pod' => '1.22';
use Test::Pod 1.22;

all_pod_files_ok();
