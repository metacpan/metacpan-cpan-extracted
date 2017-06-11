#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create 'create_json';
my %hash = (a => 'b', c => 'd');
print create_json (\%hash);

