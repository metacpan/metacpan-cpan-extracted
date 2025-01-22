#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::NizhnyNovgorod;

# Object.
my $obj = Map::Tube::NizhnyNovgorod->new;

# Get XML file.
my $xml_file = $obj->xml;

# Print out XML file.
print "XML file: $xml_file\n";

# Output like:
# XML file: .*/nizhny_novgorod-map.xml