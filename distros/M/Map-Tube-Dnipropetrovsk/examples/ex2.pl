#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Dnipropetrovsk;

# Object.
my $obj = Map::Tube::Dnipropetrovsk->new;

# Get XML file.
my $xml_file = $obj->xml;

# Print out XML file.
print "XML file: $xml_file\n";

# Output like:
# XML file: .*/dnipropetrovsk-map.xml