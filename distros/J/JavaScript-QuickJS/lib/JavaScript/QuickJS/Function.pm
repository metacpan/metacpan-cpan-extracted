package JavaScript::QuickJS::Function;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

JavaScript::QuickJS::Function

=head1 SYNOPSIS

    my $func = JavaScript::QuickJS->new()->eval("() => 123");

    print $func->();    # prints “123”; note overloading :)

=head1 DESCRIPTION

This class represents a JavaScript
L<Function|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function>
instance in Perl.

This class is not instantiated directly.

=head1 OVERLOADING

For convenience, instances of this class are callable as Perl code references.
This is equivalent to a C<call()> with $this_sv (see below) set to undef.

See the L</SYNOPSIS> above for an example.

=head1 INVOCATION METHODS

=head2 $ret = I<OBJ>->call( $this_sv, @arguments )

Like JavaScript’s method of the same name.

=head1 ACCESSOR METHODS

The following methods return their corresponding JS property:

=over

=item * C<length()>

=item * C<name()>

=back

=cut

#----------------------------------------------------------------------

sub _as_coderef;

use overload (
    '&{}' => \&_as_coderef,
    nomethod => \&_give_self,   # xsub
);

sub _as_coderef {
    my ($self) = @_;

    return sub { $self->call(undef, @_) };
}

1;
