#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Pod' => '1.22';
use Test::Pod 1.22;

all_pod_files_ok();
