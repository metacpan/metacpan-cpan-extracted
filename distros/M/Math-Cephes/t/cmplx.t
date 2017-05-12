#!/usr/bin/perl
use strict;
use warnings;
######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use vars qw($loaded);
BEGIN {$| = 1; print "1..50\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:hypers :trigs :constants);
#use Math::Cephes::Complex qw(:cmplx);
use Math::Cephes::Complex;
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

my $y = Math::Cephes::Complex->new(1,3);
my $x = new Math::Cephes::Complex(5,6);
my $z = $x->cadd($y);
ok( $z->r, 6);
ok( $z->i, 9);
$z = $x->csub($y);
ok( $z->r, 4);
ok( $z->i, 3);
$z = $x->cmul($y);
ok( $z->r, -13);
ok( $z->i, 21);
$z = $x->cdiv( $y);
ok( $z->r, 2.3);
ok( $z->i, -0.9);
$z = $z->cneg;
ok( $z->r, -2.3);
ok( $z->i, 0.9);
$z = $x->cmov;
ok( $z->r, 5);
ok( $z->i, 6);
ok( $z->cabs, sqrt(61));
$z = $x->clog;
ok( $z->r, log(hypot(5,6)));
ok( $z->i, atan2(6,5));
$z = $x->cexp;
ok( $z->r, exp(5)*cos(6));
ok( $z->i, exp(5)*sin(6));
$z = $x->csin;
my $d = new Math::Cephes::Complex(sin(5)*cosh(6), cos(5)*sinh(6));
ok( $z->r, $d->r);
ok( $z->i, $d->i);
$z = $d->casin;
ok( $z->r, 5-2*$PI);
ok( $z->i, 6);
$d = new Math::Cephes::Complex(cos(5)*cosh(6), -sin(5)*sinh(6));
$z = $x->ccos;
ok( $z->r, $d->r);
ok( $z->i, $d->i);
$z = $d->cacos;
ok( $z->r, 5-2*$PI);
ok( $z->i, 6);
my $den = cos(10) + cosh(12);
$d = new Math::Cephes::Complex(sin(10)/$den, sinh(12)/$den);
$z = $x->ctan;
ok( $z->r, $d->r);
ok( $z->i, $d->i);
$z = $d->catan;
ok( $z->r, 5-2*$PI);
ok( $z->i, 6);
$z = $x->ccot;
$den = cosh(12) - cos(10);
ok( $z->r, sin(10)/$den);
ok( $z->i, -sinh(12)/$den);
$z = $x->csqrt;
ok( $z->r, 3/$z->i);
ok( $z->i, sqrt( ( sqrt(61) - 5 ) / 2 ) );
$d = new Math::Cephes::Complex(2,3);
$z = $d->csinh;
ok( $z->r, sinh(2)*cos(3));
ok( $z->i, cosh(2)*sin(3));
$y = $z->casinh;
ok( $y->r, 2);
ok( $y->i, 3);
$z = $d->ccosh;
ok( $z->r, cosh(2)*cos(3));
ok( $z->i, sinh(2)*sin(3));
$y = $z->cacosh;
ok( $y->r, 2);
ok( $y->i, 3);
$den = cosh(4) + cos(6);
$z = $d->ctanh;
ok( $z->r, sinh(4)/$den);
ok( $z->i, sin(6)/$den);
$y = $z->catanh;
ok( $y->r, 2);
ok( $y->i, 3-$PI);
$d = new Math::Cephes::Complex(4,5);
$z = $d->cpow( $y);
my $c = $d->clog;
my $f = $y->cmul( $c);
my $g = $f->cexp;
ok( $z->r, $g->r);
ok( $z->i, $g->i);
$x->r(55);
$x->i(66);
ok( $x->r, 55);
ok( $x->i, 66);
