#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create 'create_json';
my %example = (
    x => {
	y => 2,
	z => 3,
    },
    a => {
	b => 4,
	c => 5,
    },
);
print create_json (\%example);
