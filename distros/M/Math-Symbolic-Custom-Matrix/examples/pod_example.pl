use strict;
use Math::Symbolic 0.613 qw/:all/;
use Math::Symbolic::MiscAlgebra qw/:all/;
use Math::Symbolic::Custom::Matrix 0.2;
use Math::Symbolic::Custom::Polynomial 0.3;
use Math::Symbolic::Custom::CollectSimplify 0.2;
Math::Symbolic::Custom::CollectSimplify->register();

# Say we want the eigenvalues of some matrix with a parameter.
# 1. A = | 4, 3-k |
#        | 2, 3   |
my @matrix = ([4,'3-k'],[2,3]);
my $A = make_symbolic_matrix(\@matrix);

# 2. get an identity matrix
my $I = identity_matrix(2);

# 3. multiply it with lambda
my $lambda_I = scalar_multiply_matrix("lambda", $I);

# 4. subtract it from matrix A
my $B = sub_matrix($A, $lambda_I);

# 5. form the characteristic polynomial, |A-lambda*I|
my $c_poly = det(@{$B})->simplify();
print "Characteristic polynomial is: $c_poly\n";

# 6. analyze the polynomial to get roots
my ($var, $coeffs, $disc, $roots) = $c_poly->test_polynomial('lambda');
print "Expressions for the roots are:\n\t$roots->[0]\n\t$roots->[1]\n";

# 7. Check for some values of parameter k
foreach my $k (0..3) {
    print "For k = $k: lambda_1 = ", 
        $roots->[0]->value('k' => $k), "; lambda_2 = ", 
        $roots->[1]->value('k' => $k), "\n";
}

exit;

