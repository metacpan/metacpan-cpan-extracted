#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 13;

use Math::Window2Viewport;

my $mapper = new_ok 'Math::Window2Viewport', [
    Wb => 0, Wt => 1, Wl => 0, Wr => 1,
    Vb => 9, Vt => 0, Vl => 0, Vr => 9,
];

is int( $mapper->Dx( .5 ) ), '4',   "correct Dx()";
is int( $mapper->Dy( .6 ) ), '3',   "correct Dx()";

my ($x, $y);

$x = 0;
$y = sin( $x );
is int( $mapper->Dx( $x ) ), 0,   "correct Dx() sin wave 1/5";
is int( $mapper->Dy( $y ) ), 9,   "correct Dy() sin wave 1/5";

$x = 0.1;
$y = sin( $x );
is int( $mapper->Dx( $x ) ), 0,   "correct Dx() sin wave 2/5";
is int( $mapper->Dy( $y ) ), 8,   "correct Dy() sin wave 2/5";

$x = 0.2;
$y = sin( $x );
is int( $mapper->Dx( $x ) ), 1,   "correct Dx() sin wave 3/5";
is int( $mapper->Dy( $y ) ), 7,   "correct Dy() sin wave 3/5";

$x = 0.3;
$y = sin( $x );
is int( $mapper->Dx( $x ) ), 2,   "correct Dx() sin wave 4/5";
is int( $mapper->Dy( $y ) ), 6,   "correct Dy() sin wave 4/5";

$x = 0.4;
$y = sin( $x );
is int( $mapper->Dx( $x ) ), 3,   "correct Dx() sin wave 5/5";
is int( $mapper->Dy( $y ) ), 5,   "correct Dy() sin wave 5/5";
