#!/usr/bin/perl -w

use strict;

use Games::Maze;
use Games::Maze::SVG;
use Getopt::Std;

# Parse command line
my %opts = ();

getopts( 'xXs:e:n:o:f:b:i', \%opts ) || usage();

usage() if @ARGV == 1;

my %parms = (
    cols => $ARGV[0] || 12,
    rows => $ARGV[1] || 12,
    ( exists $opts{f} ? ( wallform => $opts{f} ) : () ),
    interactive => $opts{i},
    ( exists $opts{b} ? ( crumb    => $opts{b} ) : () ),
    ( exists $opts{s} ? ( startcol => $opts{s} ) : () ),
    ( exists $opts{e} ? ( endcol   => $opts{e} ) : () ),
);

if ( defined $opts{s} )
{
    unless ( $opts{s} >= 1 and $opts{s} <= $parms{cols} )
    {
        die "Starting column out of range.\n";
    }
}
if ( defined $opts{e} )
{
    unless ( $opts{e} >= 1 and $opts{e} <= $parms{cols} )
    {
        die "Ending column out of range.\n";
    }
}

# Prepare to generate output
my $shape = 'Rect';
$shape = 'RectHex' if $opts{x};
$shape = 'Hex'     if $opts{X};
my $build_maze = Games::Maze::SVG->new( $shape, %parms );

my $out = \*STDOUT;

if ( $opts{o} )
{
    $out = undef;
    open( $out, ">$opts{o}" ) or die "Unable to create $opts{o}: $!";
}

# build maze
my $num = $opts{n} || 1;
print $out $build_maze->toString() while $num-- > 0;

# ----------------------------------------
# Subroutines

# ----------------------
#  Usage message if parameters are messed up.
sub usage
{
    ( my $prog = $0 ) =~ s/^.\///;
    print <<EOH;
Usage: $prog  [-x] [-X] [cols rows [levels]]

where   -x       specifies hexagonal cells
        -X       specifies a hexagonal maze with hexagonal cells
	-s col   what column holds the entrance
	-e col   what column holds the exit
	-f form  wall forms (straight|round|roundcorners|bevel)
	-n num   how many mazes to print.
	-o file  write to a file not the screen
	-i       interactive mode (only for SVG)
	-b style breadcrumb style (dash|dot|line|none)
EOH
    exit 1;
}

