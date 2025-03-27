package Math::Symbolic::Custom::ToTallString;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

=pod

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::ToTallString - Pretty-print Math::Symbolic expressions

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Base;

BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}
   
our $Aggregate_Export = [qw/to_tall_string/];

use Carp;

=pod

=head1 SYNOPSIS

    use strict;
    use Math::Symbolic 0.613 qw(:all);
    use Math::Symbolic::Custom::ToTallString;

    my $example1 = "x / 5";
    print parse_from_string($example1)->to_tall_string(), "\n\n";

    #  x 
    # ---
    #  5 

    my $example2 = "(sin((1 / x) - (1 / y))) / (x + y)";
    print parse_from_string($example2)->to_tall_string(), "\n\n";

    #     ( 1     1 ) 
    #  sin(--- - ---) 
    #     ( x     y ) 
    # ----------------
    #      x + y      

    my $example3 = "K + (K * ((1 - exp(-2 * K * t))/(1 + exp(-2 * K * t))) )";
    print parse_from_string($example3)->to_tall_string(10), "\n\n";

    #               (           (-2*K*t) )
    #               (     1 - e^         )
    #           K + (K * ----------------)
    #               (           (-2*K*t) )
    #               (     1 + e^         )

    my $example4 = "((e^x) + (e^-x))/2";
    print parse_from_string($example4)->to_tall_string(3), "\n\n";

    #       x     -x 
    #     e^  + e^   
    #    ------------
    #         2     

=head1 DESCRIPTION

Provides C<to_tall_string()> through the Math::Symbolic module extension class. Large Math::Symbolic expressions can sometimes be difficult to read when displayed with C<to_string()> and C<to_shorter_infix_string()> (from L<Math::Symbolic::Custom::ToShorterString>). The primary obstacles are the division and exponent operators, so C<to_tall_string()> will compose numerator and denominator onto different lines of output and will put exponents on the line above in an attempt to improve readability. See the examples above. Note that unlike C<to_shorter_infix_string()> the output from C<to_tall_string()> is in no way compatible with the Math::Symbolic parser.

C<to_tall_string()> accepts one optional parameter, the number of spaces to indent the returned string block.

=cut

sub to_tall_string {
    my ($t, $indent) = @_;

    my $pretty = _prettify($t);

    if ( defined($pretty) && (ref($pretty) eq 'ARRAY') ) {

        if ( defined $indent ) {

            if ( $indent =~ /\A \d+ \z/msx ) {

                my ($frag, $h, $w) = @{$pretty};
                my @rows = split(/\n/, $frag);
                my @new_rows;
                foreach my $row (@rows) {
                    my $new_line = (" " x $indent) . $row;
                    push @new_rows, $new_line;
                }
                return join("\n", @new_rows);
            }
            else {
                carp "to_tall_string(): Indent must be numeric";
                return $pretty->[0];
            }

        }
        else {
            return $pretty->[0];
        }
    }
    
    carp "to_tall_string(): Could not create output string";
    return q{};
}


