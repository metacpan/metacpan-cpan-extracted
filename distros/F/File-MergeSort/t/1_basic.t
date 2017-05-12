#!/usr/bin/perl

use 5.006;
use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok('IO::File') };         # test 1
BEGIN { use_ok('File::MergeSort') };  # test 2

my @files = qw( t/1 t/2 t/3 t/4 );
my $coderef = sub { my $line = shift; substr($line,0,2); };

my $m;
eval {
    $m = File::MergeSort->new( \@files, $coderef );
};

ok( ref $m eq 'File::MergeSort', 'Module instantiated' ); # test 3

my $in_lines = 0;

foreach my $file ( @files ) {
    open my $fh, '<', $file or die "Unable to open test file $file: $!";
    while (<$fh>) { $in_lines++ };
    close $fh or die "Problems closing test file, $file: $!";
}

my $d;

eval {
    $d = $m->dump("t/output");
};

ok( $d eq $in_lines, 'Expected number of lines output reported' ); # test 4

my $out_lines = 0;

open my $fh, '<', 't/output' or die "Unable to open test output: $!";
while (<$fh>) { $out_lines++ };
close $fh or die "Problems closing test output: $!";

ok( $d eq $out_lines, 'Expected number of lines actually output to file' ); # test 5

if (-f "t/output") {
    unlink "t/output" or die "Unable to unlink test output: $!";
}

# Check that records are really output in sort order, then file
# preference order, as documented.

$m = File::MergeSort->new( [ 't/5', 't/6' ], sub { return substr($_[0], 0, 2) } );

my $fail = 0;
my $i = 0;
my ( $last_k, $last_f );
while ( my $line = $m->next_line() ) {
    my ( $key, $file ) = unpack( 'A3A1', $line );
    if ( $i > 0 ) {
        $fail++ unless ( $key ge $last_k && $file ge $last_f );
    }
}

ok( 0 == $fail, 'Records in expected order' ); # test 6

# Read two input files, one with no blank lines, one with. Enable
# skipping of blank records and check for number of lines.

@files = ( 't/6', 't/7' );
$m = File::MergeSort->new( \@files,
			   sub { return substr($_[0], 0, 2 ) },
			   { skip_empty_lines => 1 },
			 );

my $non_blank_lines = 0;

foreach my $file ( @files ) {
    open my $fh, '<', $file or die "Unable to open test file $file: $!";
    while (<$fh>) { $non_blank_lines++ unless /^$/; };
    close $fh or die "Problems closing test file, $file: $!";
}

my $out = $m->dump();

ok( $out == $non_blank_lines,
    'Expected number of lines whilst skip_empty_lines enabled'
  ); # test 7

