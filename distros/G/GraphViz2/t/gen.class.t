# Annotation: Demonstrates each kind of 'class' attribute
#
# 'class' attributes appear in the 'svg' output format.
#
# See comments at the end for examples of how these classes can be used.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $graph = GraphViz2->new(
  global => {
    directed => 0,
    name => '',
  },
  graph => {
    # Set a class on the overall graph:
    class => 'graph_root',
    style => 'rounded',
    stylesheet => 'class-demo-styles.css',
  },
  node => {
    shape => 'box',
    style => 'rounded',
  },
  label => 'Demo of SVG class attributes',
);

$graph->push_subgraph(
 name => 'cluster_match',
 graph => {
  label => 'Championship Match',
  # Setting a class on a cluster:
  class => 'match',
  margin => 32,
  },
);

# Set a class on a subcluster:
$graph->push_subgraph(
 name => 'cluster_team1',
 graph => {
  label => 'Orange Team',
  class => 'team_orange',
  margin => 16,
  bgcolor => 'peachpuff',
  },
);
$graph->add_node(
  name => 'Coach O',
  class => 'coach', # This node's class='coach'; others below use 'player'
  shape => 'hexagon',
  style => 'filled',
  fillcolor => 'white',
);

# Place all players at the same rank:
$graph->push_subgraph(subgraph => {rank => 'sink'});
$graph->add_node(name => 'oplayer1', label => 'Player O1', class => 'player');
$graph->add_node(name => 'oplayer2', label => 'Player O2', class => 'player');
# For edges connecting players, class='teammate_of';
$graph->add_edge(from => 'oplayer1', to => 'oplayer2', class => 'teammate_of');
$graph->pop_subgraph; # End of same-rank group

# For edges between coach and players, class='coach_of' 
$graph->add_edge(from => 'Coach O', to => 'oplayer1', class => 'coach_of');
$graph->add_edge(from => 'Coach O', to => 'oplayer2', class => 'coach_of');

$graph->pop_subgraph; # End of team1 cluster

# Render the second team similarly:
$graph->push_subgraph(
 name => 'cluster_team2',
 graph => {
  label => 'Blue Team',
  class => 'team_blue',
  margin => 16,
  bgcolor => 'lightblue',
  },
);
$graph->add_node(
  name => 'Coach B',
  class => 'coach',
  shape => 'hexagon',
  style => 'filled',
  fillcolor => 'white',
);

# Place all players at the same rank:
$graph->push_subgraph(subgraph => {rank => 'sink'});
$graph->add_node(name => 'bplayer1', label => 'Player B1', class => 'player');
$graph->add_node(name => 'bplayer2', label => 'Player B2', class => 'player');
$graph->add_edge(from => 'bplayer1', to => 'bplayer2', class => 'teammate_of');
$graph->pop_subgraph; # End of same-rank group

$graph->add_edge(from => 'Coach B', to => 'bplayer1', class => 'coach_of');
$graph->add_edge(from => 'Coach B', to => 'bplayer2', class => 'coach_of');

$graph->pop_subgraph; # End of team2 cluster
$graph->pop_subgraph; # End of match cluster

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "class.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}

=begin comment

Below is an example of a stylesheet which can be applied to the SVG
output of this diagram.

To use it:

1. Run this script with the 'svg' file format parameter:

     $ perl t/gen.class.t svg

   A file 'class.svg' will be produced which contains a reference to a
   file in the same directory named 'class-demo-styles.css'.
   (This name is set in the 'stylesheet' directive above.)

2. Copy the CSS content below into a file in the same directory, using
   the mentioned filename (class-demo-styles.css).

3. Load the SVG file in an appropriate viewer.

The style declarations in the CSS file will modify the default
appearance of several parts of the diagram:
  a. The entire diagram will have a subtle gradient background.
  b. Each team's panel/cluster will have a custom drop shadow.
  c. The "Coach" hexagons will be made semi-transparent, letting their
     team colors show through.
  d. The edges will have different dash patterns, based on the type
     of relationship they represent.
  e. Various text strings will be re-styled as italic or bold italic.
     (This particular effect can *also* be achieved by sending certain
     parameters through the Graphviz diagram construction process.
     Depending on the specific scenario, CSS styles may provide a more
     convenient way to achieve this customization.)

CSS content appears between these lines:
----------------------------------------

/* Add a light gradient background to the whole SVG document: */

svg { background-image: linear-gradient(#eee, #def); }

/*
Make the graph's default base white rectangle invisible so the above
gradient shows through. (It's the only polygon which is a direct descendant
of g.graph_root)
*/

.graph_root > polygon { opacity: 0; }

/* Styles for the main cluster: */
.match {
  font-style: italic;
  font-weight: bold;
}

/* Subcluster accents */

.team_orange path { filter: drop-shadow(4px 4px 2px orange); }
.team_blue path { filter: drop-shadow(-4px 4px 2px blue); }

/* Node styles applied across clusters: */

.coach polygon { fill-opacity: 50%; }
.player { font-style: italic; }

/* Edge styles based on the named relation: */

.coach_of {
  stroke-width: 1;
  stroke-dasharray: 4 6;
}

.teammate_of {
  stroke-width: 2;
  stroke-dasharray: 2 1;
}

----------------------------------------
=end comment
