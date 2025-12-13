#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Pod::Spelling::CommonMistakes' => '1.001';
use Test::Pod::Spelling::CommonMistakes;

all_pod_files_ok();

done_testing;
