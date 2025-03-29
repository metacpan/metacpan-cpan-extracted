#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
eval "use Test::Kwalitee qw(kwalitee_ok)";
plan skip_all => "Test::Kwalitee required for testing kwalitee" if $@;

kwalitee_ok( );

done_testing( );
