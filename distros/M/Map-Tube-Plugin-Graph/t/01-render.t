#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval {require Map::Tube::London; 1} or plan skip_all => 'This test requires Map::Tube::London';

my $tube = Map::Tube::London->new();
my ($diagram, $fname, $teststr);

($diagram, $fname) = $tube->render( );
$teststr = substr( $diagram, 1, 3);
is( $teststr, 'PNG', 'PNG in binary format' );
ok( !$fname, 'PNG without output file' );

unlink('xxxtest.png');
($diagram, $fname) = $tube->render( output_file => 'xxxtest.png' );
is( $fname, 'xxxtest.png', 'PNG with output file' );
unlink('xxxtest.png');

unlink('London_Tube.png');
($diagram, $fname) = $tube->render( output_file => undef );
is( $fname, 'London_Tube.png', 'PNG with default output file' );
unlink('London_Tube.png');

($diagram, $fname) = $tube->render( output_file => undef, driver => 'neato' );
is( $fname, 'London_Tube.png', 'neato driver' );
unlink('London_Tube.png');

if ($ENV{author_testing}) {
  ($diagram, $fname) = $tube->render( output_file => undef, driver => 'fdp' );
  is( $fname, 'London_Tube.png', 'fdp driver' );
  unlink('London_Tube.png');
} else {
  diag('Skipping lengthy test of fdp driver')
}

($diagram, $fname) = $tube->render( base64 => 1 );
$teststr = substr( $diagram, 0, 5);
is( $teststr, 'iVBOR', 'PNG in base64 format' );

($diagram, $fname) = $tube->render( format => 'dot' );
$teststr = substr( $diagram, 0, 255);
like( $teststr, qr/^digraph\s/, 'DOT format (start)' );
like( $teststr, qr/lwidth=/, 'DOT format - should include formatting instructions' );

($diagram, $fname) = $tube->render( format => 'gv' );
$teststr = substr( $diagram, 0, 255);
like( $teststr, qr/^digraph\s/, 'GV format (start)' );
unlike( $teststr, qr/lwidth=/, 'GV format - should not include formatting instructions' );

($diagram, $fname) = $tube->render( format => 'svg' );
$teststr = substr( $diagram, 0, 1024);
like( $teststr, qr/<svg\s/, 'SVG format' );

unlink('London_Tube_Bakerloo.png');
($diagram, $fname) = $tube->render( 'Bakerloo', output_file => undef );
$teststr = substr( $diagram, 1, 3);
is( $teststr, 'PNG', 'Line with PNG in binary format (1)' );
is( $fname, 'London_Tube_Bakerloo.png', 'Line with default PNG output file (1)' );
unlink($fname);

($diagram, $fname) = $tube->render( output_file => undef, line_name => 'Bakerloo' );
$teststr = substr( $diagram, 1, 3);
is( $teststr, 'PNG', 'Line with PNG in binary format (2)' );
is( $fname, 'London_Tube_Bakerloo.png', 'Line with default PNG output file (2)' );
unlink($fname);

($diagram, $fname) = $tube->render( 'Bakerloo', output_file => undef, line_name => 'Jubilee' );
is( $fname, 'London_Tube_Bakerloo.png', 'Conflicting line name resolution' );
unlink($fname);

done_testing;
