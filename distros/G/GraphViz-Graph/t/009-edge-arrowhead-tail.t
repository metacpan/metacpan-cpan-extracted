#!/usr/bin/perl
use warnings;
use strict;

use GraphViz::Graph;

use Test::More tests => 1;
use Test::Files;

my $file_base_name = 'test-009';
my $dot_file_name  = "$file_base_name.dot";
my $png_file_name  = "$file_base_name.png";
my $graph = GraphViz::Graph->new($file_base_name);

my $nd_one   = $graph->node();
my $nd_two   = $graph->node();
my $nd_three = $graph->node();
my $nd_four  = $graph->node();

$nd_one   -> label({text=>'A'});
$nd_two   -> label({text=>'B'});
$nd_three -> label({text=>'C'});
$nd_four  -> label({text=>'D'});


my $edge_1 = $graph->edge($nd_one  , $nd_two  );
my $edge_2 = $graph->edge($nd_two  , $nd_three);
my $edge_3 = $graph->edge($nd_three, $nd_four );

$edge_1->arrow_start('odot'   ); $edge_1->arrow_end('none'    );
$edge_2->arrow_start('diamond'); $edge_2->arrow_end('crow'    );
$edge_3->arrow_start('tee'    ); $edge_3->arrow_end('invempty');

$graph->create('png');

compare_ok($dot_file_name, "t/$dot_file_name.expected", "dot file should be equal");

unlink $dot_file_name;
unlink $png_file_name;
