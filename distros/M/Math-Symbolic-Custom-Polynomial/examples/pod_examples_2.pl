use strict;
use warnings;
use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Polynomial;

# Divide (2*x^3 - 6*x^2 + 2*x - 1) by (x - 3)
my $poly = parse_from_string("2*x^3 - 6*x^2 + 2*x - 1");
my $evaluator = 3; # it will put "x - $evaluator" internally.

# Specifying 'x' as the polynomial variable in apply_synthetic_division() is optional, see test_polynomial().
# It is not needed for this straightforward polynomial but is just present for documentation.
my ($full_expr, $divisor, $quotient, $remainder) = $poly->apply_synthetic_division($evaluator, 'x');  

# The return values are Math::Symbolic expressions
print "Full expression: $full_expr\n";  # Full expression: ((x - 3) * (2 + (2 * (x ^ 2)))) + 5
print "Divisor: $divisor\n";    # Divisor: x - 3
print "Quotient: $quotient\n";  # Quotient: 2 + (2 * (x ^ 2))
print "Remainder: $remainder\n";    # Remainder: 5



# Also works symbolically. Divide it by r.
($full_expr, $divisor, $quotient, $remainder) = $poly->apply_synthetic_division('r');  

print "Full expression: $full_expr\n";
# Full expression: ((x - r) * (((((2 + (2 * (r ^ 2))) + (2 * (x ^ 2))) + ((2 * r) * x)) - (6 * r)) - (6 * x))) + ((((2 * r) + (2 * (r ^ 3))) - 1) - (6 * (r ^ 2)))
print "Divisor: $divisor\n";    # Divisor: x - r
print "Quotient: $quotient\n";  # Quotient: ((((2 + (2 * (r ^ 2))) + (2 * (x ^ 2))) + ((2 * r) * x)) - (6 * r)) - (6 * x)
print "Remainder: $remainder\n";    # Remainder: (((2 * r) + (2 * (r ^ 3))) - 1) - (6 * (r ^ 2))



# Divide (2*y^3 - 3*y^2 - 3*y +2) by (y - 2)
$poly = symbolic_poly('y', [2, -3, -3, 2]);
($full_expr, $divisor, $quotient, $remainder) = $poly->apply_polynomial_division('y-2', 'y');

print "Full expression: $full_expr\n";  # Full expression: (y - 2) * ((y + (2 * (y ^ 2))) - 1)
print "Divisor: $divisor\n";    # Divisor: y - 2
print "Quotient: $quotient\n";  # Quotient: (y + (2 * (y ^ 2))) - 1
print "Remainder: $remainder\n";    # Remainder: 0



# Also works symbolically. Divide by (y^2 - 2*k*y + k)
($full_expr, $divisor, $quotient, $remainder) = $poly->apply_polynomial_division('y^2 - 2*k*y + k', 'y');

print "Full expression: $full_expr\n";
# Full expression: ((((y ^ 2) - ((2 * k) * y)) + k) * (((4 * k) + (2 * y)) - 3)) + (((((2 + (3 * k)) + ((8 * (k ^ 2)) * y)) - (4 * (k ^ 2))) - (3 * y)) - ((8 * k) * y))
print "Divisor: $divisor\n";    # Divisor: ((y ^ 2) - ((2 * k) * y)) + k
print "Quotient: $quotient\n";  # Quotient: ((4 * k) + (2 * y)) - 3
print "Remainder: $remainder\n";    # Remainder: ((((2 + (3 * k)) + ((8 * (k ^ 2)) * y)) - (4 * (k ^ 2))) - (3 * y)) - ((8 * k) * y)


