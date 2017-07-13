#!/usr/bin/perl
use warnings;
use strict;

use GraphViz::Graph;

use Test::More tests => 1;
use Test::Files;
use Test::Exception;

my $file_base_name = 'test-006';
my $dot_file_name  = "$file_base_name.dot";
my $png_file_name  = "$file_base_name.png";
my $graph = GraphViz::Graph->new($file_base_name);

$graph->label({html=>"<font point-size='20'><b><font face='Courier'>$file_base_name</font></b></font>"});

my $nd_1 = $graph->node();
my $nd_2 = $graph->node();
my $nd_3 = $graph->node();

$nd_1->label({text=>'Text label'});
$nd_2->label({html=>'<font point-size="45"><font face="Courier">html</font><font face="Helvetica">label</font></font>'});

$graph->create('png');


compare_ok($dot_file_name, "t/$dot_file_name.expected", "dot file should be equal");
unlink $dot_file_name;
unlink $png_file_name;
