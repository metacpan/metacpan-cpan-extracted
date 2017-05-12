=head1 NAME

Declare::Constraints::Simple::Result - Validation Result

=cut

package Declare::Constraints::Simple::Result;
use warnings;
use strict;

use overload
    bool => \&is_valid,
    fallback => 1;

=head1 SYNOPSIS

  my $result = $constraint->($value);

  my $message = $result->message;
  my $path    = $result->path;

=head1 DESCRIPTION

This represents a result returned by a L<Declare::Constraints::Simple>
constraint. Objects of this kind overload their boolean context, so the
value of the L<is_valid()> accessor is reflected to it.

=cut

my %init = (
    message => '',
    valid   => 0,
);

=head1 METHODS

=head2 new()

Constructor. As you will mostly just receive result objects, you should 
never be required to call this yourself.

=cut

sub          new { bless {%init, stack => []} => shift }

=head2 set_valid($bool)

Sets the results validity flag.

=head2 is_valid()

Boolean accessor telling if this is a true result or not.

=cut

sub    set_valid { $_[0]->{valid} = $_[1] }
sub     is_valid { shift->{valid} }

=head2 set_message($message)

The error message. Useful only on non-valid results.

=head2 message()

Returns the message of the result object.

=cut

sub  set_message { $_[0]->{message} = $_[1] }
sub      message { shift->{message} }

=head2 add_to_stack($constraint_name)

This adds another level at the beginning (!) of the results constraint
stack. This is mostly intended to use for the C<prepare_generator>method
in L<Declare::Constraints::Simple::Library> package.

=head2 path([$separator])

Returns a string containing the L<stack()> contents joined together by
the C<$separator> string (defaulting to C<.>).

=cut

sub add_to_stack { unshift @{shift->{stack}}, shift }
sub         path { join( ($_[1]||'.'), @{$_[0]->stack} ) }

=head2 stack()

Returns an array reference containing the results currrent stack. This
is a list of the constraints path parts. This is usually just the
constraints name. If there's additional info, it is appended to the
name like C<[$info]>.

=cut

sub        stack { $_[0]->{stack} }

=head1 SEE ALSO

L<Declare::Constraints::Simple>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This module is free software, you can redistribute it and/or modify it 
under the same terms as perl itself.

=cut

1;
