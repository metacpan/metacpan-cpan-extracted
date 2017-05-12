#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..10\n";}
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:elliptics :constants :utils :trigs);
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

my $x = 0.3;
ok( ellpk(1-$x*$x), 1.608048620);
ok( ellik(asin(0.2), $x*$x), .2014795901);
ok( ellpe(1-$x*$x), 1.534833465);
ok( ellie(asin(0.2), $x*$x), .2012363833);
my $phi = $PIO4;
my $m = 0.3;
my $u = ellik($phi, $m);
my ($flag, $sn, $cn, $dn, $phi_out) = ellpj($u, $m);
ok( $flag, 0);
ok( $phi, $phi_out);
ok( $sn, sin($phi_out));
ok( $cn, cos($phi_out));
ok( $dn, sqrt(1-$m*sin($phi_out)*sin($phi_out)));
