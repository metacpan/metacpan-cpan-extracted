# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 17-derivative-eval.t'
use 5.010001;
use Test::Simple tests => 12;

use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my(@coef, $y, $dy, $d2y);

my $fltcmp = generate_fltcmp();

#
# (13)
#
#
# At point 5, even though the equation is a constant.
#
@coef = (13);

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 5);

ok( (&$fltcmp($y, 13) == 0 and
	&$fltcmp($dy, 0) == 0 and
	&$fltcmp($d2y, 0) == 0),
	"   [ " . join(", ", @coef) . " ]");

#
# (4, 21.5)
#
# (a linear equation).
#
# At point 5.
#
@coef = (-4, 21.5);

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 5);

ok( (&$fltcmp($y, 103.5) == 0 and
	&$fltcmp($dy, 21.5) == 0 and
	&$fltcmp($d2y, 0) == 0),
	"   [ " . join(", ", @coef) . " ]");


#
# (1, 0, 0, 0, -1)
#
# At point 5.
#
@coef = (-1, 0, 0, 0, 1);

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 5);

ok( (&$fltcmp($y, 624) == 0 and
	&$fltcmp($dy, 500) == 0 and
	&$fltcmp($d2y, 300) == 0),
	"   [ " . join(", ", @coef) . " ]");

#
# (1, 4, 6, 4, 1)
#
# At point 5.
#
@coef = (1, 4, 6, 4, 1);

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 5);

ok( (&$fltcmp($y, 1296) == 0 and
	&$fltcmp($dy, 864) == 0 and
	&$fltcmp($d2y, 432) == 0),
	"   [ " . join(", ", @coef) . " ]");

#
# (1, -10, 35, -50, 24)
#
# At point 5.
#
@coef = (24, -50, 35, -10, 1);

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 5);

ok( (&$fltcmp($y, 24) == 0 and
	&$fltcmp($dy, 50) == 0 and
	&$fltcmp($d2y, 70) == 0),
	"   [ " . join(", ", @coef) . " ]");

#
# (-31, 14, -16, -14, 1)
#
# At point 5
#
@coef = (1, -14, -16, 14, -31);

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 5);

ok( (&$fltcmp($y, -18094) == 0 and
	&$fltcmp($dy, -14624) == 0 and
	&$fltcmp($d2y, -8912) == 0),
	"   [ " . join(", ", @coef) . " ]");

#
# (4, -20, -7, 49, -70, 7, -53, 90)
#
# At points 5, 3, 1, -1, -3, -5
#
@coef = (90, -53, 7, -70, 49, -7, -20, 4);

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 5);

ok( (&$fltcmp($y, 0) == 0 and
	&$fltcmp($dy, 59892) == 0 and
	&$fltcmp($d2y, 145114) == 0),
	"   [ " . join(", ", @coef) . " ]");

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 3);

ok( (&$fltcmp($y, -5460) == 0 and
	&$fltcmp($dy, -8192) == 0 and
	&$fltcmp($d2y, -7510) == 0),
	"   [ " . join(", ", @coef) . " ]");

($y, $dy, $d2y) = pl_dxevaluate(\@coef, 1);

ok( (&$fltcmp($y, 0) == 0 and
	&$fltcmp($dy, -180) == 0 and
	&$fltcmp($d2y, -390) == 0),
	"   [ " . join(", ", @coef) . " ]");

($y, $dy, $d2y) = pl_dxevaluate(\@coef, -1);

ok( (&$fltcmp($y, 252) == 0 and
	&$fltcmp($dy, -360) == 0 and
	&$fltcmp($d2y, 394) == 0),
	"   [ " . join(", ", @coef) . " ]");

($y, $dy, $d2y) = pl_dxevaluate(\@coef, -3);

ok( (&$fltcmp($y, -15456) == 0 and
	&$fltcmp($dy, 39460) == 0 and
	&$fltcmp($d2y, -79078) == 0),
	"   [ " . join(", ", @coef) . " ]");

($y, $dy, $d2y) = pl_dxevaluate(\@coef, -5);

ok( (&$fltcmp($y, -563220) == 0 and
	&$fltcmp($dy, 760752) == 0 and
	&$fltcmp($d2y, -865686) == 0),
	"   [ " . join(", ", @coef) . " ]");

1;
