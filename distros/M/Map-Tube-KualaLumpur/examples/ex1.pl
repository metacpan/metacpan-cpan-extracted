#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::KualaLumpur;

# Object.
my $obj = Map::Tube::KualaLumpur->new;

# Get route.
my $route = $obj->get_shortest_route('Kuang', 'Subang Jaya');

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Kuang (Seremban Line), Sungai Buloh (Seremban Line), Kepong Sentral (Seremban Line), Kepong (Seremban Line), Segambut (Seremban Line), Putra (Port Klang Line, Walking), Bank Negara (Port Klang Line, Walking), Kuala Lumpur (Port Klang Line), KL Sentral (Port Klang Line, Terminal1, Terminal5, Walking, Terminal6), Angkasapuri (Port Klang Line), Pantai Dalam (Port Klang Line), Petaling (Port Klang Line), Jalan Templer (Port Klang Line), Kampung Dato Harun (Port Klang Line), Seri Setia (Port Klang Line), Setia Jaya (Port Klang Line), Subang Jaya (Port Klang Line)