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

is int( $mapper->Dx( .5 ) ), '4',       "correct Dx()";
is int( $mapper->Dy( .6 ) ), '3',       "correct Dx()";

is int( $mapper->Dx( 0 ) ), 0,          "correct Dx() sin wave 1/5";
is int( $mapper->Dy( sin(0) ) ), 9,     "correct Dy() sin wave 1/5";

is int( $mapper->Dx( .1 ) ), 0,         "correct Dx() sin wave 2/5";
is int( $mapper->Dy( sin(.1) ) ), 8,    "correct Dy() sin wave 2/5";

is int( $mapper->Dx( .2 ) ), 1,         "correct Dx() sin wave 3/5";
is int( $mapper->Dy( sin(.2) ) ), 7,    "correct Dy() sin wave 3/5";

is int( $mapper->Dx( .3 ) ), 2,         "correct Dx() sin wave 4/5";
is int( $mapper->Dy( sin(.3) ) ), 6,    "correct Dy() sin wave 4/5";

is int( $mapper->Dx( .4 ) ), 3,         "correct Dx() sin wave 5/5";
is int( $mapper->Dy( sin(.4) ) ), 5,    "correct Dy() sin wave 5/5";
