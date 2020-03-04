#!/usr/bin/env perl

use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::DMIDecode;

# Arguments.
if (@ARGV < 2) {
        print STDERR "Usage: $0 dir handle\n";
        exit 1;
}
my $dir = $ARGV[0];
my $handle = $ARGV[1];

# Print all dmidecode handles in directory.
foreach my $file (File::Find::Rule->dmidecode_handle($handle)->in($dir)) {
        print "$file\n";
}

# Output like:
# Usage: qr{[\w\/]+} dir handle