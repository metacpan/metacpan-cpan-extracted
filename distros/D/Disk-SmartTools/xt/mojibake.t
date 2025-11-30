#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Mojibake';
use Test::Mojibake;

all_files_encoding_ok();
