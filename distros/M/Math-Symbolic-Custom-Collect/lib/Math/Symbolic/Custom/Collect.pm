package Math::Symbolic::Custom::Collect;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

=pod

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Collect - Collect up Math::Symbolic expressions

=head1 VERSION

Version 0.35

=cut

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw/symbolic_complex/;

our $VERSION = '0.35';

use Math::Symbolic qw(:all);
use Math::Symbolic::Derivative qw//;
use Math::Symbolic::Custom::Base;

BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}

our $Aggregate_Export = [qw/to_collected to_terms to_derivative test_complex to_complex_conjugate/];
Math::Symbolic::Custom::Collect->export_to_level(1, undef, 'symbolic_complex');

use Carp;

=head1 DESCRIPTION

Provides some methods for working with Math::Symbolic expressions through the Math::Symbolic module extension class. 

=head1 EXAMPLES

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Collect;

    my $t1 = "0.125";
    print "Output: ", parse_from_string($t1)->to_collected()->to_string(), "\n";                
    # Output: 1 / 8

    my $t2 = "25/100";
    print "Output: ", parse_from_string($t2)->to_collected()->to_string(), "\n";                
    # Output: 1 / 4

    my $t3 = "10^100 + 1 - 10^100";
    print "Output: ", parse_from_string($t3)->to_collected()->to_string(), "\n";
    # Output: 1

    my $t4 = "((1/4)+(1/2))*3*x";
    print "Output: ", parse_from_string($t4)->to_collected()->to_string(), "\n";     
    # Output: (9 * x) / 4           

    my $t5 = "1/(1-(1/x))";
    print "Output: ", parse_from_string($t5)->to_collected()->to_string(), "\n";          
    # Output: x / (x - 1)

    my $t6 = "sin(x^2+y)*sin(y+x^2)";
    print "Output: ", parse_from_string($t6)->to_collected()->to_string(), "\n";    
    # Output: (sin((x ^ 2) + y)) ^ 2

    my $t7 = "x + x^2 + 3*x^3 + 2*x - x^2";
    print "Output: ", parse_from_string($t7)->to_collected()->to_string(), "\n";
    # Output: (3 * x) + (3 * (x ^ 3))

    my $t8 = "((1/(3*a))-(1/(3*b)))/((a/b)-(b/a))";
    print "Output: ", parse_from_string($t8)->to_collected()->to_string(), "\n";
    # Output: (b - a) / ((3 * (a ^ 2)) - (3 * (b ^ 2)))

    my $t9 = "(x+y+z)/2";
    my @terms = parse_from_string($t9)->to_terms();
    print "Terms: (", join("), (", @terms), ")\n";
    # Terms: (x / 2), (y / 2), (z / 2)

    $Math::Symbolic::Custom::Collect::COMPLEX_VAR = 'j';   # default is 'i'
    my $t10 = "j*(3-7*j)*(2-j)";
    print "Output: ", parse_from_string($t10)->to_collected()->to_string(), "\n";
    # Output: 17 - j

    my $t11 = "(3*x - 1)^2";
    print "Output: ", parse_from_string($t11)->to_derivative()->to_string(), "\n";
    # Output: (18 * x) - 6

    my $t12 = "u*t + (1/2)*a*t^2";
    print "Output: ", parse_from_string($t12)->to_derivative('t')->to_string(), "\n";
    # Output: u + (a * t)

=cut

# this symbol represents the solution to x^2 = -1. If for some reason 'i' is being used as a variable for a different 
# purpose in the expression, this should be changed (e.g. to 'j'). Otherwise things will get very confusing
our $COMPLEX_VAR = "i";  

# variable constraints. 
our %VARIABLE_CONSTRAINTS;
# e.g. %VARIABLE_CONSTRAINTS = (
#   'x'     =>      { nonzero => 1, positive => 1},     # x is > 0
#   'y'     =>      { nonzero => 1 },                   # y != 0
#   );

# if evaluating a constant exponent expression gives a result higher than this, it won't bother and keep the exponent expression
our $EXP_MAX = "1000000"; 

=head2 Method to_collected()

'to_collected' performs the following operations on the inputted Math::Symbolic tree:-

=over

=item * Folds constants

=item * Converts decimal numbers to rational numbers

=item * Combines fractions

=item * Expands brackets

=item * Collects like terms

=item * Cancels down

=back

The result is often a more concise expression. See EXAMPLES above.

=head3 $EXP_MAX

C<$EXP_MAX> is a package variable which can be used to set a maximum value on evaluating/folding constants 
with a constant exponent. By default it is set to 1,000,000. 

    use strict;
    use Math::Symbolic 0.613 qw(:all);
    use Math::Symbolic::Custom::Collect 0.35;

    # some expression with a power
    my $expr = parse_from_string("1 + 32^3");

    my $output = $expr->to_collected();
    print "\$output = $output\n";       # $output = 32769

    # decide to keep it as 32^3
    $Math::Symbolic::Custom::Collect::EXP_MAX = 1000;

    $output = $expr->to_collected();
    print "\$output = $output\n";       # $output = 1 + (32 ^ 3)

=cut

sub to_collected {
    my ($t1) = @_;

    return undef unless defined wantarray;

    # 1. recursion step. 
    # Fold constants, convert decimal to rational, combine fractions, expand brackets
    my $t2 = prepare($t1);
    if (!defined $t2) {
        return undef;
    }
    
    # 2. collect like terms
    if ( ($t2->term_type() == T_OPERATOR) && ($t2->type() == B_DIVISION) ) {
    
        my $numerator = $t2->op1();
        my $denominator = $t2->op2();
        my ($n_hr, $d_hr);
        
        my ($c_n, $c_n_cth) = collect_like_terms($numerator);
        my ($c_d, $c_d_cth) = collect_like_terms($denominator);

        if ( defined($c_n_cth) && defined($c_d_cth) ) {
            # 3. attempt to cancel down
            ($numerator, $n_hr, $denominator, $d_hr) = cancel_down($c_n, $c_n_cth, $c_d, $c_d_cth);
        }
        else {
            if ( defined $c_n ) {
                $numerator = $c_n;
                $n_hr = $c_n_cth;
            }
            if ( defined $c_d ) {
                $denominator = $c_d;
                $d_hr = $c_d_cth;
            }
        }
        
        # check denominator
        if ( ($denominator->term_type() == T_CONSTANT) && ($denominator->value() == 1) ) {
            return wantarray ? ($numerator, $n_hr) : $numerator;
        }
        elsif ( ($denominator->term_type() == T_CONSTANT) && ($denominator->value() == 0) ) {
            # FIXME: divide by zero at this point?!
            return $t2;
        }
        else {
            
            my ($Re, $Im) = $denominator->test_complex();
            # Rationalize a complex denominator
            if ( defined($Im) && !(($Im->term_type() == T_CONSTANT) && ($Im->value() == 0)) ) {

                # construct complex conjugate
                my $ccj = symbolic_complex($Re, Math::Symbolic::Operator->new('*', Math::Symbolic::Constant->new(-1), $Im));

                # multiply with numerator and denominator
                my $new_num = Math::Symbolic::Operator->new('*', $numerator, $ccj);
                my $new_den = Math::Symbolic::Operator->new('*', $denominator, $ccj);

                # Reconstruct the expression and collect up again
                my $t3 = Math::Symbolic::Operator->new( '/', $new_num, $new_den );
                my ($t4, $n_hr2, $d_hr2) = $t3->to_collected();

                return wantarray ? ($t4, $n_hr2, $d_hr2) : $t4;                
            }
            else {

                my $t3 = Math::Symbolic::Operator->new( '/', $numerator, $denominator );
                return wantarray ? ($t3, $n_hr, $d_hr) : $t3;
            }
        }
    }
    else {
        my ($collected, $ct_href) = collect_like_terms($t2);

        if ( defined $collected ) {
            return wantarray ? ($collected, $ct_href) : $collected;
        }
        else {
            return $t2;
        }
    }
}

=head2 Method to_terms()

'to_terms()' uses 'to_collected()' and returns the expression as a list of terms, that is a list of sub-expressions that can be summed to create an expression which is (numerically) equivalent to the original expression.

Called in a scalar context, returns the number of terms. 

=cut

sub to_terms {
    my ($t1) = @_;

    return undef unless defined wantarray;

    my ($t2, $n_hr, $d_hr) = to_collected($t1);

    return undef unless defined $t2;

    my @terms;
    if ( exists($d_hr->{terms}) && exists($n_hr->{terms}) ) {

        my $terms = $n_hr->{terms};
        my $trees = $n_hr->{trees};

        my $denominator = build_summation_tree($d_hr);
        
        my $const_acc = $terms->{constant_accumulator};
        $const_acc = 0 if not defined $const_acc;
        push @terms, Math::Symbolic::Constant->new($const_acc) / $denominator if $const_acc != 0;
        delete $terms->{constant_accumulator};
        while ( my ($k, $v) = each %{$terms} ) {
            my $numerator = build_summation_tree({ terms => { constant_accumulator => 0, $k => $v }, trees => $trees });
            my $expr = $numerator / $denominator;
            my $expr2 = to_collected($expr);
            $expr = $expr2 if defined $expr2;
            push @terms, $expr;
        }        

    }
    elsif ( exists $n_hr->{terms} ) {

        my $terms = $n_hr->{terms};
        my $trees = $n_hr->{trees};

        my $const_acc = $terms->{constant_accumulator};
        $const_acc = 0 if not defined $const_acc;
        push @terms, Math::Symbolic::Constant->new($const_acc) if $const_acc != 0;
        delete $terms->{constant_accumulator};
        while ( my ($k, $v) = each %{$terms} ) {
            push @terms, build_summation_tree({ terms => { constant_accumulator => 0, $k => $v }, trees => $trees });
        }
    }
    else {
        push @terms, $t2;
    }

    if ( scalar(@terms) == 0 ) {
        push @terms, Math::Symbolic::Constant->new(0);
    }

    return wantarray ? @terms : scalar(@terms);
}

