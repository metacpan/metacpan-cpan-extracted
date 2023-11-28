#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Leader;
use MARC::Leader::Print;

if (@ARGV < 1) {
        print "Usage: $0 marc_leader\n";
        exit 1;
}
my $marc_leader = $ARGV[0];

# Object.
my $obj = MARC::Leader->new;

# Parse.
my $leader_obj = $obj->parse($marc_leader);

# Print to output.
print scalar MARC::Leader::Print->new->print($leader_obj), "\n";

# Output for '02200cem a2200541 i 4500':
# Record length: 2200
# Record status: Corrected or revised
# Type of record: Cartographic material
# Bibliographic level: Monograph/Item
# Type of control: No specified type
# Character coding scheme: UCS/Unicode
# Indicator count: Number of character positions used for indicators
# Subfield code count: Number of character positions used for a subfield code (2)
# Base address of data: 541
# Encoding level: Full level
# Descriptive cataloging form: ISBD punctuation included
# Multipart resource record level: Not specified or not applicable
# Length of the length-of-field portion: Number of characters in the length-of-field portion of a Directory entry (4)
# Length of the starting-character-position portion: Number of characters in the starting-character-position portion of a Directory entry (5)
# Length of the implementation-defined portion: Number of characters in the implementation-defined portion of a Directory entry (0)
# Undefined: Undefined