#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use File::Temp;
use File::Spec;
use File::Which;
use Test::Lib;
use Test::More tests => 11;
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

my $res = is_dot_missing( );
if ($res) {
  is( $res, '', 'Availability of the external GraphViz binary' );
  BAIL_OUT('A problem with GraphViz');
}

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

my $dataname = File::Spec->catfile( @localdir, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );
my ($diagram, $fname, $teststr);

($diagram, $fname) = $tube->render( format => 'gv' );
$teststr = substr( $diagram, 0, 255 );
like( $teststr, qr/^digraph\s/, 'GV format (start)' );
unlike( $teststr, qr/lwidth=/, 'GV format - should not include formatting instructions' );

($diagram, $fname) = $tube->render( format => 'dot' );
$teststr = substr( $diagram, 0, 255 );
like( $teststr, qr/^digraph\s/, 'DOT format (start)' );
like( $teststr, qr/lwidth=/, 'DOT format - should include formatting instructions' );

unlink('xxxtest.dot');
($diagram, $fname) = $tube->render( format => 'dot', output_file => 'xxxtest.dot' );
is( $fname, 'xxxtest.dot', 'DOT with output file' );
unlink($fname);

unlink('test.dot');
($diagram, $fname) = $tube->render( format => 'dot', output_file => undef );
is( $fname, 'test.dot', 'PNG with default output file' );
unlink($fname);

unlink('test_Line_1.dot');
($diagram, $fname) = $tube->render( 'Line 1', format => 'dot', output_file => undef );
$teststr = substr( $diagram, 0, 255 );
like( $teststr, qr/^digraph\s/, 'Line with DOT (1)' );
is( $fname, 'test_Line_1.dot', 'Line with DOT output file (1)' );
unlink($fname);

($diagram, $fname) = $tube->render( format => 'dot', output_file => undef, line_name => 'Line 1' );
$teststr = substr( $diagram, 0, 255 );
like( $teststr, qr/^digraph\s/, 'Line with DOT (2)' );
is( $fname, 'test_Line_1.dot', 'Line with DOT output file (2)' );
unlink($fname);

($diagram, $fname) = $tube->render( 'Line 1', format => 'dot', output_file => undef, line_name => 'Line 2' );
is( $fname, 'test_Line_1.dot', 'Conflicting line name resolution' );
unlink($fname);

done_testing;
