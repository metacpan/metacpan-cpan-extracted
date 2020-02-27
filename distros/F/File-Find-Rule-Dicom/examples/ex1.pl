#!/usr/bin/env perl

use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::Dicom;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 dir\n";
        exit 1;
}
my $dir = $ARGV[0];

# Print all DICOM files in directory.
foreach my $file (File::Find::Rule->dicom_file->in($dir)) {
        print "$file\n";
}

# Output like:
# Usage: qr{[\w\/]+} dir