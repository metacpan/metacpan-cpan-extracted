package Math::Symbolic::Custom::Polynomial;

use 5.006;
use strict;
use warnings;

=pod

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Polynomial - Polynomial routines for Math::Symbolic

=head1 VERSION

Version 0.31

=cut

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw/symbolic_poly/;

our $VERSION = '0.31';

use Math::Symbolic 0.613 qw(:all);
use Math::Symbolic::Custom::Collect 0.36;
use Math::Symbolic::Custom::Base;

BEGIN {
    *import = \&Math::Symbolic::Custom::Base::aggregate_import
}
   
our $Aggregate_Export = [qw/test_polynomial apply_synthetic_division apply_polynomial_division/];

# attempt to circumvent above redefinition of import function
Math::Symbolic::Custom::Polynomial->export_to_level(1, undef, 'symbolic_poly');

use Carp;

=head1 DESCRIPTION

This is the beginnings of a module to provide some polynomial utility routines for Math::Symbolic. 

"symbolic_poly()" creates a polynomial Math::Symbolic expression according to the supplied variable and 
coefficients, and "test_polynomial()" attempts the inverse, it looks at a Math::Symbolic expression and 
tries to extract polynomial coefficients (so long as the expression represents a polynomial). The 
"apply_synthetic_division()" and "apply_polynomial_division()" methods will attempt to perform division 
on a target polynomial. 

=head1 EXAMPLE

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Polynomial;
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

=head1 symbolic_poly()

Exported by default (or it should be; try calling it directly if that fails). Constructs a Math::Symbolic 
expression corresponding to the passed parameters: a symbol for the desired indeterminate variable, and an array 
ref to the coefficients in descending order (which can also be symbols).

See the 'Example' section above for examples of use.

=cut

sub symbolic_poly {
    my ($var, $coeffs) = @_;

    return undef unless defined $var;
    return undef unless defined($coeffs) and (ref($coeffs) eq 'ARRAY');

    my @c = reverse @{ $coeffs };       # reverse the coefficient array as it will be built in ascending order
    return undef unless scalar(@c) > 0;     # TODO: perhaps should return 0?

    if ( scalar(@c) == 1 ) {
        my $single = $c[0];
        $single = parse_from_string($single) unless ref($single) =~ /^Math::Symbolic/;
        return $single;
    }

    $var = parse_from_string($var) unless ref($var) =~ /^Math::Symbolic/;
    return undef unless defined $var;

    my @to_sum;
    my $exp = 0;

    BUILD_POLY: while ( defined(my $co = shift @c) ) {

        if ( length($co) > 0 ) {
            $co = parse_from_string($co) unless ref($co) =~ /^Math::Symbolic/;

            if ( ($co->term_type() == T_CONSTANT) && ($co->value() == 0) ) {
                $exp++;
                next BUILD_POLY;
            }

            if ( $exp == 0 ) {
                push @to_sum, $co;
            }
            elsif ( $exp == 1 ) {
                if ( ($co->term_type() == T_CONSTANT) && ($co->value() == 1) ) {
                    push @to_sum, $var;
                }
                else {
                    push @to_sum, Math::Symbolic::Operator->new('*', $co, $var);
                }
            }
            else {
                if ( ($co->term_type() == T_CONSTANT) && ($co->value() == 1) ) {
                    push @to_sum, Math::Symbolic::Operator->new('^', $var, $exp);
                }
                else {
                    push @to_sum, Math::Symbolic::Operator->new('*', $co, Math::Symbolic::Operator->new('^', $var, $exp));
                }
            }
        }

        $exp++;
    }

    @to_sum = reverse @to_sum; # restore descending order
    my $nt = shift @to_sum; 
    while (@to_sum) {
        my $e = shift @to_sum;
        $nt = Math::Symbolic::Operator->new( '+', $nt, $e );
    }

    return $nt;
}

=head1 method test_polynomial()

Exported through the Math::Symbolic module extension class. Call it on a polynomial Math::Symbolic expression and it will 
try to determine the coefficient expressions. 

Takes one parameter, the indeterminate variable. If this is not provided, test_polynomial will try to detect the variable. This
can be useful to test if an arbitrary Math::Symbolic expression looks like a polynomial.
 
If the expression looks like a polynomial of degree 2, then it will apply the quadratic equation to produce
expressions for the roots, and the discriminant.

