#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create 'create_json';
print create_json ({a => undef, b => [undef, undef]}), "\n";

