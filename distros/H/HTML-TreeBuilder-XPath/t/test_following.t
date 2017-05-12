#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use Test::More tests => 47;

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

test_q( $tree, q{//p[@class="c1"]}, "p1p2");
test_q( $tree, q{//p[@class="c1"]/following::p[1]}, "f1f2");

test_q( $tree, q{//body/descendant::p[1]}, "p1"); 
test_q( $tree, q{//body/descendant::p[2]}, "f1"); 
test_q( $tree, q{//body/descendant::p[3]}, "p2"); 
test_q( $tree, q{//body/descendant::p[4]}, "f2"); 
test_q( $tree, q{//body/descendant::p[5]}, "f3"); 
test_q( $tree, q{//body/descendant::p[6]}, ""  );

test_q( $tree, q{//body/p[1]}, "p1"); 
test_q( $tree, q{//body/p[2]}, "f1"); 
test_q( $tree, q{//body/p[3]}, "p2"); 
test_q( $tree, q{//body/p[4]}, "f2"); 
test_q( $tree, q{//body/p[5]}, "f3"); 
test_q( $tree, q{//body/p[6]}, ""  ); 

test_q( $tree, q{//body//p[1]}, "p1"); 
test_q( $tree, q{//body//p[2]}, "f1"); 
test_q( $tree, q{//body//p[3]}, "p2"); 
test_q( $tree, q{//body//p[4]}, "f2"); 
test_q( $tree, q{//body//p[5]}, "f3"); 
test_q( $tree, q{//body//p[6]}, ""  );

test_q( $tree, q{//p[1]}, "p1"); 
test_q( $tree, q{//p[2]}, "f1"); 
test_q( $tree, q{//p[3]}, "p2"); 
test_q( $tree, q{//p[4]}, "f2"); 
test_q( $tree, q{//p[5]}, "f3"); 
test_q( $tree, q{//p[6]}, ""  ); 

test_q( $tree, q{//a/following::p}, "p1f1p2f2f3"); 

test_q( $tree, q{//p[@class="c1"][1]}, "p1");
test_q( $tree, q{//p[@class="c1"][2]}, "p2");

test_q( $tree, q{//a/following::p[1]}, "p1");
test_q( $tree, q{//a/following::p[2]}, "f1");
test_q( $tree, q{//a/following::p[3]}, "p2");
test_q( $tree, q{//a/following::p[4]}, "f2");
test_q( $tree, q{//a/following::p[5]}, "f3");

test_q( $tree, q{//p[@id="ip1"]/following::p[1]}, "f1");
test_q( $tree, q{//p[@id="ip1"][1]/following::p[1]}, "f1");
test_q( $tree, q{//p[@id="ip1"][1]/following::p[2]}, "p2");
test_q( $tree, q{//p[@id="ip1"][1]/following::p[3]}, "f2");
test_q( $tree, q{//p[@id="ip1"][1]/following::p[4]}, "f3");
test_q( $tree, q{//p[@id="ip3"]/following::p[1]}, "f2");
test_q( $tree, q{//p[@id="ip3"]/following::p[2]}, "f3");

test_q( $tree, q{//p[@class="c1"][1]/following::p[1]}, "f1");
test_q( $tree, q{//p[@class="c1"][1]/following::p[2]}, "p2");
test_q( $tree, q{//p[@class="c1"][1]/following::p[3]}, "f2");
test_q( $tree, q{//p[@class="c1"][1]/following::p[4]}, "f3");
test_q( $tree, q{//p[@class="c1"][2]/following::p[1]}, "f2");
test_q( $tree, q{//p[@class="c1"][2]/following::p[2]}, "f3");

sub test_q
  { my( $tree, $query, $expected)= @_;
    my $class= ref( $tree);
    is( $tree->findvalue( $query), $expected, "$class: $query ($expected)");
  }
