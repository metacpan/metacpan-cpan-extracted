#!/usr/bin/env perl

use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::BOM;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 dir\n";
        exit 1;
}
my $dir = $ARGV[0];

# Print all files with UTF-32 BOM in directory.
foreach my $file (File::Find::Rule->bom_utf32->in($dir)) {
        print "$file\n";
}

# Output like:
# Usage: qr{[\w\/]+} dir