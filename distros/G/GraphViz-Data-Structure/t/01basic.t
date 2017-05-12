#!/usr/bin/perl -w
use strict;
BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>9;

use GraphViz::Data::Structure;

ok(GraphViz::Data::Structure->can('new'), 'new() works');

my $gvds = GraphViz::Data::Structure->new(1);
ok(defined $gvds,                            "new() returns something");
isa_ok($gvds, 'GraphViz::Data::Structure',   "proper object");

ok($gvds->can('graph'),                      "object can graph()");
ok($gvds->can('was_null'),                   "object can was_null()");

my $g = $gvds->graph();
isa_ok($g, 'GraphViz',                       "graph() returns a GraphViz");

$g = $gvds->graph();
isa_ok($g, 'GraphViz',                       "still returns a GraphViz");

# test "null graph from dot" situation
my @a;
@a = (1,\@a,2);
$gvds = GraphViz::Data::Structure->new(\@a);
isa_ok($gvds, 'GraphViz::Data::Structure',   "weird structure returns object");
TODO: {
 local $TODO = "Some dot implementations can't handle self-ref array elements"; 
ok($gvds->was_null(),                        "dot broken as expected");
}
