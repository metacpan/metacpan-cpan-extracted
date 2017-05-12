#!/usr/bin/perl -w

use Test::More tests => 17;
use strict;
  
my $c = 'Games::Irrlicht::Thingy'; 

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Games::Irrlicht::Thingy'); 
  }

can_ok ($c, qw/ 
  new _init activate deactivate is_active id name
  /);

my $de = 0; sub _deactivated_thing { $de ++; }
my $ac = 0; sub _activated_thing { $ac ++; }

# create thingy
my $thingy = $c->new ( 'main' );

is (ref($thingy), $c, 'new worked');
is ($thingy->id(), 1, 'id is 1');

is ($thingy->is_active(), 1, 'is active');
is ($de, 0, 'no callback yet');
is ($thingy->deactivate(), 0, 'is deactive');
is ($de, 1, 'callback to app happened');
is ($thingy->deactivate(), 0, 'is still deactive');
is ($de, 1, 'but nocallback happened');

is ($thingy->is_active(), 0, 'is no longer active');
is ($ac, 0, 'no callback yet');
is ($thingy->activate(), 1, 'is active again');
is ($ac, 1, 'callback to app happened');

is ($thingy->activate(), 1, 'is stil active');
is ($ac, 1, 'but no callback happened');

is ($thingy->name(), 'Thingy #1', "knows it's name");

