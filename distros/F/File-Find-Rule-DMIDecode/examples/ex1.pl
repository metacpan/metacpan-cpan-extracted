#!/usr/bin/env perl

use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::DMIDecode;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 dir\n";
        exit 1;
}
my $dir = $ARGV[0];

# Print all dmidecode files in directory.
foreach my $file (File::Find::Rule->dmidecode_file->in($dir)) {
        print "$file\n";
}

# Output like:
# Usage: qr{[\w\/]+} dir