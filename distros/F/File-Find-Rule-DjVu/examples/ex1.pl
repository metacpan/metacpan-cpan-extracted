#!/usr/bin/env perl

use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::DjVu;

# Arguments.
if (@ARGV < 2) {
        print STDERR "Usage: $0 dir djvu_chunk\n";
        exit 1;
}
my $dir = $ARGV[0];
my $djvu_chunk = $ARGV[1];

# Print all DjVu files in directory with chunk.
foreach my $file (File::Find::Rule->djvu_chunk($djvu_chunk)->in($dir)) {
        print "$file\n";
}

# Output like:
# Usage: qr{[\w\/]+} dir