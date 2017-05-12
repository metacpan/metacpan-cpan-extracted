#!/usr/bin/perl -w
use strict;
BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>3;

use GraphViz::Data::Structure;

my $gvds;
my($foo, $s);

$gvds = GraphViz::Data::Structure->new(1, Fuzz=>4);

$foo = undef;
$s = $gvds->_dot_escape($foo);
is($s, "undef");

$foo = "this is way too long";
$s = $gvds->_dot_escape($foo);
is($s, "this ...");

$foo="too\nlong\nand newlines";
$s = $gvds->_dot_escape($foo);
is($s, "too ...");
