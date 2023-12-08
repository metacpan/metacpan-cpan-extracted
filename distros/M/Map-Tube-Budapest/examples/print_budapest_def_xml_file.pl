#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::Budapest;

# Object.
my $obj = Map::Tube::Budapest->new;

# Get XML file.
my $xml_file = $obj->xml;

# Print out XML file.
print "XML file: $xml_file\n";

# Output like:
# XML file: .*/budapest-map.xml