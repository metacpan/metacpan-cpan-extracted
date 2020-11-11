#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::Prague;
use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(color_line);

my $prague = Map::Tube::Prague->new;

my $graphviz = Map::Tube::GraphViz->new(
        'tube' => $prague,
);

foreach my $line_num (1 .. 25) {
        print "Line number: $line_num\n";
        my $line = Map::Tube::Line->new('id' => 'line'.$line_num);
        my $line_color = color_line($graphviz, $line);
        print "Line color: $line_color\n";
}

# Output:
# Line number: 1
# Line color: red
# Line number: 2
# Line color: green
# Line number: 3
# Line color: yellow
# Line number: 4
# Line color: cyan
# Line number: 5
# Line color: magenta
# Line number: 6
# Line color: blue
# Line number: 7
# Line color: grey
# Line number: 8
# Line color: orange
# Line number: 9
# Line color: brown
# Line number: 10
# Line color: white
# Line number: 11
# Line color: greenyellow
# Line number: 12
# Line color: red4
# Line number: 13
# Line color: violet
# Line number: 14
# Line color: tomato
# Line number: 15
# Line color: cadetblue
# Line number: 16
# Line color: aquamarine
# Line number: 17
# Line color: lawngreen
# Line number: 18
# Line color: indigo
# Line number: 19
# Line color: deeppink
# Line number: 20
# Line color: darkslategrey
# Line number: 21
# Line color: khaki
# Line number: 22
# Line color: thistle
# Line number: 23
# Line color: peru
# Line number: 24
# Line color: darkgreen
# Line number: 25
# Line color: red