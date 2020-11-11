# Annotation: Demonstrates graphing a Set::FA::Element's state transition table.

use strict;
use warnings;
use File::Spec;
use GraphViz2;
use GraphViz2::Parse::STT;

sub read_file {
  open my $fh, '<:encoding(UTF-8)', $_[0] or die "$_[0]: $!";
  local $/;
  <$fh>;
}

my $stt = read_file(File::Spec->catfile('t', 'sample.stt.2.dat'));
my $g = GraphViz2::Parse::STT->new(stt => $stt, mode => 're_structs');

if (@ARGV) {
  my $format = shift || 'svg';
  my $output_file = shift || File::Spec->catfile('html', "parse.stt.$format");
  my $mode = shift; # default in the module
  my $graph = GraphViz2->from_graph(GraphViz2::Parse::STT::graphvizify($g->as_graph, $mode));
  $graph->run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($g->graph->dot_input, 'dot file');
  Test::More::done_testing();
}
