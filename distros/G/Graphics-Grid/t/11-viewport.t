#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Viewport;
use Graphics::Grid::ViewportTree;

{
    my $vp = Graphics::Grid::Viewport->new( width => 0.5, height => 0.5 );
    ok( $vp, 'construction' );
    is( $vp->name, 'GRID.VP.0', "default name starts with 'GRID.VP.0'" );

    is( Graphics::Grid::Viewport->new()->name,
        'GRID.VP.1', "default name generted is unique'" );
}

# Tree
{
    my ( $a, $b, $c, $d ) =
      map { Graphics::Grid::Viewport->new( name => $_ ) } qw(A B C D);
    my $tree = Graphics::Grid::ViewportTree->new(
        node     => $a,
        children => [
            $b,
            Graphics::Grid::ViewportTree->new(
                node     => $c,
                children => [$d]
            ),
        ]
    );
    is( $tree->stringify,
        'Viewport[A]->(Viewport[B],Viewport[C]->(Viewport[D]))', 'stringify' );
}

done_testing;
