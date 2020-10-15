# Annotation: Demonstrates a graph with a 'plaintext' shape.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $id		= 4;
my $html_template = <<'EOF';
<html>
<head><title>Demo %1$s - A server-side image map</title></head>
<body><h1 align = 'center'>Demo %1$s - A server-side image map</h1></body>
</html>
EOF
my $file_main = "gen.map.$id.1.html";
my $file_2 = "gen.map.$id.2.html";
my $file_3 = "gen.map.$id.3.html";
my $graph = GraphViz2->new(
	edge   => {color => 'grey'},
	global => {
		directed	=> 1,
		name		=> 'mainmap',
	},
	graph	=> {rankdir => 'TB'},
	im_meta	=> {
		URL => $file_main,	# Note: URL must be in caps.
	},
	node	=> {shape => 'oval'},
);

$graph->add_node(name => 'source', URL => $file_2);
$graph->add_node(name => 'destination');
$graph->add_edge(from => 'source', to => 'destination', URL => $file_3);

if (@ARGV) {
  my($format)			= shift || 'svg';
  my $output_file = shift || "map.$id.$format";
  my($im_format)		= shift || 'cmapx';
  (my $volume, my $dirname) = File::Spec->splitpath($output_file);
  my $im_output_file = shift || File::Spec->catpath($volume, $dirname, "gen.map.$id.map");
  $graph -> run(format => $format, output_file => $output_file, im_format => $im_format, im_output_file => $im_output_file);
  for ($file_main, $file_2, $file_3) {
    open my $fh, '>', File::Spec->catpath($volume, $dirname, $_) or die "$_: $!";
    print $fh sprintf $html_template, $_;
  }
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
