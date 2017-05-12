=head1 NAME

Declare::Constraints::Simple::Library - Constraint Library Bundle

=cut

package Declare::Constraints::Simple::Library;
use warnings;
use strict;

use base qw(
    Declare::Constraints::Simple::Library::General
    Declare::Constraints::Simple::Library::Scalar
    Declare::Constraints::Simple::Library::Numerical
    Declare::Constraints::Simple::Library::OO
    Declare::Constraints::Simple::Library::Referencial
    Declare::Constraints::Simple::Library::Hash
    Declare::Constraints::Simple::Library::Array
    Declare::Constraints::Simple::Library::Operators
);

=head1 DESCRIPTION

This module functions as bundle of all default libraries, and as map
and/or reference of said ones.

=head1 LIBRARIES

=over

=item L<Declare::Constraints::Simple::Library::General>

General constraints and constraint-like elements that affect the whole
framework.

Provides: C<Message>, C<Scope>, C<SetResult>, C<IsValid>, C<ReturnTrue>,
C<ReturnFalse>

=item L<Declare::Constraints::Simple::Library::Scalar>

Constraints for scalar value validation.

Provides: C<Matches>, C<IsDefined>, C<HasLength>, C<IsOneOf>, C<IsTrue>,
C<IsEq>

=item L<Declare::Constraints::Simple::Library::Numerical>

These validate values by their numerical properties.

Provides: C<IsNumber>, C<IsInt>

=item L<Declare::Constraints::Simple::Library::OO>

For validation of values in an object oriented manner.

Provides: C<IsA>, C<IsClass>, C<IsObject>, C<HasMethods>

=item L<Declare::Constraints::Simple::Library::Referencial>

These can validate properties by their reference types.

Provides: C<IsRefType>, C<IsScalarRef>, C<IsArrayRef>, C<IsHashRef>,
C<IsCodeRef>, C<IsRegex>

=item L<Declare::Constraints::Simple::Library::Array>

These constraints deal with array references and their contents.

Provides: C<HasArraySize>, L<OnArrayElements>, L<OnEvenElements>, 
L<OnOddElements>

=item L<Declare::Constraints::Simple::Library::Hash>

All constraints appliable to hash references as well as their keys and
values.

Provides: C<HasAllKeys>, C<OnHashKeys>

=item L<Declare::Constraints::Simple::Library::Operators>

Operators can be used in any place a constraint can be used, as
their implementations are similar.

Provides: C<And>, C<Or>, C<XOr>, C<Not>, C<CaseValid>

=back

=head1 SEE ALSO

L<Declare::Constraints::Simple>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This module is free software, you can redistribute it and/or modify it 
under the same terms as perl itself.

=cut

1;

