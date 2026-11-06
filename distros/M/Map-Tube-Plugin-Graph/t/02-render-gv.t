#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use File::Which;
use Path::Tiny;
use Test::Lib;
use Test::More tests => 11;
use Sample;

sub is_dot_missing {
  # Based on Makefile.PL for GraphViz2
  # 1: Create a temp file containing GraphViz DOT commands.
  # The EXLOCK option is mainly for BSD-based systems running old versions of File::Temp.

  my $temp_dir;
  eval { $temp_dir = Path::Tiny->tempdir( 'temp.XXXX', CLEANUP=>1, EXLOCK=>0, TMPDIR=>1 ) };
  return "Can't create temp directory: $@\n" if $@;
  my $gv_file = path( $temp_dir, 'test.gv' );
  $gv_file->spew("digraph graph_14 {node_14}\n") or return "Can't write to temp file: $!";
  # 2: Attempt to run dot to create an SVG file.
  my $dot_bin = which('dot') or return "Please install Graphviz from http://www.graphviz.org/";
  open( my $fh, '-|', $dot_bin, '-Tsvg', $gv_file );
  my $stdout;
  $stdout .= $_ while (<$fh>);
  close($fh);
  # my $stdout = `$dot_bin -Tsvg $gv_file`;
  # 3: If that failed, we die.
  return "Please install Graphviz from http://www.graphviz.org/" if ($stdout !~ m|</svg>|);
  return;
}

my $res = is_dot_missing( );
if ($res) {
  is( $res, '', 'Availability of the external GraphViz binary' );
  BAIL_OUT('A problem with GraphViz');
}

my $dataname = path( path($0)->parent, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );
my ($diagram, $fname);

($diagram, $fname) = $tube->render( format => 'gv' );
like( $diagram, qr/^digraph\s/, 'GV format (start)' );
unlike( $diagram, qr/pos\s*=/, 'GV format - should not include formatting instructions' );

($diagram, $fname) = $tube->render( format => 'dot' );
like( $diagram, qr/^digraph\s/, 'DOT format (start)' );
like( $diagram, qr/pos\s*=/, 'DOT format - should include formatting instructions' );

path('xxxtest.dot')->remove;
($diagram, $fname) = $tube->render( format => 'dot', output_file => 'xxxtest.dot' );
is( $fname, 'xxxtest.dot', 'DOT with output file' );
path($fname)->remove;

path('test.dot')->remove;
($diagram, $fname) = $tube->render( format => 'dot', output_file => undef );
is( $fname, 'test.dot', 'PNG with default output file' );
path($fname)->remove;

path('test_Line_1.dot')->remove;
($diagram, $fname) = $tube->render( 'Line 1', format => 'dot', output_file => undef );
like( $diagram, qr/^digraph\s/, 'Line with DOT (1)' );
is( $fname, 'test_Line_1.dot', 'Line with DOT output file (1)' );
path($fname)->remove;

($diagram, $fname) = $tube->render( format => 'dot', output_file => undef, line_name => 'Line 1' );
like( $diagram, qr/^digraph\s/, 'Line with DOT (2)' );
is( $fname, 'test_Line_1.dot', 'Line with DOT output file (2)' );
path($fname)->remove;

($diagram, $fname) = $tube->render( 'Line 1', format => 'dot', output_file => undef, line_name => 'Line 2' );
is( $fname, 'test_Line_1.dot', 'Conflicting line name resolution' );
path($fname)->remove;

done_testing;
