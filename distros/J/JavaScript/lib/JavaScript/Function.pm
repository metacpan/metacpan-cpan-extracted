package JavaScript::Function;

use strict;
use warnings;

our @ISA = qw(JavaScript::Boxed);

use overload '&{}'  => 'as_function', fallback => 1;

sub as_function {
    my $self = shift;
    return sub { $self->context->call( $self, @_ ) };
}

1;
__END__

=head1 NAME

JavaScript::Function - Reference to a JavaScript function

=head1 DESCRIPTION

Functions in JavaScript are actually C<Function>-objects. This class encapsulates them
and make them invokeable as a code-reference from Perl.

=head1 INTERFACE

=head2 INSTANCE METHODS

=over 4

=item as_function

Returns an code-reference that can be invoked which calls the underlying JavaScript C<Function>-object.

=back

=head2 OVERLOADED METHODS

Instances of this class overloads C<&{}> which means that you can use the instance as a code-reference
directlly without having to use C<as_function>.

=cut
