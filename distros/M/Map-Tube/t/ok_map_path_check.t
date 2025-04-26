#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use FindBin;
use lib "lib/";
use lib "$FindBin::Bin/../../lib";
use Map::Tube::Utils qw/untaint_path/;

# Setup: Create a temp file
my ($fh, $filename) = tempfile(SUFFIX => '.json');
print $fh '{"test": "data"}';
close $fh;

subtest 'Valid path should pass' => sub {
    my $sanitized = untaint_path($filename);
    ok(-f $sanitized, "File exists and is valid");
};

subtest 'Path with .. should resolve and pass' => sub {
    my $rel_path = File::Spec->abs2rel($filename, "$FindBin::Bin/../lib");
    my $indirect = "$FindBin::Bin/../lib/$rel_path";
    my $sanitized = untaint_path($indirect);
    ok(-f $sanitized, "File with .. resolved correctly");
};

subtest 'Tainted characters should fail' => sub {
    my $tainted = "$filename\0";
    eval { untaint_path($tainted) };
    like($@, qr/Tainted path/, "Fails on control characters");
};

subtest 'Nonexistent file should fail' => sub {
    eval { untaint_path("/tmp/definitely_not_existing_file.json") };
    like($@, qr/Not a regular file/, "Fails on non-existent file");
};

done_testing();
