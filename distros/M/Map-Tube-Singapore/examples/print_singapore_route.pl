#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::Singapore;

# Object.
my $obj = Map::Tube::Singapore->new;

# Get route.
my $route = $obj->get_shortest_route('Admiralty', 'Tampines');

# Print out type.
print "Route: ".$route."\n";

# Output:
# Route: Admiralty (North South MRT Line), Sembawang (North South MRT Line), Canberra (North South MRT Line), Yishun (North South MRT Line), Khatib (North South MRT Line), Yio Chu Kang (North South MRT Line), Ang Mo Kio (North South MRT Line), Bishan (North South MRT Line), Bishan (Circle MRT Line), Lorong Chuan (Circle MRT Line), Serangoon (Circle MRT Line), Bartley (Circle MRT Line), Tai Seng (Circle MRT Line), MacPherson (Circle MRT Line), Paya Lebar (Circle MRT Line), Paya Lebar (East West MRT Line), Eunos (East West MRT Line), Kembangan (East West MRT Line), Bedok (East West MRT Line), Tanah Merah (East West MRT Line), Simei (East West MRT Line), Tampines (East West MRT Line)