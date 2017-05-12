=head1 NAME

Declare::Constraints::Simple::Library::Numerical - Numerical Constraints

=cut

package Declare::Constraints::Simple::Library::Numerical;
use warnings;
use strict;

use Declare::Constraints::Simple-Library;

use Scalar::Util ();

=head1 SYNOPSIS

  # test for number-conformity
  my $looks_like_number = IsNumber;

  # only integers
  my $is_int = IsInt;

=head1 DESCRIPTIONS

This library contains the constraints needed to validate numerical values.

=head1 CONSTRAINTS

=head2 IsNumber()

True if the value is a number according to L<Scalar::Util>s 
C<looks_like_number>. 

=cut

constraint 'IsNumber',
    sub {
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _result(Scalar::Util::looks_like_number($_[0]), 
                'Does not look like Number');
        };
    };

=head2 IsInt()

True if the value is an integer.

=cut

constraint 'IsInt',
    sub {
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _result(scalar($_[0] =~ /^-?\d+$/), 'Not an Integer');
        };
    };

=head1 SEE ALSO

L<Declare::Constraints::Simple>, L<Declare::Constraints::Simple::Library>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This module is free software, you can redistribute it and/or modify it 
under the same terms as perl itself.

=cut

1;
