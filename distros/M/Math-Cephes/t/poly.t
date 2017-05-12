#!/usr/bin/perl
######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';
use strict;
use warnings;
use vars qw($loaded);
BEGIN {$| = 1; print "1..156\n";}
END {print "not ok 1\n" unless $loaded;}
use Math::Cephes::Polynomial qw(poly);
$loaded = 1;
print "ok 1\n";
######################### End of black magic.
my $count = 1;
my $eps = 1e-07;
sub ok {
  local($^W) = 0;
  $count++;
  my ($package, $file, $line) = caller;
  my($value, $true, $skip) = @_;
  $skip ||= '';
  $skip = "# skip ($skip)" if $skip;
  my $error = sprintf( "%12.8f", abs($value - $true));
  print($error < $eps ? "ok $count $skip\n" :
	"not ok $count (expected $true: got $value) at $file line $line\n");
}

eval {require Math::Complex; import Math::Complex qw(Re Im);};
my $skip_mc;
$skip_mc = 'no Math::Complex' if $@;
eval {local $^W=0; require Math::Fraction; };
my $skip_mf;
$skip_mf = 'no Math::Fraction' if $@;

my $a = Math::Cephes::Polynomial->new([1,-2,3]);
$a->clr(2);
ok( $a->coef->[0], 0);
my $b = Math::Cephes::Polynomial->new([1,2,3]);
my $c = [4,6,6,7];
my $d = $b->add($c)->coef;
ok( $d->[0], 5);
ok( $d->[1], 8);
$c = Math::Cephes::Polynomial->new($c);
my $e = $c->sub($b);
ok( $e->coef->[0], 3);
ok( $e->coef->[1], 4);
ok( $e->coef->[3], 7);
my $f = $e->new()->coef;
ok( $f->[0], 3);
ok( $f->[1], 4);
ok( $f->[3], 7);
my $h = $b->cos()->coef;
ok( $h->[0], 0.5403023059);
ok( $h->[1], -1.68294197);
ok( $h->[2], -3.605017566);
my $i = $b->sin()->coef;
ok( $i->[0], 0.8414709848);
ok( $i->[1], 1.080604612);
ok( $i->[2], -0.062035052);
my $j = $b->sqt()->coef;
ok( $j->[0], 1);
ok( $j->[1], 1);
ok( $j->[2], 1);
my $s = $b->eval(5);
ok( $s, 86);
$s = $b->eval(-2);
ok( $s, 9);
my $g = $b->mul($c);
my $gd = $g->coef;
ok( $gd->[0], 4);
ok( $gd->[2], 30);
ok( $gd->[5], 21);
$s = $g->eval(0.5);
ok( $s, 25.78125);
my $k = $c->sbt($b);
my $kd = $k->coef;
ok( $kd->[0], 23);
ok( $kd->[2], 225);
ok( $kd->[5], 378);
ok( $kd->[6], 189);
$s = $k->eval(-0.5);
ok( $s, 14.828125);
my $m = $b->div($c)->coef;
ok( $m->[0], 4);
ok( $m->[2], -2);
ok( $m->[5], 5);
my $n = $b->atn($c)->coef;
ok( $n->[0], 0.2449786631);
ok( $n->[2], 0.1730103806);
# This test seems to fail consistently on some platforms
#ok( $n->[3], -0.8637628062);
my $w = Math::Cephes::Polynomial->new([-2, 0, -1, 0, 1]);
my ($flag, $r) = $w->rts();
any($r, 0, 1);
any($r, 0, -1);
any($r, sqrt(2), 0);
any($r, -sqrt(2), 0);

my $u1 = Math::Cephes::Complex->new(2,1);
my $u2 = Math::Cephes::Complex->new(1,-3);
my $u3 = Math::Cephes::Complex->new(2,4);
my $v1 = Math::Cephes::Complex->new(1,3);
my $v2 = Math::Cephes::Complex->new(2,4);
my $z1 = Math::Cephes::Polynomial->new([$u1, $u2, $u3]);
my $z2 = Math::Cephes::Polynomial->new([$v1, $v2]);
my $z3 = $z1->mul($z2)->coef;
ok( $z3->{r}->[0], -1);
ok( $z3->{r}->[1], 10);
ok( $z3->{r}->[2], 4);
ok( $z3->{r}->[3], -12);
ok( $z3->{i}->[0], 7);
ok( $z3->{i}->[1], 10);
ok( $z3->{i}->[2], 8);
ok( $z3->{i}->[3], 16);
$z3 = $z1->add($z2)->coef;
ok( $z3->{r}->[0], 3);
ok( $z3->{r}->[1], 3);
ok( $z3->{r}->[2], 2);
ok( $z3->{i}->[0], 4);
ok( $z3->{i}->[1], 1);
ok( $z3->{i}->[2], 4);
$z3 = $z2->sub($z1)->coef;
ok( $z3->{r}->[0], -1);
ok( $z3->{r}->[1], 1);
ok( $z3->{r}->[2], -2);
ok( $z3->{i}->[0], 2);
ok( $z3->{i}->[1], 7);
ok( $z3->{i}->[2], -4);
my $z4 = $z2->eval(10);
ok($z4->r, 21);
ok($z4->i, 43);

