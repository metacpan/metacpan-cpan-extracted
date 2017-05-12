#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
eval 'use Test::Signature';
plan skip_all => 'Test::Signature required for this test' if $@;
signature_ok();
done_testing;
