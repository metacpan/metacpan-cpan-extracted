#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:utils :constants);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# util
my $count = 1;
my $eps = 1e-07;
sub ok {
  local($^W) = 0;
  $count++;
  my ($package, $file, $line) = caller;
  my ($value, $true, $skip) = @_;
  $skip ||= '';
  $skip = "# skip ($skip)" if $skip;
  my $error = sprintf( "%12.8f", abs($value - $true));
  print($error < $eps ? "ok $count $skip\n" :
	"not ok $count (expected $true: got $value) at $file line $line\n");
}

my $x = 5.57;
my $y = -5.43;
ok( ceil($x), 6);
ok( floor($x), 5);
ok( round($x), 6);
ok( ceil($y), -5);
ok( floor($y), -6);
ok( round($y), -5);
ok( sqrt(2), $SQRT2);
ok( sqrt(2/$PI), $SQ2OPI);
ok( cbrt(729), 9);
ok( cbrt(704.969), 8.9);
ok( fabs($y), 5.43);
ok( pow(2,10), 1024);
ok( powi(2,10), 1024);
ok( pow(5,1/3), cbrt(5));
ok( fac(10), 3628800);
my ($z, $expnt) = frexp(6);
ok( $z, .75);
ok( $expnt, 3);
ok( ldexp(.75, 3), 6);
ok( lsqrt(2147483647), 46341);


