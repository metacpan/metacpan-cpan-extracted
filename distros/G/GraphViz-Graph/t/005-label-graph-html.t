#!/usr/bin/perl
use warnings;
use strict;

use GraphViz::Graph;

use Test::More tests => 4;
use Test::Files;
use Test::Exception;

my $file_base_name = 'test-005';
my $dot_file_name  = "$file_base_name.dot";
my $png_file_name  = "$file_base_name.png";
my $graph = GraphViz::Graph->new($file_base_name);

$graph->label({html=>'<font point-size="88">Test <b><font face="Courier">005</font></b></font>'});

$graph->create('png');

compare_ok($dot_file_name, "t/$dot_file_name.expected", "dot file should be equal");
unlink $dot_file_name;
unlink $png_file_name;

$graph = GraphViz::Graph->new('FileNameBase');
dies_ok { $graph->label() } 'A label must either be html or text';

$graph = GraphViz::Graph->new('FileNameBase');
dies_ok { $graph->label('scalar') } 'A scalar cannot be passed';

dies_ok { $graph->label({text=>'foo', additional_opt=>1}) } 'A scalar cannot be passed';
