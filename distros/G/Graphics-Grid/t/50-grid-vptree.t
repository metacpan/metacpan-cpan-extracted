#!perl

use strict;
use warnings;

use Test2::V0;

use boolean;

use Graphics::Grid;
use Graphics::Grid::ViewportTree;

my $grid = Graphics::Grid->new;
my ( $a, $b, $c, $d, $e, $f, $g ) =
  map { Graphics::Grid::Viewport->new( name => $_ ) } ( 'A' .. 'G' );

is( $grid->current_vptree->stringify,
    'Viewport[ROOT]', 'vptree has a ROOT node' );

$grid->push_viewport($a);
$grid->push_viewport([$b, $c]);
$grid->push_viewport($d, $e);
is(
    $grid->current_vptree->stringify,
'Viewport[ROOT]->(Viewport[A]->(Viewport[B],Viewport[C]->(Viewport[D]->(Viewport[E]))))',
    'push_viewport'
);
is( $grid->current_viewport->name, 'E',
    "current_viewport after push_viewport" );

$grid->up_viewport(2);
is( $grid->current_viewport->name, 'C', 'up_viewport' );
is(
    $grid->current_vptree(false)->stringify,
    'Viewport[C]->(Viewport[D]->(Viewport[E]))',
    'up_viewport does not remove viewports'
);
$grid->up_viewport(0);
is( $grid->current_viewport->name, 'ROOT', 'up_viewport(0)' );

is($grid->down_viewport('E'), 4, "down_viewport returns the depths it went down");
is( $grid->current_viewport->name, 'E', 'down_viewport' );

$grid->pop_viewport(2);
is( $grid->current_viewport->name, 'C', 'pop_viewport' );
is( $grid->current_vptree(false)->stringify,
    'Viewport[C]', 'pop_viewport removes viewports' );

$grid->pop_viewport(0);
is( $grid->current_vptree->stringify, 'Viewport[ROOT]', 'pop_viewport(0)' );

$grid->push_viewport( $a, $b, $a );
$grid->seek_viewport('A');

is(
    $grid->current_vptree(false)->stringify,
    'Viewport[A]->(Viewport[B]->(Viewport[A]))',
    'seek_viewport(name)'
);

$grid->seek_viewport( [qw(B A)] );
is( $grid->current_vptree(false)->stringify,
    'Viewport[A]', 'seek_viewport(path)' );

done_testing;
