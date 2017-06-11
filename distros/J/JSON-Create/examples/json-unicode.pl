#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use JSON;
use JSON::Create 'create_json';
no utf8;
my $x = 'かきくけこ';
use utf8;
my $y = 'さしすせそ';
my $v = {x => $x, y => $y};
binmode STDOUT, ":encoding(utf8)";
print to_json ($v), "\n";
print create_json ($v), "\n";
