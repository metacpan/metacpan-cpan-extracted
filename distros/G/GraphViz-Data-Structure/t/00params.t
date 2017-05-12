#!/usr/bin/perl -w
use strict;
BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>25;

use GraphViz::Data::Structure;
ok(GraphViz::Data::Structure->can('new'), 'new() works');

my $gvds;

$gvds = GraphViz::Data::Structure->new(1);
ok(defined $gvds,                            "new() returns something");
isa_ok($gvds, 'GraphViz::Data::Structure',   "proper object");
is($gvds->{Fuzz}, 40,                        "standard fuzz");
is($gvds->{Depth}, undef,                    "standard depth");
is($gvds->{Label}, 'left',                   "standard label");
is($gvds->{Orientation},'horizontal',        "standard orientation");

$gvds = GraphViz::Data::Structure->new(1,Fuzz=>99);
is($gvds->{Fuzz}, 99,                        "custom fuzz");
is($gvds->{Depth}, undef,                    "standard depth");
is($gvds->{Label}, 'left',                   "standard label");
is($gvds->{Orientation},'horizontal',        "standard orientation");

$gvds = GraphViz::Data::Structure->new(1,Depth=>20);
is($gvds->{Fuzz}, 40,                        "standard fuzz");
is($gvds->{Depth}, 20,                       "custom depth");
is($gvds->{Label}, 'left',                   "standard label");
is($gvds->{Orientation},'horizontal',        "standard orientation");

$gvds = GraphViz::Data::Structure->new(1,Label=>'right');
is($gvds->{Fuzz}, 40,                        "standard fuzz");
is($gvds->{Depth}, undef,                    "standard depth");
is($gvds->{Label}, 'right',                  "custom label");
is($gvds->{Orientation},'horizontal',        "standard orientation");

$gvds = GraphViz::Data::Structure->new(1,Orientation=>'vertical');
is($gvds->{Fuzz}, 40,                        "standard fuzz");
is($gvds->{Depth}, undef,                    "standard depth");
is($gvds->{Label}, 'left',                   "standard label");
is($gvds->{Orientation},'vertical',          "custom orientation");

$gvds = GraphViz::Data::Structure->add(1);
ok(defined $gvds,                            "add() returns something");
isa_ok($gvds, 'GraphViz::Data::Structure',   "proper object");
