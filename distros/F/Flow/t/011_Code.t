#===============================================================================
#
#  DESCRIPTION:  test Code Flow mod
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$

use strict;
use warnings;
use Test::More tests => 3;                      # last test to print
#use Test::More ('no_plan');
use Flow::Test;
use Data::Dumper;
use Flow::To::XML;
use_ok('Flow::Code');
{
my $c1 = new Flow::Code:: {
    flow => sub { my $self = shift; $self->{count_}++ for @_; return},
    end => sub {
          my $self = shift;
          $self->put_flow( $self->{count_} );
          [@_]
    }
};
my $str;
Flow::create_flow( $c1, new Flow::To::XML::(\$str) );
$c1->run(1..1000);
is_deeply_xml  $str, 
q#<FLOW makedby="Flow::To::XML">
  <flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">1000</key>
      </value>
    </flow_data_struct>
  </flow>
</FLOW>#, 'make count'
}

{
    my $s1;
    my $f = new Flow::;
    Flow::create_flow( $f, sub { [1] }, new Flow::To::XML::(\$s1));
    $f->run(1);

is_deeply_xml $s1, q#<?xml version="1.0" encoding="UTF-8"?>
<FLOW makedby="Flow::To::XML">
  <flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">1</key>
      </value>
    </flow_data_struct>
  </flow>
</FLOW>#, 'check create_flow for anon subs'
}
