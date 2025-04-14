#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Leader;
use MARC::Leader::Utils qw(material_type);

if (@ARGV < 1) {
        print STDERR "Usage: $0 leader_string\n";
        exit 1;
}
my $leader_string = $ARGV[0];

my $leader = MARC::Leader->new->parse($leader_string);

my $material_type = material_type($leader);

print "Leader: |$leader_string|\n";
print "Material type: $material_type\n";

# Output for '     nem a22     2  4500':
# Leader: |     nem a22     2  4500|
# Material type: map