#!/usr/bin/perl -w

use Test::More tests => 10;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Games::OpenGL::Font::2D');
  }

can_ok ('Games::OpenGL::Font::2D', qw/ 
  new output
  color alpha transparent 
  spacing spacing_x spacing_y
  copy zoom
  pre_output
  post_output
  align_x align_y align
  char_width char_height
  border_x border_y
  DESTROY
  /);

my $font = Games::OpenGL::Font::2D->new (
  file => '../data/courier.bmp', color => [ 0,1,0 ], alpha => 0.5
  );

is (ref($font), 'Games::OpenGL::Font::2D', 'new worked');

is (join(',',@{$font->color()}), '0,1,0', 'color');
is ($font->alpha(), '0.5', 'alpha');

my $copy = $font->copy();

is (ref($copy), 'Games::OpenGL::Font::2D', 'copy worked');

is (join(',',@{$font->color(1,1,1)}), '1,1,1', 'color');
is (join(',',@{$font->color([0.4,0.2,0.3])}), '0.4,0.2,0.3', 'color');

is ($font->border_x(), 0, 'border is 0');
is ($font->border_y(), 0, 'border is 0');
 
