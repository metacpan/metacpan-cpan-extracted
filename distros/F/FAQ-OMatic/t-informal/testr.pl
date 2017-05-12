#!/usr/local/bin/perl

use lib '/u/jonh/fom24dev/lib';

use FAQ::OMatic;

#@p = ('x','y','z');
@p = ('-z'=>'z2', '-x'=>'x2', '-y'=>'y2');
my ($x,$y,$z) = FAQ::OMatic::rearrange(['x', 'y', 'z'], @p);
print "x: $x y: $y z: $z\n";
