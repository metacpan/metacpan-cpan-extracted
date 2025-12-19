#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Leader::Utils qw(check_material_type);

if (@ARGV < 1) {
        print STDERR "Usage: $0 material_type\n";
        exit 1;
}
my $material_type = $ARGV[0];

my $ret = check_material_type($material_type);

print "Expected material type: $material_type\n";
print "Result: $ret\n";

# Output (book):
# Expected material type: book
# Result: 1

# Output (foo):
# Expected material type: foo
# Result: 0