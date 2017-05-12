#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..27\n";}
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:bessels);
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
my $x = 2;
my $y = 20;
my $n = 5;
my $v = 3.3;
ok( j0($x), .2238907791);
ok( j0($y), .1670246643);
ok( j1($x), .5767248078);
ok( j1($y), .06683312418);
ok( jn($n, $x), .007039629756);
ok( jn($n, $y), .1511697680);
ok( jv($v, $x), .08901510322);
ok( jv($v, $y), -.02862625778);
ok( y0($x), .5103756726);
ok( y0($y), .06264059681);
ok( y1($x), -.1070324315);
ok( y1($y), -.1655116144 );
ok( yn($n, $x), -9.935989128 );
ok( yn($n, $y), -.1000357679);
ok( yv($v, $x), -1.412002815 );
ok( yv($v, $y), .1773183649);
ok( i0($x), 2.279585302);
ok( i0e($y), .08978031187);
ok( i1($x), 1.590636855 );
ok( i1e($y), .08750622217);
ok( iv($v, $x), .1418012924);
ok( k0($x), .1138938727);
ok( k0e($y), .2785448766 );
ok( k1($x), .1398658818);
ok( k1e($y), .2854254970);
ok( kn($n, $x), 9.431049101)
