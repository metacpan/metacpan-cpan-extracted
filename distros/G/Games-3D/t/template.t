#!/usr/bin/perl -w

use Test::More tests => 16;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  chdir 't' if -d 't';
  use_ok ('Games::3D::Template'); 
  }

can_ok ('Games::3D::Template', qw/ 
  new 
  id class 
  validate validate_key 
  as_string from_string
  add_key keys
  init_thing
  /);

use Games::3D::Thingy;

# create
my $tpl = Games::3D::Template->new ( );

is (ref($tpl), 'Games::3D::Template', 'new worked');
is ($tpl->id(), 1, 'id is 1');

is ($tpl->validate( { id => 9 } ), 
  "Object class 'HASH' does not match template class 'Games::3D::Thingy'",
  'wrong class');

my @lines;
while (my $line = <DATA>) { push @lines, $line; }

is ($tpl->as_string(), join ('',@lines), 'as string');

my $def_keys = 15;
is ($tpl->keys(), $def_keys, '5 defaults');

is ($tpl->add_key('foo', 'STRING="abcdef"'), $tpl, 'added key');
is ($tpl->keys(), $def_keys+1, '6 keys');
is ($tpl->add_key('bar', 'INT=0'), $tpl, 'added key');
is ($tpl->keys(), $def_keys+2, '7 keys');

#print $tpl->as_string(),"\n";

my $foo = Games::3D::Thingy->new( name => 'abcd', );
#print $foo->as_string();

is ($tpl->validate( $foo ), undef, 'validated ok'); 

$foo->{foobar} = 1;

is ($tpl->validate( $foo ), 
  "Invalid key 'foobar' on object Games::3D::Thingy #1", 'not validated'); 

my $clone = 
 Games::3D::Template::from_string( $tpl->as_string(), 'Games::3D::Template' );

is (ref($clone), 'Games::3D::Template', 'from_string worked');

is ($clone->as_string(), $tpl->as_string(), 'clone worked');

##############################################################################
# creation from blueprint

$tpl = Games::3D::Template->new ( class => "Games::3D::Thingy" );

my $thingy = Games::3D::Thingy->new( $tpl );
#print $thingy->as_string();

is ($tpl->validate($thingy), undef, 'validated ok');

1;

__DATA__
Games::3D::Thingy {
  active = BOOL=true
  class = STR=
  id = INT=
  info = STR=
  inputs = ARRAY=0
  name = STR=
  next_think = INT=0
  outputs = ARRAY=0
  state = INT=0
  state_0 = ARRAY=1
  state_1 = ARRAY=1
  state_endtime = INT=
  state_target = INT=
  think_time = INT=0
  visible = BOOL=false
}
