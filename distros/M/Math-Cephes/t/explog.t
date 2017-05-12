#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:explog :utils :constants);
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

my $e = exp(1);
ok( log(pow($e, $e)), $e);
ok( log($e*$e), 2);
ok( 1/log(2), $LOG2E);
ok( exp(-1), 1/$e);
ok( exp($LOGE2), 2);
ok( log10(10000), 4);
ok( log10(sqrt(10)), 0.5);
ok( exp2(-1/2), $SQRTH);
ok( exp2(8), 256);
ok( log2($SQRT2), 0.5);
ok( log2(256), 8);
ok( log1p(0.5), log(1.5));
ok( expm1(0.5), exp(0.5)-1);
ok( expxx(0.5), exp(0.25));
ok( expxx(2, -1), exp(-4));
