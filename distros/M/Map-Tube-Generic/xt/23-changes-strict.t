#!perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Map::Tube::Generic;

plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

eval 'use Test::Changes::Strict::Simple -version_re => qr/\d+\.\d+(?:\.\d+)?/, -check_dots => 0';
plan skip_all => 'Test::Changes::Strict::Simple required for this test' if $@;
plan skip_all => 'Capitalisation issue of Test::Changes::Strict::Simple <= 0.06' if $Test::Changes::Strict::Simple::VERSION le '0.06';
plan tests => 1;

changes_strict_ok( module_version => $Map::Tube::Generic::VERSION, release_today => 1, );
