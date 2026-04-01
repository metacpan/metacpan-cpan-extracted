#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use FindBin;
use lib "lib/";
use lib "$FindBin::Bin/../../lib";
use Map::Tube::CLI;

# Setup: Create a temp file
my ($fh, $filename) = tempfile(SUFFIX => '.json', DIR => '.', UNLINK => 1);
print $fh '{"test": "data"}';
close $fh;

subtest 'Valid path should pass' => sub {
    my $sanitized = Map::Tube::CLI::_clean_path($filename);
    ok(-f $sanitized, "File exists and is valid");
};

subtest 'Non-printable characters should fail' => sub {
    my $badname = "$filename\0";
    eval { Map::Tube::CLI::_clean_path($badname) };
    like($@, qr/^Non-printable characters/, "Fails on control characters");
};

($fh, $filename) = tempfile(SUFFIX => '.json', TMPDIR => 1, UNLINK => 1);
print $fh '{"test": "data"}';
close $fh;

subtest 'File must be forced into current directory' => sub {
    my $sanitized = Map::Tube::CLI::_clean_path($filename);
    my $relpath = File::Spec->abs2rel($sanitized);
    like($relpath, qr/^[^\\\/]*$/, "Current directory only");
};

subtest 'Existing non-files should fail' => sub {
    my $badname = "t";
    eval { Map::Tube::CLI::_clean_path($badname) };
    like($@, qr/^File exists but is not a regular file:/, "Name of existing directory");
};

subtest 'Existing special file should fail' => sub {
    # On Windows 'nul' exists; on Linux we can use the 't' directory
    my $badname = ($^O eq 'MSWin32') ? 'nul' : 't';
    eval { Map::Tube::CLI::_clean_path($badname) };
    like($@, qr/^File exists but is not a regular file: $badname/, "Caught non-regular file");
};

done_testing;
