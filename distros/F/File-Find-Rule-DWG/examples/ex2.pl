#!/usr/bin/env perl

use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::DWG;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 dir acad_magic\n";
        exit 1;
}
my $dir = $ARGV[0];
my $acad_magic = $ARGV[1];

# Print all DWG files in directory.
foreach my $file (File::Find::Rule->dwg_magic($acad_magic)->in($dir)) {
        print "$file\n";
}

# Output like:
# Usage: qr{[\w\/]+} dir acad_magic