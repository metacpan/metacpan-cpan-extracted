#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};
}

eval { require ExtUtils::Manifest };
plan skip_all => 'No ExtUtils::Manifest' if $@;
plan skip_all => 'No MANIFEST.SKIP' unless -f 'MANIFEST.SKIP';
plan tests => 2;

my ( $missing, $extra ) = ExtUtils::Manifest::fullcheck();

is_deeply $missing, [], 'missing files';
is_deeply $extra,   [], 'extra files';

# vim: expandtab shiftwidth=4
