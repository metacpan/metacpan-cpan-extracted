#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Kwalitee';
use Test::Kwalitee 'kwalitee_ok';

kwalitee_ok(qw(-use_strict -has_meta_yml));

done_testing;
