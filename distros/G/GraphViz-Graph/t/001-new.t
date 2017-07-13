#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 4;
use Test::Exception;

use GraphViz::Graph;

dies_ok { GraphViz::Graph->new()  ; } 'Expecting to die';
dies_ok { GraphViz::Graph->new({}); } 'Expecting to die';

my $graph = GraphViz::Graph->new('FileNameBase');

is(ref $graph, 'GraphViz::Graph', 'ref() of thing returned by new');

dies_ok { GraphViz::Graph->new({unrecognized_parameter=>'test'}) } 'passing an unrecognized_parameter should die';