Example (also see 'Example' section above):

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Polynomial;
    use Math::Complex;

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

=cut

sub test_polynomial {
    my ($f, $ind) = @_;

    return undef unless defined wantarray;

    my ($f2, $n_hr, $d_hr) = $f->to_collected();

    return undef unless defined $n_hr;
    return undef unless $f2->term_type() == T_OPERATOR;

    my $denominator;
    if ( defined($d_hr) && ($f2->type() == B_DIVISION) ) {
        $denominator = $f2->op2();
    }

    my $terms = $n_hr->{terms};
    my $trees = $n_hr->{trees};

    if ( !defined($ind) ) {
        # try to detect indeterminate variable
        # get some statistics on the variables in the expression
        my $num_terms = scalar(keys %{$terms});
        my %v_freq;
        my %v_pows; 
        while ( my ($k, $v) = each %{$terms} ) {
            foreach my $v2 (split(/,/, $k)) {
                my ($vv, $p) = split(/:/, $v2);
                if ( $vv =~ /^VAR/ ) {
                    $v_freq{$vv}++;
                    $v_pows{$p}{$vv}++;
                }
            }
        }

        if ( scalar(keys %v_freq) == 1 ) {
            # only one variable
            my @v = keys %v_freq;
            $ind = $trees->{$v[0]}{name};
        }
        else {
            # find highest power
            my @p_s = sort { $b <=> $a } keys %v_pows;
            my $highest_p = $p_s[0];

            my @t3 = 
                map { $_->[0] }
                sort { $b->[1] <=> $a->[1] }
                map { [$_, $v_freq{$_}] }
                keys %{$v_pows{$highest_p}};
            
            $ind = $trees->{$t3[0]}{name};
        }
    }

    my $var = $ind;
    my @coeffs;
    my @constants;
    # save off the constant accumulator immediately
    push @constants, Math::Symbolic::Constant->new($terms->{constant_accumulator});
    delete $terms->{constant_accumulator};

    my @vars = grep { $trees->{$_}{name} eq $var } grep { /^VAR/ } keys %{$trees};
    if ( scalar(@vars) == 0 ) {
        carp("Passed indeterminate '$ind' but no variable in expression matches.");
        return undef;
    }
    my $k = $vars[0];
    
    my @ks = keys %{$terms};

    # go through every term and figure out the coefficient for this term.
    foreach my $kss (@ks) {

        # look at all the variables, functions, etc. for this term.
        # remove the variable we are considering
        my @tkss = split(/,/, $kss);
        my @n_ss = grep { $_ !~ /^$k/ } @tkss;  # this is all elements in the term not the polynomial variable

        # create a Math::Symbolic product tree for the coefficient
        my @product_list;
        push @product_list, Math::Symbolic::Constant->new( $terms->{$kss} );    # the constant multiplier for the term

        # look at the variables which remain
        V_LOOP: foreach my $nv (@n_ss) {    
            
            my ($nvar, $npow) = split(/:/, $nv);            
            next V_LOOP if $npow == 0;

            if ( $npow == 1 ) {
                push @product_list, $trees->{$nvar}->new();
            }
            else {
                push @product_list, Math::Symbolic::Operator->new('^', $trees->{$nvar}->new(), Math::Symbolic::Constant->new($npow));
            }
        }

        my $ntp = shift @product_list;
        while (@product_list) {
            my $e = shift @product_list;
            $ntp = Math::Symbolic::Operator->new( '*', $ntp, $e );
        }

        if ( scalar(@n_ss) == scalar(@tkss) ) {
            # no instance of the indeterminate in this term. Put it into the constant
            push @constants, $ntp;
        }
        else {
            my @pkss = grep { $_ =~ /^$k/ } @tkss;  # extract the element corresponding to the polynomial variable
            my ($v, $p) = split(/:/, $pkss[0]);     # there should be only one.
           
            # save this coefficient in a slot corresponding to the index of the indeterminate in this term
            if ( defined($coeffs[$p]) ) {
                $coeffs[$p] += $ntp;
            }
            else {
                $coeffs[$p] = $ntp;
            }
        }
    }
    
    # deal with the constant terms
    my $const = shift @constants;
    while (@constants) {
        my $e = shift @constants;
        $const = Math::Symbolic::Operator->new( '+', $const, $e );
    }

    $coeffs[0] = $const;

    if ( defined $denominator ) {
        foreach my $p (0..scalar(@coeffs)-1) {
            $coeffs[$p] /= $denominator;
        }
    }

    if ( defined $var ) {
        # post-process the extracted coefficients. Simplify coefficients and set undefined coefficients to 0
        foreach my $p (0..scalar(@coeffs)-1) {
            if ( defined($coeffs[$p]) && (ref($coeffs[$p]) =~ /^Math::Symbolic/) ) {                
                $coeffs[$p] = $coeffs[$p]->to_collected();  # simplify this coefficient as much as possible
            }
            elsif ( !defined($coeffs[$p]) ) {
                $coeffs[$p] = Math::Symbolic::Constant->new(0);
            }
        }
    }
    else {
        return undef;
    }

    @coeffs = reverse @coeffs;

    # root equations and discriminant
    # TODO: cubic and quartic(!?)
    my @roots;
    my $discriminant;
    if ( scalar(@coeffs) == 3 ) {
        my ($qa, $qb, $qc) = @coeffs;

        # discriminant formula
        # b^2 - 4*a*c
        $discriminant = parse_from_string("b^2 - 4*a*c");
        $discriminant->implement( 'a' => $qa, 'b' => $qb, 'c' => $qc );
        $discriminant = $discriminant->to_collected();

        # quadratic formula
        # (-b +- sqrt(b^2  - 4*a*c))/2a
        my $qeq1 = parse_from_string("(-1*b + sqrt(discriminant))/(2*a)");
        $qeq1->implement( 'a' => $qa, 'b' => $qb, 'discriminant' => $discriminant );
        my $qeq1_c = $qeq1->to_collected();
        $qeq1 = $qeq1_c if defined $qeq1_c;

        my $qeq2 = parse_from_string("(-1*b - sqrt(discriminant))/(2*a)");
        $qeq2->implement( 'a' => $qa, 'b' => $qb, 'discriminant' => $discriminant );
        my $qeq2_c = $qeq2->to_collected();
        $qeq2 = $qeq2_c if defined $qeq2_c;

        @roots = ($qeq1, $qeq2);
    }

    return wantarray ? ($var, \@coeffs, $discriminant, \@roots) : [$var, \@coeffs, $discriminant, \@roots];
}

