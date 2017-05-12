#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan skip_all => 'for authors only -- define $ENV{AUTHOR_TESTING}' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
eval 'use Test::Signature';
plan skip_all => 'Test::Signature required for this test' if $@;
signature_ok();
done_testing;
