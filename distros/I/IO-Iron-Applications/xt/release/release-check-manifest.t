#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

if ( not $ENV{RELEASE_TESTING} ) {
	my $msg = 'Author test. Set $ENV{RELEASE_TESTING} to a true value to run.';
	plan( skip_all => $msg );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
