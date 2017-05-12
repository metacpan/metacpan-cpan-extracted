#===============================================================================
#
#  DESCRIPTION:  Test import from XML
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$

#use Test::More('no_plan');
use strict;
use warnings;
use Flow;
use Flow::Test;
use Data::Dumper;
use Test::More tests => 3;                      # last test to print

use_ok('Flow::From::XML');
my $s;
my $p = Flow::create_flow( ToXML=>\$s)->parser;
$p->begin;
$p->flow(1);
$p->ctl_flow(2);
$p->flow(3);
$p->end;
is_deeply_xml $s,
q#<?xml version="1.0" encoding="UTF-8"?>
<FLOW makedby="Flow::To::XML">
  <flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">1</key>
      </value>
    </flow_data_struct>
  </flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">2</key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">3</key>
      </value>
    </flow_data_struct>
  </flow>
</FLOW>#, "generate XML";
my $t = $s;
my $rec_sub = sub { my $self = shift; push @{ $self->{__rec} }, @_ ; \@_};
my $record = new Flow::Code:: flow=>$rec_sub, ctl_flow=>$rec_sub;
my $p1 = Flow::create_flow( new Flow::From::XML::( \$t) , $record);
$p1->run();
is_deeply  $record->{__rec}, [1..3], 'restore from XML'


