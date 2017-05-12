=head1 NAME

DynGig::Range::Time::Object - Implements DynGig::Range::Interface::Object.

=cut
package DynGig::Range::Time::Object;

use base DynGig::Range::Interface::Object;

use warnings;
use strict;

use overload
    '+=' => \&add,
    '-=' => \&subtract,
    '&=' => \&intersect;

=head1 METHODS

See base class for additional methods.

=head2 clear()

Returns the object after clearing its content.

=cut
sub clear
{
    my ( $this ) = @_;

    map { $this->[$_]->clear() } 1 .. $#$this;
    return $this;
}

=head2 empty()

Returns I<true> if object is empty, I<false> otherwise.

=cut
sub empty
{
    my ( $this ) = @_;
    return ! grep { ! $this->[$_]->empty() } 1 .. $#$this;
}

=head2 clone( object )

Returns a cloned object.

=cut
sub clone
{
    my ( $this ) = @_;
    bless [ map { $_->clone() } @$this ], ref $this;
}

=head2 add( object )

Overloads B<+=>. Returns the object after union with another object.

=cut
sub add
{
    my ( $this, $that ) = @_;

    map { $this->[$_] += $that->[$_] } 1 .. $#$this;
    return $this;
}

=head2 subtract( object )

Overloads B<-=>. Returns the object after subtraction with another object.

=cut
sub subtract
{
    my ( $this, $that ) = @_;

    map { $this->[$_] -= $that->[$_] } 1 .. $#$this;
    return $this;
}

=head2 intersect( object )

Overloads B<&=>. Returns the object after intersection with another object.

=cut
sub intersect
{
    my ( $this, $that ) = @_;

    map { $this->[$_] &= $that->[$_] } 1 .. $#$this;
    return $this;
}

1;

__END__

=head1 NOTE

See DynGig::Range::Time

=cut
