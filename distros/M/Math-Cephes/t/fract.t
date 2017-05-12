#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes::Fraction qw(:fract);
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

my $y = fract(5, 6);
my $x = fract(1, 3);
my $z = $x->radd( $y);
ok( $z->n, 7);
ok( $z->d, 6);
$z = $x->rsub($y);
ok( $z->n, -1);
ok( $z->d, 2);
$z = $x->rmul($y);
ok( $z->n, 5);
ok( $z->d, 18);
$z = $x->rdiv( $y);
ok( $z->n, 2);
ok( $z->d, 5);
my @a = mixed_fract($z);
ok( $a[0], 0);
ok( $a[1], 2);
ok( $a[2], 5);
my $n1 = 60;
my $n2 = 144;
@a = euclid($n1, $n2);
ok( $a[0], 12);
ok( $a[1], 5);
ok( $a[2], 12);
$z->n(16);
$z->d(3);
ok( $z->n, 16);
ok( $z->d, 3);
@a = mixed_fract($z);
ok( $a[0], 5);
ok( $a[1], 1);
ok( $a[2], 3);
$x->n(44);
$x->d(55);
ok( $x->n, 44);
ok( $x->d, 55);

