use 5.010001;
use Test::More tests => 10;

use Math::Polynomial::Solve qw(:utility);
use strict;
use warnings;

#
# Cue the poly_iteration choices...
#
my @expected_names = qw( hessenberg laguerre newtonraphson sturm_bisection);
my $expectedstr = join(" ", sort @expected_names);
my %ikeys = poly_iteration();
my $ikeystr = join(" ", sort keys %ikeys);

ok( $ikeystr eq $expectedstr,
	"Mis-matched keys, expected '$expectedstr', got '$ikeystr'");

poly_iteration(hessenberg => 200);
%ikeys = poly_iteration();
my $val = $ikeys{hessenberg};
ok($val == 200, "hessenberg option is '$val' didn't get set");

poly_iteration(laguerre => 25);
%ikeys = poly_iteration();
$val = $ikeys{laguerre};
ok($ikeys{laguerre} == 25, "laguerre option is '$val' didn't get set");

poly_iteration(sturm_bisection => 30);
%ikeys = poly_iteration();
$val = $ikeys{sturm_bisection};
ok($ikeys{sturm_bisection} == 30, "sturm_bisection option is '$val' didn't get set");

poly_iteration(hessenberg => 60);
%ikeys = poly_iteration();
$val = $ikeys{hessenberg};
ok($ikeys{hessenberg} == 60, "hessenberg option is '$val' didn't get set");

poly_iteration(laguerre => 65);
%ikeys = poly_iteration();
$val = $ikeys{laguerre};
ok($ikeys{laguerre} == 65, "laguerre option is '$val' didn't get set");

poly_iteration(sturm_bisection => 70);
%ikeys = poly_iteration();
$val = $ikeys{sturm_bisection};
ok($ikeys{sturm_bisection} == 70, "sturm_bisection option is '$val' didn't get set");

#
# Now the poly_tolerance choices.
#
@expected_names = qw( laguerre newtonraphson);
$expectedstr = join(" ", sort @expected_names);
my %tkeys = poly_tolerance();
my $tkeystr = join(" ", sort keys %tkeys);

ok( $tkeystr eq $expectedstr,
	"Mis-matched keys, expected '$expectedstr', got '$tkeystr'");

poly_tolerance(laguerre => 2.9e-10);
%tkeys = poly_tolerance();
$val = $tkeys{laguerre};
ok($tkeys{laguerre} == 2.9e-10, "laguerre option is '$val' didn't get set");

poly_tolerance(newtonraphson => 2.9e-10);
%tkeys = poly_tolerance();
$val = $tkeys{newtonraphson};
ok($tkeys{newtonraphson} == 2.9e-10, "newtonraphson option is '$val' didn't get set");

exit(0);
