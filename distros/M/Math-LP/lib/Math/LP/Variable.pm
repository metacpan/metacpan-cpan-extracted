package Math::LP::Variable;
use strict;
#use Math::LP::Object;
use Math::SimpleVariable;
use base qw(Math::SimpleVariable);
use fields(
    'is_int',      # flags whether it is an integer variable, defaults to false
    'upper_bound', # defaults to +infinity
    'lower_bound', # defaults to 0, as is the convention in linear programming
    'col_index',   # column index in an LP, used by the Math::LP functions
);

sub initialize {
    my Math::LP::Variable $this = shift;
    $this->{is_int} ||= 0;
    $this->{upper_bound} = $Math::LP::Solve::DEF_INFINITE 
	unless defined($this->{upper_bound});
    $this->{lower_bound} = 0 
	unless defined($this->{lower_bound});
    $this->SUPER::initialize();
}

1;

__END__

=head1 NAME

Math::LP::Variable - variables used in linear programs

=head1 SYNOPSIS

    use Math::LP::Variable;

    # make a variable named x1
    my $x1 = new Math::LP::Variable(name => 'x1');

    # make an integer variable named x2
    my $x2 = new Math::LP::Variable(name => 'x2', is_int => 1);

    # make a variable named x3 initialized to 3.1415
    my $x3 = new Math::LP::Variable(name => 'x3', value => '3.1415');

=head1 DESCRIPTION

=head2 DATA FIELDS

=over 4

=item name

a string with the name of the variable (required)

=item is_int

a flag indicating whether the variable can only have integer values
(optional, defaults to false)

=item value

a number representing the value of the variable (optional)

=item upper_bound

an upper bound to the value, defaults to 1E24

=item lower_bound

a lower bound to the value, defaults to 0

=item col_index

an integer number holding the index of the variable in the matrix of the
LP the variable is used in (optional)

=back

=head2 METHODS

Math::LP::Variable inherits all methods from Math::SimpleVariable, without
adding any new methods.

=head1 SEE ALSO

More info on the base class is found in L<Math::SimpleVariable>.
The usage of Math::LP::Variables in linear programs is illustrated
in L<Math::LP>.

=head1 AUTHOR

Wim Verhaegen E<lt>wimv@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright(c) 2000-2001 Wim Verhaegen. All rights reserved. 
This program is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

=cut

