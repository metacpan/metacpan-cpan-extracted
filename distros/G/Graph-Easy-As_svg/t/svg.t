#!/usr/bin/env perl

use Test::More;
use strict;

BEGIN
   {
   plan tests => 86;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

use Graph::Easy::Edge::Cell qw/EDGE_END_E EDGE_END_N EDGE_END_S EDGE_END_W EDGE_HOR/;

#############################################################################
my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

is ($graph->nodes(), 0, '0 nodes');
is ($graph->edges(), 0, '0 edges');

is (join (',', $graph->edges()), '', '0 edges');

# this will load As_svg:
my $svg = $graph->as_svg();

# after loading As_svg, this should work:
can_ok ('Graph::Easy::Node', qw/as_svg/);
can_ok ('Graph::Easy', qw/as_svg_file/);
can_ok ('Graph::Easy::As_svg', qw/_text_length/);

like ($svg, qr/enerated at .* by/, 'contains generator notice');
like ($svg, qr/<svg/, 'looks like SVG');
like ($svg, qr/<\/svg/, 'looks like SVG');
like ($svg, qr/1\.1/, 'looks like SVG v1.1');
like ($svg, qr/\.node/, 'contains .node class');

#############################################################################
# with some nodes

my $bonn = Graph::Easy::Node->new( name => 'Bonn' );
my $berlin = Graph::Easy::Node->new( 'Berlin' );

$graph->add_edge ($bonn, $berlin);

$svg = $graph->as_svg();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/Berlin/, 'contains Berlin');
like ($svg, qr/<text/, 'contains <text');

like ($svg, qr/<rect/, 'contains <rect');
like ($svg, qr/<line/, 'contains <line (for edge)');

unlike ($svg, qr/<text.*?><\/text>/, "doesn't contain empty text tags");

#print $graph->as_svg(),"\n";

#############################################################################
# as_svg_file

$svg = $graph->as_svg_file();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/standalone="yes"/, 'standalone');
like ($svg, qr/xmlns="/, 'xmlns');
like ($svg, qr/<\?xml/, 'contains <xml');

#print $graph->as_svg(),"\n";

#############################################################################
#############################################################################
# edge drawing (line_straigh)

sub LINE_HOR () { 0; }
sub LINE_VER () { 1; }

my $edge = Graph::Easy::Edge->new();
my $cell = Graph::Easy::Edge::Cell->new( edge => $edge, type => EDGE_HOR);
$cell->{w} = 100;
$cell->{h} = 50;

$svg = join ('', $cell->_svg_line_straight(0, 0, LINE_HOR(), 0.1, 0.1 ));
is ($svg, '<line x1="10" y1="25" x2="90" y2="25" />', 'line hor');

$svg = join ('', $cell->_svg_line_straight(0, 0, LINE_VER(), 0.1, 0.1 ));
is ($svg, '<line x1="50" y1="5" x2="50" y2="45" />', 'line ver');

$svg = join ('', $cell->_svg_line_straight(0, 0, LINE_VER(), 0.1, 0.1 ));
is ($svg, '<line x1="50" y1="5" x2="50" y2="45" />', 'line ver');

#############################################################################
# arrorw drawing

$svg = $cell->_svg_arrow({}, 0, 0, EDGE_END_E, , '' );
is ($svg, '<use xlink:href="#ah" x="90" y="25"/>'."\n", 'arrowhead east');

$svg = $cell->_svg_arrow({}, 0, 0, EDGE_END_N, , '' );
is ($svg, '<use xlink:href="#ah" transform="translate(50 5)rotate(-90)"/>'."\n", 'arrowhead north');

$svg = $cell->_svg_arrow({}, 0, 0, EDGE_END_S, , '' );
is ($svg, '<use xlink:href="#ah" transform="translate(50 45)rotate(90)"/>'."\n", 'arrowhead south');

#############################################################################
# with some nodes with attributes

$graph = Graph::Easy->new();

$edge = $graph->add_edge ($bonn, $berlin);

$bonn->set_attribute( 'shape' => 'circle' );

is ($bonn->predecessors(), 0, 'no pre');
is ($berlin->successors(), 0, 'no pre');
is ($bonn->successors(), 1, 'one pre');
is ($berlin->predecessors(), 1, 'one pre');

is (keys %{$graph->{cells}}, 0, 'no cells');
is ($bonn->{graph}, $graph, 'graph is ok');
is ($berlin->{graph}, $graph, 'graph is ok');
is ($edge->{graph}, $graph, 'graph on edge is ok');

$svg = $graph->as_svg();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/Berlin/, 'contains Bonn');
like ($svg, qr/circle/, 'contains circle shape');

