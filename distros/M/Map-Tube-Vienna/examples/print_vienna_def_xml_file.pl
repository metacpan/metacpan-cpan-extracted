#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::Vienna;

# Object.
my $obj = Map::Tube::Vienna->new;

# Get XML file.
my $xml_file = $obj->xml;

# Print out XML file.
print "XML file: $xml_file\n";

# Output like:
# XML file: .*/vienna-map.xml