=head2 Method to_derivative()

This is a convenience method to differentiate the inputted Math::Symbolic expression. It calls to_collected() before passing the results through to L<Math::Symbolic::Derivative>'s partial_derivative(). 

Takes one parameter, the variable of differentiation. If not provided it will check if the expression and if there is only one variable it will use that.

Using to_collected() on an expression before differentiating it, often yields better results (because to_collected() reformats the expression, and preparing the expression is half the battle in calculus). For example, from L<Bug #55842 - Math-Symbolic: Simplification deficiency affects Algorithm::CurveFit|https://rt.cpan.org/Public/Bug/Display.html?id=55842>:-

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Derivative qw(:all);
    use Math::Symbolic::Custom::Collect;

    # the expression from the bug report
    my $f = parse_from_string('A*(x - x_0)^2 + y_0');

    # try differentiating it directly, introduces a pole at x-x_0=0
    my $f_d1 = partial_derivative($f, 'x_0');
    print "$f_d1\n"; # A * ((2 * ((x - x_0) ^ 2)) * ((1 * (-1)) / (x - x_0)))

    # try with to_derivative()
    my $f_d2 = $f->to_derivative('x_0');
    print "$f_d2\n"; # ((2 * A) * x_0) - ((2 * A) * x)
    # i.e., no pole.

=cut

sub to_derivative {
    my ($t1, $var) = @_;

    if ( not defined $var ) {
        my @vars = $t1->explicit_signature();
        if ( scalar(@vars) == 1 ) {
            $var = $vars[0];
        }
        else {
            return undef;
        }
    }
    
    my $t2 = $t1->to_collected();
    return undef unless defined $t2;
    
    $var = Math::Symbolic::Variable->new($var) unless ref($var) =~ /^Math::Symbolic::Variable/;
    my $diff = Math::Symbolic::Derivative::partial_derivative( $t2, $var );
    return $diff->to_collected();    
}

=head1 COMPLEX NUMBERS

From version 0.2, there is some support for complex numbers. The symbol in C<$Math::Symbolic::Custom::Collect::COMPLEX_VAR> (set to 'i' by default) is considered by the module to be the symbol for the imaginary unit and treated as such when collecting up the expression. It is a Math::Symbolic variable to permit easy conversion to Math::Complex numbers using the value() method, for example:

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Collect;
    use Math::Complex;

    my $t = "x+sqrt(-100)+y*i";
    my $M_S = parse_from_string($t)->to_collected();
    print "$M_S\n"; # ((10 * i) + x) + (i * y)

    # we want some kind of actual number from this expression
    my $M_C = $M_S->value( 
                    'x' => 2,
                    'y' => 3, 
                    'i' => i,  # glue Math::Symbolic and Math::Complex 
                    );

    # $M_C is a Math::Complex number
    print "$M_C\n"; # 2+13i

If you are not going to be using complex numbers and want the symbol C<i> available to use as a normal Math::Symbolic variable then you will have to override C<$Math::Symbolic::Custom::Collect::COMPLEX_VAR> to something else at the beginning of your program, e.g.:

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Collect;
    $Math::Symbolic::Custom::Collect::COMPLEX_VAR = 'blahblahblah'; 
    # note: remember not to use 'blahblahblah' as a Math::Symbolic variable name

    my $coord = parse_from_string("5*i + 2*j + 6*k");   # 'i' is just a normal variable here

It is not a good idea to change the contents of C<$Math::Symbolic::Custom::Collect::COMPLEX_VAR> mid-program, for example if you define some expressions using 'i' and then want to start using 'j', the module is not going to remember that 'i' was also intended to be the imaginary unit. Best thing is to pick something at the beginning of the program and stick to it.

From version 0.3 there are some helper methods and routines for working with complex (number) expressions:-

=head2 symbolic_complex()

Pass in an expression for the real component and an expression for the imaginary component and symbolic_complex will return a Math::Symbolic expression with the imaginary parameter multiplied by the contents of C<$Math::Symbolic::Custom::Collect::COMPLEX_VAR>, and summed with the real parameter. For example:-

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Collect;

    my $Re = 1;
    my $Im = 2;
    my $e = symbolic_complex($Re, $Im);
    print "$e\n"; # 1 + (2 * i)

    $e = symbolic_complex('exp(2)', 'sin(x)');
    print "$e\n"; # (e ^ 2) + ((sin(x)) * i)
    
=cut

sub symbolic_complex {
    my ($Re, $Im) = @_;
    
    $Re = parse_from_string($Re) unless ref($Re) =~ /^Math::Symbolic/;
    $Im = parse_from_string($Im) unless ref($Im) =~ /^Math::Symbolic/;    
    
    return Math::Symbolic::Operator->new('+', $Re, 
            Math::Symbolic::Operator->new('*', $Im, Math::Symbolic::Variable->new($COMPLEX_VAR)));
}

=head2 Method test_complex()

Returns the real and imaginary components of the expression as an array (the imaginary component has C<$Math::Symbolic::Custom::Collect::COMPLEX_VAR> removed). For example:-

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Collect;

    my ($Re, $Im) = parse_from_string('1+i')->test_complex();
    print "$Re\n";  # 1
    print "$Im\n";  # 1

    ($Re, $Im) = parse_from_string('x^2 + sin(x) - sqrt(-49)')->test_complex();
    print "$Re\n";  # (x ^ 2) + (sin(x))
    print "$Im\n";  # -7

=cut

sub test_complex {
    my ($t1) = @_;
    
    # use to_terms() to get all the terms
    my @terms = $t1->to_terms();
    
    if ( scalar(@terms) == 0 ) {    # ?? TODO: possible error in to_terms()
        return (Math::Symbolic::Constant->new(0), Math::Symbolic::Constant->new(0));
    }
    
    # check each one using explicit_signature() to see if it contains the imaginary unit
    # put in the real or imaginary arrays @Re and @Im as appropriate
    my @Re;
    my @Im;
    foreach my $term (@terms) {
        my @vars = $term->explicit_signature();
        my @cvar = grep { $_ eq $COMPLEX_VAR } @vars;
        if ( scalar @cvar ) {
            push @Im, $term;
        }
        else {
            push @Re, $term;
        }
    }

    # create an expression for the real part
    my $ntr;    
    if ( scalar(@Re) == 0 ) {   # no real part
        $ntr = Math::Symbolic::Constant->new(0);
    }
    else {
        # sum the @Re array
        $ntr = shift @Re;
        while (@Re) {
            my $e = shift @Re;
            $ntr = Math::Symbolic::Operator->new('+', $ntr, $e);
        }   
    }
    
    if ( scalar(@Im) == 0 ) {   # no imaginary part
        return ($ntr, Math::Symbolic::Constant->new(0));
    }    
    
    # Remove the imaginary unit from the imaginary part
    # Sum the imaginary terms
    my $nti = shift @Im;
    while (@Im) {
        my $e = shift @Im;
        $nti = Math::Symbolic::Operator->new('+', $nti, $e);
    }       

    # run to_collected() to get useful data structures
    my ($c, $nhr, $dhr) = $nti->to_collected();
    
    foreach my $hr ($nhr, $dhr) {
        next unless defined $hr;
    
        # figure out the variable name in the data structure with the imaginary unit
        my @vars = grep { $hr->{trees}{$_}{name} eq $COMPLEX_VAR } grep { /^VAR/ } keys %{$hr->{trees}};
        next if scalar(@vars) == 0; # could not find imaginary unit # TODO: fatal error if none present at all
        my $k = $vars[0];   # should only be one instance anyway
    
        my @t_keys = keys %{$hr->{terms}};
        foreach my $kss (@t_keys) {
            my $css = $hr->{terms}{$kss};
            my @tkss = split(/,/, $kss);
            my @n_ss = grep { $_ !~ /^$k/ } @tkss;  # remove imaginary unit from this term

            # update the data structure
            delete $hr->{terms}{$kss};
            if ( scalar @n_ss ) {
                $hr->{terms}{ join(",", @n_ss) } += $css;
            }
            else {
                $hr->{terms}{constant_accumulator} += $css;
            }
        }
    }

    # recombine
    my $new_n = build_summation_tree( $nhr );

    if ( defined $dhr ) {
        my $new_d = build_summation_tree( $dhr );
        my $t3 = Math::Symbolic::Operator->new( '/', $new_n, $new_d );
        
        return ($ntr, $t3);
    }
    else {
        return ($ntr, $new_n);
    }
}

=head2 Method to_complex_conjugate()

Returns the complex conjugate of the expression, essentially by multiplying the imaginary component by -1.

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Collect;

    my $cc = parse_from_string('1+i')->to_complex_conjugate();
    print "$cc\n"; # 1 - i

    $cc = parse_from_string('5*x+i*sin(y+z)')->to_complex_conjugate();
    print "$cc\n"; # (5 * x) - ((sin(y + z)) * i)

=cut

sub to_complex_conjugate {
    my ($t1) = @_;
    
    # extract the real and imaginary parts
    my ($Re, $Im) = $t1->test_complex();
    # multiple the imaginary part by -1 and use it to create a new complex expression
    my $ccj = symbolic_complex($Re, Math::Symbolic::Operator->new('*', Math::Symbolic::Constant->new(-1), $Im));
    return $ccj->to_collected();
}


#our %VARIABLE_CONSTRAINTS;
# e.g. %VARIABLE_CONSTRAINTS = (
#   'x'     =>      { nonzero => 1, positive => 1},     # x is > 0
#   'y'     =>      { nonzero => 1 },                   # y != 0
#   );

