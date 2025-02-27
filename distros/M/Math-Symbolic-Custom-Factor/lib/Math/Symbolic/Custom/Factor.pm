package Math::Symbolic::Custom::Factor;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

=pod

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Factor - Re-arrange a Math::Symbolic expression into a product of factors

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Base;
use Math::Symbolic::Custom::Collect 0.32;
use Math::Symbolic::Custom::Polynomial 0.3;

BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}

our $Aggregate_Export = [qw/to_factored/];

use Carp;

=head1 DESCRIPTION

Provides method to_factored() through the Math::Symbolic module extension class. This method attempts to factorize a Math::Symbolic expression.

This is a very early version and can only factor relatively simple expressions. It has a few factoring strategies in it, and hopefully more will come 
along in later versions if I have time to implement them. 

=head1 EXAMPLES

    use strict;
    use Math::Symbolic qw/:all/;
    use Math::Symbolic::Custom::Factor;

    # to_factored() returns the full expression as a product of factors
    # and an array ref to the factors themselves (so that multiplying them 
    # together and collecting up should produce the original expression).
    my ($factored, $factors) = parse_from_string("3*x + 12*y")->to_factored();
    # $factored and the factors in $factors->[] are Math::Symbolic expressions.
    print "Full expression: $factored\n";   # Full expression: (x + (4 * y)) * 3
    print "Factors: '", join(q{', '}, @{$factors}), "'\n\n";  # Factors: '3', 'x + (4 * y)'

    ($factored, $factors) = parse_from_string("x^2 - 81")->to_factored();
    print "Full expression: $factored\n";   # Full expression: (9 + x) * (x - 9)
    print "Factors: '", join(q{', '}, @{$factors}), "'\n\n";  # Factors: 'x - 9', '9 + x'

    ($factored, $factors) = parse_from_string("6*x^2 + 37*x + 6")->to_factored();
    print "Full expression: $factored\n";   # Full expression: (6 + x) * (1 + (6 * x))
    print "Factors: '", join(q{', '}, @{$factors}), "'\n\n";  # Factors: '6 + x', '1 + (6 * x)'

    ($factored, $factors) = parse_from_string("y^4 - 5*y^3 - 5*y^2 + 23*y + 10")->to_factored();
    print "Full expression: $factored\n";   # Full expression: ((y - 5) * (((y ^ 2) - 1) - (2 * y))) * (2 + y)
    print "Factors: '", join(q{', '}, @{$factors}), "'\n\n";  # Factors: '2 + y', 'y - 5', '((y ^ 2) - 1) - (2 * y)'

    # This one does not factor (using the strategies in this module).
    # The original expression is returned (albeit re-arranged) and the number of entries in
    # @{$factors} is 1.
    ($factored, $factors) = parse_from_string("x^2 + 2*x + 2")->to_factored();
    print "Full expression: $factored\n";   # Full expression: (2 + (2 * x)) + (x ^ 2)
    print "Factors: '", join(q{', '}, @{$factors}), "'\n";  # Factors: '(2 + (2 * x)) + (x ^ 2)'
    print "Did not factorize\n\n" if scalar(@{$factors}) == 1; # Did not factorize

=cut

sub to_factored {
	my ($t1) = @_;

    # Split the original expression into pre-existing factors.
    # e.g. if we are given 3*x^2*y then we want (3,x^2,y)
    my @original_factors;
    get_factors($t1, \@original_factors);
    
    # Go through that list of factors and try to factorize more.
    my @factors;
    FACTORIZE: foreach my $expr (@original_factors) {

        my ($t2, $n_hr, $d_hr) = $expr->to_collected();
        
        if ( !defined $t2 ) {
			carp "to_factored: undefined result from to_collected() for [$expr]";
			return undef;
		}
		elsif ( !defined($n_hr) ) {
			# very simple expression
			push @factors, $t2;
		}
		elsif ( scalar(keys %{$n_hr->{terms}}) == 1 ) {  
            # just the constant accumulator
            push @factors, $t2;       
        }
        elsif ( (scalar(keys %{$n_hr->{terms}}) == 2) && ($n_hr->{terms}{constant_accumulator} == 0)) {  
            # again, just one term
            push @factors, $t2;   
        }
        elsif ( !defined $d_hr ) {
			# Attempt to factorize this sub-expression using some strategies.
			my @new_factors = factorize($t2, $n_hr);
			push @factors, @new_factors;
		}
		else {
			# cannot process at the moment, pass-through
			push @factors, $t2;
		}
	}

    @factors = map { scalar($_->to_collected()) } @factors;	
    my $product_tree = build_product_tree(@factors);
    
    return wantarray ? ($product_tree, \@factors) : $product_tree;
}


