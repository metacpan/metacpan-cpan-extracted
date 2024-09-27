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

Version 0.01

=cut

our $VERSION = '0.01';

use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Base;

BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}
   
our $Aggregate_Export = [qw/to_collected/];

use Carp;

=head1 SYNOPSIS

    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Collect;

    my $t1 = "0.125";
    print "Output: ", parse_from_string($t1)->to_collected()->to_string(), "\n";                
    # Output: 1 / 8

    my $t2 = "25/100";
    print "Output: ", parse_from_string($t2)->to_collected()->to_string(), "\n";                
    # Output: 1 / 4

    my $t3 = "((1/4)+(1/2))*3*x";
    print "Output: ", parse_from_string($t3)->to_collected()->to_string(), "\n";     
    # Output: (9 * x) / 4           

    my $t4 = "1/(1-(1/x))";
    print "Output: ", parse_from_string($t4)->to_collected()->to_string(), "\n";          
    # Output: x / (x - 1)

    my $t5 = "sin(x^2+y)*sin(y+x^2)";
    print "Output: ", parse_from_string($t5)->to_collected()->to_string(), "\n";    
    # Output: (sin((x ^ 2) + y)) ^ 2

    my $t6 = "x + x^2 + 3*x^3 + 2*x - x^2";
    print "Output: ", parse_from_string($t6)->to_collected()->to_string(), "\n";
    # Output: (3 * x) + (3 * (x ^ 3))

    my $t7 = "((1/(3*a))-(1/(3*b)))/((a/b)-(b/a))";
    print "Output: ", parse_from_string($t7)->to_collected()->to_string(), "\n";
    # Output: (b - a) / ((3 * (a ^ 2)) - (3 * (b ^ 2)))

=head1 DESCRIPTION

Provides "to_collected()" through the Math::Symbolic module extension class. "to_collected" performs the following operations on the inputted Math::Symbolic tree:-

=over

=item * Folds constants

=item * Converts decimal numbers to rational numbers

=item * Combines fractions

=item * Expands brackets

=item * Collects like terms

=item * Cancels down

=back

The result is often a more concise expression. However, because it does not (yet) factor the expression, the result is not always the simplest representation. Hence it is not offered as a simplify().

=cut

sub to_collected {
    my ($t1) = @_;

    # 1. recursion step. 
    # Fold constants, convert decimal to rational, combine fractions, expand brackets
    my $t2 = prepare($t1);
    if (!defined $t2) {
        return undef;
    }
    elsif ( !$t1->test_num_equiv($t2) ) {
        return undef;
    }
   
    # 2. collect like terms
    my $t3;
    if ( ($t2->term_type() == T_OPERATOR) && ($t2->type() == B_DIVISION) ) {
    
        my $numerator = $t2->op1();
        my $denominator = $t2->op2();
        
        my ($c_n, $c_n_cth) = collect_like_terms($numerator);
        my ($c_d, $c_d_cth) = collect_like_terms($denominator);

        if ( defined($c_n_cth) && defined($c_d_cth) ) {
            # 3. attempt to cancel down
            ($numerator, $denominator) = cancel_down($c_n, $c_n_cth, $c_d, $c_d_cth);
        }
        elsif ( defined $c_n ) {
            $numerator = $c_n;
        }
        elsif ( defined $c_d ) {
            $denominator = $c_d;
        }
        
        # check denominator
        if ( ($denominator->term_type() == T_CONSTANT) && ($denominator->value() == 1) ) {
            $t3 = $numerator;
        }
        elsif ( ($denominator->term_type() == T_CONSTANT) && ($denominator->value() == 0) ) {
            # FIXME: divide by zero at this point?!
            $t3 = $t2;
        }
        else {
            $t3 = Math::Symbolic::Operator->new( '/', $numerator, $denominator );
        }
    }
    else {
        my ($collected, $ct_href) = collect_like_terms($t2);

        if ( defined $collected ) {
            $t3 = $collected;
        }
        else {
            $t3 = $t2;
        }
    }

    return $t3;
}