sub set_constraints {
    my ($var, @constraints) = @_;

    my %con;
    $con{$_} = 1 for @constraints;

    $VARIABLE_CONSTRAINTS{$var} = \%con;

    return;
}

sub add_constraints {
    my ($var, @constraints) = @_;

    my %con;
    if ( exists $VARIABLE_CONSTRAINTS{$var} ) {
        $con{$_} = 1 for keys %{$VARIABLE_CONSTRAINTS{$var}};
    }

    $con{$_} = 1 for @constraints;

    $VARIABLE_CONSTRAINTS{$var} = \%con;

    return;
}

sub remove_constraints {
    my ($var, @constraints) = @_;

    my %con;
    if ( exists $VARIABLE_CONSTRAINTS{$var} ) {
        $con{$_} = 1 for keys %{$VARIABLE_CONSTRAINTS{$var}};
    }

    delete $con{$_} for @constraints;

    $VARIABLE_CONSTRAINTS{$var} = \%con;

    return;
}

sub remove_all_constraints {
    my ($var) = @_;
    
    delete $VARIABLE_CONSTRAINTS{$var};
}

sub get_constraints {
    my ($var) = @_;

    return $VARIABLE_CONSTRAINTS{$var} || {};
}

sub get_constraints_as_list {
    my ($var) = @_;

    my @constraints;
    
    if ( exists $VARIABLE_CONSTRAINTS{$var} ) {
        my $con = $VARIABLE_CONSTRAINTS{$var};
        @constraints = grep { $con->{$_} == 1 } keys %{$con};
    }

    return @constraints;
}

sub test_constraint {
    my ($var, $constraint) = @_;

    if ( exists $VARIABLE_CONSTRAINTS{$var}{$constraint} ) {       
        return 1;        
    }

    return 0;
}


#### cancel_down. 
# Checks numerator and denominator expressions for constants and variables which can cancel.
sub cancel_down {
    my ($c_n, $n_cth, $c_d, $d_cth) = @_;

    my %n_ct = %{$n_cth};
    my %d_ct = %{$d_cth};

    my %n_terms = %{ $n_ct{terms} };
    my %n_funcs = %{ $n_ct{trees} };

    my %d_terms = %{ $d_ct{terms} };
    my %d_funcs = %{ $d_ct{trees} };

    my $n_acc = $n_terms{constant_accumulator} || 0;
    my $d_acc = $d_terms{constant_accumulator} || 0;

    delete $n_terms{constant_accumulator};
    delete $d_terms{constant_accumulator};

    my $did_some_cancellation = 0;

    my %constants;
    $constants{$n_acc}++ if $n_acc != 0;
    $constants{$d_acc}++ if $d_acc != 0;
    $constants{$_}++ for values %n_terms;
    $constants{$_}++ for values %d_terms;
    my @con = sort {$a <=> $b} map { abs } keys %constants;
    my @con_int = grep { $_ eq int($_) } @con;
    
    if ( scalar(@con) == scalar(@con_int) ) {

        my $min = $con[0];

        my $GCF;
        FIND_GCF: foreach my $div (reverse(2..$min)) {
            my $div_ok = 1;
            DIV_TEST: foreach my $num (@con) {
                if ( $num % $div != 0 ) {
                    $div_ok = 0;
                    last DIV_TEST;
                }
            }
            if ( $div_ok ) {
                $GCF = $div;
                last FIND_GCF;
            }
        }
        
        if ( defined $GCF ) {           
            $n_acc /= $GCF;
            $d_acc /= $GCF;
            $n_terms{$_} /= $GCF for keys %n_terms;
            $d_terms{$_} /= $GCF for keys %d_terms;
            $did_some_cancellation = 1;
        }
    }

    if ( ($n_acc == 0) && ($d_acc == 0) ) {

        # try to cancel vars
        # see if there are any common variables we can cancel
        # count up the number of unique vars within numerator and denominator
        my %c_vars;
        my %c_pow;
        foreach my $e (\%n_terms, \%d_terms) {
            foreach my $key (keys %{$e}) {
                my @v1 = split(/,/, $key);
                foreach my $v2 (@v1) {
                    my ($v, $c) = split(/:/, $v2);
                    if ( ($v =~ /^CONST/) or ($v =~ /^VAR/) ) {
                        $c_vars{$v}++;
                        if ( exists $c_pow{$v} ) {
                            if ( $c_pow{$v} > $c ) {
                                $c_pow{$v} = $c;
                            }
                        }
                        else {
                            $c_pow{$v} = $c;
                        }
                    }
                }
            }            
        }

        # if a variable exists in each term, perhaps we can cancel it
        my @all_terms;
        while ( my ($v, $c) = each %c_vars ) {
            if ( $c == (scalar(keys %n_terms)+scalar(keys %d_terms)) ) {

                if ( $v =~ /^CONST/ ) {
                    push @all_terms, $v;
                }
                elsif ( $v =~ /^VAR/ ) {
                    if ( $n_funcs{$v}->{name} ne $COMPLEX_VAR ) {
                        push @all_terms, $v;
                    }
                }                
            }
        }

        while ( my $v = pop @all_terms ) {

            my %n_ct_new;
            my %d_ct_new;

            my $num_d_terms = scalar(keys %d_terms);

            $did_some_cancellation = 0;

            # cancel from denominator
            while ( my ($t, $c) = each %d_terms ) {
                my @v1 = split(/,/, $t);
                my @nt;
                foreach my $v2 (@v1) {
                    my ($vv, $cc) = split(/:/, $v2);
                    if ($vv eq $v) {
                        if ( ($num_d_terms == 1) && ($cc == 1) && ($v =~ /^VAR/) && !test_constraint($d_funcs{$v}->{name}, 'nonzero') ) {          
                            # refuse to cancel all instances of a variable from the denominator
                            push @nt, $v2;
                        }
                        else {
                            my $c_sub = $c_pow{$v};
                            if ( $cc < $c_sub ) {
                                croak "cancel_down: Variable $v has index $cc but want to cancel $c_sub";
                            }                            
                            $cc -= $c_sub;
                            if ($cc > 0) {
                                push @nt, "$vv:$cc";
                                $did_some_cancellation = 1;
                            }
                            elsif ( scalar(@v1) == 1 ) {  
                                $d_acc = $c;
                                $did_some_cancellation = 1;
                            } 
                        }
                    }
                    else {
                        push @nt, $v2;
                    }
                }
                if ( scalar(@nt) ) {
                    $d_ct_new{join(",", @nt)} = $c;
                }
            }

            if ( $did_some_cancellation ) {
        
                # cancel from numerator
                while ( my ($t, $c) = each %n_terms ) {
                    my @v1 = split(/,/, $t);
                    my @nt;
                    foreach my $v2 (@v1) {
                        my ($vv, $cc) = split(/:/, $v2);
                        if ($vv eq $v) {
                            my $c_sub = $c_pow{$v};
                            if ( $cc < $c_sub ) {
                                croak "cancel_down: Variable $v has index $cc but want to cancel $c_sub";
                            }                            
                            $cc -= $c_sub;
                            if ($cc > 0) {
                                push @nt, "$vv:$cc";
                            }
                            elsif ( scalar(@v1) == 1 ) {  
                                $n_acc = $c;
                            } 
                        }
                        else {
                            push @nt, $v2;
                        }
                    }
                    if ( scalar(@nt) ) {
                        $n_ct_new{join(",", @nt)} = $c;              
                    }
                }
               
                %n_terms = %n_ct_new;
                %d_terms = %d_ct_new;
            }               
        }
    }

    # postprocess for constant exponents
    EXP_LOOP_n: foreach my $n_key (keys %n_terms) {
        my $coeff = $n_terms{$n_key};
        next EXP_LOOP_n unless $n_key =~ /\A CONST_(\d+):(\d+) \z/msx;
        my ($const, $exp) = ($1, $2);
        
        my $result = $const ** $exp;
        
        if ( ($result < $EXP_MAX)  ) {
            $n_acc += $coeff * $result;
            delete $n_terms{$n_key};
        }
    }
    
    EXP_LOOP_d: foreach my $d_key (keys %d_terms) {
        my $coeff = $d_terms{$d_key};
        next EXP_LOOP_d unless $d_key =~ /\A CONST_(\d+):(\d+) \z/msx;
        my ($const, $exp) = ($1, $2);
        
        my $result = $const ** $exp;
        
        if ( ($result < $EXP_MAX)  ) {
            $d_acc += $coeff * $result;
            delete $d_terms{$d_key};
        }
    }

    if ( (scalar(keys %n_terms) == 0) && (scalar(keys %d_terms) == 0) ) {
        # do some tidying up of constant fractions with negative denominators
        if ( $d_acc < 0 ) {
            $n_acc *= -1;
            $d_acc = abs($d_acc);
            $did_some_cancellation = 1;
        }
        # cancel down constant fraction if necessary
        if ( ($n_acc == int($n_acc)) && ($d_acc == int($d_acc)) ) {
            my $GCF = get_frac_GCF( abs($n_acc), abs($d_acc) );            
            $n_acc /= $GCF;
            $d_acc /= $GCF;
            $did_some_cancellation = 1;
        }     
    }

    $n_terms{constant_accumulator} = $n_acc;
    $d_terms{constant_accumulator} = $d_acc;

    my $n_hr = { terms => \%n_terms, trees => \%n_funcs };
    my $d_hr = { terms => \%d_terms, trees => \%d_funcs };

    if ( $did_some_cancellation ) {

        my $new_n = build_summation_tree( $n_hr );
        my $new_d = build_summation_tree( $d_hr );

        return ($new_n, $n_hr, $new_d, $d_hr);
    }

    return ($c_n, $n_cth, $c_d, $d_cth);
}

