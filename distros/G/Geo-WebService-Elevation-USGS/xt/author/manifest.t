package main;

use strict;
use warnings;

use Test;

eval {
    require ExtUtils::Manifest;
    ExtUtils::Manifest->import (qw{manicheck filecheck});
};
my $skip = $@ ? 'Can not load ExtUtils::Manifest' : '';

plan tests => 2;
my $test = 0;

foreach ([manicheck => 'Missing files per manifest'],
    [filecheck => 'Files not in MANIFEST or MANIFEST.SKIP'],
) {
    my ($subr, $title) = @$_;
    $test++;
    my @got = $skip ? ('skipped') : ExtUtils::Manifest->$subr ();
    print <<eod;
#
# Test $test - $title
#      Expected: ''
#           Got: '@got'
eod
    skip ($skip, @got == 0);
}

1;
