#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:hypers :explog);
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

my $x = 3;
my $y = (exp($x)+exp(-$x))/2;
ok(cosh($x), $y);
ok( acosh($y), $x);
$y = (exp($x)-exp(-$x))/2;
ok( sinh($x), $y);
ok( asinh($y), $x);
$y = 1 - 2/(exp(2*$x)+1);
ok( tanh($x), $y);
ok( atanh($y), $x);
