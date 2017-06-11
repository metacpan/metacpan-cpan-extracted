#!/usr/bin/env perl
use warnings;
use strict;
use JSON;
use JSON::Create 'create_json';
use Gzip::Faster;
$|=1;
# Generate some random garbage bytes
my $x = gzip ('かきくけこ');
use utf8;
my $y = 'さしすせそ';
my $v = {x => $x, y => $y};
binmode STDOUT, ":encoding(utf8)";
print to_json ($v), "\n";
print create_json ($v), "\n";
