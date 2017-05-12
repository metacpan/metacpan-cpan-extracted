#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use_ok 'Graph::Implicit';
my $graph = Graph::Implicit->new(sub {});
isa_ok $graph, 'Graph::Implicit';

