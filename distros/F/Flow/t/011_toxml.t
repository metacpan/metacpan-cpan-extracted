#===============================================================================
#
#  DESCRIPTION:  Test export to xml;
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$


use strict;
use warnings;
#use Test::More tests => 1;                      # last test to print
use Test::More ('no_plan');
use Flow::Test;
use_ok('Flow::To::XML');

my $str = "";
my $to_xml = new Flow::To::XML:: \$str;
my $p = $to_xml->parser;
$p->begin;
$p->flow(1..2);
$p->ctl_flow({test=>1});
$p->flow(3..4);
$p->end;
is_deeply_xml $str, 
q#<?xml version="1.0"?>
<FLOW makedby="Flow::To::XML">
  <flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="1">2</key>
        <key name="0">1</key>
      </value>
    </flow_data_struct>
  </flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="test">1</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="1">4</key>
        <key name="0">3</key>
      </value>
    </flow_data_struct>
  </flow>
</FLOW>
#,"export to XML";
