#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(encode_utf8);
use Map::Tube::Nanjing;

# Object.
my $obj = Map::Tube::Nanjing->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# 南京地铁10号线
# 南京地铁1号线
# 南京地铁2号线
# 南京地铁3号线
# 宁天城际轨道交通
# 宁高城际轨道交通