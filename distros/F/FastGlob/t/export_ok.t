#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# Test that all documented @EXPORT_OK symbols are importable.
# The platform configuration variables (dirsep, rootpat, curdir,
# parentdir, hidedotfiles) should be available for import so that
# Windows/MacOS users can customize path behavior.

my @expected_exports = qw(dirsep rootpat curdir parentdir hidedotfiles);

for my $sym (@expected_exports) {
    my $ok = eval "package TestPkg_$sym; require FastGlob; FastGlob->import('$sym'); 1";
    ok($ok, "can import '$sym' via EXPORT_OK")
        or diag "Failed to import '$sym': $@";
}

# Verify defaults are accessible
require FastGlob;
is($FastGlob::parentdir, '..', 'parentdir defaults to ".."');
my $expected_dirsep = ( $^O eq 'MSWin32' ) ? '\\' : '/';
is($FastGlob::dirsep, $expected_dirsep, "dirsep defaults to '$expected_dirsep'");

done_testing;
