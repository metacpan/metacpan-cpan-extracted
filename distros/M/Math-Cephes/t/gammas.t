#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:gammas :constants :utils);
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

my $x = 0.5;
my $euler = 0.57721566490153286061;
my $e = exp(1);
ok( gamma($x), sqrt($PI));
ok( lgam($x), log(sqrt($PI)));
ok( gamma(10), fac(9));
ok( fac(9), 362880);
ok( rgamma($x), 1/sqrt($PI));
ok( psi(1/2), -$euler - 2*$LOGE2);
ok( igam(4,4), 1-71/3*pow($e,-4));
my $p = igamc(4,4);
ok( $p, 71/3*pow($e, -4));
ok( igami(4,$p), 4);