#### collect_like_terms
sub collect_like_terms {
    my ($t) = @_;
    
    my @elements;
    my $ok = get_elements_collect( \@elements, '+', $t, 1 );

    if ( $ok ) {
        my $ct_href = collect_terms(\@elements);
        if ( defined $ct_href ) {
            return (build_summation_tree($ct_href), $ct_href);
        }
    }
    
    return undef;
}

sub get_elements_collect {
    my ($l, $s, $tree) = @_;

    if ( $tree->term_type() == T_VARIABLE ) {
        my $r = { type => 'variable', object => $tree };
        if ( $s eq '+' ) {
            push @{$l}, $r;
        }
        elsif ( $s eq '-' ) {
            push @{$l}, { type => 'products', list => [ { type => 'constant', object => Math::Symbolic::Constant->new(-1) }, $r ] };    
        }
        return 1;
    }   
    elsif ( $tree->term_type() == T_CONSTANT ) {
        my $r = { type => 'constant', object => $tree };
        if ( $s eq '+' ) {
            push @{$l}, $r;
        }
        elsif ( $s eq '-' ) {
            push @{$l}, { type => 'products', list => [ { type => 'constant', object => Math::Symbolic::Constant->new(-1) }, $r ] };    
        }
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->arity() == 1) ) {

        # walk through functions e.g. sin, cos
        my $tree2 = $tree->new();
        my ($ctree) = to_collected($tree->op1());     
        if ( defined $ctree ) {
            $tree2->{operands}[0] = $ctree;
        }
        my $r = { type => 'function', object => $tree2 };
        if ( $s eq '+' ) {
            push @{$l}, $r;
        }
        elsif ( $s eq '-' ) {
            push @{$l}, { type => 'products', list => [ { type => 'constant', object => Math::Symbolic::Constant->new(-1) }, $r ] };    
        }
        return 1;        
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_PRODUCT) ) {
        my @product_elements;
        my $ok1 = get_product_elements_collect(\@product_elements, $tree->op1());
        my $ok2 = get_product_elements_collect(\@product_elements, $tree->op2());
        my @sorted = sort { $a->{type} cmp $b->{type} } @product_elements;

        if ( $ok1 && $ok2 ) {
            if ( $s eq '-' ) {
                push @sorted, { type => 'constant', object => Math::Symbolic::Constant->new(-1) };
            }
            push @{$l}, { type => 'products', list => \@sorted };   
            return 1;
        }
        return 0;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_SUM) ) {
        my $ok1 = get_elements_collect($l, '+', $tree->op1());
        my $ok2 = get_elements_collect($l, '+', $tree->op2());
        return $ok1 & $ok2; 
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_DIFFERENCE) ) {
        my $ok1 = get_elements_collect($l, '+', $tree->op1());
        my $ok2 = get_elements_collect($l, '-', $tree->op2());
        return $ok1 & $ok2; 
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_EXP) ) {
        # op1 must be a variable. op2 must be an int > 0
        my $op1 = $tree->op1();
        my $exp = $tree->op2();
        if (    ($op1->term_type() == T_VARIABLE) &&
                ($exp->term_type() == T_CONSTANT) &&
                ($exp->value() eq int($exp->value())) && 
                ($exp->value() > 0) ) {
    
            my @v_list;
            for (0..$exp->value()-1) {
                push @v_list, { type => 'variable', object => $op1->new() };
            }
            if ( $s eq '-' ) {
                push @v_list, { type => 'constant', object => Math::Symbolic::Constant->new(-1) };
            }
            push @{$l}, { type => 'products', list => \@v_list };
            return 1;
        }
        # do a list of constants
        elsif (    ($op1->term_type() == T_CONSTANT) &&
                ($exp->term_type() == T_CONSTANT) &&
                ($exp->value() eq int($exp->value())) && 
                ($exp->value() > 0) ) {
    
            my @v_list;
            my $result = $op1->value() ** $exp->value();
            if ( $result < $EXP_MAX ) {
                push @v_list, { type => 'constant', object => Math::Symbolic::Constant->new($result) };
            }
            else {
                for (0..$exp->value()-1) {
                    my $obj = $op1->new();
                    $obj->{special} = $op1->value();
                    $obj->{name} = q{};
                    push @v_list, { type => 'constant', object => $obj };
                }
            }
            if ( $s eq '-' ) {
                push @v_list, { type => 'constant', object => Math::Symbolic::Constant->new(-1) };
            }
            push @{$l}, { type => 'products', list => \@v_list };
            return 1;
        }
    }

    return 0;
}

sub get_product_elements_collect {
    my ($l, $tree) = @_;

    if ( $tree->term_type() == T_VARIABLE ) {
        push @{$l}, { type => 'variable', object => $tree, };
        return 1;
    }   
    elsif ( $tree->term_type() == T_CONSTANT ) {
        push @{$l}, { type => 'constant', object => $tree, };
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->arity() == 1) ) {
        my $tree2 = $tree->new();
        my $ctree = to_collected( $tree->op1() );
        if ( defined $ctree ) {
            $tree2->{operands}[0] = $ctree;
        }
        push @{$l}, { type => 'function', object => $tree2, };
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == U_MINUS) && ($tree->op1()->term_type() == T_CONSTANT) ) {
        # Fold U_MINUS of constant into constant
        push @{$l}, { type => 'constant', object => Math::Symbolic::Constant->new(-1), }; 
        push @{$l}, { type => 'constant', object => $tree->op1(), };
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_EXP) ) {
        # op1 must be a variable. op2 must be an int > 0
        my $op1 = $tree->op1();
        my $exp = $tree->op2();
        if (    ($op1->term_type() == T_VARIABLE) &&
                ($exp->term_type() == T_CONSTANT) &&
                ($exp->value() eq int($exp->value())) && 
                ($exp->value() > 0) ) {
    
            for (0..$exp->value()-1) {
                push @{$l}, { type => 'variable', object => $op1->new() };
            }            
            return 1;
        }
        elsif (    ($op1->term_type() == T_CONSTANT) &&
                ($exp->term_type() == T_CONSTANT) &&
                ($exp->value() eq int($exp->value())) && 
                ($exp->value() > 0) ) {
    
            my $result = $op1->value() ** $exp->value();
            if ( $result < $EXP_MAX ) {
                push @{$l}, { type => 'constant', object => Math::Symbolic::Constant->new($result) };
            }
            else {
                for (0..$exp->value()-1) {
                    my $obj = $op1->new();
                    $obj->{special} = $op1->value();
                    $obj->{name} = q{};
                    push @{$l}, { type => 'constant', object => $obj };
                }            
            }
            return 1;
        }
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_PRODUCT) ) {
        my $ok1 = get_product_elements_collect($l, $tree->op1());
        my $ok2 = get_product_elements_collect($l, $tree->op2());
        return $ok1 & $ok2; 
    }

    return 0;
}

