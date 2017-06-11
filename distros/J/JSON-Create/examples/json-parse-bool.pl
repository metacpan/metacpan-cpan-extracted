#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Parse '0.38', 'parse_json';
use JSON::Create 'create_json';
my $in = parse_json ('[true,false,"boo"]');
print create_json ($in);
