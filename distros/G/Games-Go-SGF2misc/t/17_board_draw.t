# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 17_board_draw.t,v 1.5 2004/03/25 14:56:37 jettero Exp $

use strict;
use Test;
use Games::Go::SGF2misc;

my $sgf = new Games::Go::SGF2misc;

plan tests => 1;

$sgf->parse("sgf/redrose-tartrate.sgf");

my $the_node = $sgf->nodelist;
   $the_node = $the_node->{1}[0];
   $the_node = $the_node->[ $#{ $the_node } ];

my $lhs = $sgf->as_text($the_node) or die $sgf->errstr;

my $rhs = q( . . . . . . . . . . . . . . . . . . .
 . . . X O . . O X . X . O X X X O O .
 . . . X . O . O X O X . O X O O X . .
 . . X . . . . . O X X . . . . . X . .
 . . . . . . . . . O X . O O O X . . .
 . . O . . . . . O . . . O X X X . . .
 . . O . O . O . . . X . X . . . . . .
 . X X O . . . . O O X . X . . X X X .
 . . . X X X X X O X O O O O O O O X .
 . . . . . O . O X X X O O X X O X X .
 . . . X . . . O . . O X O O X X O . .
 . . . . . . . O X X O X X O X O O . .
 . . . . . X X O X . O O X X X X O . .
 . . . X X . O O X O . O X . X . O . .
 . X X X O O . . X O . O X X . O . . .
 X . O O . O O . X . . O O . X . . . .
 O O O . . O . . . X . X O O X X O . .
 . O . . . O O . . . . X O . O X O . .
 O . . O . O . . . . . . . O . O . . .
);

ok($lhs, $rhs);