sub collect_terms {
    my ($e) = @_;

    my @elements = @{$e};

    my $accumulator = 0;
    my %collected_terms;
    my $tree_num = 1;
    my %trees;    
    foreach my $e (@elements) {
        if ( ($e->{type} eq 'constant') ) {
            if ( $e->{object}->special() eq '' ) {
                $accumulator += $e->{object}->value();
            }
            else {               
                my $name;
                GET_CONST_NAME_1: foreach my $n (grep { /^CONST/ } keys %trees) {
                    if ( $e->{object}->is_identical($trees{$n}) ) {
                        $name = $n;
                        last GET_CONST_NAME_1;
                    }
                }
                if ( not defined $name ) {
                    $name = 'CONST' . "_" . $e->{object}->{special};
                    $trees{$name} = $e->{object};
                    $tree_num++;
                }
                $collected_terms{terms}{$name . ":1"}++;                
            }
        }
        elsif ( $e->{type} eq 'variable' ) {
            my $name;
            GET_VAR_NAME_1: foreach my $n (grep { /^VAR/ } keys %trees) {
                if ( $e->{object}->is_identical($trees{$n}) ) {
                    $name = $n;
                    last GET_VAR_NAME_1;
                }
            }
            if ( not defined $name ) {
                $name = 'VAR' . "_" . $e->{object}->{name};
                $trees{$name} = $e->{object};
                $tree_num++;
            }
            $collected_terms{terms}{$name . ":1"}++;     
        }
        elsif ( $e->{type} eq 'function' ) {
            my $name;
            GET_FUNC_NAME_1: foreach my $n (grep { /^FUNC/ } keys %trees) {
                if ( $e->{object}->is_identical($trees{$n}) ) {
                    $name = $n;
                    last GET_FUNC_NAME_1;
                }
            }
            if ( not defined $name ) {
                $name = 'FUNC' . $tree_num;
                $trees{$name} = $e->{object};
                $tree_num++;
            }
            $collected_terms{terms}{$name . ":1"}++;     
        }
        elsif ( $e->{type} eq 'products' ) {
            my @list = @{$e->{list}};
            # if it's a list of constants, fold them into the accumulator
            my @con_list = grep { ($_->{type} eq 'constant') && ($_->{object}->special() eq '') } @list;
            if (scalar(@con_list) == scalar(@list)) {
                my $c_n = 1;
                $c_n *= $_->{object}->value() for @list;
                $accumulator += $c_n;
            }
            else {
                my $num_coeff = 1;
                my %hist;
                foreach my $l (@list) {
                    if ( ($l->{type} eq 'constant') ) {
                        if ( $l->{object}->special() eq '' ) {
                            $num_coeff *= $l->{object}->value();
                        }
                        else {               
                            my $name;
                            GET_CONST_NAME_2: foreach my $n (grep { /^CONST/ } keys %trees) {
                                if ( $l->{object}->is_identical($trees{$n}) ) {
                                    $name = $n;
                                    last GET_CONST_NAME_2;
                                }
                            }
                            if ( not defined $name ) {
                                $name = 'CONST' . "_" . $l->{object}->{special};
                                $trees{$name} = $l->{object};
                                $tree_num++;
                            }                            
                            $hist{$name}++;
                        }
                    }
                    elsif ($l->{type} eq 'variable') {
                        my $name;
                        GET_VAR_NAME_2: foreach my $n (grep { /^VAR/ } keys %trees) {
                            if ( $l->{object}->is_identical($trees{$n}) ) {
                                $name = $n;
                                last GET_VAR_NAME_2;
                            }
                        }
                        if ( not defined $name ) {
                            $name = 'VAR' . "_" . $l->{object}->{name};
                            $trees{$name} = $l->{object};
                            $tree_num++;
                        }
                        $hist{$name}++;
                    }
                    elsif ($l->{type} eq 'function') {
                        my $name;
                        GET_FUNC_NAME_2: foreach my $n (grep { /^FUNC/ } keys %trees) {
                            if ( $l->{object}->is_identical($trees{$n}) ) {
                                $name = $n;
                                last GET_FUNC_NAME_2;
                            }
                        }
                        if ( not defined $name ) {
                            $name = 'FUNC' . $tree_num;
                            $trees{$name} = $l->{object};
                            $tree_num++;
                        }
                        $hist{$name}++;
                    }
                    else {                    
                        return (undef, undef);
                    }
                }
                my @str_elems;
                foreach my $k (sort keys %hist) {
                    push @str_elems, join(":", $k, $hist{$k});
                }
                my $key = join(",", @str_elems);
                $collected_terms{terms}{$key} += $num_coeff;
            }
        }
    }    
   
    # Post-process for complex numbers
    # see if expression contains the designated complex variable.
    my $contains_complex = 0;
    my $complex_name;
    GET_COMPLEX: foreach my $k (grep { /^VAR/ } keys %trees) {
        if ( $trees{$k}->{name} eq $COMPLEX_VAR ) {
            $contains_complex = 1;
            $complex_name = $k;
            last GET_COMPLEX;
        }
    }

    if ( $contains_complex ) {

        my %c_ct_new;

        while ( my ($t, $c) = each %{$collected_terms{terms}} ) {
            my @v1 = split(/,/, $t);
            my @nt;
            foreach my $v2 (@v1) {
                my ($vv, $cc) = split(/:/, $v2);
                if (($vv eq $complex_name) && ($cc > 1) && ($cc == int($cc))) {
                    # various results from different powers of the imaginary unit
                    my $pmod = $cc % 4;
                    if ( $pmod == 0 ) {
                        if ( scalar(@v1) == 1 ) {
                            $accumulator += $c;
                        }
                    }
                    elsif ( $pmod == 1 ) {
                        push @nt, "$vv:1";
                    }
                    elsif ( $pmod == 2 ) {
                        $c *= -1;
                        if ( scalar(@v1) == 1 ) {
                            $accumulator += $c;
                        }
                    }
                    elsif ( $pmod == 3 ) {
                        $c *= -1;
                        push @nt, "$vv:1";
                    }
                }
                else {
                    push @nt, $v2;
                }
            }
            if ( scalar(@nt) ) {
                my $nk = join(",", @nt);
                if ( exists $c_ct_new{$nk} ) {
                    $c_ct_new{$nk} += $c;
                }
                else {
                    $c_ct_new{$nk} = $c;
                }
            }
        }

         $collected_terms{terms} = \%c_ct_new;
    }

    # put the accumulator into the data structure
    $collected_terms{terms}{constant_accumulator} = $accumulator;
    # and the functions 
    $collected_terms{trees} = \%trees;

    return \%collected_terms;
}

sub get_term_name {
    my ($tn, $thr) = @_;

    if ( $tn =~ /^VAR/ ) {

        my ($n,$p) = split(/:/, $tn);
        if ( exists $thr->{$n} ) {
            $tn = $thr->{$n}{name} . $p;
        }
    }

    return $tn;
}


sub build_summation_tree {
    my ($ct) = @_;
    my %ct = %{$ct};
    my %collected_terms = %{$ct{terms}};
    my %trees = %{$ct{trees}};

    my $accumulator = $collected_terms{constant_accumulator};
    delete $collected_terms{constant_accumulator};
    
    # check if all coefficients are zero
    my @coeffs = values %collected_terms;
    my @zero = grep { $_ == 0 } @coeffs;
    if ( scalar(@zero) == scalar(@coeffs) ) {
        return Math::Symbolic::Constant->new( $accumulator );
    }

    # try to put the terms in a neat consistent order
    my @sorted_terms =  sort {  length(get_term_name($a, \%trees)) <=> length(get_term_name($b, \%trees)) || 
                                get_term_name($a, \%trees) cmp get_term_name($b, \%trees) || 
                                $collected_terms{$a} <=> $collected_terms{$b} } 
                                keys %collected_terms;

    my @negative = grep { $_ <= 0 } @coeffs;
    my $all_neg = 0;
    if ( scalar(@negative) == scalar(@sorted_terms) ) {
        $all_neg = 1;
    }

    # generate the Math::Symbolic tree
    my @to_sum;
    if ( $accumulator > 0 ) {
        push @to_sum, ['+', Math::Symbolic::Constant->new($accumulator)];
    }
    elsif ( $accumulator < 0 ) {
        push @to_sum, ['-', Math::Symbolic::Constant->new(abs($accumulator))];
    }

    my $c = 0;
    TERM_LOOP: foreach my $term (@sorted_terms) {
        
        my $const = $collected_terms{$term};
        next TERM_LOOP if $const == 0;

        my @product_list;
        my $sign = '+';
        if ( $all_neg && ($c == 0) && ($accumulator == 0) ) {
            # keep first one negative
        }
        elsif ( ($const < 0) ) {
            $sign = '-';
            $const = abs($const);
        }
        if ( $const != 1 ) {
            push @product_list, Math::Symbolic::Constant->new( $const );
        }

        my @vars = split(/,/, $term);
        VAR_LOOP: foreach my $v (@vars) {    
            
            my ($var, $pow) = split(/:/, $v);            
            next VAR_LOOP if $pow == 0; #?? how would that get there?

            if ( exists $trees{$var} ) {
                if ( $pow == 1 ) {
                    push @product_list, $trees{$var}->new();
                }
                else {
                    push @product_list, Math::Symbolic::Operator->new('^', $trees{$var}->new(), Math::Symbolic::Constant->new($pow));
                }
            }
            else {
                 croak "build_summation_tree: Found something without an associated Math::Symbolic object!: $var";
            }
        }

        my $ntp = shift @product_list;
        while (@product_list) {
            my $e = shift @product_list;
            $ntp = Math::Symbolic::Operator->new( '*', $ntp, $e );
        }

        push @to_sum, [$sign, $ntp];
        $c++;
    }

    @to_sum = sort { $a->[0] cmp $b->[0] } @to_sum if !$all_neg;

    my $first = shift @to_sum;
    my $nt = $first->[1];
    if ( $first->[0] eq '-' ) {       
        if ( ($first->[1]->term_type() == T_CONSTANT) && ($first->[1]->special() eq '') ) {
            # folding -1 into constant
            $nt = Math::Symbolic::Constant->new(-1 * $first->[1]->value());
        }
        else {
            # FIXME: this feels like a bodge
            $nt = Math::Symbolic::Operator->new('neg', $nt);
        }
    }

    while (@to_sum) {
        my $e = shift @to_sum;
        if ( $e->[0] eq '+' ) {
            $nt = Math::Symbolic::Operator->new( '+', $nt, $e->[1] );
        }
        elsif ( $e->[0] eq '-' ) {
            $nt = Math::Symbolic::Operator->new( '-', $nt, $e->[1] );
        }
    }

    return $nt;
}

###########################

sub get_frac_GCF {
    my ($n, $d) = @_;

    my $min = ($n < $d ? $n : $d);
    my $GCF = 1;
    DIV_GCF: foreach my $div (reverse(2..$min)) {
        if ( (($n % $div) == 0) && (($d % $div) == 0) ) {
            $GCF = $div;
            last DIV_GCF;
        } 
    }

    return $GCF;
}