#### cancel_down. 
# Checks numerator and denominator expressions for constants and variables which can cancel.
sub cancel_down {
    my ($c_n, $n_cth, $c_d, $d_cth) = @_;

    my %n_ct = %{$n_cth};
    my %d_ct = %{$d_cth};

    my %n_terms = %{ $n_ct{terms} };
    my %n_funcs = %{ $n_ct{funcs} };

    my %d_terms = %{ $d_ct{terms} };
    my %d_funcs = %{ $d_ct{funcs} };

    my $n_acc = $n_terms{constant_accumulator};
    my $d_acc = $d_terms{constant_accumulator};

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

    if ( ($n_acc == 0) && ($d_acc == 0) && (scalar(%d_terms)>1) ) {

        # try to cancel vars
        # see if there are any common variables we can cancel
        # count up the number of unique vars within numerator and denominator
        my %c_vars;
        foreach my $e (\%n_terms, \%d_terms) {
            foreach my $key (keys %{$e}) {
                my @v1 = split(/,/, $key);
                foreach my $v2 (@v1) {
                    my ($v, $c) = split(/:/, $v2);
                    if ( !(exists($n_funcs{$v}) || exists($d_funcs{$v})) ) {
                        $c_vars{$v}++;
                    }
                }
            }            
        }

        # if a variable exists in each term, perhaps we can cancel it
        my @all_terms;
        while ( my ($v, $c) = each %c_vars ) {
            if ( $c == (scalar(keys %n_terms)+scalar(keys %d_terms)) ) {
                push @all_terms, $v;
            }
        }

        while ( my $v = pop @all_terms ) {
            my %n_ct_new;
            my %d_ct_new;
    
            # cancel from numerator
            while ( my ($t, $c) = each %n_terms ) {
                my @v1 = split(/,/, $t);
                my @nt;
                foreach my $v2 (@v1) {
                    my ($vv, $cc) = split(/:/, $v2);
                    if ($vv eq $v) {
                        $cc--;
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

            # cancel from denominator
            while ( my ($t, $c) = each %d_terms ) {
                my @v1 = split(/,/, $t);
                my @nt;
                foreach my $v2 (@v1) {
                    my ($vv, $cc) = split(/:/, $v2);
                    if ($vv eq $v) {
                        $cc--;
                        if ($cc > 0) {
                            push @nt, "$vv:$cc";
                        }
                        elsif ( scalar(@v1) == 1 ) {  
                            $d_acc = $c;
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

            %n_terms = %n_ct_new;
            %d_terms = %d_ct_new;
           
            $did_some_cancellation = 1;
        }
    }

    $n_terms{constant_accumulator} = $n_acc;
    $d_terms{constant_accumulator} = $d_acc;

    if ( $did_some_cancellation ) {

        my $new_n = build_summation_tree( { terms => \%n_terms, funcs => \%n_funcs } );
        my $new_d = build_summation_tree( { terms => \%d_terms, funcs => \%d_funcs } );

        return ($new_n, $new_d);
    }

    return ($c_n, $c_d); 
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

sub collect_terms {
    my ($e) = @_;

    my @elements = @{$e};

    my $accumulator = 0;
    my %collected_terms;
    my $func_prefix = '|-&-|=&&=|';        # FIXME: some random string for the hash which is unlikely to be an existing variable name. 
    my $func_num = 1;
    my %func_trees;
    foreach my $e (@elements) {
        if ( $e->{type} eq 'constant' ) {
            $accumulator += $e->{object}->value();
        }
        elsif ( $e->{type} eq 'variable' ) {
            my $key = $e->{object}->name() . ":1";
            $collected_terms{terms}{$key}++;         
        }
        elsif ( $e->{type} eq 'function' ) {    
            my $ft = $e->{object};
            my $func_name;
            GET_FUNC_NAME_1: foreach my $fn (keys %func_trees) {
                if ( $ft->is_identical($func_trees{$fn}) ) {
                    $func_name = $fn;
                    last GET_FUNC_NAME_1;
                }
            }
            if ( !defined $func_name ) {
                # no existing function definition, initialise
                $func_name = $func_prefix . $func_num;
                $func_trees{$func_name} = $ft;
                $func_num++;
            }
            $collected_terms{terms}{$func_name . ":1"}++;
        }
        elsif ( $e->{type} eq 'products' ) {
            my @list = @{$e->{list}};
            # if it's a list of constants, fold them into the accumulator
            my @con_list = grep { $_->{type} eq 'constant' } @list;
            if (scalar(@con_list) == scalar(@list)) {
                my $c_n = 1;
                $c_n *= $_->{object}->value() for @list;
                $accumulator += $c_n;
            }
            else {
                my $num_coeff = 1;
                my %hist;
                foreach my $l (@list) {
                    if ($l->{type} eq 'constant') {
                        $num_coeff *= $l->{object}->value();
                    }
                    elsif ($l->{type} eq 'variable') {
                        $hist{$l->{object}->name()}++;
                    }
                    elsif ($l->{type} eq 'function') {                     
                        my $ft = $l->{object};
                        my $func_name;
                        GET_FUNC_NAME_2: foreach my $fn (keys %func_trees) {
                            if ( $ft->is_identical($func_trees{$fn}) ) {
                                $func_name = $fn;
                                last GET_FUNC_NAME_2;
                            }
                        }
                        if ( !defined $func_name ) {
                            $func_name = $func_prefix . $func_num;
                            $func_trees{$func_name} = $ft;
                            $func_num++;
                        }                        
                        $hist{$func_name}++;
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

    # put the accumulator into the data structure
    $collected_terms{terms}{constant_accumulator} = $accumulator;
    # and the functions 
    $collected_terms{funcs} = \%func_trees;

    return \%collected_terms;
}

sub build_summation_tree {
    my ($ct) = @_;
    my %ct = %{$ct};
    my %collected_terms = %{$ct{terms}};
    my %func_trees = %{$ct{funcs}};

    my $accumulator = $collected_terms{constant_accumulator};
    delete $collected_terms{constant_accumulator};
    
    # check if all coefficients are zero
    my @coeffs = values %collected_terms;
    my @zero = grep { $_ == 0 } @coeffs;
    if ( scalar(@zero) == scalar(@coeffs) ) {
        return Math::Symbolic::Constant->new( $accumulator );
    }

    # try to put the terms in a neat consistent order
    my @sorted_terms =  sort { length($a) <=> length($b) || $a cmp $b || $collected_terms{$a} <=> $collected_terms{$b} } 
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

            if ( exists $func_trees{$var} ) {
                if ( $pow == 1 ) {
                    push @product_list, $func_trees{$var}->new();
                }
                else {
                    push @product_list, Math::Symbolic::Operator->new('^', $func_trees{$var}->new(), Math::Symbolic::Constant->new($pow));
                }
            }
            else {
                if ( $pow == 1 ) {
                    push @product_list, Math::Symbolic::Variable->new($var);
                }
                else {
                    push @product_list, Math::Symbolic::Operator->new('^', Math::Symbolic::Variable->new($var), Math::Symbolic::Constant->new($pow));
                }
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
        if ( $first->[1]->term_type() == T_CONSTANT ) {
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
    
    # base case.
    if ( $t->term_type() == T_VARIABLE ) {
         $return_t = $t->new();
    }
    elsif ( $t->term_type() == T_CONSTANT ) {
        # convert (non-integer decimal) constants into rational numbers where possible
        my $val = $t->value();
        if ( $val eq int($val) ) {
            $return_t = $t->new();
        }
        else {
            my (undef, $frac) = split(/\./, $val);
            if ( defined($frac) && (length($frac)>=1) ) {
                my $mult = 10**length($frac);
                # this will (possibly) be cancelled down later 
                $return_t = Math::Symbolic::Operator->new( '/', Math::Symbolic::Constant->new($val*$mult), Math::Symbolic::Constant->new($mult) )
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
            if ( ($op1->term_type() == T_CONSTANT) && ($op2->term_type() == T_CONSTANT) ) {
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
            elsif ( ($t->op2()->term_type() == T_OPERATOR) && ($t->op2()->type() == B_DIVISION) ) {                
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
            if ( ($op1->term_type() == T_CONSTANT) && ($op2->term_type() == T_CONSTANT) ) {
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
            elsif ( ($t->op2()->term_type() == T_OPERATOR) && ($t->op2()->type() == B_DIVISION) ) {
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
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op2->term_type() == T_CONSTANT) &&
                    (($op1->value()/$op2->value()) eq int($op1->value()/$op2->value())) ) {
                # Denominator evenly divides into numerator, removing division
                $return_t = Math::Symbolic::Constant->new($op1->value()/$op2->value())
            }
            elsif ( ($op2->term_type() == T_CONSTANT) && ($op2->value() < 0) ) {
                # Pulling negative out of denominator
                my $numerator = Math::Symbolic::Operator->new( '*', Math::Symbolic::Constant->new(-1), $op1 );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, Math::Symbolic::Constant->new(abs($op2->value())) ), $d);
            }    
            elsif ( ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_PRODUCT) &&
                    ($op2->op1()->term_type() == T_CONSTANT) && ($op2->op1()->value() < 0) ) {
                # Pulling negative out of denominator
                my $numerator = Math::Symbolic::Operator->new( '*', Math::Symbolic::Constant->new(-1), $op1 );
                my $denominator = Math::Symbolic::Operator->new( '*', Math::Symbolic::Constant->new(abs($op2->op1()->value())), $op2->op2()->new() );
                $return_t = prepare(Math::Symbolic::Operator->new( '/', $numerator, $denominator ), $d);
            }
            elsif ( ($op2->term_type() == T_OPERATOR) && ($op2->type() == B_PRODUCT) &&
                    ($op2->op2()->term_type() == T_CONSTANT) && ($op2->op2()->value() < 0) ) {
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
            elsif ( ($op1->term_type() == T_CONSTANT) && ($op2->term_type() == T_CONSTANT) ) {
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
        elsif ( ($t->type() == B_EXP) && ($op2->term_type() == T_CONSTANT) ) {          
            my $val = $op2->value();
            if ( ($val eq int($val)) && ($val > 0) ) {
                if ( $val == 1 ) {
                    # Found expression^1. Return the expression
                    $return_t = $op1;
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
            else {
                # Passing through exponentiation
                $return_t = Math::Symbolic::Operator->new('^', $op1, $op2 );
            }
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
            if ( $op1->term_type() == T_CONSTANT ) {
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
        if ( $c->{type} eq 'constant' ) {
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

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-symbolic-custom-collect at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Symbolic-Custom-Collect>.  I will be notified, and then you'll
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


