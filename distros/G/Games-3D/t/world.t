#!/usr/bin/perl -w

use Test::More tests => 19;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  chdir 't' if -d 't';
  use_ok ('Games::3D::World'); 
  }

can_ok ('Games::3D::World', qw/ 
  new load_from_file save_to_file reload
  load_templates save_templates
  ID _reset_ID
  update render register unregister
  things thinkers
  time
  /);

# create world
my $world = Games::3D::World->new ( );

is ($world->things(), 0, 'empty');
is (ref($world), 'Games::3D::World', 'new worked');
is ($world->id(), 0, 'world has ID 0');

is ($world->update(0), $world, 'updated');

my $rendered = 0;
is ($world->render(0, sub { $rendered++ }), $world, 'rendered');

is ($rendered, 0, 'none so far');
is ($world->time(), 0, 'world time is 0');

##############################################################################
# load templates from file

$world->load_templates('data/templates.txt');
is ($world->templates(), 9, 'nine templates');

##############################################################################
# create some test objects

my $test_object = $world->create('Physical::Light');

is (ref($test_object), 'Games::3D::Thingy', 'create object');
is ($test_object->get('class'), 'Physical::Light', "field class is set");

foreach my $t (qw/r g b a/)
  {
  is ($test_object->get($t), 0, "field $t exists and is zero");
  }

my $test_link = $world->create('Virtual::Link');

is (ref($test_link), 'Games::3D::Link', 'create link');
is ($test_link->get('class'), 'Virtual::Link', "field class is set");

##############################################################################
# check that templates are hirachical: 

$test_object = $world->create('Physical::Light');

is ($test_object->get('model'), 'default.md2',
  'Physical::Light inherits from Physical')

