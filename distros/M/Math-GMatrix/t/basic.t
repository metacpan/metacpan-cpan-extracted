# -----------------------------------------------------------------------------
#
#			t/basics.t for Math::GMatrix
#
# $Id: basic.t,v 1.1 2004/02/05 12:17:44 acester Exp $
#
# -----------------------------------------------------------------------------
#
#
#
# Version History:
# ----------------
# $Date: 2004/02/05 12:17:44 $
# $Revision: 1.1 $
# $Log: basic.t,v $
# Revision 1.1  2004/02/05 12:17:44  acester
# added docs and test script
#
# -----------------------------------------------------------------------------

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 12; };
END {print "not ok 1\n" unless $loaded;}
use Math::GMatrix;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub equal {
  my ($a,$b) = @_;

  my $diff = ($a > $b) ? $a - $b : $b - $a;
  return ($diff < $Math::GMatrix::eps);
}


# -------------------------------------

srand(time);
$A = new Math::GMatrix ([rand,rand,rand],
                       [rand,rand,rand],
                       [rand,rand,rand]);
$A->print("A random Matrix A");
print "ok 2\n";

# -------------------------------------

$v = new Math::GMatrix ([rand,rand,rand]);
$v->print("A random vector v");
print "ok 3\n";

# -------------------------------------

$M = $A->concat($v->transpose);
$M->print('The equation system A*x=v');
print "ok 4\n";

# -------------------------------------

$x = $M->solve;
$x->print("The solution x");
print "ok 5\n";

# -------------------------------------

$u = $A->multiply($x)->transpose;
$u->print("The proof that A*x yields v?");
print "ok 6\n";

# -------------------------------------

for (0..2) {
  if (equal($v->[0]->[$_],$u->[0]->[$_])) {
    printf "ok %d\n", $_ + 7;
  } else {
    printf "(%f,%f)\n",$v->[0]->[$_],$u->[0]->[$_];
    printf "not ok %d\n", $_ + 7;
  }
}

# -------------------------------------
# operator overloading
# -------------------------------------

eval {
  $b = ~($A * $x);
  $b->print("transpose(A*x) overloaded");
  $c = $b - $v;
  $c->print("=v (transpose(A*x) - v   ");
};
if ($@) {
  print "not ok 10\n";
} else {
  print "ok 10\n";
}

# -------------------------------------

$M = new Math::GMatrix('I');
$M->print("M identity Matrix M\n");
print ((($M->size()==3)?"":"not "),"ok 11\n");

$M = $M->translate(-1,-1);
$M->print("M after applying translate(-1,-1)\n");

$M = $M->rotate(90);
$M->print("M after applying rotate(90)\n");

$M = $M->scale(2.5);
$M->print("M after applying scale(2.5)\n");

$M = $M->translate(1,1);
$M->print("M after applying translate(1,1)\n");

@v1 = (10,10);
@v2 = $M->xform(@v1);
print "xform(",join(",",@v1),") is (",join(",",@v2),")\n";

print "not " unless (($#v2 == 1) && ($v2[0] == -21.5) && ($v2[1] == 23.5));
print "ok 12\n";

# -------------------------------------
#		E-O-F
# -------------------------------------
