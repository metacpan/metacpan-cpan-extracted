#!/usr/bin/perl -w

use Games::Maze;
use Games::Maze::SVG;
use CGI;
use strict;

$| = 1;

my $q     = CGI::new();
my %parms = $q->Vars();

# Fixup for new HTML style
my $shape = 'Rect';
if ( $parms{style} )
{
    my @pieces = split( ':', $parms{style} );
    $parms{walls} = $pieces[1];
    $shape = 'RectHex' if $pieces[0] eq "hex";
    $shape = 'Hex'     if $pieces[0] eq "Hex";
}

# extract parameters from command line
my $desc = eval { get_maze_desc( \%parms ); };
if ($@)
{
    my $err = $@;
    print $q->header, $q->start_html, $q->h1($err),
        $q->p("Press back button and try again."), $q->end_html;
    exit 0;
}

# Prepare to generate output
my $build_maze = Games::Maze::SVG->new( $shape, dir => '/svg/', %{$desc} );

my $svg = $build_maze->toString();
print $q->header( -type => "image/svg+xml", -Content_length => length $svg ),
    $svg;

# ----------------------------------------
# Subroutines

# ----------------------
# Get maze description from the parsed \%parms from the cgi request
#
# returns  the description hash
sub get_maze_desc
{
    my $parms = shift;

    my %desc = (
        cols => $parms->{width}  || 12,
        rows => $parms->{height} || 12,
        ( $parms{walls} ? ( wallform => $parms{walls} ) : () ),
        interactive => ( $parms->{playable} || '' ) eq "yes",
        ( $parms{crumb} ? ( crumb => $parms{crumb} ) : () ),
    );

    if ( $parms->{enter} )
    {
        unless ( $parms->{enter} >= 1 and $parms->{enter} <= $desc{cols} )
        {
            die "Starting column out of range.\n";
        }
        $desc{startcol} = $parms->{enter};
    }

    if ( $parms->{exit} )
    {
        unless ( $parms->{exit} >= 1 and $parms->{exit} <= $desc{cols} )
        {
            die "Ending column out of range.\n";
        }
        $desc{endcol} = $parms->{exit};
    }

    ( \%desc );
}
