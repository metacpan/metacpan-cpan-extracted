#!/usr/bin/perl
use warnings;
use strict;

use GraphViz::Graph;

use Test::More tests => 1;
use Test::Files;

my $file_base_name = 'test-010';
my $dot_file_name  = "$file_base_name.dot";
my $png_file_name  = "$file_base_name.png";
my $graph = GraphViz::Graph->new($file_base_name);

my $nd_1 = $graph->node();
my $nd_2 = $graph->node();
my $nd_3 = $graph->node();
my $nd_4 = $graph->node();
my $nd_5 = $graph->node();
my $nd_6 = $graph->node();

$nd_1 -> label({text=>'A'});
$nd_2 -> label({text=>'B'});
$nd_3 -> label({text=>'C'});
$nd_4 -> label({text=>'D'});
$nd_5 -> label({text=>'E'});
$nd_6 -> label({text=>'F'});


my $edge_1_2 = $graph->edge($nd_1, $nd_2);
my $edge_2_3 = $graph->edge($nd_2, $nd_3);

my $edge_6_5 = $graph->edge($nd_6, $nd_5);
my $edge_5_4 = $graph->edge($nd_5, $nd_4);


$graph->same_rank($nd_2, $nd_3, $nd_4);
$graph->same_rank($nd_1, $nd_6);

$graph->create('png');

compare_ok($dot_file_name, "t/$dot_file_name.expected", "dot file should be equal");

unlink $dot_file_name;
unlink $png_file_name;
