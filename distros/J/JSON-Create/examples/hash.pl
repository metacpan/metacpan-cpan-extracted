#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create 'create_json';
my %example = (
    x => 1,
    y => 2,
    z => 3,
);
print create_json (\%example);
