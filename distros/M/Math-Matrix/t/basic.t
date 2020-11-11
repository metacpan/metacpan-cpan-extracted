#                              -*- Mode: Perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Matrix;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

srand(time);
$A = Math::Matrix -> new([[rand,rand,rand],
                          [rand,rand,rand],
                          [rand,rand,rand]]);
$A->print("A random Matrix A");
print "ok 2\n";
$v = Math::Matrix -> new([[rand,rand,rand]]);
$v->print("A random vector v");
print "ok 3\n";
$M = $A->concat($v->transpose);
$M->print('The equation system A*x=v');
print "ok 4\n";
$x = $M->solve;
$x->print("The solution x");
print "ok 5\n";
$u = $A->multiply($x)->transpose;
$u->print("The proof that A*x yields v?");
print "ok 6\n";

for (0..2) {
    if (equal($v->[0]->[$_],$u->[0]->[$_])) {
        printf "ok %d\n", $_ + 7;
    } else {
        printf "not ok %d\n", $_ + 7;
    }
}

# operator overloading
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

sub equal {
    my ($a,$b) = @_;

    if ($a > $b) {
        $a - $b < $Math::Matrix::eps;
    } else {
        $b - $a < $Math::Matrix::eps;
    }
}