sub prepare {
    my ($t, $d) = @_;

    if ( defined $d ) {
        $d++;
    }
    else {
        $d = 0;
    }
    
    my $op_arity = 0;
    if ( $t->term_type() == T_OPERATOR ) {
        $op_arity = $t->arity();  
    }
    
    my $return_t;
    
    if ( $t->term_type() == T_VARIABLE ) {
         $return_t = $t->new();
    }
    elsif ( $t->term_type() == T_CONSTANT ) {
        # convert (non-integer decimal) constants into rational numbers where possible
        my $val = $t->value();
        if ( ($val eq int($val)) || length($t->special()) ) {
            $return_t = $t->new();
        }
        else {
            my (undef, $frac) = split(/\./, $val);
            if ( defined($frac) && (length($frac)>=1) && (length($frac)<10) ) {
                my $mult = 10**length($frac);
                my $n = $val*$mult;
                my $GCF = get_frac_GCF($n, $mult);
                $return_t = Math::Symbolic::Operator->new( '/', Math::Symbolic::Constant->new($n/$GCF), Math::Symbolic::Constant->new($mult/$GCF) );
            }
            else {
                $return_t = $t->new();
            }
        }
    }
    elsif ( $op_arity == 2 ) {

        # recursion.
        my $op1 = prepare( $t->op1(), $d );
        my $op2 = prepare( $t->op2(), $d );
        
        # collect some obvious constant expressions while we are in here.
        # also combine fractions to make it easier to collect like terms.
        # expand out brackets and indices where possible.
        #
        # here come the "hardly readable if-else blocks" Steffen warned of in Math::Symbolic::Custom::Transformation
        if ( $t->type() == B_SUM ) {
            if ( ($op1->term_type() == T_CONSTANT) && ($op1->special() eq '') && ($op2->term_type() == T_CONSTANT) && ($op2->special() eq '') ) {
                # Executing addition of two constants
                $return_t = Math::Symbolic::Constant->new($op1->value() + $op2->value());
            }
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op1->value() == 0) ) {
                # Removing addition with 0
                $return_t = $op2;
            }
            elsif ( ($op2->term_type() == T_CONSTANT) && ($op2->value() == 0) ) {
                # Removing addition with 0
                $return_t = $op1;
            }
            elsif (     ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_DIVISION) &&
                        ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) ) {                
                # Adding two fractions into one
                my $frac1 = $op1;
                my $frac2 = $op2;
                my $denom_left = $frac1->op2();
                my $denom_right = $frac2->op2();

                if ( $denom_left->is_identical($denom_right) ) {
                    my $numerator = Math::Symbolic::Operator->new( '+', $frac1->op1(), $frac2->op1() );
                    $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, $denom_right ), $d);
                }
                else {
                    my $num_left = Math::Symbolic::Operator->new( '*', $frac1->op1(), $denom_right );
                    my $num_right = Math::Symbolic::Operator->new( '*', $frac2->op1(), $denom_left );
                    my $numerator = Math::Symbolic::Operator->new( '+', $num_left, $num_right );
                    my $denominator = Math::Symbolic::Operator->new( '*', $denom_left, $denom_right );
                    $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, $denominator ), $d);                                  
                }                
            }
            elsif ( ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_DIVISION) ) {
                # Merging sum into fraction
                my $numerator = $op1->op1();
                my $denominator = $op1->op2();
                my $m1 = Math::Symbolic::Operator->new( '*', $op2, $denominator );
                my $new_numerator = Math::Symbolic::Operator->new( '+', $numerator, $m1 );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $new_numerator, $denominator ), $d);                                  
            }
            elsif ( ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) ) {                
                # Merging sum into fraction                
                my $numerator = $op2->op1();
                my $denominator = $op2->op2();
                my $m1 = Math::Symbolic::Operator->new( '*', $op1, $denominator );
                my $new_numerator = Math::Symbolic::Operator->new( '+', $numerator, $m1 );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $new_numerator, $denominator ), $d);                                  
            }
            else {
                # Passing through addition
                $return_t = Math::Symbolic::Operator->new('+', $op1, $op2) ;
            }
        }
        elsif ( $t->type() == B_DIFFERENCE ) {
            if ( ($op1->term_type() == T_CONSTANT) && ($op1->special() eq '') && ($op2->term_type() == T_CONSTANT) && ($op2->special() eq '') ) {
                # Executing subtraction of two constants
                $return_t = Math::Symbolic::Constant->new( $op1->value() - $op2->value() );
            }
            elsif ( ($op2->term_type() == T_CONSTANT) && ($op2->value() == 0) ) {
                # Removing subtraction of 0
                $return_t = $op1;
            }
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op1->value() == 0) ) {
                # Changing subtraction from 0 to multiplication by -1
                my $ntp = Math::Symbolic::Operator->new( '*', Math::Symbolic::Constant->new(-1), $op2 );
                $return_t = prepare($ntp, $d);
            }
            elsif (     ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_DIVISION) &&
                        ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) ) {
                # Subtracting two fractions into one                
                my $frac1 = $op1;
                my $frac2 = $op2;
                my $denom_left = $frac1->op2();
                my $denom_right = $frac2->op2();

                if ( $denom_left->is_identical($denom_right) ) {
                    my $numerator = Math::Symbolic::Operator->new( '-', $frac1->op1(), $frac2->op1() );
                    $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, $denom_right ), $d);
                }
                else {
                    my $num_left = Math::Symbolic::Operator->new( '*', $frac1->op1(), $denom_right );
                    my $num_right = Math::Symbolic::Operator->new( '*', $frac2->op1(), $denom_left );
                    my $numerator = Math::Symbolic::Operator->new( '-', $num_left, $num_right );
                    my $denominator = Math::Symbolic::Operator->new( '*', $denom_left, $denom_right );
                    $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, $denominator ), $d);                                  
                }                
            }
            elsif ( ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_DIVISION) ) {            
                # Merging subtraction into fraction          
                my $numerator = $op1->op1();
                my $denominator = $op1->op2();
                my $m1 = Math::Symbolic::Operator->new( '*', $op2, $denominator );
                my $new_numerator = Math::Symbolic::Operator->new( '-', $numerator, $m1 );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $new_numerator, $denominator ), $d);                                  
            }
            elsif ( ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) ) {
                # Merging subtraction into fraction                
                my $numerator = $op2->op1();
                my $denominator = $op2->op2();
                my $m1 = Math::Symbolic::Operator->new( '*', $op1, $denominator );
                my $new_numerator = Math::Symbolic::Operator->new( '-', $m1, $numerator );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $new_numerator, $denominator ), $d);                                  
            }
            else {
                # Converting subtraction into addition
                my $ntp = Math::Symbolic::Operator->new('*', Math::Symbolic::Constant->new(-1), $op2);
                $ntp = Math::Symbolic::Operator->new('+', $op1, $ntp);
                $return_t = prepare($ntp, $d);
            }
        }
        elsif ( $t->type() == B_DIVISION ) {
            if ( ($op2->term_type() == T_CONSTANT) && ($op2->value() == 0) ) {
                # Division by zero found
                croak "prepare: Division by zero found. Refusing to proceed.";  # TODO
            }
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op1->value() == 0) ) {
                # Dividing something into 0. Returning 0
                $return_t = Math::Symbolic::Constant->new(0);                     
            }
            elsif ( ($op2->term_type() == T_CONSTANT) && ($op2->value() == 1) ) {
                # Division by unity found, removing division
                $return_t = $op1;
            }
            elsif ( ($op1->term_type() == T_VARIABLE) && ($op2->term_type() == T_VARIABLE) && 
                    ($op1->name() eq $op2->name()) && test_constraint($op1->name(), 'nonzero') ) {
                $return_t = Math::Symbolic::Constant->new(1);                 
            }
            # TODO: more complicated expressions, e.g. (y*x)/x
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op1->special() eq '') && ($op2->term_type() == T_CONSTANT) && ($op2->special() eq '') ) {
                if ( ($op1->value()/$op2->value()) eq int($op1->value()/$op2->value()) ) {
                    # Denominator evenly divides into numerator, removing division
                    $return_t = Math::Symbolic::Constant->new($op1->value()/$op2->value())
                }
                elsif ( ($op1->value() == int($op1->value())) && ($op2->value() == int($op2->value())) ) {
                    # Cancel down constant fraction
                    my $GCF = get_frac_GCF( abs($op1->value()), abs($op2->value()) );
                    $return_t = Math::Symbolic::Operator->new('/', Math::Symbolic::Constant->new($op1->value()/$GCF), Math::Symbolic::Constant->new($op2->value()/$GCF));
                }
                else {
                    # Passing through division
                    $return_t = Math::Symbolic::Operator->new('/', $op1, $op2);
                }
            }
            elsif ( ($op2->term_type() == T_CONSTANT) && ($op2->special() eq '') && ($op2->value() < 0) ) {
                # Pulling negative out of denominator
                my $numerator = Math::Symbolic::Operator->new( '*', Math::Symbolic::Constant->new(-1), $op1 );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, Math::Symbolic::Constant->new(abs($op2->value())) ), $d);
            }    
            elsif ( ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_PRODUCT) &&
                    ($op2->op1()->term_type() == T_CONSTANT) && ($op2->op1()->special() eq '') && ($op2->op1()->value() < 0) ) {
                # Pulling negative out of denominator
                my $numerator = Math::Symbolic::Operator->new( '*', Math::Symbolic::Constant->new(-1), $op1 );
                my $denominator = Math::Symbolic::Operator->new( '*', Math::Symbolic::Constant->new(abs($op2->op1()->value())), $op2->op2()->new() );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, $denominator ), $d);
            }
            elsif ( ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_PRODUCT) &&
                    ($op2->op2()->term_type() == T_CONSTANT) && ($op2->op2()->special() eq '') && ($op2->op2()->value() < 0) ) {
                # Pulling negative out of denominator
                my $numerator = Math::Symbolic::Operator->new( '*', Math::Symbolic::Constant->new(-1), $op1->new() );
                my $denominator = Math::Symbolic::Operator->new( '*', $op2->op1()->new(), Math::Symbolic::Constant->new(abs($op2->op2()->value())) );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, $denominator ), $d);
            }            
            elsif (     ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_DIVISION) &&
                        ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) ) {
                # Dividing two fractions into one fraction
                my $numerator = Math::Symbolic::Operator->new( '*', $op1->op1(), $op2->op2() );
                my $denominator = Math::Symbolic::Operator->new( '*', $op1->op2(), $op2->op1() );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, $denominator ), $d);                        
            }                        
            elsif ( ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_DIVISION) ) {
                # Numerator is fraction, dividing into one fraction
                $return_t = prepare(Math::Symbolic::Operator->new('/', $op1->op1(), Math::Symbolic::Operator->new('*', $op1->op2(), $op2)), $d);
            }
            elsif ( ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) ) {
                # Denominator is fraction, dividing into one fraction
                $return_t = prepare(Math::Symbolic::Operator->new('/', Math::Symbolic::Operator->new('*', $op1, $op2->op2()), $op2->op1()), $d);
            }
            # TODO: check these rules
            elsif (     ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_EXP) &&
                        ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_EXP) &&
                        $op1->op1()->is_identical($op2->op1())
                        ) {
                # x^m / x^n = x^(m-n)
                my $sum = Math::Symbolic::Operator->new('-', $op1->op2(), $op2->op2());
                $return_t = prepare(Math::Symbolic::Operator->new( '^', $op1->op1(), $sum->to_collected() ), $d);
            }
            elsif (     ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_EXP) &&
                        ($op2->term_type() == T_CONSTANT) && ($op2->value() != 0) &&
                        ($op1->op1()->term_type() == T_CONSTANT) && ($op1->op1()->value() == $op2->value())
                        ) {

                # x^m / x = x^m-1
                my $sum = Math::Symbolic::Operator->new('-', $op1->op2(), Math::Symbolic::Constant->new(1));
                $return_t = prepare(Math::Symbolic::Operator->new( '^', $op1->op1(), $sum->to_collected() ), $d);                
            }
            else {
                # Passing through division
                $return_t = Math::Symbolic::Operator->new('/', $op1, $op2);
            }
        }
        elsif ( $t->type() == B_PRODUCT ) {            
            if (    (($op1->term_type() == T_CONSTANT) && ($op1->value() == 0)) || 
                    (($op2->term_type() == T_CONSTANT) && ($op2->value() == 0))
                ) {
                # Multiplication by 0. Returning 0
                $return_t = Math::Symbolic::Constant->new(0);
            }
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op1->value() == 1) ) {
                # Removing multiply by unity
                $return_t = $op2;
            }
            elsif ( ($op2->term_type() == T_CONSTANT) && ($op2->value() == 1) ) {
                # Removing multiply by unity
                $return_t = $op1;
            }
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op1->special() eq '') && ($op2->term_type() == T_CONSTANT) && ($op2->special() eq '') ) {
                # Executing multiplication of two constants
                $return_t = Math::Symbolic::Constant->new($op1->value() * $op2->value());
            }
            elsif (     ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_DIVISION) &&
                        ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) ) {
                # Multiplying two fractions into one fraction
                my $numerator = Math::Symbolic::Operator->new( '*', $op1->op1(), $op2->op1() );
                my $denominator = Math::Symbolic::Operator->new( '*', $op1->op2(), $op2->op2() );
                $return_t = Math::Symbolic::Operator->new( '/', prepare($numerator, $d), prepare($denominator, $d) );                                  
            }
            elsif ( ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_DIVISION) ) {
                # Multiplying with a fraction                         
                my $numerator = Math::Symbolic::Operator->new( '*', $op1->op1(), $op2 );
                $return_t = Math::Symbolic::Operator->new( '/', prepare($numerator, $d), $op1->op2() );
            }            
            elsif ( ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) ) {
                # Multiplying with a fraction
                my $numerator = Math::Symbolic::Operator->new( '*', $op2->op1(), $op1 );
                $return_t = Math::Symbolic::Operator->new( '/', prepare($numerator, $d), $op2->op2() );   
            }
            elsif (     ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_EXP) &&
                        ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_EXP) &&
                        $op1->op1()->is_identical($op2->op1())
                        ) {
                # x^m * x^n = x^(m+n)
                my $sum = Math::Symbolic::Operator->new('+', $op1->op2(), $op2->op2());
                $return_t = prepare(Math::Symbolic::Operator->new( '^', $op1->op1(), $sum->to_collected() ), $d);
            }
            elsif (     ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_EXP) &&
                        (($op2->term_type() == T_CONSTANT) || ($op2->term_type() == T_VARIABLE)) &&     # FIXME: could it be any expression? (and below)
                        $op1->op1()->is_identical($op2)
                        ) {
                # x^m * x = x^(m+1)
                my $sum = Math::Symbolic::Operator->new('+', $op1->op2(), 1);
                $return_t = prepare(Math::Symbolic::Operator->new( '^', $op1->op1(), $sum->to_collected() ), $d);
            }
            elsif (     ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_EXP) &&
                        (($op1->term_type() == T_CONSTANT) || ($op1->term_type() == T_VARIABLE)) &&
                        $op2->op1()->is_identical($op1)
                        ) {
                # x * x^m = x^(m+1)
                my $sum = Math::Symbolic::Operator->new('+', $op2->op2(), 1);
                $return_t = prepare(Math::Symbolic::Operator->new( '^', $op2->op1(), $sum->to_collected() ), $d);
            }
            elsif (     (($op1->term_type() == T_OPERATOR) && (($op1->type() == B_SUM) || ($op1->type() == B_DIFFERENCE))) || 
                        (($op2->term_type() == T_OPERATOR) && (($op2->type() == B_SUM) || ($op2->type() == B_DIFFERENCE))) ) {
                # Attempting to multiply out brackets
                my @elements1;
                my @elements2;
                my $good = get_elements( \@elements1, '+', $op1 );

                if ( $good ) {
                    my $sign = '+';
                    $sign = '-' if ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIFFERENCE);
                    $good = get_elements( \@elements2, $sign, $op2 );
                }
        
                if ( $good ) {
                    # Contents of operands look okay for multiplying out
                    my @to_sum;
                    foreach my $elem1 (sort { $a->{type} cmp $b->{type} } @elements1) {
                        foreach my $elem2 (sort { $a->{type} cmp $b->{type} } @elements2) {       
                            next if ($elem1->{type} eq 'constant') && ($elem1->{object}->value() == 0);
                            next if ($elem2->{type} eq 'constant') && ($elem2->{object}->value() == 0);

                            if ( exists($elem1->{list}) && exists($elem2->{list}) ) {
                                my $num_entries = scalar(@{$elem2->{list}});
                                push @{$elem1->{list}}, @{$elem2->{list}};
                                push @to_sum, create_element( $elem1 );
                                pop @{$elem1->{list}} for (1..$num_entries);
                            }
                            elsif ( exists($elem1->{list}) ) {
                                push @{$elem1->{list}}, $elem2;
                                push @to_sum, create_element( $elem1 );
                                pop @{$elem1->{list}};                            
                            
                            }
                            elsif ( exists($elem2->{list}) ) {
                                push @{$elem2->{list}}, $elem1;
                                push @to_sum, create_element( $elem2 );
                                pop @{$elem2->{list}};
                            }                    
                            else {
                                my $e = { type => 'products', list => [ $elem1, $elem2 ] };
                                push @to_sum, create_element( $e );
                            }                    
                        }
                    }

                    if ( scalar(@to_sum) == 0 ) {
                        $return_t = Math::Symbolic::Constant->new(0);
                    }
                    else {
                        my $ntp = shift @to_sum;
                        while (@to_sum) {
                            my $e = shift @to_sum;
                            $ntp = Math::Symbolic::Operator->new( '+', $ntp, $e );
                        }
                        $return_t = prepare($ntp, $d);
                    }
                }
                else {
                    # Contents of operands NOT ready for multiplying out. Passing through
                    $return_t = Math::Symbolic::Operator->new('*', $op1, $op2);
                }   
            }
            else {
                # Passing through multiplication
                $return_t = Math::Symbolic::Operator->new('*', $op1, $op2);
            }
        }
        elsif ( $t->type() == B_EXP ) {

            if ( ($op1->term_type() == T_OPERATOR) && ($op1->type() == B_EXP) ) {
                $return_t = prepare( Math::Symbolic::Operator->new('^', $op1->op1(), Math::Symbolic::Operator->new('*', $op1->op2(), $op2)), $d);
            }
            elsif ( ($op2->term_type() == T_CONSTANT) && ($op2->special() eq '') ) {         
     
                my $val = $op2->value();

                if ( $val == 0 ) {
                    $return_t = Math::Symbolic::Constant->new(1);
                }   
                elsif ( $val == 1 ) {
                    # Found expression^1. Return the expression
                    $return_t = $op1;
                }
                elsif ( ($val > 1) && ($val eq int($val)) ) {        

                    if ( ($op1->term_type() == T_CONSTANT) && ($op1->special() eq '') ) {
                        $return_t = Math::Symbolic::Operator->new('^', $op1->value(), $val);
                    }
                    else {

                        # Found constant positive integer power. Removing exponent through multiplication                    
                        my @product_list = ($op1) x $val;
                        my $ntp = shift @product_list;
                        while (@product_list) {
                            my $e = shift @product_list;
                            $ntp = Math::Symbolic::Operator->new( '*', $ntp, $e );
                        }
                        $return_t = prepare($ntp, $d);
                    }
                }
                elsif ( $val == -1 ) {
                    # remove negative index
                    $return_t = prepare( Math::Symbolic::Operator->new('/', Math::Symbolic::Constant->new(1), $op1), $d );
                }
                elsif ( $val < -1 ) {
                    $return_t = prepare( Math::Symbolic::Operator->new( '/', 
                                            Math::Symbolic::Constant->new(1), 
                                            Math::Symbolic::Operator->new('^', $op1, Math::Symbolic::Constant->new(abs($val))) 
                                        ), $d);
                }  
                else {
                    # Passing through exponentiation
                    my $op1_col;
                    if ( $op1->term_type() == T_OPERATOR ) {
                        $op1_col = $op1->to_collected(); # try to collect up the subexpression
                    }
                    if ( defined($op1_col) && !$op1->is_identical($op1_col) ) {
                        $op1 = $op1_col;
                    }

                    $return_t = Math::Symbolic::Operator->new('^', $op1, $op2);
                }
            }
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op1->special() eq '') &&
                    ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_DIVISION) &&
                    ($op2->op1()->term_type == T_CONSTANT) && ($op2->op1()->value() == 1) &&
                    ($op2->op2()->term_type == T_CONSTANT) && ($op2->op2()->value() == 2)
                    ) {                

                if ( $op1->value() < 0 ) {                    
                    $return_t = Math::Symbolic::Operator->new('*',  Math::Symbolic::Variable->new($COMPLEX_VAR), 
                                                                    prepare(Math::Symbolic::Operator->new('^', Math::Symbolic::Constant->new(abs($op1->value())), $op2), $d));
                }
                elsif ( $op1->value() == 0 ) {
                    $return_t = Math::Symbolic::Constant->new(0);
                }
                else {
                    # sqrt of a positive constant.
                    my $sqrt = sqrt($op1->value());
                    if ( $sqrt == int($sqrt) ) {
                        $return_t = Math::Symbolic::Constant->new($sqrt);
                    }
                    else {
                        # Passing through exponentiation
                        $return_t = Math::Symbolic::Operator->new('^', $op1, $op2 );
                    }
                }
            }
            else {
                # Passing through exponentiation
                my $op1_col;
                if ( $op1->term_type() == T_OPERATOR ) {
                    $op1_col = $op1->to_collected();
                }
                if ( defined($op1_col) && !$op1->is_identical($op1_col) ) {
                    $op1 = $op1_col;
                }

                my $op2_col;
                if ( $op2->term_type() == T_OPERATOR ) {
                    $op2_col = $op2->to_collected();
                }
                if ( defined($op2_col) && !$op2->is_identical($op2_col) ) {
                    $op2 = $op2_col;
                }

                $return_t = Math::Symbolic::Operator->new('^', $op1, $op2);
            }
        }
        elsif ( ($t->type() == U_P_DERIVATIVE) || ($t->type() == U_T_DERIVATIVE) ) {
            # pass through derivative operators, but try collect up the internal expression
            my $op1_col = $op1->to_collected();
            if ( defined $op1_col ) {
                $op1 = $op1_col;
            }
            my $op_type = 'partial_derivative';
            $op_type = 'total_derivative' if $t->type() == U_T_DERIVATIVE;
            $return_t = Math::Symbolic::Operator->new($op_type, $op1, $op2);
        }
        else {
            my $o = $t->new();
            $o->{operands}[0] = $op1;
            $o->{operands}[1] = $op2;
            $return_t = $o;
        }
    }
    elsif ( $op_arity == 1 ) {

        my $op1 = prepare($t->op1(), $d);
    
        if ( $t->type() == U_MINUS ) {
            if ( ($op1->term_type() == T_CONSTANT) && ($op1->special() eq '') ) {
                # Removing negation of a constant by directly folding multiplication of -1 into that constant
                $return_t = Math::Symbolic::Constant->new( -1*$op1->value() );
            }
            else {
                # Replacing negation by multiplication of subexpression by -1
                my $ntp = Math::Symbolic::Operator->new('*', Math::Symbolic::Constant->new(-1), $op1);       
                $return_t = prepare($ntp, $d);
            }
        }
        else { 
            my $o = $t->new();
            $o->{operands}[0] = $op1;
            $return_t = $o;
        }        
    }
    else {
        croak "prepare: cannot process operator with arity [$op_arity]";
    }

    if ( not defined $return_t ) {
        croak "prepare: reached end. Cannot process";
    }

    return $return_t;
}

