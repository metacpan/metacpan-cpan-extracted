package Math::Symbolic::Custom::CollectSimplify;

use 5.006001;
use strict;
use warnings;
no warnings 'recursion';

=pod

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::CollectSimplify - Simplify Math::Symbolic expressions using Math::Symbolic::Custom::Collect

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

use Math::Symbolic qw(:all);
use base 'Math::Symbolic::Custom::Simplification';
use Math::Symbolic::Custom::Collect 0.21;

=head1 SYNOPSIS

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::CollectSimplify;

    # 1. We have some expressions
    my $f1 = parse_from_string('2*(x+3)');
    my $f2 = parse_from_string('(6*x+2)*(4+x)');
    my $f3 = parse_from_string('3*x+(2*(x+1))');

    # 2. Manipulate them in some way to create a big expression
    my $f4 = $f1 + $f2 + $f3;

    # 3. We want to simplify this
    print "Expression: $f4\n";
    # Expression: ((2 * (x + 3)) + (((6 * x) + 2) * (4 + x))) + ((3 * x) + (2 * (x + 1)))

    # 4. Try with the simplify() that comes with Math::Symbolic
    my $f4_s1 = $f4->simplify();

    print "Original: $f4_s1\n";
    # Original: (((2 * (3 + x)) + ((2 + (6 * x)) * (4 + x))) + (2 * (1 + x))) + (3 * x)

    if ( $f4->test_num_equiv($f4_s1) ) {
        print "\t- Is numerically equivalent with original expression\n";
    }

    # 5. Try with the simplify() in this module instead
    # redefine "simplify()" using the register() method
    Math::Symbolic::Custom::CollectSimplify->register();

    my $f4_s2 = $f4->simplify();

    print "New: $f4_s2\n";
    # New: (16 + (33 * x)) + (6 * (x ^ 2))

    if ( $f4->test_num_equiv($f4_s2) ) {
        print "\t- Is numerically equivalent with original expression\n";
    }

=head1 DESCRIPTION

Redefines L<Math::Symbolic>'s "simplify()" method using the Math::Symbolic module extension class L<Math::Symbolic::Custom::Simplification>. This new simplify() method uses
"to_collected()" in L<Math::Symbolic::Custom::Collect>. Because "to_collected()" doesn't always produce a simpler expression,
this module uses a measure of expression complexity based on the number of constants, variables and operators to try to determine 
if the resultant expression is any simpler; if not it will return the expression passed to it.

=cut

sub simplify {
    my $f1 = shift;
    
    # calculate the complexity of the input expression
    my $f1_score = test_complexity($f1);

    # use to_collected() to (potentially) simplify it
    my $f2 = $f1->to_collected();

    if ( !defined $f2 ) {
        return $f1;
    }

    # compare on complexity and pass through the input expression
    # if the collected one is no simpler.
    my $f2_score = test_complexity($f2);

    return $f1_score > $f2_score ? $f2 : $f1;
}


# Try to achieve a measure of "complexity" of a Math::Symbolic expression.
# The greater the score, the higher the "complexity".
sub test_complexity {
    my ($tree) = @_;

    # Look at:
    # 1. the depth of the tree
    # 2. the number of constants
    # 3. the number of variable instances (e.g. x * x should count as 2 variables)
    # 4. the number of operations
    my %metrics = ( depth => 0, constants => 0, variables => 0, operations => 0 );
    walk($tree, 0, \%metrics);

    my $score = 0;
    # it should be possible to weight these metrics;
    # for now all metrics are at weight 1.
    $score += $_ for values %metrics;

    return $score;
}

# helper routine to walk the Math::Symbolic expression tree and tot up the metrics.
sub walk {
    my ($node, $depth, $hr) = @_;

    $hr->{depth} = $depth if $depth > $hr->{depth};

    if ($node->term_type() == T_CONSTANT) {
        $hr->{constants}++;
    } elsif ($node->term_type() == T_VARIABLE) {
        $hr->{variables}++;
    } else {
        $hr->{operations}++;
        foreach my $child (@{$node->{operands}}) {
            walk($child, $depth + 1, $hr);
        }
    }
}

=head1 SEE ALSO

L<Math::Symbolic>

L<Math::Symbolic::Custom::Simplification>

L<Math::Symbolic::Custom::Collect>

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


