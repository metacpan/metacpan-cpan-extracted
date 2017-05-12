#!/usr/bin/perl -w
#
# This is a simple example which provides an 
# alternative way of displaying a data structure
# than Data::Dumper

use strict;
use lib '../lib';
use GraphViz::Data::Grapher;

my(@d);

#@d = qw(3 1 4 1);
#@d = ([3, 1, 4, 1], 9, 9, 9);
#@d = ([3, 1, 4, 1], "foo", \"bar", \3.141, [[3]]);
#@d = ({ a => '3', b => '4'});
#@d = ("red", { a => [3, 1, 4, 1], b => { q => 'a', w => 'b'}}, "blue", undef, GraphViz::Data::Grapher->new(), 2);
@d = ("red", { a => [3, 1, 4, 1], b => { q => 'a', w => 'b'}}, "blue", undef);

my $graph = GraphViz::Data::Grapher->new(\@d);

$graph->as_png("dumper.png");

#use Data::Dumper;
#warn Dumper(\@d);
