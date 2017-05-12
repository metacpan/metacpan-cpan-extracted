#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Map::Tube::Plugin::FuzzyFind;
use Test::More;
plan skip_all => 'for authors only -- define $ENV{AUTHOR_TESTING}' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
eval 'use Test::CPAN::Changes';
plan skip_all => 'Test::CPAN::Changes required for this test' if $@;
plan tests => 6;
changes_file_ok( undef, { version => $Map::Tube::Plugin::FuzzyFind::VERSION } );