# unfortunately, these routines are slightly different to the ones for collecting like terms
sub get_elements {
    my ($l, $s, $tree) = @_;

    if ( $tree->term_type() == T_VARIABLE ) {
        my $r = { type => 'variable', object => $tree };
        if ( $s eq '+' ) {
            push @{$l}, $r;
        }
        elsif ( $s eq '-' ) {
            push @{$l}, { type => 'products', list => [ { type => 'constant', object => Math::Symbolic::Constant->new(-1) }, $r ] };    
        }
        return 1;
    }   
    elsif ( $tree->term_type() == T_CONSTANT ) {
        my $r = { type => 'constant', object => $tree };
        if ( $s eq '+' ) {
            push @{$l}, $r;
        }
        elsif ( $s eq '-' ) {
            push @{$l}, { type => 'products', list => [ { type => 'constant', object => Math::Symbolic::Constant->new(-1) }, $r ] };    
        }
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->arity() == 1) ) {
        my $r = { type => 'function', object => $tree };
        if ( $s eq '+' ) {
            push @{$l}, $r;
        }
        elsif ( $s eq '-' ) {
            push @{$l}, { type => 'products', list => [ { type => 'constant', object => Math::Symbolic::Constant->new(-1) }, $r ] };    
        }
        return 1;        
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_DIVISION) ) {
        my $r = { type => 'fraction', num => $tree->op1(), den => $tree->op2() };
        if ( $s eq '+' ) {
            push @{$l}, $r;
        }
        elsif ( $s eq '-' ) {
            push @{$l}, { type => 'products', list => [ { type => 'constant', object => Math::Symbolic::Constant->new(-1) }, $r ] };    
        }
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_PRODUCT) ) {
        my @product_elements;
        my $ok1 = get_product_elements(\@product_elements, $tree->op1());
        my $ok2 = get_product_elements(\@product_elements, $tree->op2());
        my @sorted = sort { $a->{type} cmp $b->{type} } @product_elements;

        if ( $ok1 && $ok2 ) {
            if ( $s eq '-' ) {
                push @sorted, { type => 'constant', object => Math::Symbolic::Constant->new(-1) };
            }
            push @{$l}, { type => 'products', list => \@sorted };   
            return 1;
        }
        return 0;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_SUM) ) {
        my $ok1 = get_elements($l, '+', $tree->op1());
        my $ok2 = get_elements($l, '+', $tree->op2());
        return $ok1 & $ok2; 
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_DIFFERENCE) ) {
        my $ok1 = get_elements($l, '+', $tree->op1());
        my $ok2 = get_elements($l, '-', $tree->op2());
        return $ok1 & $ok2; 
    }

    return 0;
}

