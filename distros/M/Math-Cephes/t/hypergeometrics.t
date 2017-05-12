#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:hypergeometrics);
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
my $x = 0.1;
my $y = 0.2;
my $z = 0.3;
my $u = 0.4;
ok(hyp2f1($x, $y, $z, $u), 1.03417940155);
ok(hyperg($x, $y, $z), 1.17274559901);


