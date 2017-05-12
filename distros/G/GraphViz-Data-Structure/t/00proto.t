#!/usr/bin/perl -w
use strict;
BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>5;

use GraphViz::Data::Structure;
ok(GraphViz::Data::Structure->can('new'), 'new() works');

my $gvds = GraphViz::Data::Structure->new(1);
ok(defined $gvds,                            "new() returns something");
isa_ok($gvds, 'GraphViz::Data::Structure',   "proper object");

my $clone=$gvds->new(2);
ok(defined $clone,                           "protoyped new() returns object");
isa_ok($clone, "GraphViz::Data::Structure",  "proper type");
