#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse 'parse_json';
my $json = '["golden", "fleece"]';
my $perl = parse_json ($json);
# Same effect as $perl = ['golden', 'fleece'];