sub get_factors {
    my ($t, $l) = @_;

    if ( ($t->term_type() == T_OPERATOR) && ($t->type() == B_PRODUCT) ) {
        get_factors($t->op1(), $l);
        get_factors($t->op2(), $l);
    }
    else {
        push @{$l}, $t;
    }
}

sub build_product_tree {
    my @product_list = @_;

    my %h;

    my @str = map { $_->to_string() } @product_list;
    $h{$_}++ for @str;

    my @to_mult;
    foreach my $expr ( sort { $h{$b} <=> $h{$a} } keys %h ) {

        my $index = $h{$expr};

        if ( $index > 1 ) {
            push @to_mult, parse_from_string("($expr)^$index");
        }
        else {
            push @to_mult, parse_from_string($expr);
        }
    }

    my $ntp = shift @to_mult;
    while (@to_mult) {
        my $e = shift @to_mult;
        $ntp = Math::Symbolic::Operator->new( '*', $ntp, $e );
    }

    return $ntp;
}

sub factorize {
    my ($t, $n_hr) = @_;
		
    my %n_terms = %{ $n_hr->{terms} };
    my %n_funcs = %{ $n_hr->{trees} };

    my @factors;
	
    # extract common constants
    my %constants;
    $constants{$_}++ for grep { $_ != 0 } values %n_terms;
    my @con = sort {$a <=> $b} map { abs } keys %constants;
    my @con_int = grep { $_ eq int($_) } @con;
    
    if ( scalar(@con) == scalar(@con_int) ) {   # all integer, proceed
        my $min = $con[0];
        my $GCF;
        FIND_CONST_GCF: foreach my $div (reverse(2..$min)) {
            my $div_ok = 1;
            CONST_DIV_TEST: foreach my $num (@con) {
                if ( $num % $div != 0 ) {
                    $div_ok = 0;
                    last CONST_DIV_TEST;
                }
            }
            if ( $div_ok ) {
                $GCF = $div;
                last FIND_CONST_GCF;
            }
        }
        
        if ( defined $GCF ) {       
            push @factors, Math::Symbolic::Constant->new($GCF);
            $n_terms{$_} /= $GCF for keys %n_terms;
        }
    }
    
    # extract common variables
    if ($n_terms{constant_accumulator} == 0) {
		    
	    my %c_vars;
        foreach my $key (keys %n_terms) {
            my @v1 = split(/,/, $key);
            foreach my $v2 (@v1) {
                my ($v, $p) = split(/:/, $v2);
                if ( exists $c_vars{$v} ) {
                    $c_vars{$v}{c}++;
                    if ($p < $c_vars{$v}{p}) {
                        $c_vars{$v}{p} = $p;
                    }
                }
                else {
                    $c_vars{$v}{c}++;
                    $c_vars{$v}{p} = $p;
                }
            }
        }           
        
        my @all_terms;
        while ( my ($v, $c) = each %c_vars ) {
            if ( $c->{c} == scalar(keys %n_terms)-1 ) {
                push @all_terms, [$v, $c->{p}];
            }
        }

	    foreach my $common_var (@all_terms) {
	        my ($var, $pow) = @{$common_var};           
	        
	        my %new_ct;
	        $new_ct{constant_accumulator} = 0;
	        
	        # remove this variable from the data structure
	        while ( my ($t, $c) = each %n_terms ) {

		        next if $t eq 'constant_accumulator';
		        my @v1 = split(/,/, $t);
		        my @nt;
		        foreach my $v2 (@v1) {
		            my ($vv, $cc) = split(/:/, $v2);
		            if ($vv eq $var) {
			            $cc -= $pow;
			            if ($cc > 0) {
			                push @nt, "$vv:$cc";
			            }
			            elsif ( scalar(@v1) == 1 ) {  
			                $new_ct{constant_accumulator} += $c;
			            } 
		            }
		            else {
			            push @nt, $v2;
		            }
		        }

		        if ( scalar(@nt) ) {
		            $new_ct{join(",", @nt)} = $c;              
		        }                 
	        }
	        
	        # add it to the list of factors
	        if ( $pow == 1 ) {
		        push @factors, Math::Symbolic::Variable->new($n_funcs{$var}->new());
	        }
	        else {
		        push @factors, Math::Symbolic::Operator->new('^', $n_funcs{$var}->new(), Math::Symbolic::Constant->new($pow));
	        }
	        
	        %n_terms = %new_ct;
	    }
    }
    
    # Various factoring formulas
    # Difference of Squares:-
    # x^2-y^2 = (x-y)*(x+y)
    # Sum/Difference of Cubes:-
    # x^3-y^3 = (x-y)*(x^2+x*y+y^2)
    # x^3+y^3 = (x+y)*(x^2−x*y+y^2) 
    # pull out the constant accumulator
    my $acc = $n_terms{constant_accumulator};
    delete $n_terms{constant_accumulator};

    if (    (scalar(keys %n_terms) == 1) && 
            (abs($acc) > 1) && 
            ($acc eq int($acc)) ) {
        
        # remaining key must be the other term
        my $t = (keys %n_terms)[0];
        my $mult = $n_terms{$t};
    
        if ( $mult > 0 ) {
           
            my $cbrt_y = int_rt(abs($acc), 3);               # y (accumulator) must be a cube
            my $cbrt_x = int_rt($mult, 3);                   # x constant multiplier must be a cube
            
            if ( ($t !~ /,/) && ($t =~ /:3$/) && defined($cbrt_x) && defined($cbrt_y) ) {
                
                my ($vv) = split(/:/, $t);
                my $v = $n_funcs{$vv}->{name};
                
                if ( $acc < -1 ) {
                
                    if ( $cbrt_x == 1 ) {
                        push @factors, parse_from_string("$v - $cbrt_y"); 
                        push @factors, parse_from_string("$v^2 + $cbrt_y*$v + " . ($cbrt_y*$cbrt_y));
                    }
                    else {
                        push @factors, parse_from_string("$cbrt_x*$v - $cbrt_y"); 
                        push @factors, parse_from_string(($cbrt_x*$cbrt_x) . "*$v^2 + " . ($cbrt_y*$cbrt_x) . "*$v + " . ($cbrt_y*$cbrt_y)); 
                    }                    
                }
                elsif ( $acc > 1 ) {
                
                    if ( $cbrt_x == 1 ) {
                        push @factors, parse_from_string("$v + $cbrt_y"); 
                        push @factors, parse_from_string("$v^2 - $cbrt_y*$v + " . ($cbrt_y*$cbrt_y));
                    }
                    else {
                        push @factors, parse_from_string("$cbrt_x*$v + $cbrt_y"); 
                        push @factors, parse_from_string(($cbrt_x*$cbrt_x) . "*$v^2 - " . ($cbrt_y*$cbrt_x) . "*$v + " . ($cbrt_y*$cbrt_y)); 
                    }                                
                }

                undef %n_terms;
		        return @factors;                
            }
    
            if ( %n_terms && ($acc < -1) ) {
            
                my $sqrt_y = int_rt(abs($acc), 2);               # y (accumulator) must be a square
                my $sqrt_x = int_rt($mult, 2);                   # x constant multiplier must be a square
                my ($vv, $pow) = split(/:/, $t);                 # power must be a square (> 1)

                if ( ($t !~ /,/) && defined($sqrt_x) && ($pow > 1) && ($pow % 2 == 0) && defined($sqrt_y) ) {
                    					
					my $v = $n_funcs{$vv}->{name};
                
                    if ( $pow == 2 ) {
                        if ( $sqrt_x == 1 ) {
                            push @factors, parse_from_string("$v - $sqrt_y");
                            push @factors, parse_from_string("$v + $sqrt_y");
                        }
                        else {
                            push @factors, parse_from_string("($sqrt_x*$v) - $sqrt_y");
                            push @factors, parse_from_string("($sqrt_x*$v) + $sqrt_y");
                        }
                    }
                    elsif ( $pow % 2 == 0 ) {
                        my $hp = $pow / 2;
                        if ( $sqrt_x == 1 ) {
                            push @factors, parse_from_string("$v^$hp - $sqrt_y");
                            push @factors, parse_from_string("$v^$hp + $sqrt_y");
                        }
                        else {
                            push @factors, parse_from_string("($sqrt_x*$v^$hp) - $sqrt_y");
                            push @factors, parse_from_string("($sqrt_x*$v^$hp) + $sqrt_y");
                        }
                    }
                    
                    undef %n_terms;
		            return @factors;
                }
            }            
        }        
    }
    elsif ( (scalar(keys %n_terms) == 2) && ($acc == 0) ) {
	    
	    # try the factoring formulas with two variables
	    my @t = keys %n_terms;
	    my @m = map { $n_terms{$_} } @t;

	    my ($vv1) = split(/:/, $t[0]);
	    my $v1 = $n_funcs{$vv1}->{name};
	    my ($vv2) = split(/:/, $t[1]);
	    my $v2 = $n_funcs{$vv2}->{name};

	    # x^2-y^2 = (x-y)*(x+y)
	    if ( ($t[0] !~ /,/) && ($t[0] =~ /:2$/) && ($t[1] !~ /,/) && ($t[1] =~ /:2$/) ) {
		    
		    if ( ($m[0] > 0) && ($m[1] < 0) ) {
			    my $sqrt_y = int_rt(abs($m[1]), 2);
			    my $sqrt_x = int_rt($m[0], 2);

			    if ( defined($sqrt_y) && defined($sqrt_x) ) {
				    if ( ($sqrt_x == 1) && ($sqrt_y == 1) ) {
					    push @factors, parse_from_string("$v1 - $v2");
					    push @factors, parse_from_string("$v1 + $v2");
				    }
				    elsif ( $sqrt_x == 1 ) {
					    push @factors, parse_from_string("$v1 - $sqrt_y*$v2");
					    push @factors, parse_from_string("$v1 + $sqrt_y*$v2");
				    }
				    elsif ( $sqrt_y == 1 ) {
					    push @factors, parse_from_string("$sqrt_x*$v1 - $v2");
					    push @factors, parse_from_string("$sqrt_x*$v1 + $v2");
				    }
				    else {
					    push @factors, parse_from_string("$sqrt_x*$v1 - $sqrt_y*$v2");
					    push @factors, parse_from_string("$sqrt_x*$v1 + $sqrt_y*$v2");
				    }                        

				    undef %n_terms;
				    return @factors;
			    }
		    }
		    elsif ( ($m[0] < 0) && ($m[1] > 0 ) ) {
			    my $sqrt_y = int_rt($m[1], 2);
			    my $sqrt_x = int_rt(abs($m[0]), 2);

			    if ( defined($sqrt_y) && defined($sqrt_x) ) {
				    if ( ($sqrt_x == 1) && ($sqrt_y == 1) ) {
					    push @factors, parse_from_string("$v2 - $v1");
					    push @factors, parse_from_string("$v2 + $v1");
				    }
				    elsif ( $sqrt_y == 1 ) {
					    push @factors, parse_from_string("$v2 - $sqrt_x*$v1");
					    push @factors, parse_from_string("$v2 + $sqrt_x*$v1");
				    }
				    elsif ( $sqrt_x == 1 ) {
					    push @factors, parse_from_string("$sqrt_y*$v2 - $v1");
					    push @factors, parse_from_string("$sqrt_y*$v2 + $v1");
				    }
				    else {
					    push @factors, parse_from_string("$sqrt_y*$v2 - $sqrt_x*$v1");
					    push @factors, parse_from_string("$sqrt_y*$v2 + $sqrt_x*$v1");
				    }

				    undef %n_terms;
				    return @factors;
			    }
		    }      
	    }
	    elsif ( ($t[0] !~ /,/) && ($t[0] =~ /:3$/) && ($t[1] !~ /,/) && ($t[1] =~ /:3$/) ) { 
				    
		    if ( ($m[0] > 0) && ($m[1] > 0) ) { 
	            # x^3+y^3 = (x+y)*(x^2−x*y+y^2) 
			    
			    my $cbrt_x = int_rt($m[0], 3);
			    my $cbrt_y = int_rt($m[1], 3);
			    
			    if ( defined($cbrt_y) && defined($cbrt_x) ) {
				    if ( ($cbrt_x == 1) && ($cbrt_y == 1) ) {
					    push @factors, parse_from_string("$v1 + $v2");
					    push @factors, parse_from_string("$v1^2 - $v1*$v2 + $v2^2");
				    }
				    elsif ( $cbrt_y == 1 ) {
					    push @factors, parse_from_string("$cbrt_x*$v1 + $v2");
					    push @factors, parse_from_string(($cbrt_x*$cbrt_x) . "*$v1^2 - $cbrt_x*$v1*$v2 + $v2^2");
				    }
				    elsif ( $cbrt_x == 1 ) {
					    push @factors, parse_from_string("$v1 + $cbrt_y*$v2");
					    push @factors, parse_from_string("$v1^2 - $cbrt_y*$v1*$v2 + " . ($cbrt_y*$cbrt_y) . "*$v2^2");
				    }
				    else {
					    push @factors, parse_from_string("$cbrt_x*$v1 + $cbrt_y*$v2");
					    push @factors, parse_from_string(($cbrt_x*$cbrt_x) . "*$v1^2 - " . ($cbrt_x*$cbrt_y) . "*$v1*$v2 + " . ($cbrt_y*$cbrt_y) . "*$v2^2");
				    }

				    undef %n_terms;
				    return @factors;		
			    }			    			    
		    }
		    elsif ( ($m[0] > 0) && ($m[1] < 0) ) { 
			    # x^3-y^3 = (x-y)*(x^2+x*y+y^2)
		    
			    my $cbrt_x = int_rt($m[0], 3);
			    my $cbrt_y = int_rt(abs($m[1]), 3);		

			    if ( defined($cbrt_y) && defined($cbrt_x) ) {
				    if ( ($cbrt_x == 1) && ($cbrt_y == 1) ) {
					    push @factors, parse_from_string("$v1 - $v2");
					    push @factors, parse_from_string("$v1^2 + $v1*$v2 + $v2^2");
				    }
				    elsif ( $cbrt_y == 1 ) {
					    push @factors, parse_from_string("$cbrt_x*$v1 - $v2");
					    push @factors, parse_from_string(($cbrt_x*$cbrt_x) . "*$v1^2 + $cbrt_x*$v1*$v2 + $v2^2");
				    }
				    elsif ( $cbrt_x == 1 ) {
					    push @factors, parse_from_string("$v1 - $cbrt_y*$v2");
					    push @factors, parse_from_string("$v1^2 + $cbrt_y*$v1*$v2 + " . ($cbrt_y*$cbrt_y) . "*$v2^2");
				    }
				    else {
					    push @factors, parse_from_string("$cbrt_x*$v1 - $cbrt_y*$v2");
					    push @factors, parse_from_string(($cbrt_x*$cbrt_x) . "*$v1^2 + " . ($cbrt_x*$cbrt_y) . "*$v1*$v2 + " . ($cbrt_y*$cbrt_y) . "*$v2^2");
				    }

				    undef %n_terms;
				    return @factors;		
			    }			
		    }
		    elsif ( ($m[0] < 0) && ($m[1] > 0) ) { 
			    # y^3-x^3 = (y-x)*(y^2+y*x+x^2)

			    my $cbrt_x = int_rt(abs($m[0]), 3);
			    my $cbrt_y = int_rt($m[1], 3);		

			    if ( defined($cbrt_y) && defined($cbrt_x) ) {
				    if ( ($cbrt_x == 1) && ($cbrt_y == 1) ) {
					    push @factors, parse_from_string("$v2 - $v1");
					    push @factors, parse_from_string("$v2^2 + $v2*$v1 + $v1^2");
				    }
				    elsif ( $cbrt_y == 1 ) {
					    push @factors, parse_from_string("$v2 - $cbrt_x*$v1");
					    push @factors, parse_from_string("$v2^2 + $cbrt_x*$v2*$v1 + " . ($cbrt_x*$cbrt_x) . "*$v1^2");
				    }
				    elsif ( $cbrt_x == 1 ) {
					    push @factors, parse_from_string("$cbrt_y*$v2 - $v1");
					    push @factors, parse_from_string(($cbrt_y*$cbrt_y) . "*$v2^2 + $cbrt_y*$v2*$v1 + $v1^2");
				    }
				    else {
					    push @factors, parse_from_string("$cbrt_y*$v2 - $cbrt_x*$v1");
					    push @factors, parse_from_string(($cbrt_y*$cbrt_y) . "*$v2^2 + " . ($cbrt_x*$cbrt_y) . "*$v2*$v1 + " . ($cbrt_x*$cbrt_x) . "*$v1^2");
				    }

				    undef %n_terms;
				    return @factors;		
			    }								
		    }
	    }                    
    }    
    
    if ( %n_terms ) {
        # rebuild expression and continue attempting to factor
	    if ( !exists $n_terms{constant_accumulator} ) {
            # put the accumulator back in if necessary
	        $n_terms{constant_accumulator} = $acc;
	    }
	    my $nt = Math::Symbolic::Custom::Collect::build_summation_tree({ terms => \%n_terms, trees => \%n_funcs });

        my $factors_in = scalar(@factors);

        POLY_FACTOR: while ( defined $nt ) {

            # test for polynomial
            # FIXME: looping around test_polynomial() like this is slow
            my ($var, $coeffs, $disc, $roots) = $nt->test_polynomial();

            last POLY_FACTOR unless defined $var;
            last POLY_FACTOR unless defined $coeffs;

            my $degree = scalar(@{$coeffs})-1;
            last POLY_FACTOR if $degree <= 1;

            # check if all the coefficients are constant integers
            my @co = @{$coeffs};
            my @const_co =  grep { $_ eq int($_) }
                            map { $_->value() } 
                            grep { ref($_) eq 'Math::Symbolic::Constant'} @co;

            if ( scalar(@const_co) == scalar(@co) ) {
                             
                # see if it trivially collapses to a binomial
                if ( $degree < 15 ) {   # FIXME: Upper limit on degree for binomials??
                    
                    my $const_term = $const_co[-1];
                    my $root = int_rt(abs($const_term), $degree);
                    
                    if ( defined $root ) {
                    
                        my @pos_matches;
                        my @neg_matches;
                        CHECK_BINOMIAL: foreach my $k (0..$degree) {

                            my $bin_coeff = binomial_coefficient($degree, $k);
                            
                            my $bin_add = $bin_coeff * $root**$k;
                            my $bin_sub = $bin_add;
                            $bin_sub *= -1 if $k % 2 == 1;
                            
                            if ( $const_co[$k] == $bin_add ) {
                                push @pos_matches, $const_co[$k];
                            }
                            if ( $const_co[$k] == $bin_sub ) {
                                push @neg_matches, $const_co[$k];
                            }
                        }
                        
                        if ( scalar(@pos_matches) == scalar(@const_co) ) {
                            push @factors, parse_from_string("$var + $root") for (1..$degree);
                            undef %n_terms;
                            undef $nt;
                            last POLY_FACTOR;
                        }
                        elsif ( scalar(@neg_matches) == scalar(@const_co) ) {
                            push @factors, parse_from_string("$var - $root") for (1..$degree);
                            undef %n_terms;
                            undef $nt;
                            last POLY_FACTOR;
                        }			 
                    }
                }
                
                # try rational root theorem
                my @potential_roots = get_rational_roots($const_co[0], $const_co[-1]);
                my $found_root = 0;
                TRY_RAT_ROOT: foreach my $root (@potential_roots) {                        

                    my $MS_root = parse_from_string($root);                        
                    my $p_val = $nt->value($var => $MS_root->value());

                    if ( abs($p_val) < 1e-11 ) {    # fix failing test on uselongdouble systems.

                        $MS_root = $MS_root->to_collected();
                        my ($full_expr, $divisor, $quotient, $remainder) = $nt->apply_synthetic_division($MS_root, $var);  

                        if ( $remainder->value() == 0 ) {
                            $found_root = 1;
                            push @factors, $divisor;                            
                            $nt = $quotient;
                        }

                        last TRY_RAT_ROOT;
                    }
                }

                unless ( $found_root ) {
                    last POLY_FACTOR;
                }
                
            }
            else {
                last POLY_FACTOR;
            }

        } # /POLY_FACTOR

        if ( ($factors_in < scalar(@factors)) && defined($nt) ) {

            my ($t3, $n_hr, $d_hr) = $nt->to_collected();
            $nt = $t3;
            %n_terms = %{ $n_hr->{terms} };
            %n_funcs = %{ $n_hr->{trees} };
        }

    }

    if ( scalar(@factors) == 0 ) {
        # could not get any new factors, return the original expression
        return $t;
    }
    elsif ( %n_terms && (scalar(@factors) > 0) ) {
	    # got some factors and a leftover expression, rebuild and return that too
	    if ( !exists $n_terms{constant_accumulator} ) {
		    $n_terms{constant_accumulator} = $acc;
	    }
	    my $nt = Math::Symbolic::Custom::Collect::build_summation_tree({ terms => \%n_terms, trees => \%n_funcs });
	    push @factors, $nt;
    }
    
    return @factors;
}

