#!/usr/bin/perl -w

use Test::More tests => 17;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  chdir 't' if -d 't';
  use_ok ('Games::3D::Signal', 
    qw/ SIG_ON SIG_OFF STATE_OFF STATE_ON
        SIG_FLIP
	SIG_DIE
	SIG_KILLED
	SIG_UNKNOWN

	SIG_LEFT SIG_RIGHT SIG_UP SIG_DOWN
	SIG_OPEN SIG_CLOSE SIG_ACTIVATE SIG_DEACTIVATE
	SIG_LEVEL_WON
	SIG_LEVEL_LOST

	SIG_STATE_0
	/);
  }

can_ok ('Games::3D::Signal', qw/ 
  invert
  /);

is (Games::3D::Signal->invert(SIG_ON), SIG_OFF, 'ON => OFF');
is (Games::3D::Signal->invert(SIG_OFF), SIG_ON, 'OFF => ON');
is (Games::3D::Signal->invert(SIG_RIGHT), SIG_LEFT, 'R => L');
is (Games::3D::Signal->invert(SIG_LEFT), SIG_RIGHT, 'L => R');
is (Games::3D::Signal->invert(SIG_OPEN), SIG_CLOSE, 'OPEN => CLOSE');
is (Games::3D::Signal->invert(SIG_CLOSE), SIG_OPEN, 'CLOSE => OPEN');
is (Games::3D::Signal->invert(SIG_ACTIVATE), SIG_DEACTIVATE, 'A => DE');
is (Games::3D::Signal->invert(SIG_DEACTIVATE), SIG_ACTIVATE, 'DE => A');

# non-invertable
is (Games::3D::Signal->invert(SIG_DIE), SIG_DIE, 'DIE => DIE');
is (Games::3D::Signal->invert(SIG_FLIP), SIG_FLIP, 'FLIP => FLIP');

is (Games::3D::Signal->invert(SIG_STATE_0), SIG_STATE_0, 'STATE_0 => STATE_0');
is (Games::3D::Signal->invert(SIG_KILLED), SIG_KILLED, 'KILLED => KILLED');

# name from signal, and signal from name

is (Games::3D::Signal::signal_name(SIG_STATE_0), 'SIG_STATE_0(100)', 
  'signal_name');

is (Games::3D::Signal::signal_by_name('SIG_DIE'), SIG_DIE, 
  'signal_from_name');
is (Games::3D::Signal::signal_by_name('SIG_STATE_0'), SIG_STATE_0, 
  'signal_from_name');


