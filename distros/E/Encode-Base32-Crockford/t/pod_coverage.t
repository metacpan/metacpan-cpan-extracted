#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 1;

SKIP: {
		eval "use Test::Pod::Coverage";
		skip "Test::Pod::Coverage required for testing POD coverage", 1 if $@;

		pod_coverage_ok( 'Encode::Base32::Crockford', 'POD coverage' );
}

