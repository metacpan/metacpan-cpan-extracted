#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use Test::More;
use Path::Tiny qw(tempfile);
use FindBin;
use lib "lib/";
use lib "$FindBin::Bin/../../lib";
use Map::Tube::Plugin::Graph::Utils;

# Setup: Create a temp file
my $filename = tempfile(SUFFIX => '.json', DIR => '.', UNLINK => 1);
$filename->spew('{"test": "data"}');

subtest 'Valid path should pass' => sub {
    my $sanitized = Map::Tube::Plugin::Graph::Utils::_clean_path($filename);
    ok(-f $sanitized, "File exists and is valid");
};

subtest 'Non-printable characters should fail' => sub {
    my $badname = "$filename\0";
    eval { Map::Tube::Plugin::Graph::Utils::_clean_path($badname) };
    like($@, qr/^Non-printable characters/, "Fails on control characters");
};

$filename = tempfile(SUFFIX => '.json', TMPDIR => 1, UNLINK => 1);
$filename->spew('{"test": "data"}');

subtest 'File must be forced into current directory' => sub {
    my $sanitized = Map::Tube::Plugin::Graph::Utils::_clean_path($filename);
    my $relpath = File::Spec->abs2rel($sanitized);
    like($relpath, qr/^[^\\\/]*$/, "Current directory only");
};

subtest 'Existing non-files should fail' => sub {
    my $badname = "t";
    eval { Map::Tube::Plugin::Graph::Utils::_clean_path($badname) };
    like($@, qr/^File exists but is not a regular file:/, "Name of existing directory");
};

subtest 'Existing special file should fail' => sub {
    # On Windows 'nul' exists; on Linux we can use the 't' directory
    my $badname = ($^O eq 'MSWin32') ? 'nul' : 't';
    eval { Map::Tube::Plugin::Graph::Utils::_clean_path($badname) };
    like($@, qr/^File exists but is not a regular file: $badname/, "Caught non-regular file");
};

done_testing;
