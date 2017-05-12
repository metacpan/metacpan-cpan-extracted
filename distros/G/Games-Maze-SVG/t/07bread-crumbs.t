#!perl -T

use Test::More tests => 11;

use Games::Maze::SVG;

use strict;
use warnings;

my %crumbstyles = (
    dash => "stroke-width:1px; stroke-dasharray:5px,3px;",
    dot  => "stroke-width:2px; stroke-dasharray:2px,6px;",
    line => "stroke-width:1px;",
    none => "visibility:hidden;",
);


my $maze = Games::Maze::SVG->new();

can_ok( $maze, "set_breadcrumb", "get_crumbstyle" );

foreach my $crumb (keys %crumbstyles)
{
    is( $maze->set_breadcrumb( $crumb ), $maze, "Successfully set crumbs." );
    is( $maze->get_crumbstyle(), $crumbstyles{$crumb}, " ... to $crumb" );
}

eval { $maze->set_breadcrumb( "xyzzy" ); };
like( $@, qr/Unrecognized breadcrumb style 'xyzzy'/, "Bad crumbs stopped." );

ok( !$maze->set_breadcrumb(), "Fail to set with no crumb." );