=head1 method apply_synthetic_division()

Exported through the Math::Symbolic module extension class. Divides the target polynomial by a divisor of the 
form (x - r) using synthetic division. This method relies on test_polynomial() to detect if the target 
Math::Symbolic expression is a polynomial, and to determine the coefficients and the indeterminate variable if 
not provided. 

Takes two parameters, the evaluator i.e. the 'r' part of (x-r) (required, can be a Math::Symbolic expression or a 
text string which will be converted to a Math::Symbolic expression using the parser), and the polynomial variable 
(optional, as test_polynomial() can try to detect it). 

If called in a scalar context, it returns the polynomial in its divided form, i.e. D*Q + R (where D is the divisor
x-r, Q is the quotient (polynomial) and R is the remainder).

If called in a list context, it returns the polynomial in divided form as describe above, and also the divisor, 
quotient and remainder expressions. 

Example:

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

=cut

sub apply_synthetic_division {
    my ($f, $r, $ind) = @_;

    return undef unless defined $r;

    $r = parse_from_string($r) unless ref($r) =~ /^Math::Symbolic/;
    return undef unless defined $r;

    my ($var, $co) = $f->test_polynomial($ind);

    return undef unless defined $var;

    my @coeffs = @{$co};
    my $degree = scalar(@coeffs)-1;

    return undef if $degree < 2;

    my @quotient;  # Coefficients of Q
    my $remainder; # Remainder R
    
    # Initialize with the leading coefficient
    my $carry = shift @coeffs;
    push @quotient, $carry;

    # Perform synthetic division
    foreach my $coeff (@coeffs) {
        $carry = Math::Symbolic::Operator->new('+', $coeff, Math::Symbolic::Operator->new('*', $carry, $r));
        push @quotient, $carry;
    }

    # The last carry is the remainder
    $remainder = pop @quotient;
    $remainder = $remainder->to_collected();

    my $q_poly = symbolic_poly($var, \@quotient);
    $q_poly = $q_poly->to_collected();

    my $divisor = Math::Symbolic::Operator->new('-', Math::Symbolic::Variable->new($var), $r);
    my $full_expr = Math::Symbolic::Operator->new('+', Math::Symbolic::Operator->new('*',  $divisor, $q_poly), $remainder);

    return wantarray ? ($full_expr, $divisor, $q_poly, $remainder) : $full_expr;
}

