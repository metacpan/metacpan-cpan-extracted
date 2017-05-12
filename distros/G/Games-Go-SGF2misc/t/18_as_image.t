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

$sgf->as_image($the_node, {imagesize=>400, filename=>"/dev/null", gobanColor=>[255, 255, 255]}) or die $sgf->errstr;

ok 1;  # a rather weak test, but better than nothing.
