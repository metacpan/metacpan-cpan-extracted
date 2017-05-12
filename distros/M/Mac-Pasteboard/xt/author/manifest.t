package main;

use strict;
use warnings;

use Test;

BEGIN {
    eval {
	require ExtUtils::Manifest;
	ExtUtils::Manifest->import (qw{manicheck filecheck});
	1;
    } or do {
	print "1..0 # skip ExtUtils::Manifest required to check manifest.\n";
	exit;
    };
}

plan tests => 2;
my $test = 0;

foreach ([manicheck => 'Missing files per manifest'],
    [filecheck => 'Files not in MANIFEST or MANIFEST.SKIP'],
) {
    my ($subr, $title) = @$_;
    $test++;
    my @got = ExtUtils::Manifest->$subr ();
    print <<eod;
#
# Test $test - $title
#      Expected: ''
#           Got: '@got'
eod
    ok (@got == 0);
}

1;