if ($skip_mc) {
    for (1 .. 10) {
      ok(1,1,$skip_mc);
    }
  }
else {
  my $u1 = Math::Complex->make(2,1);
  my $u2 = Math::Complex->make(1,-3);
  my $u3 = Math::Complex->make(2,4);
  my $v1 = Math::Complex->make(1,3);
  my $v2 = Math::Complex->make(2,4);
  my $z1 = Math::Cephes::Polynomial->new([$u1, $u2, $u3]);
  my $z2 = Math::Cephes::Polynomial->new([$v1, $v2]);
  my $z3 = $z1->mul($z2)->coef;
  ok( $z3->{r}->[0], -1);
  ok( $z3->{r}->[1], 10);
  ok( $z3->{r}->[2], 4);
  ok( $z3->{r}->[3], -12);
  ok( $z3->{i}->[0], 7);
  ok( $z3->{i}->[1], 10);
  ok( $z3->{i}->[2], 8);
  ok( $z3->{i}->[3], 16);
  my $z4 = $z2->eval(10);
  ok(Re($z4), 21);
  ok(Im($z4), 43);

}

my $a1 = Math::Cephes::Fraction->new(1,2);
my $a2 = Math::Cephes::Fraction->new(2,1);
my $a3 = Math::Cephes::Fraction->new(3,6);
my $b1 = Math::Cephes::Fraction->new(1,2);
my $b2 = Math::Cephes::Fraction->new(2,2);
my $f1 = Math::Cephes::Polynomial->new([$a1, $a2, $a3]);
my $f2 = Math::Cephes::Polynomial->new([$b1, $b2]);
my $f3 = $f1->add($f2)->coef;
ok( $f3->{n}->[0], 1);
ok( $f3->{n}->[1], 3);
ok( $f3->{n}->[2], 1);
ok( $f3->{d}->[0], 1);
ok( $f3->{d}->[1], 1);
ok( $f3->{d}->[2], 2);
$f3 = $f1->sub($f2)->coef;
ok( $f3->{n}->[0], 0);
ok( $f3->{n}->[1], 1);
ok( $f3->{n}->[2], 1);
ok( $f3->{d}->[0], 1);
ok( $f3->{d}->[1], 1);
ok( $f3->{d}->[2], 2);
$f3 = $f1->mul($f2)->coef;
ok( $f3->{n}->[0], 1);
ok( $f3->{n}->[1], 3);
ok( $f3->{n}->[2], 9);
ok( $f3->{n}->[3], 1);
ok( $f3->{d}->[0], 4);
ok( $f3->{d}->[1], 2);
ok( $f3->{d}->[2], 4);
ok( $f3->{d}->[3], 2);
my $f4obj = $f2->new();
my $f4 = $f4obj->coef;
ok( $f4->{n}->[0], 1);
ok( $f4->{n}->[1], 1);
ok( $f4->{d}->[0], 2);
ok( $f4->{d}->[1], 1);
$f4obj->clr(7);
$f4 = $f4obj->coef;
ok( $f4->{n}->[0], 0);
ok( $f4->{n}->[1], 0);
ok( $f4->{d}->[0], 1);
ok( $f4->{d}->[1], 1);
my $f2c = $f2->coef;
ok( $f2c->{n}->[0], 1);
ok( $f2c->{n}->[1], 1);
ok( $f2c->{d}->[0], 2);
ok( $f2c->{d}->[1], 1);

my $f5 = $f2->eval(Math::Cephes::Fraction->new(3,7));
ok( $f5->n, 13);
ok( $f5->d, 14);
$f5 = $f2->eval(8);
ok( $f5->n, 17);
ok( $f5->d, 2);

my $f6 = $f2->sbt($f1)->coef;
ok( $f6->{n}->[0], 1);
ok( $f6->{n}->[1], 2);
ok( $f6->{n}->[2], 1);
ok( $f6->{d}->[0], 1);
ok( $f6->{d}->[1], 1);
ok( $f6->{d}->[2], 2);