sub _prettify {
    my ($t, $p, $op, $brackets_on) = @_;

    $brackets_on = 1 unless defined $brackets_on;

    if ( $t->term_type() == T_VARIABLE ) {

        my $fragment = $t->to_string();
        my $frag_h = 1;
        my $frag_w = length($fragment);
        
        return [$fragment, $frag_h, $frag_w];
    }

    if ( $t->term_type() == T_CONSTANT ) {
        if ( $t->{special} eq 'euler' ) {
            return ['e', 1, 1];
        }
        else {
            my $fragment = $t->to_string();
            my $frag_h = 1;
            my $frag_w = length($fragment);
            
            return [$fragment, $frag_h, $frag_w];
        }
    }

    if ( $t->term_type() == T_OPERATOR ) {

        my $op_info = $Math::Symbolic::Operator::Op_Types[$t->type()];
        my $op_str = $op_info->{infix_string};
        my $opn = $op_str;
        $opn = $op_info->{prefix_string} unless defined $opn;

        if ( $t->arity() == 2 ) {

            if ( not defined $op_str ) {

                # write ln(x) instead of log(e, x)
                if ( ($op_info->{prefix_string} eq 'log') && ($t->op1()->term_type() == T_CONSTANT) && ($t->op1()->{special} eq 'euler') ) {

                    my $fragment = _prettify($t->op2(), $t, "ln", 1);
                    my $prefix = "ln";
                    return _compose_prefix_frag($fragment, $prefix);
                }
                else {
                    my $fragment = _compose_dual($t, $p, $op, $brackets_on, ',', $opn);
                    my ($frag, $h, $w) = @{$fragment};

                    my $op_len = length($opn);
                    my $height_offset = int($h/2);
                    my @rows = split("\n", $frag);               
                    my @new_rows;
                    foreach my $i (0..$h-1) {
                        my $line;
                        if ( $i == $height_offset ) {
                            $line = "$opn(" . $rows[$i] . ")";
                        }
                        else {
                            $line = (" " x $op_len) . "(" . $rows[$i] . ")";
                        }
                        push @new_rows, $line;                   
                    }

                    my $new_frag = join("\n", @new_rows);
                    return [$new_frag, scalar(@new_rows), $w+2+$op_len];                                                    
                }

            }
            elsif ( $t->type() == B_DIVISION ) {

                my $frag_num = _prettify($t->op1(), $t, $opn, $brackets_on);
                my $frag_den = _prettify($t->op2(), $t, $opn, $brackets_on);

                my ($num, $num_h, $num_w) = @{$frag_num};
                my ($den, $den_h, $den_w) = @{$frag_den};

                my $tot_h = $num_h + 1 + $den_h;

                my $tot_w;
                my $padding = 2;

                if ( $num_w > $den_w ) {
                    $tot_w = $num_w + $padding;
                }
                else {
                    $tot_w = $den_w + $padding;        
                }
                       
                my $line = "-" x $tot_w;

                my @new_num_rows;
                my $pre_num = int(($tot_w - $num_w)/2);
                foreach my $line (split("\n", $num)) {
                    my $new_line = " " x $pre_num;
                    $new_line .= $line;
                    while ( length($new_line) < $tot_w ) {
                        $new_line .= " ";
                    }
                    push @new_num_rows, $new_line;
                }

                my @new_den_rows;
                my $pre_den = int(($tot_w - $den_w)/2);
                foreach my $line (split("\n", $den)) {
                    my $new_line = " " x $pre_den;
                    $new_line .= $line;
                    while ( length($new_line) < $tot_w ) {
                        $new_line .= " ";
                    }
                    push @new_den_rows, $new_line;
                }

                my $fragment;
                if ( defined($p) && ($p->term_type() == T_OPERATOR) && ($p->type() == B_EXP) ) {
                    $fragment = join("\n", (map { "(" . $_ . ")" } (@new_num_rows, $line, @new_den_rows)));
                    $tot_w += 2;
                }
                else {
                    $fragment = join("\n", (@new_num_rows, $line, @new_den_rows));
                }

                return [$fragment, $tot_h, $tot_w];

            }
            elsif ( $t->type() == B_EXP ) {

                # write sqrt()
                if (    (($t->op2()->term_type() == T_CONSTANT) && ($t->op2()->value() == 0.5)) || 
                        (($t->op2()->term_type() == T_OPERATOR) && ($t->op2()->type() == B_DIVISION) &&
                        ($t->op2()->op1()->term_type == T_CONSTANT) && ($t->op2()->op1()->value() == 1) &&
                        ($t->op2()->op2()->term_type == T_CONSTANT) && ($t->op2()->op2()->value() == 2))
                     ) {

                    my $fragment = _prettify($t->op1(), $t, "sqrt", 1);
                    my $prefix = "sqrt";
                    return _compose_prefix_frag($fragment, $prefix);                    
                }

                my $frag_num = _prettify($t->op1(), $t, $opn, $brackets_on);
                my $frag_pow = _prettify($t->op2(), $t, $opn, $brackets_on);

                my ($num, $num_h, $num_w) = @{$frag_num};
                my ($pow, $pow_h, $pow_w) = @{$frag_pow};

                my @frag1_rows = split("\n", $num);
                my @frag2_rows = split("\n", $pow);

                my @new_rows;
                my $done_op = 0;
                EXP_LOOP: while ( 1 ) {
                   
                    my $new_row;
                    if ( scalar(@frag2_rows) ) {

                        my $pr = shift @frag2_rows;
                        $new_row = " " x ($num_w+1);
                        $new_row .= $pr;
                    }
                    else {
                        
                        my $nr = shift @frag1_rows;
                        $new_row = $nr;
                        if ( $done_op ) {
                            $new_row .= " ";
                        }
                        else {
                            $new_row .= "^";
                        }
                        $new_row .= " " x $pow_w;                            
                    }

                    push @new_rows, $new_row;
                    last EXP_LOOP unless scalar(@frag1_rows);
                }

                my $new_h = scalar(@new_rows);
                my $new_w = $num_w + 1 + $pow_w;

                my $new_fragment = join("\n", @new_rows);
                return [$new_fragment, $new_h, $new_w];     
            }
            else {
                return _compose_dual($t, $p, $op, $brackets_on, $op_str, $opn);                    
            }

        }
        elsif ( $t->arity() == 1 ) {

            if ( not defined $op_str ) {

                my $fragment = _prettify($t->op1(), $t, $opn, 1);
                my $prefix = $op_info->{prefix_string};
                return _compose_prefix_frag($fragment, $prefix);
            }
            elsif ($op_str eq "-") {
                               
                my $fragment = _prettify($t->op1(), $t, $opn, 1);
                my ($frag, $h, $w) = @{$fragment};

                if ( ($t->op1()->term_type() == T_VARIABLE) || ($t->op1()->term_type() == T_CONSTANT) ) {
                    my $new_frag = "-" . $frag;
                    return [$new_frag, 1, length($new_frag)];
                }

                my $height_offset = int($h/2);
                my @rows = split("\n", $frag);               
                my @new_rows;
                foreach my $i (0..$h-1) {
                    my $line;
                    if ( $i == $height_offset ) {
                        $line = "-( " . $rows[$i] . " )";
                    }
                    else {
                        $line = " " . "( " . $rows[$i] . " )";
                    }
                    push @new_rows, $line;                   
                }

                my $new_frag = join("\n", @new_rows);
                return [$new_frag, scalar(@new_rows), $w+5];                
            }
            else {
                croak "operator not recognised";
            }
        }
        croak "arity not recognised";
    }
    croak "term type not recognised";   
}

