#!perl

use warnings;
use strict;
use 5.010;

use lib 't';
use Test::More;
use Lab::Test import => ['is_pdl'];

use File::Temp qw/tempfile/;
use Lab::Moose::DataFile::Read;
use Data::Dumper;
use PDL;

my ( undef, $file ) = tempfile();
open my $fh, '+>', $file
    or die "cannot open";

print {$fh} <<"EOF";
# x y
1 2
3\t4
\t
5 6
7 8
9  10
EOF

my @cols
    = read_gnuplot_format( fh => $fh, type => 'columns', num_columns => 2 );

my $cols = cat(@cols);
$cols->slice('2,:') .= 42;    # Cannot compare Nans
my $expected = pdl( [ [ 1, 3, 42, 5, 7, 9 ], [ 2, 4, 42, 6, 8, 10 ] ] );

is_pdl( $cols, $expected, "read 2 columns" );

print {$fh} "11 12\n";
close $fh;

@cols = read_gnuplot_format(
    file        => $file, type => 'columns',
    num_columns => 2
);
$cols = cat(@cols);
$cols->slice('2:3,:') .= 42;
$expected = pdl(
    [
        [ 1, 3, 42, 42, 5, 7, 9,  11 ],
        [ 2, 4, 42, 42, 6, 8, 10, 12 ]
    ]
);

is_pdl( $cols, $expected, "added one more line" );

done_testing();

