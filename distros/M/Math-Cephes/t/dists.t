#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..23\n";}
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:dists :betas :gammas :constants :misc);
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
  print($error < $eps ? "ok $count $skip ($value)\n" :
	"not ok $count (expected $true: got $value) at $file line $line\n");
}

my $k = 2;
my $n = 10;
my $p = 0.5;
my $y = 0.6;
ok( bdtr($k, $n, $p), incbet($n-$k, $k+1, 1-$p));
ok( bdtrc($k, $n, $p), incbet($k+1, $n-$k, $p));
ok( bdtri($k, $n, $y), 1-incbi($n-$k, $k+1, $y));
ok( btdtr($k, $n, $y), incbet($k, $n, $y));
ok( chdtr($k, $y), igam($k/2, $y/2));
ok( chdtrc($k, $y), igamc($k/2, $y/2));
ok( chdtri($k, $y), 2*igami($k/2, $y));
ok( fdtr($k, $n, $y), incbet($k/2, $n/2,$k*$y/($n + $k*$y)));
ok( fdtrc($k, $n, $y), incbet($n/2, $k/2, $n/($n + $k*$y)));
my $z = incbi( $n/2, $k/2, $p);
ok( fdtri($k, $n, $p), $n*(1-$z)/($k*$z));
ok( gdtr($k, $n, $y), igam($n, $k*$y));
ok( gdtrc($k, $n, $y), igamc($n, $k*$y));
my $w = nbdtr($k, $n, $p);
ok( $w, incbet($n, $k+1, $p));
ok( nbdtrc($k, $n, $p), incbet($k+1, $n, 1-$p));
ok( nbdtri($k, $n, $w), $p);
$w = ndtr($y);
ok( $w, (1+erf($y/sqrt(2)))/2);
ok( ndtri($w), $y);
ok( pdtr($k, $n), igamc($k+1, $n));
ok( pdtrc($k, $n), igam($k+1, $n));
ok( pdtri($k, $y), igami($k+1, $y));
$w = stdtr( $k, $y);
$z = $k/($k + $y*$y);
ok( $w, 1- 0.5*incbet($k/2, 1/2, $z));
ok( stdtri($k, $w), $y);