sub _compose_prefix_frag {
    my ($fragment, $prefix) = @_;

    my ($frag, $h, $w) = @{$fragment};    
    my $prefix_len = length($prefix);
    my $height_offset = int($h/2);
    my @rows = split("\n", $frag);

    my @new_rows;
    foreach my $i (0..$h-1) {
        my $line;
        if ( $i == $height_offset ) {
            $line = $prefix . "(" . $rows[$i] . ")";
        }
        else {
            $line = (" " x $prefix_len) . "(" . $rows[$i] . ")";
        }
        push @new_rows, $line;
    }
    
    my $new_w = $prefix_len + $w + 2;
    my $new_h = $h;
    my $new_frag = join("\n", @new_rows);

    return [$new_frag, $new_h, $new_w];
}

sub _compose_dual {
    my ($t, $p, $op, $brackets_on, $op_str, $opn) = @_;   
    
    my $brackets_on_2 = $brackets_on;
    if ( $brackets_on ) {
        
        # check if we can turn brackets off for the tree below
        if ( _is_all_operator($t, B_PRODUCT) || _is_all_operator($t, B_SUM) ) {
            $brackets_on_2 = 0;
        }
        if ( _is_all_operator($t, [B_SUM, B_DIFFERENCE, B_PRODUCT, U_MINUS, B_EXP]) && _is_expanded($t) ) {
            $brackets_on_2 = 0;
        }
    }

    my $frag1_r = _prettify($t->op1(), $t, $opn, $brackets_on_2);
    my $frag2_r = _prettify($t->op2(), $t, $opn, $brackets_on_2);

    my ($frag1, $h1, $w1) = @{$frag1_r};
    my ($frag2, $h2, $w2) = @{$frag2_r};

    my $new_h;
    my $f1_h_offset = 0;
    my $f2_h_offset = 0;
    if ( $h1 > $h2 ) {
        $new_h = $h1;
        $f2_h_offset = int(($new_h - $h2)/2);
        if ( ($new_h > 1) && ($new_h % 2 == 0) ) {
            $f2_h_offset++;
        }
    }
    elsif ( $h1 < $h2 ) {
        $new_h = $h2;
        $f1_h_offset = int(($new_h - $h1)/2);
        if ( ($new_h > 1) && ($new_h % 2 == 0) ) {
            $f1_h_offset++;
        }
    }
    else {
        $new_h = $h1; 
    }

    my $f1_w_offset = 0;
    my $f2_w_offset = $w1 + 1 + length($op_str) + 1;
    my $op_space = " " x length($op_str);
    my $op_buf = " ";
    if ( ($op_str eq "*") ) {
        if ( ($h1 == 1) && ($h2 == 1) ) {
            $op_buf = "";
        }
        elsif ( ($t->op1()->term_type() == T_OPERATOR) && ($t->op1()->type() == B_EXP) ) {
            $op_buf = "";
        }
        elsif ( ($t->op2()->term_type() == T_OPERATOR) && ($t->op2()->type() == B_EXP) ) {
            $op_buf = "";
        }
    }

    my $new_w = $w1 + length($op_str) + $w2 + (2*length($op_buf));

    my $op_h_offset = int($new_h/2);

    my @frag1_rows = split("\n", $frag1);
    my @frag2_rows = split("\n", $frag2);

    my @new_rows;
    foreach my $i (0..$new_h-1) {

        my $f1;
        if ( ($i >= $f1_h_offset) && scalar(@frag1_rows) ) {
            $f1 = shift @frag1_rows;
        }
        else {
            $f1 = " " x $w1;
        }
        
        my $f2;
        if ( ($i >= $f2_h_offset) && scalar(@frag2_rows) ) {
            $f2 = shift @frag2_rows;
        }
        else {
            $f2 = " " x $w2;
        }

        my $new_row;
        if ( $i == $op_h_offset ) {                    
            $new_row = $f1 . $op_buf . $op_str . $op_buf . $f2;
        }
        else {
            $new_row = $f1 . $op_buf . $op_space . $op_buf . $f2;
        }
        push @new_rows, $new_row;
    }
    
    my $new_fragment;
    my $do_brackets = $brackets_on;
    $do_brackets &= defined($p);
    $do_brackets = 1 if defined($p) && ($p->term_type() == T_OPERATOR) && ($p->type() == B_EXP);
    $do_brackets = 0 if defined($p) && ($p->term_type() == T_OPERATOR) && ($p->type() == B_DIVISION);
    $do_brackets = 0 if defined($p) && ($p->arity() == 1);
    $do_brackets = 0 if defined($op) && (($op eq 'ln') || ($op eq 'sqrt'));
    
    if ( $do_brackets ) {
        $new_fragment = join("\n", (map { "(" . $_ . ")" } @new_rows));
        $new_w += 2;
    }
    else { 
        $new_fragment = join("\n", @new_rows);
    }

    return [$new_fragment, $new_h, $new_w];   
}

