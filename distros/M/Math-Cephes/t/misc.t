#!/usr/bin/perl

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..33\n";}
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes qw(:misc :constants :trigs);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# util
my $count = 1;
my $eps = 1e-06;
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
my $x = 2.2;
my $n = 3;
ok( zetac($x), .490543257);
ok( zeta($x, $n), .2729056157);
ok( dawsn($x), .2645107600);
my ($flagf, $S, $C) = fresnl($x);
ok( $flagf, 0);
ok( $S, .4557046121);
ok( $C, .6362860449);
my ($flagt, $Si, $Ci) = sici($x);
ok( $flagt, 0);
ok( $Si, 1.687624827);
ok( $Ci, .3750745990);
my ($flagh, $Shi, $Chi) = shichi($x);
ok( $flagh, 0);
ok( $Shi, 2.884902918);
ok( $Chi, 2.847711781);
ok( expn($n, $x), .02352065665);
ok( ei($x), 5.732614700);
ok( spence($x), -.9574053086);
my ($flaga, $ai, $aiprime, $bi, $biprime) = airy($x);
ok( $flaga, 0);
ok( $ai, .02561040442);
ok( $aiprime, -.04049726324);
ok( $bi, 4.267036582);
ok( $biprime, 5.681541770);
ok( erf($x), .9981371537);
ok( erfc($x), .001862846298);
ok( struve($n, $x), .1186957024);
my $r = plancki(0.1, 200);
ok( $r, 90.72805158);
$r = simpson(\&fun, 0, 100, 1e-8, 1e-06, 100);
ok( $r, sin(100));
my ($num, $den) = bernum(16);
ok( $num, -3617);
ok( $den, 510);
($num, $den) = bernum();
ok( $num->[26], 8553103);
ok( $den->[26], 6);
ok( polylog(3, 0.2), 0.2053241957);
ok( polylog(7, 1), 1.008349277);
my $v1 = [1, 2, -1];
my $v2 = [2, -1, 3];
my $c = -3 / sqrt(6) / sqrt(14);
ok( vecang($v1, $v2), acos($c));

sub fun {
  my $x = shift;
  return cos($x);
}
