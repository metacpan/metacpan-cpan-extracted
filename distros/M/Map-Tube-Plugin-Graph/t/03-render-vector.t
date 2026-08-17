#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use File::Temp;
use File::Spec;
use File::Which;
use Test::Lib;
use Test::More;
use Sample;

sub is_dot_missing {
  # Based on Makefile.PL for GraphViz2
  # 1: Create a temp file containing GraphViz DOT commands.
  # The EXLOCK option is mainly for BSD-based systems running old versions of File::Temp.

  my $temp_dir;
  eval { $temp_dir = File::Temp->newdir( 'temp.XXXX', CLEANUP=>1, EXLOCK=>0, TMPDIR=>1 ) };
  return "Can't create temp directory: $@\n" if $@;
  my ($gv_file)  = File::Spec->catfile( $temp_dir, 'test.gv' );
  open( my $fh, '>', $gv_file )            or return "Can't create temp file: $!";
  print $fh "digraph graph_14 {node_14}\n" or return "Can't write to temp file: $!";
  close($fh)                               or return "Can't close temp file: $!";
  # 2: Attempt to run dot to create an SVG file.
  my $dot_bin = which('dot')               or return "Please install Graphviz from http://www.graphviz.org/";
  open( $fh, '-|', $dot_bin, '-Tsvg', $gv_file );
  my $stdout;
  $stdout .= $_ while (<$fh>);
  close($fh);
  # my $stdout = `$dot_bin -Tsvg $gv_file`;
  # 3: If that failed, we die.
  return "Please install Graphviz from http://www.graphviz.org/" if ($stdout !~ m|</svg>|);
  return;
}

plan skip_all => 'External GraphViz binary is not available - skipping' if is_dot_missing( );

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

my $dataname = File::Spec->catfile( @localdir, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );

plan skip_all => 'SVG not supported by this GraphViz - skipping'  unless grep { lc($_) eq 'svg' } $tube->list_formats( );
plan tests => 6;

my ($diagram, $fname) = $tube->render( format => 'svg' );
like( $diagram, qr/<svg\s/, 'SVG format' );

unlink('xxxtest.svg');
($diagram, $fname) = $tube->render( format => 'svg', output_file => 'xxxtest.svg' );
is( $fname, 'xxxtest.svg', 'SVG with output file' );
unlink($fname);

unlink('test.svg');
($diagram, $fname) = $tube->render( format => 'svg', output_file => undef );
is( $fname, 'test.svg', 'SVG with default output file' );
unlink($fname);

unlink('test_Line_1.svg');
($diagram, $fname) = $tube->render( 'Line 1', format => 'svg', output_file => undef );
like( $diagram, qr/<svg\s/, 'SVG format' );
is( $fname, 'test_Line_1.svg', 'Line with SVG output file' );
unlink($fname);

($diagram, $fname) = $tube->render( 'Line 1', format => 'svg', output_file => undef, line_name => 'Line 2' );
is( $fname, 'test_Line_1.svg', 'Conflicting line name resolution' );
unlink($fname);

done_testing;
