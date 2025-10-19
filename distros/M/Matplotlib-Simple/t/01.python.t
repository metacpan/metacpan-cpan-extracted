#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;

# --- Dependency Check 1: Python 3 ---

my $python_version_raw = qx/python3 --version 2>&1/;
my $python_version = '';
my $python_available = 0;

if ($? == 0 && $python_version_raw =~ m/Python\s+3\.\d+/i) {
    # Command succeeded and output looks like a Python 3 version string
    $python_available = 1;
    $python_version = (split(/\s+/, $python_version_raw))[1] // 'Unknown 3.x';
}

unless ($python_available) {
    # Use plan skip_all to exit gracefully if the first dependency is missing
    plan skip_all => 'SKIP: python3 command not found in PATH or is not Python 3. Matplotlib::Simple requires Python 3.';
}
# --- Dependency Check 2: Matplotlib ---

# Command to import matplotlib and print its version.
# 2>&1 redirects any errors (like "No module named...") to stdout for capture.
my $mpl_command = 'python3 -c "import matplotlib; print(matplotlib.__version__)" 2>&1';
my $mpl_version_raw = qx/$mpl_command/;
my $mpl_available = 0;
my $mpl_version = '';

# Check the exit code ($?) and ensure the output looks like a semantic version number
if ($? == 0 && $mpl_version_raw =~ m/^\s*\d+\.\d+\.\d+\s*$/) {
    $mpl_available = 1;
    $mpl_version = $mpl_version_raw;
    # Clean up any potential whitespace
    $mpl_version =~ s/^\s*|\s*$//g;
}

unless ($mpl_available) {
    # Use plan skip_all to exit gracefully if the second dependency is missing
    plan skip_all => 'SKIP: Matplotlib Python package not found or import failed. Please install it with "pip install matplotlib".';
}

# --- If we reach this point, all dependencies are met ---

# Display the detected versions using Test2's 'note' function
note('Dependencies Found:');
note("  Python 3 Version: $python_version");
note("  Matplotlib Version: $mpl_version");

# Now we declare the total number of tests and proceed.
plan tests => 2;

# --- Actual Tests Start Here ---

# Test 1: Confirm Python check passed
ok($python_available, 'Verified: "python3" is available and functional');

# Test 2: Confirm Matplotlib check passed
ok($mpl_available, 'Verified: "matplotlib" is importable under python3');

# Add your functional tests for Matplotlib::Simple below this line.

=comment
How the `Test2` File Works

1.  **`use Test2::V0;`**: This loads the modern testing bundle, giving you access to functions like `ok()`, `note()`, and the `plan` function.
2.  **`qx/command 2>&1/`**: This executes the shell command. The `2>&1` redirects standard error (where missing command messages go) into standard output, so Perl can capture it.
3.  **`$? == 0`**: This checks the exit code of the external command. A value of `0` indicates success.
4.  **`plan skip_all => "..."`**: This is the key feature. If a dependency check fails, calling `plan skip_all` immediately terminates the test script, outputs the skip message, and reports to the test harness that **all tests were skipped** rather than failing. This ensures your module doesn't incorrectly fail CI builds just because the environment is missing an optional (for testing) tool.
5.  **`note()`**: This function in `Test2` is used to print diagnostic information that is typically visible when running tests in verbose mode (e.g., using `prove -v`). It is ideal for reporting the discovered version numbers.
