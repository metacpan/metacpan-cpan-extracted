#!/usr/bin/perl -w

use Test::More tests => 4;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  chdir 't' if -d 't';
  use_ok ('Games::3D::Sensor');
  }

can_ok ('Games::3D::Sensor', qw/ 
  new _init activate deactivate is_active id name
  state output signal add_input add_output
  insert remove container
  link
  and_gate
  delay count
  once invert fixed_output
  when type
  /);
    
use Games::3D::Signal qw/
  SIG_ON SIG_OFF STATE_OFF STATE_ON SIG_ACTIVATE SIG_DEACTIVATE
  SIG_FLIP
 /;

use Games::3D::Sensor qw/
  SENSOR_BELOW SENSOR_BETWEEN 
  COND_UNCOND
  COND_MET
 /;

use Games::3D::Thingy;

my $src = Games::3D::Thingy->new();

$src->health(89);

# Send a signal SIG_ON (only once)
# if the health drops below 15
# Send a SIG_OFF (only once) if it goes outside that
# range (e.g. >= 15).
my $sensor = Games::3D::Sensor->new(
  obj => $src, what => 'health',
  type => SENSOR_BELOW,
  A => 15,
  when => COND_UNCOND,    # default
  );
# Send a signal SIG_ON (every 100 ms) if health is between
# 15 and 45. Don't send any signal if outside that range
my $sensor_2 = Games::3D::Sensor->new(
  obj => $src, what => 'health',
  type => SENSOR_BETWEEN,
  A => 15,
  B => 45,
  repeat => 100,
  count => 0,             # infinitely
  when => COND_MET,
  );

my $link = Games::3D::Link->new();

# link the sensors to an object checking the condition was met
my $dst = Games::3D::Thingy->new();

$link->link($sensor, $dst);
$link->link($sensor_2, $dst);

# network now looks like this:
#
# sensor -------> link --------> dest
#                  ^ 
# sensor_2 --------|
#

is (scalar $dst->inputs(), 1, 'dst has one input');

# Send SIG_FLIP everytime the condition changes
# This could be used to change the color of the health
# bar from green to red everytime the health goes below
# 10, and back to red if it goes over 10.
my $sensor_3 = Games::3D::Sensor->new(
  obj => $src, what => 'health',
  type => SENSOR_BELOW,
  A => 10,
  fixed_output => SIG_FLIP,
);

# link this sensor directly to $dst
$sensor_3->link( $sensor_3, $dst );

# Network now looks like this:
#
# sensor -------> link --------> dest
#                  ^              ^
# sensor_2 --------|              |
#                                 |
# sensor_3 -----------------------|
#

is (scalar $dst->inputs(), 2, 'dst has two inputs');

