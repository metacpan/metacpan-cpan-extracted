#!/usr/bin/env perl

# test that the output doesn't contain things it shouldn't

use Test::More;
use strict;

BEGIN
   {
   plan tests => 33;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

#############################################################################
my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

my ($A,$B,$E) = $graph->add_edge('A','B','C');

my ($N) = $graph->add_anon_node();
$graph->add_edge('B',$N);

my ($G) = $graph->add_group('G');

# some attributes that should not be output:

$A->set_attribute('flow','east');
$A->set_attribute('autolabel','12');
$A->set_attribute('shape','diamond');
$A->set_attribute('group','G');
$A->set_attribute('format','pod');

$B->set_attribute('shape','point');
$B->set_attribute('point-shape','star');
$B->set_attribute('point-style','closed');
$B->set_attribute('border-style','double');
$B->set_attribute('offset','2,2');
$B->set_attribute('origin','A');
$B->set_attribute('textwrap','auto');

$graph->set_attribute('type','undirected');
$graph->set_attribute('node','columns','2');
$graph->set_attribute('labelpos','bottom');
$graph->set_attribute('root','A');

$E->set_attribute('labelcolor','green');
$E->set_attribute('autojoin','always');
$E->set_attribute('autosplit','always');
$E->set_attribute('end','north');
$E->set_attribute('start','east');
$E->set_attribute('minlen','2');
$E->set_attribute('fill','red');
$E->set_attribute('format','pod');
$E->set_attribute('textwrap','auto');

$G->set_attribute('root','A');

# some things that should be in the output
$A->set_attribute('id','A1');


# this will load As_svg:
my $svg = $graph->as_svg();

for my $w (qw/
	flow auto-label arrow-style arrow-shape
	shape point-shape
	auto-join auto-split
	end start minlen
	offset origin columns
	label-pos label-color format root rank
	textwrap format
	/)
   {
   unlike ($svg, qr/$w=/, "attribute $w skipped");
   if ($w =~ /-/)
     {
     my $w2 = $w; $w2 =~ s/-//g;
     unlike ($svg, qr/$w2=/, "attribute $w skipped");
     }
   }
like ($svg, qr/(id)="/, 'attribute id included');

unlike ($svg, qr/type=.undirected/, "attribute type for graph skipped");

#print $graph->as_txt();
# print STDERR $svg."\n";

#############################################################################

# all tests done
