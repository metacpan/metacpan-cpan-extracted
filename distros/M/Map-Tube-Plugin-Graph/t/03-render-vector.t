#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use File::Which;
use Path::Tiny;
use Test::Lib;
use Test::More;
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

plan skip_all => 'External GraphViz binary is not available - skipping' if is_dot_missing( );

my $dataname = path( path($0)->parent, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );

plan skip_all => 'SVG not supported by this GraphViz - skipping'  unless grep { lc($_) eq 'svg' } $tube->list_formats( );
plan tests => 6;

my ($diagram, $fname) = $tube->render( format => 'svg' );
like( $diagram, qr/<svg\s/, 'SVG format' );

path('xxxtest.svg')->remove;
($diagram, $fname) = $tube->render( format => 'svg', output_file => 'xxxtest.svg' );
is( $fname, 'xxxtest.svg', 'SVG with output file' );
unlink($fname);

path('test.svg')->remove;
($diagram, $fname) = $tube->render( format => 'svg', output_file => undef );
is( $fname, 'test.svg', 'SVG with default output file' );
path($fname)->remove;

path('test_Line_1.svg')->remove;
($diagram, $fname) = $tube->render( 'Line 1', format => 'svg', output_file => undef );
like( $diagram, qr/<svg\s/, 'SVG format' );
is( $fname, 'test_Line_1.svg', 'Line with SVG output file' );
path($fname)->remove;

($diagram, $fname) = $tube->render( 'Line 1', format => 'svg', output_file => undef, line_name => 'Line 2' );
is( $fname, 'test_Line_1.svg', 'Conflicting line name resolution' );
path($fname)->remove;

done_testing;
