#!/usr/bin/env perl
use strict;
use warnings;

use blib;
require Google::Auth;
my $v = $Google::Auth::VERSION;
if (!defined $v || !length $v) {
  die "RELEASE LINT ERROR: VERSION not set in Google::Auth\n";
}

open my $fh, '<', 'Changes'
  or die "RELEASE LINT ERROR: Cannot read Changes: $!\n";
my $has_entry = 0;
while (<$fh>) {
  if (/^\Q$v\E\b/) {
    $has_entry = 1;
    last;
  }
}
close $fh;

if (!$has_entry) {
  die
"RELEASE LINT ERROR: No Changes entry found for version $v in Changes file!\n";
}

print "RELEASE LINT PASS: Version $v verified in Changes.\n";

print "=== Running Author/Release Tests (xt/) ===\n";
local $ENV{AUTHOR_TESTING}  = 1;
local $ENV{RELEASE_TESTING} = 1;
local $ENV{TEST_PERLTIDY}   = 1;

# Run prove on xt/ directory
my $exit_code = system('prove', '-l', 'xt/');

if ($exit_code != 0) {
  die "RELEASE LINT ERROR: Author tests (xt/) failed!\n";
}

print "RELEASE LINT PASS: All checks and tests passed.\n";
exit 0;
