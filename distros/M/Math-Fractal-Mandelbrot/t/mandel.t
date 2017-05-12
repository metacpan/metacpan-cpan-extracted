#!/usr/bin/perl -w

use Test::More tests => 12;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  # unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Math::Fractal::Mandelbrot');
  }

my $c = 'Math::Fractal::Mandelbrot';

can_ok ($c, qw/ 
   point
   hor_line ver_line
   set_bounds set_limit set_max_iter set_epsilon
  /);

is ($c->point (320,200), 0, '0,0 is in the set');
is ($c->point (0,0), 1, '-2,-2 is not in the set');

is ($c->point (0,0), 1, '-2,-2 is not in the set');

is ($c->set_max_iter(800), 800, 'can set max_iter');
is ($c->set_epsilon(0.01), 0.01, 'can set epsilon');
is ($c->set_limit(25), 25, 'can set limt');

my $line;
$line = $c->hor_line (0,0,10);
is (scalar @$line, 11, 'got 11 values for hor');
is ($line->[-1], 10, 'got 10 equal values for hor');

use Data::Dumper; print Dumper $line;

$line = $c->ver_line (0,0,10);
is (scalar @$line, 11, 'got 11 values for ver');
is ($line->[-1], 10, 'got 10 equal values for ver');

use Data::Dumper; print Dumper $line;

