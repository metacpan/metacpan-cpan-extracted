#!perl -T

use strict;
use warnings;

use Test::More tests => 8 + 2 * 8 + 2 * (1 + 2 * 3);

use Math::Complex;

use LaTeX::TikZ;

use lib 't/lib';
use LaTeX::TikZ::TestHelper;

using Tikz->formatter(
 format => '%d',
);

my $z = Math::Complex->make(1, 2);

my $p = eval {
 Tikz->point($z);
};
is $@, '', 'creating a point from a Math::Complex object doesn\'t croak';

check $p, 'a point from a Math::Complex object', <<'RES';
\draw (1cm,2cm) ;
RES

$p = eval {
 Tikz->point(1-2*i);
};
is $@, '', 'creating a point from a Math::Complex constant object doesn\'t croak';

check $p, 'a point from a constant Math::Complex object', <<'RES';
\draw (1cm,-2cm) ;
RES

$p = eval {
 Tikz->point;
};
is $@, '', 'creating a point from nothing doesn\'t croak';

check $p, 'a point from nothing', <<'RES';
\draw (0cm,0cm) ;
RES

$p = eval {
 Tikz->point(-7);
};
is $@, '', 'creating a point from a numish constant doesn\'t croak';

check $p, 'a point from a numish constant', <<'RES';
\draw (-7cm,0cm) ;
RES

$p = eval {
 Tikz->point(5,-1);
};
is $@, '', 'creating a point from two numish constants doesn\'t croak';

check $p, 'a point from two numish constants', <<'RES';
\draw (5cm,-1cm) ;
RES

$p = eval {
 Tikz->point([-3, 2]);
};
is $@, '', 'creating a point from an array ref doesn\'t croak';

check $p, 'a point from an array ref', <<'RES';
\draw (-3cm,2cm) ;
RES

$p = eval {
 Tikz->point(
  [1,-1],
  label => 'foo',
 );
};
is $@, '', 'creating a labeled point from an array ref doesn\'t croak';

check $p, 'a labeled point', <<'RES';
\draw (1cm,-1cm) [fill] circle (0.4pt) node[scale=0.20,above] {foo} ;
RES

$p = eval {
 Tikz->point(
  [2,-2],
  label => 'bar',
  pos   => 'below right',
 );
};
is $@, '',
         'creating a labeled positioned point from an array ref doesn\'t croak';

check $p, 'a labeled positioned point', <<'RES';
\draw (2cm,-2cm) [fill] circle (0.4pt) node[scale=0.20,below right] {bar} ;
RES

my $union = eval {
 Tikz->union(
  Tikz->point([ 0, -1 ]),
  Tikz->raw("foo"),
  Tikz->point(9)
 );
};
is          $@,            '',    'creating a simple union path doesn\'t croak';
is_point_ok $union->begin, 0, -1, 'beginning of a simple union path';
is_point_ok $union->end,   9, 0,  'end of a simple union path';

my $path = eval {
 Tikz->union(
  Tikz->join('--' => 1, 2, 3),
  $union,
  Tikz->chain(5 => '--' => [ 6, 1 ]),
 );
};
is          $@,           '',   'creating a complex union path doesn\'t croak';
is_point_ok $path->begin, 1, 0, 'beginning of a complex union path';
is_point_ok $path->end,   6, 1, 'end of a complex union path';
