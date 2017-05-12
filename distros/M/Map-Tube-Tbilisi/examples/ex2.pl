#!/usr/bin/env perl

# Pragmas.
use strict;
use utf8;
use warnings;

# Modules.
use Map::Tube::Tbilisi;

# Object.
my $obj = Map::Tube::Tbilisi->new;

# Get XML file.
my $xml_file = $obj->xml;

# Print out XML file.
print "XML file: $xml_file\n";

# Output like:
# XML file: .*/tbilisi-map.xml