sub factor {
    my ($n) = @_;

    $n = abs($n);
    my %factors;
    for my $i (1 .. int(sqrt($n))) {
        if ($n % $i == 0) {
            my $complement = $n / $i;
            $factors{$i}++;
            $factors{$complement}++;
        }
    }
    my @factors = keys %factors;

    return @factors;
}

sub get_rational_roots {
    my ($leading, $const_term) = @_;
    
    my @p_factors = factor($const_term);
    my @q_factors = factor($leading);
    
    # Generate all combinations of p/q
    my %roots;
    for my $p (@p_factors) {
        for my $q (@q_factors) {
            # Add both positive and negative roots
            $roots{"$p / $q"}++;
            $roots{"-$p / $q"}++;
        }
    }
    
    return keys %roots;
}

sub int_rt {
    # determine if there is an integer nth root of a number
    my ($v, $n) = @_;
    my $guess = $v**(1/$n);
    $guess = int($guess);
    return $guess if $guess**$n == $v;
    $guess += 1;
    return $guess if $guess**$n == $v;
    return undef;
}

sub factorial {
    my ($num) = @_;
    return 1 if $num <= 1;  # 0! = 1! = 1
    my $result = 1;
    $result *= $_ for (2..$num);
    return $result;
}

sub binomial_coefficient {
    my ($n, $k) = @_;
    
    # Handle edge cases
    return 0 if $k < 0 || $k > $n; # C(n, k) = 0 if k < 0 or k > n
    return 1 if $k == 0 || $k == $n; # C(n, 0) = C(n, n) = 1

    # C(n, k) = n! / (k! * (n-k)!)
    my $numerator = factorial($n);
    my $denominator = factorial($k) * factorial($n - $k);
    return $numerator / $denominator;
}

=head1 SEE ALSO

L<Math::Symbolic>

L<Math::Symbolic::Custom::Collect>

L<Math::Symbolic::Custom::Polynomial>

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Steffen Mueller, author of Math::Symbolic

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Matt Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; 
__END__


