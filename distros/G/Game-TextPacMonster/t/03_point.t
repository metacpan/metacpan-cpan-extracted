use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use Game::TextPacMonster::Point;

# test x_coord as getter
{
    my $p = Game::TextPacMonster::Point->new( 5, 100 );
    is( $p->x_coord, 5 );
}

# test x_coord as setter
{
    my $p = Game::TextPacMonster::Point->new( 5, 100 );
    is( $p->x_coord, 5 );
    is( $p->x_coord(20), $p, 'PASS: return same object' );
    is( $p->x_coord, 20 );
}

# test y_coord as getter
{
    my $p = Game::TextPacMonster::Point->new( 5, 100 );
    is( $p->y_coord, 100 );
}

# test y_coord as setter
{
    my $p = Game::TextPacMonster::Point->new( 5, 100 );
    is( $p->y_coord, 100 );
    is( $p->y_coord(125), $p, 'PASS: return same object' );
    is( $p->y_coord, 125 );
}

# test equals
{
    my $p1 = Game::TextPacMonster::Point->new( 5, 100 );
    my $p2 = Game::TextPacMonster::Point->new( 5, 100 );
    my $p3 = Game::TextPacMonster::Point->new( 6, 100 );
    my $p4 = Game::TextPacMonster::Point->new( 5, 101 );
    my $p5 = Game::TextPacMonster::Point->new( 6, 101 );

    ok( $p1->equals($p2) );
    ok( !$p1->equals($p3) );
    ok( !$p1->equals($p4) );
    ok( !$p1->equals($p5) );
}

