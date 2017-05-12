#!perl -w
use strict;
use Test::More tests => 27;
use Data::Dumper;

use_ok( 'Games::Tetris' );

my $well = Games::Tetris->new( width => 10,
                               depth => 5 );

$well->print;
isa_ok( $well, 'Games::Tetris' );
is( $well->width, 10, "well width is 10" );
is( $well->depth, 5,  "well depth is 5" );

my $square = $well->new_shape('**',
                              '**');
is_deeply( $square->center, [ 1, 1 ], "square center" );
is_deeply( [ $square->covers(0, 0) ], [ [ -1,  -1, '*'], [ 0, -1, '*'],
                                        [ -1,   0, '*'], [ 0,  0, '*'],
                                      ],
           "square covers");
isa_ok( $square, 'Games::Tetris::Shape' );

ok( !$well->fits( $square, 0, 0 ), "square doesn't fit at 0, 0" );
ok( !$well->fits( $square, 0, 1 ), "square doesn't fit at 0, 1" );
ok( !$well->fits( $square, 1, 0 ), "square doesn't fit at 1, 0" );
ok(  $well->fits( $square, 1, 1 ), "square fits at 1, 1" );

ok( !$well->fits( $square, 10, 1 ), "square doesn't fit at 10, 1" );
ok(  $well->fits( $square, 9, 1 ), "square fits at 9, 1" );

ok( $well->drop( $square, 1, 1 ), "dropped a square at 1, 1" );
$well->print;
ok( $well->drop( $square, 1, 1 ), "dropped a square at 1, 1" );
$well->print;
ok( !$well->drop( $square, 1, 1 ), "couldn't drop a square at 1, 1" );

is_deeply( $well->drop( $square, 3, 1 ), [] );
$well->print;
is_deeply( $well->drop( $square, 5, 1 ), []);
$well->print;
is_deeply( $well->drop( $square, 7, 1 ), []);
$well->print;
is_deeply( $well->drop( $square, 9, 1 ), [ 3, 4 ], "deleted 2 rows");
$well->print;

my $oneblock = Games::Tetris->new( width => 10,
                                   depth => 5 );

is_deeply( $oneblock->drop($square, 1, 1), [], "create oneblock" );
is_deeply( $well->well, $oneblock->well, "right squares are left" );

my $ess = $well->new_shape(' +',
                           '++',
                           '+ ');
isa_ok( $ess, 'Games::Tetris::Shape' );
is_deeply( $ess->center, [ 1, 1 ], "ess center" );
is_deeply( [ $ess->covers(0, 0) ], [                  [  0, -1, '+' ],
                                     [ -1,  0, '+' ], [  0,  0, '+' ],
                                     [ -1,  1, '+' ],
                                   ],
           "ess covers");

ok( $well->drop( $ess, 3, 1 ), "dropped ess at 3, 1");
$well->print;
ok( $well->drop( $ess, 3, 1 ), "dropped ess at 3, 1");
$well->print;

