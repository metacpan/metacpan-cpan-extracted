#!/usr/bin/env perl
use strict;
use warnings;

use lib qw(../lib);
use Graphviz::DSL;

my $graph = graph {
    subgraph {
        name 'cluster_0';
        nodes style => 'filled', color => 'white';
        global style => 'filled', color => 'lightgrey', label => 'process#1';

        route a0 => 'a1';
        route a1 => 'a2';
        route a2 => 'a3';
    };

    subgraph {
        name 'cluster_1';
        nodes style => 'filled';
        global color => 'blue', label => 'process#2';

        route b0 => 'b1';
        route b1 => 'b2';
        route b2 => 'b3';
    };

    route start => [qw/a0 b0/];
    route a1 => 'b3';
    route b2 => 'a3';
    route a3 => [qw/a0 end/];
    route b3 => 'end';

    node 'start', shape => 'Mdiamond';
    node 'end',   shape => 'Mdiamond';
};

$graph->save(path => 'sample', type => 'png');
