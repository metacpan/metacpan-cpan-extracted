#!perl -wT

use strict;
use warnings;
use Test::Carp;
use Test::Most tests => 3;

BEGIN {
	use_ok('File::Open::NoCache::ReadOnly');
}

CARP: {
	does_carp_that_matches(sub { File::Open::NoCache::ReadOnly->new({ filename => '/asdasd.not.there' }) }, qr/^\/asdasd.not.there/);
	does_croak_that_matches(sub { File::Open::NoCache::ReadOnly->new({ filename => '/asdasd.not.there', fatal => 1 }) }, qr/^\/asdasd.not.there/);
}