sub get_product_elements {
    my ($l, $tree) = @_;

    if ( $tree->term_type() == T_VARIABLE ) {
        push @{$l}, { type => 'variable', object => $tree, };
        return 1;
    }   
    elsif ( $tree->term_type() == T_CONSTANT ) {
        push @{$l}, { type => 'constant', object => $tree, };
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->arity() == 1) ) {
        push @{$l}, { type => 'function', object => $tree, };
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_DIVISION) ) {
        push @{$l}, { type => 'fraction', num => $tree->op1(), den => $tree->op2() };
        return 1;
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_EXP) ) {
        my $op1 = $tree->op1();
        my $exp = $tree->op2();
        if (    ($op1->term_type() == T_VARIABLE) &&
                ($exp->term_type() == T_CONSTANT) &&
                ($exp->value() eq int($exp->value())) && 
                ($exp->value() > 0) ) {
    
            my @v_list;
            for (0..$exp->value()-1) {
                push @{$l}, { type => 'variable', object => $op1->new() };
            }            
            return 1;
        }
    }
    elsif ( ($tree->term_type() == T_OPERATOR) && ($tree->type() == B_PRODUCT) ) {
        my $ok1 = get_product_elements($l, $tree->op1());
        my $ok2 = get_product_elements($l, $tree->op2());
        return $ok1 & $ok2; 
    }

    return 0;
}

sub create_element {
    my ($e) = @_;

    if ( ($e->{type} eq 'variable') || ($e->{type} eq 'constant') || ($e->{type} eq 'function') ) {
        return $e->{object}->new();
    }
    elsif ( $e->{type} eq 'fraction' ) {
        return Math::Symbolic::Operator->new('/', $e->{num}->new(), $e->{den}->new());
    }
    elsif ( $e->{type} eq 'products' ) {
        return create_product_tree($e->{list});
    }

    croak "Unrecognized type in create_element: $e->{type}";    
}

sub create_product_tree {
    my ($elements) = @_;
    
    my $const = 1;
    my @v_e;
    foreach my $c (@{$elements}) {        
        if ( ($c->{type} eq 'constant') && ($c->{object}->special() eq '') ) {
            $const *= $c->{object}->value();
        }
        else {
            push @v_e, $c;
        }
    }

    if ( scalar(@v_e) == 0 ) {
        return Math::Symbolic::Constant->new($const);
    }

    if ( $const != 1 ) {
        push @v_e, { type => 'constant', object => Math::Symbolic::Constant->new($const) };
    }
    
    my @num_to_mul;
    foreach my $e (@v_e) {
        if ( $e->{type} eq 'fraction' ) {
            push @num_to_mul, $e->{num}->new();    
        }
        else {
            push @num_to_mul, $e->{object}->new();
        }
    }
    
    # extract denominator elements, if any
    my @den_to_mul;
    foreach my $frac (grep { $_->{type} eq 'fraction' } @v_e) {
        push @den_to_mul, $frac->{den}->new();  
    }

    # multiply all numerator elements with each other
    my $ntp1 = shift @num_to_mul;
    while (@num_to_mul) {
        my $e = shift @num_to_mul;
        $ntp1 = Math::Symbolic::Operator->new( '*', $ntp1, $e );
    }    
    
    # deal with various fraction situations
    # no denominator
    if ( scalar(@den_to_mul) == 0 ) {
        return $ntp1;
    }
    
    if ( scalar(@den_to_mul) == 1 ) {
        my $den = pop @den_to_mul;
        # denominator is unity
        if ( ($den->term_type() == T_CONSTANT) && ($den->value() == 1) ) {
            return $ntp1;
        }
        # just one element in denominator (don't need to check for 0 again do I?)
        return Math::Symbolic::Operator->new( '/', $ntp1, $den );
    }
    
    # multiply all denominator elements with each other
    my $ntp2 = shift @den_to_mul;
    while (@den_to_mul) {
        my $e = shift @den_to_mul;
        $ntp2 = Math::Symbolic::Operator->new( '*', $ntp2, $e );
    }    
    
    # returned the combined fraction
    return Math::Symbolic::Operator->new( '/', $ntp1, $ntp2 );
}

=head1 SEE ALSO

L<Math::Symbolic>

L<Math::Complex>

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


