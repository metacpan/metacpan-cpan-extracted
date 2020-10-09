#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
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

my($graph)  = GraphViz2 -> new
	(
	 edge   => {color => 'grey'},
	 global => {directed => 1},
	 graph  => {rankdir => 'LR'},
	 node   => {color => 'green', shape => 'oval'},
	);
my($g)  = GraphViz2::Parse::STT -> new(graph => $graph);
my $stt = read_file(File::Spec -> catfile('t', 'sample.stt.1.dat') );

$g -> create(stt => $stt);

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "parse.stt.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  $graph->run(format => 'dot');
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
