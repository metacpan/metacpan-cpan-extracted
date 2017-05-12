#!/usr/bin/perl
######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);

BEGIN {$| = 1; print "1..74\n";}
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes::Matrix qw(mat);
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

my $M = Math::Cephes::Matrix->new([ [1, 2, -1], [2, -3, 1], [1, 0, 3]]);
my $B = [2, -1, 10];
my $X = $M->simq($B);
ok( $X->[0], 1);
ok( $X->[1], 2);
ok( $X->[2], 3);
my $C = Math::Cephes::Matrix->new([ [1, 2, 4], [2, 9, 2], [6, 2, 7]]);
my $I = $C->inv();
my $T = $I->mul($C)->coef;
ok( $T->[0]->[0], 1);
ok( $T->[1]->[1], 1);
ok( $T->[2]->[2], 1);
ok( $T->[0]->[1], 0);
ok( $T->[1]->[0], 0);
ok( $T->[2]->[0], 0);
my $V = $M->mul($X);
ok( $V->[0], $B->[0]);
ok( $V->[1], $B->[1]);
ok( $V->[2], $B->[2]);
my $D = $M->add($C)->coef;
ok( $D->[0]->[0], 2);
ok( $D->[1]->[1], 6);
ok( $D->[2]->[2], 10);
ok( $D->[0]->[1], 4);
ok( $D->[1]->[0], 4);
ok( $D->[2]->[0], 7);
$D = $M->sub($C)->coef;
ok( $D->[0]->[0], 0);
ok( $D->[1]->[1], -12);
ok( $D->[2]->[2], -4);
ok( $D->[0]->[1], 0);
ok( $D->[1]->[0], 0);
ok( $D->[2]->[0], -5);
my $H = $C->transp()->coef;
ok( $H->[0]->[0], 1);
ok( $H->[1]->[1], 9);
ok( $H->[2]->[2], 7);
ok( $H->[0]->[1], 2);
ok( $H->[1]->[0], 2);
ok( $H->[2]->[0], 4);
my $R = $M->div($C);
my $Q = $R->mul($C)->coef;
my $Mc = $M->coef;
for (my $i=0; $i<3; $i++) {
    for (my $j=0; $j<3; $j++) {
	ok($Q->[$i]->[$j], $Mc->[$i]->[$j]);
    }
}
$R = $M->mul($C)->coef;
ok( $R->[0]->[0], -1);
ok( $R->[1]->[1], -21);
ok( $R->[2]->[2], 25);
ok( $R->[0]->[1], 18);
ok( $R->[1]->[0], 2);
ok( $R->[2]->[0], 19);

$C->clr();
$R = $C->coef;
ok( $R->[0]->[0], 0);
ok( $R->[2]->[2], 0);
ok( $R->[1]->[0], 0);
ok( $R->[2]->[0], 0);

$C->clr(3);
$R = $C->coef;
ok( $R->[0]->[0], 3);
ok( $R->[2]->[2], 3);
ok( $R->[1]->[0], 3);
ok( $R->[2]->[0], 3);

my $S = Math::Cephes::Matrix->new([ [1, 2, 3], [2, 2, 3], [3, 3, 4]]);
my ($E, $EV1) = $S->eigens();
my $EV = $EV1->coef;
for (my $i=0; $i<3; $i++) {
  my $v = [];
  for (my $j=0; $j<3; $j++) {
    $v->[$j] = $EV->[$i]->[$j];
  }
  my $sv = $S->mul($v);
  for (my $j=0; $j<3; $j++) {
    ok($sv->[$j], $E->[$i]*$v->[$j]);
  }
}

my $Z = $M->new()->coef;
for (my $i=0; $i<3; $i++) {
    for (my $j=0; $j<3; $j++) {
	ok($Z->[$i]->[$j], $Mc->[$i]->[$j]);
    }
}
$Z->[0]->[0] = 5;
ok($Mc->[0]->[0], 1);
ok($Z->[0]->[0], 5);

