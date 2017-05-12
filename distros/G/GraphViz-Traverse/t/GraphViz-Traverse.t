#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

use lib 'lib';
use_ok 'GraphViz::Traverse';

my $g = eval { GraphViz::Traverse->new };
warn $@ if $@;
isa_ok $g, 'GraphViz::Traverse';
is $g->traverse, undef, 'traverse is undefined';
is $g->edge_color, undef, 'edge_color is undefined';

use_ok 'GraphViz::Traverse::Filesystem';
$g = eval { GraphViz::Traverse::Filesystem->new };
warn $@ if $@;
isa_ok $g, 'GraphViz::Traverse::Filesystem';
ok $g->traverse('.'), 'traverse is defined';
is $g->edge_color, 'gray', 'edge_color is defined';
