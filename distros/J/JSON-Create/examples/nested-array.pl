#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create 'create_json';
my @array = ([1, 2, 2.5], [qw/mocha dusty milky/], [qw/Tico Rocky Pinky/]);
print create_json (\@array);
