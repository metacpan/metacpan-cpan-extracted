#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use Test::More tests => 3;

my $html=q{
<html>
  <head />
  <body>
    <a name="a1">foo</a>
    <p class="c1" id="ip1">p1</p>
    <p id="ip2">f1</p>
    <p class="c1" id="ip3">p2</p>
    <p id="ip4">f2</p>
    <p id="ip5">f3</p>
  </body>
</html>};

my $tree  = HTML::TreeBuilder->new_from_content( $html);

test_q( $tree, q{//p[@class="c1"][2]/preceding::p[1]}, "f1");
test_q( $tree, q{//p[@class="c1"][2]/preceding::p[2]}, "p1");
test_q( $tree, q{//p[@class="c1"][2]/preceding::p}, "p1f1");

sub test_q
  { my( $tree, $query, $expected)= @_;
    my $class= ref( $tree);
    is( $tree->findvalue( $query), $expected, "$class: $query ($expected)");
  }
