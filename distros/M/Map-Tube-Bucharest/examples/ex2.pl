#!/usr/bin/env perl

# Pragmas.
use strict;
use utf8;
use warnings;

# Modules.
use Map::Tube::Bucharest;

# Object.
my $obj = Map::Tube::Bucharest->new;

# Get XML file.
my $xml_file = $obj->xml;

# Print out XML file.
print "XML file: $xml_file\n";

# Output like:
# XML file: .*/bucharest-map.xml