#print $graph->as_svg(),"\n";

$bonn->set_attribute( 'shape' => 'rounded' );

$svg = $graph->as_svg();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/Berlin/, 'contains Bonn');
like ($svg, qr/rect.*rx/, 'contains rect shape with rx/ry');
like ($svg, qr/rx="15" ry="15"/, 'contains rect shape with rx/ry');
like ($svg, qr/line/, 'contains edge');
like ($svg, qr/text/, 'contains text');
like ($svg, qr/#ah/, 'contains arrowhead');

#print $graph->as_svg(),"\n";

$edge->set_attribute('style', 'double-dash');

$graph->layout();

$svg = $graph->as_svg();
like ($svg, qr/stroke-dasharray/, 'double dash contains dash array');

#############################################################################
# unused definitions are not in the output

unlike ($svg, qr/(diamond|circle|triangle)/, 'unused defs are not there');

#############################################################################
# color on edge labels

$edge->set_attribute('color', 'orange');

$svg = $graph->as_svg();
like ($svg, qr/stroke="#ffa500"/, 'orange stroke on edge');
unlike ($svg, qr/color="#ffa500"/, 'no orange color on edge');
unlike ($svg, qr/fill="#ffa500"/, 'no orange fill on edge');

$edge->set_attribute('label', 'Schmabel');

is ($edge->label(), 'Schmabel', 'edge label');

$svg = $graph->as_svg();
like ($svg, qr/stroke="#ffa500"/, 'orange stroke on edge');
like ($svg, qr/fill="#ffa500"/, 'orange color on edge label');
unlike ($svg, qr/color="#ffa500"/, 'no orange color on edge');

#############################################################################
# text-style support

$edge->set_attribute('text-style', 'bold underline');

$svg = $graph->as_svg();
like ($svg, qr/font-weight="bold" text-decoration="underline"/, 'text-style');

$edge->set_attribute('text-style', 'bold underline overline');

$svg = $graph->as_svg();
like ($svg, qr/font-weight="bold" text-decoration="underline overline"/, 'text-style');

#############################################################################
# font-size support

$edge->set_attribute('font-size', '2em');

$svg = $graph->as_svg();
my $expect = $graph->EM() * 2;
like ($svg, qr/style=".*font-size:${expect}px"/, '2em');

#############################################################################
# <title>

$svg = $graph->as_svg();
like ($svg, qr/<title>Untitled graph<\/title>/, 'no title by default');

$graph->set_attribute('graph','label', 'My Graph');
$svg = $graph->as_svg();
like ($svg, qr/<title>My Graph<\/title>/, 'set title');

$graph->set_attribute('graph','title', 'My Graph Title');
$svg = $graph->as_svg();
like ($svg, qr/<title>My Graph Title<\/title>/, 'title overrides label');


#############################################################################
# support for rotate

$bonn->set_attribute( 'rotate' => 'right' );

is ($bonn->attribute('rotate'), 'right', 'rotate right is +90 degrees');
is ($bonn->angle(), '180', 'rotate right is 90 (default) +90 == 180 degrees');

$svg = $graph->as_svg();
like ($svg, qr/transform="rotate\(180,/, 'rotate right => 180');

#############################################################################

$bonn->set_attribute( 'label' => 'My\nMultiline' );

$svg = $graph->as_svg();
unlike ($svg, qr/<tspan[^>]+><\/tspan>/, 'no empty tspan');

#############################################################################

$bonn->set_attribute( 'label' => 'dontseeme' );
$bonn->set_attribute( 'shape' => 'point');
$bonn->set_attribute( 'point-style' => 'invisible');

$svg = $graph->as_svg();
like ($svg, qr/<!-- dontseeme/, 'invisible');
unlike ($svg, qr/invisible/, 'no "invisible" in svg');

#############################################################################

$bonn->set_attribute( 'label' => 'quote & < > "' );
$bonn->set_attribute( 'shape' => 'rect');
$bonn->del_attribute( 'point-style');

$svg = $graph->as_svg();
like ($svg, qr/<!-- quote &amp; &lt; &gt; ",/, 'quoted');
like ($svg, qr/>quote &amp; &lt; &gt; &quot;<\/text>/, 'quoted');

#############################################################################
# check that node.cities is converted to "node_cities"

$bonn->set_attribute( 'class' => 'cities' );

$svg = $graph->as_svg();
like ($svg, qr/class="node_cities"/, 'node.cities => node_cities');
unlike ($svg, qr/.node,\s*.node_cities/, 'no class style cities yet' );

$graph->set_attribute( 'node.cities', 'color', 'red' );
$svg = $graph->as_svg();

like ($svg, qr/class="node_cities"/, 'node.cities => node_cities');
like ($svg, qr/.node,\s*.node_cities/, 'node.cities => node_cities');

#############################################################################
# edges with no fill but arrowstyle: fill

$graph = Graph::Easy->new();

$edge = $graph->add_edge ('A','B');

$edge->set_attribute('arrowstyle','filled');
$edge->set_attribute('color','green');

$svg = $graph->as_svg();

like ($svg, qr/fill="#008000"/, 'edge fill is not inherit');

#############################################################################
# check that we really filter out labelpos etc.

$graph = Graph::Easy->new();
$edge = $graph->add_edge ('A','B');
$edge->set_attribute('arrow-shape','triangle');
$edge->set_attribute('arrow-style','open');
$graph->set_attribute('label-pos','bottom');
$graph->set_attribute('text-style','bold');
$graph->node('A')->set_attribute('auto-title','label');
$graph->node('B')->set_attribute('auto-label','10');

$svg = $graph->as_svg();

for my $not (qw/labelpos arrowshape arrowstyle autotitle autolabel textstyle/)
  {
  unlike ($svg, qr/$not/, "$not not output");
  }

#############################################################################
# see that we output the font for the graph itself

$graph = Graph::Easy->new();
$edge = $graph->add_edge ('A','B');
$graph->set_attribute('font','Foo');
$graph->set_attribute('label','Labels');

$svg = $graph->as_svg();

like ($svg, qr/font-family: Foo/, "font-family was output");

#############################################################################
# see that we output the font for the nodes

$graph = Graph::Easy->new();
$edge = $graph->add_edge ('A','B');
$graph->set_attribute('font','Foo');
$graph->node('A')->set_attribute('font','Fooobar');

$svg = $graph->as_svg();

like ($svg, qr/font-family:Fooobar/, "font-family for node was output");

#############################################################################
# output background for rounded nodes in groups

$graph = Graph::Easy->new();
my ($A,$B);
($A,$B,$edge) = $graph->add_edge ('A','B');
my $group = $graph->add_group ('');
$group->add_node($A);
$graph->node('A')->set_attribute('shape','rounded');

$svg = $graph->as_svg();

# rect x="19" y="19" width="5" height="3" fill="#a0d0ff"
like ($svg, qr/rounded(.|\n)+rect.+fill=".a0d0ff"/, "background for rounded node");

#############################################################################
# quote "&" in links as well as add links on edges

$graph = Graph::Easy->new();
($A,$B,$edge) = $graph->add_edge ('A','B','test');
$edge->set_attribute('link','http://bloodgate.com/?foo=a&bar=b');

$svg = $graph->as_svg();

like ($svg, qr/xlink:href="http:\/\/bloodgate.com.*\&amp;/, "link has &amp;");

