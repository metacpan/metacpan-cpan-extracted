package main;

use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    eval {
	require ExtUtils::Manifest;
	ExtUtils::Manifest->import( qw{ manicheck filecheck } );
	1;
    } or do {
	plan skip_all => "ExtUtils::Manifest required";
	exit;
    };
}

is join( ' ', manicheck() ), '', 'Missing files per manifest';
is join( ' ', filecheck() ), '', 'Files not in MANIFEST or MANIFEST.SKIP';

done_testing;

1;
