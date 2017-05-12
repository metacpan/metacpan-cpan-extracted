use 5.010001;
use Test::More tests => 7;

use Math::Polynomial::Solve qw(:numeric);
use strict;
use warnings;
require "t/coef.pl";

my @options = qw( hessenberg root_function varsubst);
my %okeys = poly_option();
my $keystr = join(" ", sort keys %okeys);

ok( $keystr eq join(" ", sort @options),
	"Mis-matched keys, expected '$keystr'");

poly_option(hessenberg => 0);
%okeys = poly_option();
my $val = $okeys{hessenberg};
ok($val == 0, "hessenberg option is '$val' didn't get set");

poly_option(root_function => 1);
%okeys = poly_option();
$val = $okeys{root_function};
ok($okeys{root_function} == 1, "root_function option is '$val' didn't get set");

poly_option(varsubst => 1);
%okeys = poly_option();
$val = $okeys{varsubst};
ok($okeys{varsubst} == 1, "varsubst option is '$val' didn't get set");

poly_option(hessenberg => 1);
%okeys = poly_option();
$val = $okeys{hessenberg};
ok($okeys{hessenberg} == 1, "hessenberg option is '$val' didn't get set");

poly_option(root_function => 0);
%okeys = poly_option();
$val = $okeys{root_function};
ok($okeys{root_function} == 0, "root_function option is '$val' didn't get set");

poly_option(varsubst => 0);
%okeys = poly_option();
$val = $okeys{varsubst};
ok($okeys{varsubst} == 0, "varsubst option is '$val' didn't get set");


exit(0);
