#!/usr/bin/perl
use warnings;
use strict;

use GraphViz::Graph;

use Test::More tests => 1;
use Test::Files;

my $file_base_name = 'test-004';
my $dot_file_name  = "$file_base_name.dot";
my $png_file_name  = "$file_base_name.png";
my $graph = GraphViz::Graph->new($file_base_name);

$graph->label({text=>'Test 004'});

$graph->create('png');

compare_ok($dot_file_name, "t/$dot_file_name.expected", "dot file should be equal");

unlink $dot_file_name;
unlink $png_file_name;
