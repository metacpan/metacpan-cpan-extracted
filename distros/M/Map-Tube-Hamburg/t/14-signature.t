#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

eval 'use Test::Signature';
plan skip_all => 'Test::Signature required for this test' if $@;
signature_ok( );

done_testing( );
