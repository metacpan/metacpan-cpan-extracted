#!/usr/bin/perl -w
#
# This is an example of using GraphViz::Parse::Yapp
# to graph a simple Yapp grammar (well, the Ruby grammar
# converted to Parse::Yapp) 

use strict;
use lib '../lib';
use GraphViz::Parse::Yapp;

my $g = GraphViz::Parse::Yapp->new('Yapp.output');
$g->as_png("yapp.png");