=head1 method apply_polynomial_division()

Exported through the Math::Symbolic module extension class. Divides the target polynomial by a divisor polynomial
using polynomial long division. This method relies on test_polynomial() to detect if the target and divisor 
expressions are polynomials, and to determine the coefficients and the indeterminate variables if not provided. 
The indeterminate variables must be the same in both expressions.

Takes two parameters, the divisor polynomial (required, can be a Math::Symbolic expression or a text string which
will be converted to a Math::Symbolic expression using the parser), and the polynomial variable (optional, as 
test_polynomial() can try to detect it). 

If called in a scalar context, it returns the polynomial in its divided form, i.e. D*Q + R (where D is the divisor, 
Q is the quotient and R is the remainder).

If called in a list context, it returns the polynomial in divided form as describe above, and also the divisor, 
quotient and remainder expressions. 

Example:

    use strict;
    use warnings;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Polynomial;

    # Divide (2*y^3 - 3*y^2 - 3*y +2) by (y - 2)
    my $poly = symbolic_poly('y', [2, -3, -3, 2]);
    my ($full_expr, $divisor, $quotient, $remainder) = $poly->apply_polynomial_division('y-2', 'y');

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

=cut

sub apply_polynomial_division {
    my ($f, $divisor, $ind) = @_;

    return undef unless defined $divisor;

    $divisor = parse_from_string($divisor) unless ref($divisor) =~ /^Math::Symbolic/;
    return undef unless defined $divisor;

    my ($var1, $co1) = $f->test_polynomial($ind);
    return undef unless defined $var1;    

    my ($var2, $co2) = $divisor->test_polynomial($ind);
    return undef unless defined $var2;

    return undef unless $var1 eq $var2;

    my @dividend = @{$co1};  # Coefficients of the dividend polynomial
    my @divisor = @{$co2};    # Coefficients of the divisor polynomial
    
    my $dividend_degree = scalar(@dividend) - 1;
    my $divisor_degree  = scalar(@divisor) - 1;
    
    my @quotient = ();
    my @remainder = @dividend;      

    # Perform division until the degree of remainder is less than the divisor's degree
    while (scalar(@remainder) - 1 >= $divisor_degree) {

        my $lead_coeff_ratio = Math::Symbolic::Operator->new('/', $remainder[0], $divisor[0]);
        push @quotient, $lead_coeff_ratio;

        my $degree_diff = scalar(@remainder) - scalar(@divisor);

        # Subtract the product of the divisor and the term from the remainder
        my @scaled_divisor = map { Math::Symbolic::Operator->new('*', $_, $lead_coeff_ratio) } (@divisor, (0) x $degree_diff);
        @remainder = map { Math::Symbolic::Operator->new('-', $remainder[$_], $scaled_divisor[$_]) } (0..scalar(@remainder)-1);
        
        shift @remainder;
    }

    # Collect up the new coefficients
    @quotient = map { scalar($_->to_collected()) } @quotient;
    @remainder = map { scalar($_->to_collected()) } @remainder;

    my $q_poly = symbolic_poly($var1, \@quotient);
    return undef unless defined $q_poly;
    $q_poly = $q_poly->to_collected();

    my $r_poly = symbolic_poly($var1, \@remainder);

    my $full_expr;
    if ( defined($r_poly) && !$r_poly->is_identical(Math::Symbolic::Constant->new(0)) ) {
        $r_poly = $r_poly->to_collected();
        $full_expr = Math::Symbolic::Operator->new('+', Math::Symbolic::Operator->new('*',  $divisor, $q_poly), $r_poly);
    }
    else {
        $full_expr = Math::Symbolic::Operator->new('*',  $divisor, $q_poly);
        $r_poly = Math::Symbolic::Constant->new(0) unless defined $r_poly;
    }

    return wantarray ? ($full_expr, $divisor, $q_poly, $r_poly) : $full_expr;
}

=head1 SEE ALSO

L<Math::Symbolic>

L<Math::Polynomial>

L<Math::Polynomial::Solve>

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Steffen Mueller, author of Math::Symbolic

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Matt Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; 
__END__

