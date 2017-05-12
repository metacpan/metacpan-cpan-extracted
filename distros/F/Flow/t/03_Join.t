#===============================================================================
#
#  DESCRIPTION:  Test Flow::Join mod
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package Record;
use base 'Flow';

sub flow {
    my $self = shift;
    push @{ $self->{recs} }, @_;
}
1;

package RR;
use base 'Flow';
1;

package count_begin_end;
use base 'Flow';

sub begin {
    my $self = shift;
    $self->{b}++;
    return $self->SUPER::begin(@_);
}

sub end {
    my $self = shift;
    $self->{e}++;
    return $self->SUPER::end(@_);
}

sub count {
    my $self = shift;
    return $self->{e} + $self->{b};
}
1;

package main;
#use Test::More('no_plan');
use strict;
use warnings;
use Flow::Test;
use Data::Dumper;

use Test::More tests => 5;                      # last test to print

use_ok('Flow::Join');
use_ok('Flow::Splice');

{

    my $n = new Flow::NamedPipesPack( name => "Test" );
    my $s;
    my $x = new Flow::To::XML:: \$s;
    Flow::create_flow( $n, $x );
    $x->parser->begin;
    $n->run(1);
    $x->parser->end;
    is_deeply_xml $s, q#<?xml version="1.0" encoding="UTF-8"?>
<FLOW makedby="Flow::To::XML">
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">1</key>
            <key name="name">Test</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
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
        <key name="0">
          <value type="hashref">
            <key name="stage">2</key>
            <key name="name">Test</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
</FLOW>#, 'NamedPipesPack'
}

{
    my $s;
    my $f1 = new Flow::Splice:: 20;
    my $f2 = new Flow::Splice:: 20;

    my $j = new Flow::Join::( Data => $f1, Meta => $f2 );

    my $flw = Flow::create_flow( $j, ToXML => \$s );
    $flw->parser->begin;
    $flw->parser->flow( 1 .. 2 );
    $flw->parser->ctl_flow(60);
    $flw->parser->flow( 1 .. 2 );
    $flw->parser->end;
    is_deeply_xml $s, q#<?xml version="1.0" encoding="UTF-8"?>
<FLOW makedby="Flow::To::XML">
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">1</key>
            <key name="name">Data</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
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
            <key name="stage">2</key>
            <key name="name">Data</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">3</key>
            <key name="name">Data</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">60</key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">4</key>
            <key name="name">Data</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">1</key>
            <key name="name">Meta</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
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
            <key name="stage">2</key>
            <key name="name">Meta</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">3</key>
            <key name="name">Meta</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">60</key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">4</key>
            <key name="name">Meta</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">1</key>
            <key name="name">Data</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
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
            <key name="stage">2</key>
            <key name="name">Data</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">1</key>
            <key name="name">Meta</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
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
            <key name="stage">2</key>
            <key name="name">Meta</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
</FLOW>#, 'join named pipes'

}

{
    my ( $s, $s1 );
    my $f1 = Flow::create_flow(
        Splice => 200,
        Join   => {
            Data => Flow::create_flow(
                sub {
                    return [ grep { $_ > 10 } @_ ];
                },
                Splice => 10

            ),
            Min => Flow::create_flow(
                sub {
                    return [ grep { $_ == 1 } @_ ];
                },
                Splice => 40,
            )
        },
        ToXML  => \$s,
    );
    $f1->run( 1, 3, 11 );
is_deeply_xml $s,
q#<?xml version="1.0" encoding="UTF-8"?>
<FLOW makedby="Flow::To::XML">
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">1</key>
            <key name="name">Min</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
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
        <key name="0">
          <value type="hashref">
            <key name="stage">2</key>
            <key name="name">Min</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">1</key>
            <key name="name">Data</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
  <flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">11</key>
      </value>
    </flow_data_struct>
  </flow>
  <ctl_flow>
    <flow_data_struct>
      <value type="arrayref">
        <key name="0">
          <value type="hashref">
            <key name="stage">2</key>
            <key name="name">Data</key>
            <key name="type">named_pipes</key>
          </value>
        </key>
      </value>
    </flow_data_struct>
  </ctl_flow>
</FLOW>#, "Join and grep"
}

