#!/usr/bin/perl -w

use Test::More tests => 5;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Games::Console::OpenGL');
  }

can_ok ('Games::Console::OpenGL', qw/ 
  new
  message
  text_color text_alpha
  background_color background_alpha
  open close visible toggle
  screen_width
  screen_height
  render
  backbuffer_size cursor prompt
  input add_input backspace
  _render
  /);

my $console = Games::Console::OpenGL->new (
  );

is (ref($console), 'Games::Console::OpenGL', 'new worked');

is (join(',',@{$console->text_color()}), '0.4,0.6,0.8', 'text color');
is ($console->background_alpha(), '0.5', 'background alpha');