my $f7 = $f2->sin()->coef;
ok($f7->[0], 0.4794255386);
ok($f7->[1], 0.8775825619);
$f7 = $f2->cos()->coef;
ok($f7->[0], 0.8775825619);
ok($f7->[1], -0.4794255386);
$f7 = $f2->sqt()->coef;
ok($f7->[0], 0.707106781);
ok($f7->[1], 0.707106781);
$f7 = $f2->atn($f1)->coef;
ok($f7->[0], 0.7853981635);
ok($f7->[1], -1);


if ($skip_mf) {
  for (1 .. 10) {
    ok(1,1,$skip_mf);
  }
}
else {
  local $^W = 0;
  my $a1 = Math::Fraction->new(1,2);
  my $a2 = Math::Fraction->new(2,1);
  my $a3 = Math::Fraction->new(3,6);
  my $b1 = Math::Fraction->new(1,2);
  my $b2 = Math::Fraction->new(2,2);
  my $f1 = Math::Cephes::Polynomial->new([$a1, $a2, $a3]);
  my $f2 = Math::Cephes::Polynomial->new([$b1, $b2]);
  my $f3 = $f1->add($f2)->coef;
  ok( $f3->{n}->[0], 1);
  ok( $f3->{n}->[1], 3);
  ok( $f3->{n}->[2], 1);
  ok( $f3->{d}->[0], 1);
  ok( $f3->{d}->[1], 1);
  ok( $f3->{d}->[2], 2);
  my $f5 = $f2->eval(Math::Fraction->new(3,7));
  ok( $f5->{frac}->[0], 13);
  ok( $f5->{frac}->[1], 14);
  $f5 = $f2->eval(8);
  ok( $f5->{frac}->[0], 17);
  ok( $f5->{frac}->[1], 2);
}

my $c1 = Math::Cephes::Fraction->new(1,6);
my $c2 = Math::Cephes::Fraction->new(-1,12);
my $c3 = Math::Cephes::Fraction->new(-103, 216);
my $c4 = Math::Cephes::Fraction->new(-5,432);
my $c5 = Math::Cephes::Fraction->new(-2,27);
my $c6 = Math::Cephes::Fraction->new(1, 432);
my $c7 = Math::Cephes::Fraction->new(1, 72);
my $q = Math::Cephes::Polynomial->new([$c1,$c2,$c3,$c4,$c5,$c6,$c7]);
my ($flag1, $s1) = $q->rts();
any($s1, 0, 2);
any($s1, 0, -2);
any($s1, 3, 0);
any($s1, -3, 0);
any($s1, 1/2, 0);
any($s1, -2/3, 0);
my $w1 = $q->eval(10);
ok($w1->n, 359632);
ok($w1->d, 27);
my $c8 = Math::Cephes::Fraction->new(3,8);
my $v = $q->eval($c8);
ok($v->n, 139125);
ok($v->d, 2097152);

my $h1 = $q->sin()->coef;
ok( $h1->[0], 0.1658961327);
ok( $h1->[1], -0.08217860263);
ok( $h1->[2], -0.4708202544);
my $i1 = $q->cos()->coef;
ok( $i1->[0], 0.9861432316);
ok( $i1->[1], 0.01382467772);
ok( $i1->[2], 0.07568376966);
my $j1 = $q->sqt()->coef;
ok( $j1->[0], 0.4082482906);
ok( $j1->[1], -0.1020620726);
ok( $j1->[2], -0.5967796192);


my $d1 = Math::Cephes::Fraction->new(1,6);
my $d2 = Math::Cephes::Fraction->new(-1,12);
my $d3 = Math::Cephes::Fraction->new(3, 4);
my $e1 = Math::Cephes::Polynomial->new([$d1, $d2, $d3]);
my $d4 = Math::Cephes::Fraction->new(-1,2);
my $d5 = Math::Cephes::Fraction->new(5,3);
my $e2 = Math::Cephes::Polynomial->new([$d4, $d5]);
my $e3 = $e1->sbt($e2)->coef();
ok($e3->{n}->[0], 19);
ok($e3->{d}->[0], 48);
ok($e3->{n}->[1], -25);
ok($e3->{d}->[1], 18);
ok($e3->{n}->[2], 25);
ok($e3->{d}->[2], 12);

sub any {
  local $^W = 0;
  my ($ref, $rtrue, $itrue, $skip) = @_;
  $skip ||= '';
  $count++;
  $skip = "# skip ($skip)" if $skip;
  my ($package, $file, $line) = caller;
  for (my $i=0; $i<@$ref; $i++) {
    my $rerr = sprintf( "%12.8f", abs($ref->[$i]->r - $rtrue));
    my $ierr = sprintf( "%12.8f", abs($ref->[$i]->i - $itrue));
    if ($rerr < $eps and $ierr < $eps) {
      print "ok $count $skip\n";
      return 1;
    }
  }
  print "not ok $count (expected real=$rtrue and imag=$itrue) at $file line $line\n";
}
