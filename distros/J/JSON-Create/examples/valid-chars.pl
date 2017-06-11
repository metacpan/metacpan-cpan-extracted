#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create 'create_json';
use utf8;
$| = 1;
binmode STDOUT, ":encoding(utf8)";
print create_json ('赤ブöＡↂϪ'), "\n";
no utf8;
binmode STDOUT, ":raw";
print create_json ('赤ブöＡↂϪ'), "\n";
print create_json ("\x99\xff\x10"), "\n";
