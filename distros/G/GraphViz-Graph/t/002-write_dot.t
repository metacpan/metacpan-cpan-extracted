#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 2;
use Test::Files;

use GraphViz::Graph;

my $file_base_name = 'test-002';
my $dot_file_name  = "$file_base_name.dot";
my $graph = GraphViz::Graph->new($file_base_name);
$graph->write_dot();

ok(-e $dot_file_name);

compare_ok($dot_file_name, "t/$dot_file_name.expected", "dot file should be equal");

unlink $dot_file_name;
