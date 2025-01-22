#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Nanjing;

# Object.
my $obj = Map::Tube::Nanjing->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('鼓楼'), decode_utf8('大厂'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: 鼓楼 (南京地铁1号线), 大厂 (宁天城际轨道交通)