=head1 NAME

DynGig::Range::Interface::Object - Base class for range objects

=cut
package DynGig::Range::Interface::Object;

use warnings;
use strict;

use overload
    '+'  => \&Add,
    '-'  => \&Subtract,
    '*'  => \&Multiply,
    '&'  => \&Intersect,
    '='  => \&assign,
    bool => \&bool,
    '==' => \&same,
    '!=' => sub { ! same( @_ ) };

sub new
{
    my ( $class, $this ) = @_;
    bless $this, ref $class || $class;
}

=head1 DESCRIPTION

See derived class for additional methods.

=head2 expand( input .. )

See base class list() for return value.

=cut
sub expand
{
    my $class = shift @_;
    $class->new( @_ )->list();
}

=head2 serial( input .. )

See base class string() for return value.

=cut
sub serial
{
    my $class = shift @_;
    $class->new( @_ )->string();
}

=head2 assign()

Overloads B<=>. Returns the object itself.

=cut
sub assign { $_[0] }

=head2 bool()

Overloads B<bool>. Returns I<true> if object is defined, I<false> otherwise.

=cut
sub bool { defined $_[0] }

=head2 same( object )

Overloads B<==>. ( And the inverse overloads B<!=> ).
Returns I<true> if two objects are the same, I<false> otherwise.

=cut
sub same { overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] ) }

=head2 Add( object )

Overloads B<+>. Returns the union of two objects.

=cut
sub Add
{
    my $this = shift @_;
    $this->clone()->add( @_ );
}

=head2 Subtract( object )

Overloads B<->. Returns the I<left> difference of two objects.

=cut
sub Subtract
{
    my $this = shift @_;
    $this->clone()->subtract( @_ );
}

=head2 Intersect( object )

Overloads B<&>. Returns the intersection of two objects.

=cut
sub Intersect
{
    my $this = shift @_;
    $this->clone()->intersect( @_ );
}

=head2 Multiply( object )

Overloads B<*>. Returns the product of two objects.

=cut
sub Multiply
{
    my $this = shift @_;
    $this->clone()->multiply( @_ );
}

=head1 NOTE

expand() and serial() depend on list() and string() respectlively.

Add(), Subtract(), Multiply(), and Intersect(), each depends on a
corresponding Lvalue implementation. See base class.

=head1 NOTE

See DynGig::Range

=cut

1;

__END__
