#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
# written with Gemini's help
# --- Dependency Check 1: Python 3 ---

my $python_version_raw = qx/python3 --version 2>&1/;
my $python_version = '';
my $python_available = 0;

if ($? == 0 && $python_version_raw =~ m/Python\s+3\.\d+/i) {
    # Command succeeded and output looks like a Python 3 version string
    $python_available = 1;
    # Capture the version number
    $python_version = (split(/\s+/, $python_version_raw))[1] // 'Unknown 3.x';
}

unless ($python_available) {
    # plan skip_all is the core module way to gracefully skip the entire file
    plan skip_all => 'SKIP: python3 command not found in PATH or is not Python 3. Matplotlib::Simple requires Python 3.';
}

# --- Dependency Check 2: Matplotlib ---

# Command to import matplotlib and print its version.
my $mpl_command = 'python3 -c "import matplotlib; print(matplotlib.__version__)" 2>&1';
my ($mpl_major, $mpl_minor, $mpl_patch);
my $mpl_version_raw = qx/$mpl_command/;
my $mpl_available = 0;
my $mpl_version = '';

# Check the exit code ($?) and ensure the output looks like a semantic version number
if ($? == 0 && $mpl_version_raw =~ m/^\s*\d+\.\d+\.\d+(\.\d+)?\s*$/) {
    $mpl_available = 1;
    $mpl_version = $mpl_version_raw;
    # Clean up any potential whitespace
    $mpl_version =~ s/^\s*|\s*$//g;
}
if ($mpl_version =~ m/^(\d+)\.(\d+)\.(\d+)/) {
	($mpl_major, $mpl_minor, $mpl_patch) = ($1, $2, $3);
}

my $mpl_version_correct = 0;

unless ($mpl_available) {
    plan skip_all => 'SKIP: Matplotlib Python package not found or import failed. Please install it with "pip install matplotlib" or "python -m pip install matplotlib" or something similar.';
}
my $mpl_version_err_msg = "matplotlib major version = $mpl_major; matplotlib minor version = $mpl_minor; minimum is 3.10;\nFix is something like this: \"python -m pip install --upgrade matplotlib\"";
if (($mpl_major == 3) && ($mpl_minor < 10)) {
	plan skip_all => $mpl_version_err_msg;
} elsif ($mpl_major < 3) {
	plan skip_all => $mpl_version_err_msg;
} elsif (($mpl_major == 3) && ($mpl_minor >= 10)) {
	$mpl_version_correct = 1;
} else {
	$mpl_version_correct = 1;
}

# ----------------------------------------------------
# --- If we reach this point, all dependencies are met ---

# Use Test::More's 'diag' to print the version numbers to the test harness output
# This is equivalent to Test2's 'note' and works with core modules.
diag('Dependencies Found:');
diag("  Python 3 Version: $python_version");
diag("  Matplotlib Version: $mpl_version");
# Now we declare the total number of tests and proceed.
plan tests => 3;

# --- Actual Tests Start Here ---

# Test 1: Confirm Python check passed
ok($python_available, 'Verified: "python3" is available and functional');

# Test 2: Confirm Matplotlib check passed
ok($mpl_available, 'Verified: "matplotlib" is importable under python3');

# Add your Matplotlib::Simple functional tests here.
ok($mpl_version_correct, 'Verified, "matplotlib" version is >= 3.10');
