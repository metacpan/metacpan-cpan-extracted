#!/usr/bin/perl
use warnings;
use strict;

use GraphViz::Graph;

use Test::More tests => 1;
use Test::Files;

my $file_base_name = 'test-008';
my $dot_file_name  = "$file_base_name.dot";
my $png_file_name  = "$file_base_name.png";
my $graph = GraphViz::Graph->new($file_base_name);

my $nd_one   = $graph->node();
my $nd_two   = $graph->node();
my $nd_three = $graph->node();
my $nd_four  = $graph->node();

$nd_one->label({html=>"<table>
  <tr><td>a</td><td>b</td></tr>
  <tr><td>c</td><td>d</td></tr>
  <tr><td>e</td><td>f</td></tr>
</table>"});

$nd_two->label({html=>"<table>
  <tr><td              >d</td><td>e</td></tr>
  <tr><td port='port_f'>f</td><td>g</td></tr>
  <tr><td              >h</td><td>i</td></tr>
</table>"});

$nd_three->label({html=>"<table>
  <tr><td              >j</td><td port='port_k'>k</td></tr>
  <tr><td port='port_l'>l</td><td              >m</td></tr>
  <tr><td              >n</td><td              >o</td></tr>
</table>"});

$nd_four->label({text=>'End'});

$graph->edge($nd_one                  , $nd_two  ->port('port_f'));
$graph->edge($nd_two  ->port('port_f'), $nd_three->port('port_l'));
$graph->edge($nd_three->port('port_k'), $nd_four                 );

$graph->create('png');

compare_ok($dot_file_name, "t/$dot_file_name.expected", "dot file should be equal");

unlink $dot_file_name;
unlink $png_file_name;
