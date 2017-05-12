#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:betas :constants :gammas);
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
my $y = 2.2;
my $u = 0.3;
my $z = beta($x, $y);
ok( $z, gamma($x)*gamma($y)/gamma(7.77));
ok( lbeta($x, $y), log($z));
$z = incbet($x, $y, $u);
ok( $z, 0.00761009624);
ok( incbi($x, $y, $z), $u);
