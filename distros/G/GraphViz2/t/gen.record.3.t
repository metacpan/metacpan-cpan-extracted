# Annotation: Deeply nested records using nested array-refs.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $id    = '3';
my $graph = GraphViz2->new(
	global => {directed => 1, combine_node_and_port => 0, record_shape => 'record'},
	graph  => {
          label => "Record demo $id - Deeply nested records " .
            "using nested array-refs"
        },
);

$graph->add_node(name => 'Alphabet', label => [
  { port => 'port_a', text => 'a:port_a' },
  [
    { port => 'port_b', text => 'b:port_b' },
    'c',
    [
      { port => 'port_d', text => 'd:port_d' },
      'e',
      'f',
      [
        'g',
        { port => 'port_h', text => 'h:port_h' },
        'i',
        'j',
        [
          'k',
          'l',
          'm',
          { port => 'port_n', text => 'n:port_n' },
          'o',
          'p',
        ],
        'q',
        'r',
        { port => 'port_s', text => 's:port_s' },
        't',
      ],
      'u',
      'v',
      { port => 'port_w', text => 'w:port_w' },
    ],
    'x',
    { port => 'port_y', text => 'y:port_y' },
  ],
  'z',
]);

$graph -> add_edge(
  from => 'Alphabet', tailport => 'port_a', to => 'Alphabet', headport => 'port_n', color => 'maroon',
);
$graph -> add_edge(
  from => 'Alphabet', tailport => 'port_b', to => 'Alphabet', headport => 'port_s', color => 'blue',
);
$graph -> add_edge(
  from => 'Alphabet', tailport => 'port_d', to => 'Alphabet', headport => 'port_w', color => 'red',
);
$graph -> add_edge(
  from => 'Alphabet', tailport => 'port_y', to => 'Alphabet', headport => 'port_h', color => 'green',
);

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "record.$id.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
