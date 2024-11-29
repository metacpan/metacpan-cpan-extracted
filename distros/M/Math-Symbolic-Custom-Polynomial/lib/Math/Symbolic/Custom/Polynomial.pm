package Math::Symbolic::Custom::Polynomial;

use 5.006;
use strict;
use warnings;

=pod

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Polynomial - Polynomial routines for Math::Symbolic

=head1 VERSION

Version 0.11

=cut

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw/symbolic_poly/;

our $VERSION = '0.11';

use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Collect 0.2;
use Math::Symbolic::Custom::Base;

BEGIN {
    *import = \&Math::Symbolic::Custom::Base::aggregate_import
}
   
our $Aggregate_Export = [qw/test_polynomial/];

# attempt to circumvent above redefinition of import function
Math::Symbolic::Custom::Polynomial->export_to_level(1, undef, 'symbolic_poly');

use Carp;

=head1 DESCRIPTION

This is the beginnings of a module to provide some polynomial utility routines for Math::Symbolic. 

"symbolic_poly()" creates a polynomial Math::Symbolic expression according to the supplied variable and 
coefficients, and "test_polynomial()" attempts the inverse, it looks at a Math::Symbolic expression and 
tries to extract polynomial coefficients (so long as the expression represents a polynomial).

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

=head1 symbolic_poly

Exported by default (or it should be; try calling it directly if that fails). Constructs a Math::Symbolic 
expression corresponding to the passed parameters: a symbol for the desired indeterminate variable, and an array 
ref to the coefficients in descending order (which can also be symbols).

=cut

sub symbolic_poly {
    my ($var, $coeffs) = @_;

    return undef unless defined $var;
    return undef unless defined($coeffs) and (ref($coeffs) eq 'ARRAY');

    my @c = reverse @{ $coeffs };       # reverse the coefficient array as it will be built in ascending order
    return undef unless scalar(@c) > 1;

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

=head1 test_polynomial

Exported through the Math::Symbolic module extension class. Call it on a polynomial Math::Symbolic expression  
(for the moment, the indeterminate variable has to be provided) and it will attempt to figure out the
coefficient expressions. 

If the expression looks like a polynomial of degree 2, then it will apply the quadratic equation to produce
expressions for the roots, and the discriminant.

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

    my $var = $ind; # TODO: try to autodetect indeterminate if not supplied
    my @coeffs;
    my @constants;
    # save off the constant accumulator immediately
    push @constants, Math::Symbolic::Constant->new($terms->{constant_accumulator});
    delete $terms->{constant_accumulator};

    # ...assume we've figured out the indeterminate of the polynomial
    my @vars = grep { $trees->{$_}{name} eq $var } keys %{$trees};
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
            $coeffs[$p] = $ntp;
            $coeffs[$p] /= $denominator if defined $denominator;
        }
    }

    # deal with the constant terms
    my $const = shift @constants;
    while (@constants) {
        my $e = shift @constants;
        $const = Math::Symbolic::Operator->new( '+', $const, $e );
    }

    $coeffs[0] = $const;
    $coeffs[0] /= $denominator if defined $denominator;

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


=head1 SEE ALSO

L<Math::Symbolic>

L<Math::Polynomial>

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-symbolic-custom-polynomial at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Symbolic-Custom-Polynomial>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

Steffen Mueller, author of Math::Symbolic

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Matt Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; 
__END__


