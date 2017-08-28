package MYDan::Node::Object;

=head1 NAME

MYDan::Node::Object - MYDan::Node Object Interface.

Each Captialized method depends on a corresponding Lvalue implementation.

e.g. Add() depends on child class add().

=cut
use strict;
use warnings;

use overload
    '='   => \&assign,
    '+'   => \&Add,
    '-'   => \&Subtract,
    '*'   => \&Multiply,
    '&'   => \&Intersect,
    '^'   => \&Symdiff,
    '""'  => \&Dump,
    '@{}' => \&List,
    bool  => \&bool,
    '=='  => \&same,
    '!='  => sub { ! same( @_ ) };

=head1 METHODS

=head3 clone()

Returns a cloned object. Requires a load() method.

=cut
sub clone
{
    my $self = shift;
    my $clone = $self->new()->load( $self );
}

=head3 assign()

Overloads B<=>. Returns the object itself.

=cut
sub assign { $_[0] }

=head3 bool()

Overloads B<bool>. Returns I<true> if object is defined, I<false> otherwise.

=cut
sub bool { defined $_[0] }

=head3 same( object )

Overloads B<==>. ( And the inverse overloads B<!=> ).
Returns I<true> if two objects are the same, I<false> otherwise.

=cut
sub same { overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] ) }

=head3 List()

Overloads '@{}'. Returns a list.

=cut
sub List
{
    my $self = shift;
    return wantarray ? $self->list() : [ $self->list() ];
}

=head3 Dump()

Overloads '""'. Returns a string expression.

=cut
sub Dump
{
    my $self = shift;
    return $self->dump();
}

=head3 Add( $o )

Overloads B<+>. Returns the union of two objects.

=head3 Subtract( $o )

Overloads B<->. Returns the I<left> difference of two objects.

=head3 Intersect( $o )

Overloads B<&>. Returns the intersection of two objects.

=head3 Symdiff( $o )

Overloads B<^>. Returns the symmetric difference of two objects.

=head3 Multiply( $o )

Overloads B<*>. Returns the product of two objects.

=cut
sub AUTOLOAD
{
    my $self = shift;
    my $op = our $AUTOLOAD =~ /::(Add|Subtract|Interact|Multiply|Symdiff)$/
        ? $self->can( lcfirst $1 ) : undef;
    return $op ? $self->clone()->$op( @_ ) : $self;
}

sub DESTROY { }

1;
