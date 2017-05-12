#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:trigs :constants);
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
my $x = 7*$PI + $PIO4;
my $y = 945;
ok( -sin($x), $SQRTH);
ok( -cos($x), $SQRTH);
ok( tan($x), 1);
ok( cot($x), 1);
ok( acos($SQRTH), $PIO4);
ok( asin($SQRTH), $PIO4);
ok( atan(1), $PIO4);
ok( atan2(sqrt(3), 1), $PI/3);
ok( -sindg($y), $SQRTH);
ok( -cosdg($y), $SQRTH);
ok( tandg($y), 1);
ok( cotdg($y), 1);
ok( radian(359, 59, 60), 2*$PI);
ok( cosm1(0), 0);
ok( hypot(5, 12), 13);
