#!/usr/bin/perl -w

use Test::More tests => 37;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Games::Console');
  }

can_ok ('Games::Console', qw/ 
  new
  message
  text_color text_alpha
  background_color background_alpha
  screen_width
  screen_height
  speed width height
  open close toggle visible
  render
  backbuffer_size cursor prompt
  input add_input backspace last_input autocomplete
  _render
  messages clear
  scroll offset
  /);

my $console = Games::Console->new (
  );

is (ref($console), 'Games::Console', 'new worked');

is (join(',',@{$console->text_color()}), '0.4,0.6,0.8', 'text color');
is ($console->background_alpha(), '0.5', 'background alpha');

is ($console->speed(), '50', 'speed is 50');
is ($console->speed(-1), '1', 'speed is positive');
is ($console->speed(-120), '100', 'speed is < 100');
is ($console->speed(110), '100', 'speed is < 100');

is ($console->width(), '100', 'width is 100');
is ($console->width(10), '10', 'width is 10');
is ($console->width(-1), '1', 'width is positive');
is ($console->width(-120), '100', 'width is < 100');
is ($console->width(110), '100', 'width is < 100');

is ($console->height(), '50', 'h is 50');
is ($console->height(-1), '1', 'h is positive');
is ($console->height(-120), '100', 'h is < 100');
is ($console->height(110), '100', 'h is < 100');

is ($console->prompt(), '> ', 'prompt is ok');
is ($console->prompt('hah!'), 'hah!', 'prompt is ok');

is ($console->cursor(), '_', 'cursor is ok');
is ($console->cursor('||'), '||', 'cursor is ok');

is ($console->input(''), '', 'input is empty');
is ($console->input('hallo'), 'hallo', 'input is ok');
is ($console->input('hallo2'), 'hallo2', 'input is ok');
is ($console->add_input('hallo2'), 'hallo2hallo2', 'input is ok');

is ($console->input('foo'), 'foo', 'input is ok');
is ($console->last_input(), 'hallo2hallo2', 'last input is ok');
$console->input('foo');
is ($console->backspace(), 'fo', 'input was erased');
is ($console->backspace(), 'f', 'input was erased');
is ($console->backspace(), '', 'input was erased');
is ($console->backspace(), '', 'input was erased');

$console->message('hallo');
is ($console->messages(), 1, '1 msg');

is ($console->offset(), 0, 'ofs is 0');
is ($console->scroll(1), 1, 'ofs is 1');
is ($console->offset(), 1, 'ofs is 1');

$console->clear();
is ($console->messages(), 0, 'empty');

