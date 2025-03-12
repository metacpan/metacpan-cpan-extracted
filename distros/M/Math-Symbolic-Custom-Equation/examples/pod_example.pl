use strict;
use Math::Symbolic 0.613 qw(:all);
use Math::Symbolic::Custom::Equation 0.2;
use Math::Symbolic::Custom::Polynomial 0.3;
use Math::Symbolic::Custom::CollectSimplify 0.2;
Math::Symbolic::Custom::CollectSimplify->register();

# Solve the simultaneous equations:-
# x - 2*y = 7
# x^2 + 4*y^2 = 37
my $eq1 = Math::Symbolic::Custom::Equation->new('x - 2*y = 7');
my $eq2 = Math::Symbolic::Custom::Equation->new('x^2 + 4*y^2 = 37');

print "Solve the simultaneous equations:-\n\n";
print "\t[1]\t", $eq1->to_string(), "\n";
print "\t[2]\t", $eq2->to_string(), "\n\n";

# Make x the subject of eq. 1
my $eq1_x = $eq1->isolate('x');
die "Cannot isolate 'x' in " . $eq1->to_string() . "\n" unless defined $eq1_x;
print "Make x the subject of [1]: ", $eq1_x->to_string(), "\n\n";
my $x_expr = $eq1_x->RHS();

# Substitute into eq. 2, re-arrange to make RHS = 0, and simplify
my $eq3 = $eq2->implement('x' => $x_expr)->simplify();
print "Substitute into [2]: ", $eq3->to_string(), "\n\n";

# Re-arrange it to equal 0
my $eq3_2 = $eq3->to_zero()->simplify();
print "Rearrange to equal zero: ", $eq3_2->to_string(), "\n\n";

# we have an expression for y, solve it
my ($var, $coeffs, $disc, $roots) = $eq3_2->LHS()->test_polynomial();
die "Cannot solve quadratic!\n" unless defined($var) && ($var eq 'y');

my $y_1 = $roots->[0];
my $y_2 = $roots->[1];

print "The solutions for y are: ($y_1, $y_2)\n\n";

# put these solutions into the expression for x in terms of y to get x values
my $x_1 = $eq1_x->implement('y' => $y_1)->simplify()->RHS();
my $x_2 = $eq1_x->implement('y' => $y_2)->simplify()->RHS();
print "The solutions for x given y are: (x = $x_1 when y = $y_1) and (x = $x_2 when y = $y_2)\n\n";

# Check that these solutions hold for the original equations
print "Check: ";
if ( $eq1->holds({'x' => $x_1, 'y' => $y_1}) && $eq2->holds({'x' => $x_1, 'y' => $y_1}) ) {
    print "Solution (x = $x_1, y = $y_1) holds for [1] and [2]\n";
}
print "Check: ";
if ( $eq1->holds({'x' => $x_2, 'y' => $y_2}) && $eq2->holds({'x' => $x_2, 'y' => $y_2}) ) {
    print "Solution (x = $x_2, y = $y_2) holds for [1] and [2]\n";
}



