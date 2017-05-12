package Math::LP::LinearCombination;
use strict;
#use Math::LP::Object;
use Math::LinearCombination;
use Math::LP::Variable;
use base qw(Math::LinearCombination);
use fields(
    'value', # cached value
);

1;

__END__

=head1 NAME

Math::LP::LinearCombination - linear combination of Math::LP::Variable objects

=head1 SYNOPSIS

    use Math::LP::LinearCombination;

    # first construct some variables
    $x1 = new Math::LP::Variable(name => 'x1');
    $x2 = new Math::LP::Variable(name => 'x2');

    # build x1 + 2 x2 from an empty linear combination
    $lc1 = new Math::LP::LinearCombination;
    $lc1->add_entry(var => $x1, coeff => 1.0);
    $lc1->add_entry(var => $x2, coeff => 2.0);

    # alternatively, make x1 + 2 x2 in one go
    $lc2 = make Math::LP::LinearCombination($x1, 1.0,
                                            $x2, 2.0 );

=head1 DESCRIPTION

Any client should not access any other field than the C<value> field.
This field contains the value of the linear combination, typically
obtained in calculate_value(), but it may be set elsewhere (e.g. by
the solve() function in Math::LP).

The following methods are available:

=over 4

=item new()

returns a new, empty linear combination

=item make($var1,$coeff1,$var2,$coeff2,...)

returns a new linear combination initialized with the given variables and
coefficients. A ref to an array of variables and coefficients is also
accepted as a legal argument.

=item add_entry(var => $var, coeff => $coeff)

adds a variable to the linear combination with the given coefficient

=item evaluate()

calculates the value of the linear combination. The value is also stored in the
C<value> field. Requires that the values of all variables are defined.

=back

=head1 SEE ALSO

The base class of Math::LP::LinearCombination is documented in
L<Math::LinearCombination>

The usage of variables is documented in L<Math::LP::Variable>
and L<Math::LP::SimpleVariable>

The interaction with other classes for solving linear programs
is described in L<Math::LP>

=head1 AUTHOR

Wim Verhaegen E<lt>wimv@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright(c) 2000-2001 Wim Verhaegen. All rights reserved. 
This program is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

=cut


