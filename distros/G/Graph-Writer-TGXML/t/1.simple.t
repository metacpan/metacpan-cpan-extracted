#!/usr/bin/env perl -w

use strict;
use Test::More tests => 2;
use Graph;
use Graph::Writer::TGXML;

my @v = qw/Alice Bob Crude Dr/;
my $g = Graph->new;
$g->add_vertices(@v);

my $wr = Graph::Writer::TGXML->new();
$wr->write_graph($g,'t/graph.simple.xml');

my $file;
my $openres = open $file, 't/graph.simple.xml';
ok($openres, "File created");

$/ = undef;
my $g1 = <DATA>;

my $g2 = <$file>;
close($file);

is($g2,$g1, 'Got expected xml content');
unlink('t/graph.simple.xml');

__DATA__
<TOUCHGRAPH_LB version="1.20">
  <NODESET>
    <NODE nodeID="Bob">
      <NODE_LOCATION x="633" y="30" visible="true" />
      <NODE_LABEL label="Bob" shape="2" backColor="FFFFFF" textColor="000000" fontSize="16" />
      <NODE_URL url="" urlIsLocal="false" urlIsXML="false" />
      <NODE_HINT hint="" width="400" height="-1" isHTML="false" />
    </NODE>
    <NODE nodeID="Dr">
      <NODE_LOCATION x="633" y="30" visible="true" />
      <NODE_LABEL label="Dr" shape="2" backColor="FFFFFF" textColor="000000" fontSize="16" />
      <NODE_URL url="" urlIsLocal="false" urlIsXML="false" />
      <NODE_HINT hint="" width="400" height="-1" isHTML="false" />
    </NODE>
    <NODE nodeID="Alice">
      <NODE_LOCATION x="633" y="30" visible="true" />
      <NODE_LABEL label="Alice" shape="2" backColor="FFFFFF" textColor="000000" fontSize="16" />
      <NODE_URL url="" urlIsLocal="false" urlIsXML="false" />
      <NODE_HINT hint="" width="400" height="-1" isHTML="false" />
    </NODE>
    <NODE nodeID="Crude">
      <NODE_LOCATION x="633" y="30" visible="true" />
      <NODE_LABEL label="Crude" shape="2" backColor="FFFFFF" textColor="000000" fontSize="16" />
      <NODE_URL url="" urlIsLocal="false" urlIsXML="false" />
      <NODE_HINT hint="" width="400" height="-1" isHTML="false" />
    </NODE>
  </NODESET>
  <EDGESET></EDGESET>
</TOUCHGRAPH_LB>