### These routines duplicated from ToShorterString.pm

sub _is_all_operator {
    my ($t, $op_type) = @_;
    
    return 1 if ($t->term_type() == T_CONSTANT) || ($t->term_type() == T_VARIABLE);

    # this will stop descent into e.g. sin, cos
    my $op = $Math::Symbolic::Operator::Op_Types[$t->type()];
    if ( defined($op->{prefix_string}) and not defined($op->{infix_string}) ) {
        return 1;
    }
    
    if ( ref($op_type) eq "ARRAY" ) {
        my @m = grep { $_ == $t->type() } @{$op_type};    
        return 0 if scalar(@m) == 0;
    }
    else {
        return 0 if $t->type() != $op_type;
    }
    
    my $ok = 1;
    $ok &= _is_all_operator($_, $op_type) for @{$t->{operands}};
    return $ok;
}

sub _is_expanded {
    my ($t, $flag) = @_;
    
    $flag = 0 unless defined $flag;

    return 1 if ($t->term_type() == T_CONSTANT) || ($t->term_type() == T_VARIABLE);
    
    my $op = $Math::Symbolic::Operator::Op_Types[$t->type()];
    if ( defined($op->{prefix_string}) and not defined($op->{infix_string}) ) {
        return 1;
    }
    
    if ( $flag && (($t->type() == B_SUM) || ($t->type() == B_DIFFERENCE)) ) {
        return 0;
    }

    if ( ($t->type() == B_PRODUCT) || ($t->type() == B_DIFFERENCE) ) {
        $flag = 1;
    }

    my $ok = 1;
    $ok &= _is_expanded($_, $flag) for @{$t->{operands}};
    return $ok;
}

=pod

=head1 SEE ALSO

L<Math::Symbolic>

L<Math::Symbolic::Custom::ToShorterString>

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

