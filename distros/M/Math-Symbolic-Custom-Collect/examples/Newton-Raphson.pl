#!/usr/bin/perl
use strict;
use warnings;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::Collect;
use Math::Symbolic::Custom::ToShorterString;

# Define natural log in the parser (not strictly necessary, just an example)
use Math::SymbolicX::ParserExtensionFactory (
    ln => sub {
        my $arg = shift;
        return Math::Symbolic::Operator->new('log', Math::Symbolic::Constant->euler(), $arg);
    },
);

# 1. We want to find a root of f(x) = ln(x) - 4 + x (for example).
my $f = parse_from_string("ln(x) - 4 + x");
print "Find a root of f(x) = ", $f->to_shorter_infix_string(), "\n\n";

# 2. Find by experiment approximately where the sign of f(x) changes. 
print "\tx\t\tf(x)\t\tsgn(f(x))\n\n";
my ($start, $end, $inc) = (1, 5, 0.5);
my $prev_sign;
my $prev_val;
SIGN_LOOP: for (my $i = $start; $i < $end; $i += $inc) {
    my $val = $f->value( 'x' => $i);
    my $sign = $val < 0 ? '-' : '+';
    print "\t", sprintf("%.1f", $i), "\t\t", sprintf("%.1f", $val), "\t\t$sign\n"; 
    if ( defined($prev_sign) and ($prev_sign ne $sign) ) {
        # sign has changed         
        last SIGN_LOOP; 
    }
    $prev_sign = $sign;
    $prev_val = $i;
}
print "\nSign change indicates there is a root between x = $prev_val and ", $prev_val + $inc, ".\n\n";

# 3. Differentiate. f'(x) = (d/dx) f(x)
my $f_prime = $f->to_derivative();
print "f'(x) = ", $f_prime->to_shorter_infix_string(), "\n\n";

# 4. Assemble Newton-Raphson formula.
my $NR = Math::Symbolic::Variable->new('x') - ($f / $f_prime);
print "The Newton-Raphson formula is: ", $NR->to_shorter_infix_string(), "\n\n";

# 5. Say the initial guess is the midpoint of where we determined the sign changed.
my $x0 = $prev_val + (($prev_val + $inc) - $prev_val)/2;
print "Initial guess x = $x0\n\n";

# 6. Iterate a few times with the NR to home in on the root.
my $x_v = $x0;
print "\tStep\t\tRoot\n";
print "\t0\t\t$x_v\n";
foreach my $i (1..5) {
    $x_v = $NR->value( 'x' => $x_v );
    print "\t$i\t\t$x_v\n";
}

# 7. Check the answer.
print "\nValue of f(x) at x = $x_v: ", $f->value( 'x' => $x_v ), "\n";

