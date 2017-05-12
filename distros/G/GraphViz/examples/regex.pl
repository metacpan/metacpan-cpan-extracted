#!/usr/bin/perl -w
#
# An example of visualising a regular expression using GraphViz::Regex

use strict;
use lib '../lib';
use GraphViz::Regex;

#my $regex = '((a{0,5}){0,5}){0,5}[c]';
#my $regex = '([ab]c)+';
#my $regex = '^([abcd0-9]+|foo)';
#my $regex = '(?-imsx:(?ms:((?<=foo)|(?=ae|io|u))?(?(1)bar|\x20{4,6})))';
#my $regex = '[\d]';
#my $regex = '()ef';
#my $regex = 'a(?:b|c|d){6,7}(.)';
#my $regex = '(x)?(?(1)b|a)'; # error!
my $regex = '^([0-9a-fA-F]+)(?:x([0-9a-fA-F]+)?)(?:x([0-9a-fA-F]+))?'; # pretty

my $graph = GraphViz::Regex->new($regex);

#warn $graph->_as_debug;
$graph->as_png("regex.png");
