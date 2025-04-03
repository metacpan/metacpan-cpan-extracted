use strict;
use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Polynomial 0.2;
use Math::Complex;

# create a polynomial expression
my $f1 = symbolic_poly('x', [5, 4, 3, 2, 1]);
print "Output: $f1\n\n\n";   
# Output: ((((5 * (x ^ 4)) + (4 * (x ^ 3))) + (3 * (x ^ 2))) + (2 * x)) + 1

# also works with symbols
my $f2 = symbolic_poly('t', ['a/2', 'u', 0]);
print "Output: $f2\n\n\n"; 
# Output: ((a / 2) * (t ^ 2)) + (u * t)

# analyze a polynomial with complex roots
my $complex_poly = parse_from_string("y^2 + y + 1");
my ($var, $coeffs, $disc, $roots) = $complex_poly->test_polynomial('y');

my $degree = scalar(@{$coeffs})-1;
print "'$complex_poly' is a polynomial in $var of degree $degree with " . 
        "coefficients (ordered in descending powers): (", join(", ", @{$coeffs}), ")\n";
print "The discriminant has: $disc\n";
print "Expressions for the roots are:\n\t$roots->[0]\n\t$roots->[1]\n";

# evaluate the root expressions as they should resolve to numbers
# 'i' => i glues Math::Complex and Math::Symbolic
my $root1 = $roots->[0]->value('i' => i);   
my $root2 = $roots->[1]->value('i' => i);
# $root1 and $root2 are Math::Complex numbers
print "The roots evaluate to: (", $root1, ", ", $root2, ")\n";

# plug back in to verify the roots take the poly back to zero
# (or at least, as numerically close as can be gotten).
print "Putting back into original polynomial:-\n\tat y = $root1:\t", 
        $complex_poly->value('y' => $root1), 
        "\n\tat y = $root2:\t", 
        $complex_poly->value('y' => $root2), "\n\n\n";

# analyze a polynomial with a parameter 
my $some_poly = parse_from_string("x^2 + 2*k*x + (k^2 - 4)");
($var, $coeffs, $disc, $roots) = $some_poly->test_polynomial('x');

$degree = scalar(@{$coeffs})-1;
print "'$some_poly' is a polynomial in $var of degree $degree with " .
        "coefficients (ordered in descending powers): (", join(", ", @{$coeffs}), ")\n";
print "The discriminant has: $disc\n";
print "Expressions for the roots are:\n\t$roots->[0]\n\t$roots->[1]\n";

# evaluate the root expressions for k = 3 (for example)
my $root1 = $roots->[0]->value('k' => 3);
my $root2 = $roots->[1]->value('k' => 3);
print "Evaluating at k = 3, roots are: (", $root1, ", ", $root2, ")\n";

# plug back in to verify
print "Putting back into original polynomial:-\n\tat k = 3 and x = $root1:\t", 
        $some_poly->value('k' => 3, 'x' => $root1), 
        "\n\tat k = 3 and x = $root2:\t", 
        $some_poly->value('k' => 3, 'x' => $root2), "\n\n";
        
# finding roots with Math::Polynomial::Solve
use Math::Polynomial::Solve qw(poly_roots coefficients);
coefficients order => 'descending';

# some big polynomial
my $big_poly = parse_from_string("phi^8 + 3*phi^7 - 5*phi^6 + 2*phi^5 -7*phi^4 + phi^3 + phi^2 - 2*phi + 9");
# if test_polynomial() is not supplied with the indeterminate variable, it will try to autodetect
my ($var, $co) = $big_poly->test_polynomial();  
my @coeffs = @{$co};
my $degree = scalar(@coeffs)-1;

print "'$big_poly' is a polynomial in $var of degree $degree with " . 
            "coefficients (ordered in descending powers): (", join(", ", @coeffs), ")\n";

# Find the roots of the polynomial using Math::Polynomial::Solve. 
my @roots = poly_roots( 
      # call value() on each coefficient to get a number.
      # if there were any parameters, we would have to supply their value
      # here to force the coefficients down to a number.
      map { $_->value() } @coeffs 
      );

print "The roots and corresponding values of the polynomial are:-\n";
foreach my $root (@roots) {
      # put back into the original expression to verify
      my $val = $big_poly->value('phi' => $root);
      print "\t$root => $val\n";
}

