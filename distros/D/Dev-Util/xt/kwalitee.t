#!/usr/bin/env perl

use 5.018;
use Test2::V0;
use Test2::Require::AuthorTesting;
use Test::Kwalitee 'kwalitee_ok';

kwalitee_ok(qw(-use_strict -has_meta_yml));

done_testing;
