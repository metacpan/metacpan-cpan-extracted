package Ops::MathKw;
use strict;
use warnings;
use Ex::Op;

our @EXPORT_OK   = qw(kadd kclamp kname);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

op kadd ($x, $y) { $x + $y }
op kclamp ($v, $lo, $hi) { return $lo if $v < $lo; return $hi if $v > $hi; $v }
sub kname { 'kw' }

1;
