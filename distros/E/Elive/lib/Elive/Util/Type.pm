package Elive::Util::Type;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;
use Try::Tiny;

our $VERSION = '1.37';

=head1 NAME

Elive::Util::Type - Type introspection class

=cut

has 'type' => (is => 'rw', isa => 'Str', required => 1);
has 'array_type' => (is => 'rw', isa => 'Str');
has 'elemental_type' => (is => 'rw', isa => 'Str', required => 1);
has '_other_types' => (is => 'rw', isa => 'ArrayRef[Str]', required => 1);

sub BUILDARGS {
    my ($class, $type) = @_;

    my %info;

    #
    # Bit of a hack, tailored for Elive specific types and type unions.
    #

    my $array_type;
    my ($elemental_type, @other_types) = split(/\|/, $type);

    if (try { $type->can('element_class') }) {
	($elemental_type, @other_types) = split(/\|/, $type->element_class || 'Str');
	$array_type = $type;
    }

    $info{type} = $type;
    $info{array_type} = $array_type if defined $array_type;
    $info{elemental_type} = $elemental_type;
    $info{_other_types} = \@other_types;

    return \%info;
}

=head1 METHODS

=head2 new

       $type = Elive::Util::inspect_type('Elive::Entity::Participants');
       if ($type->is_array) {
           # ...
       }

Creates an object of type L<Elive::Util::Type>.

=cut

=head2 is_struct

    Return true, if the type is an ancestor of Elive::DAO

=cut

sub is_struct {
    my $self = shift;

    my $elemental_type = $self->elemental_type;
    return ($elemental_type  =~ m{^Elive::}
	    && $elemental_type->isa('Elive::DAO'));
}

=head2 is_ref

    Return true if the elemental_type is a reference; including objects.

=cut

sub is_ref {
    my $self = shift;

    return $self->is_array || $self->is_struct || $self->elemental_type =~ m{^Ref}x;
}

=head2 is_array

Return an elemental class if objects are substantiated as arrays.

    my $type = Elive::Util::Type->new('Elive::Entity::Participants');
    print $type->is_array;
    # prints Elive::Entity::Participant

If the class is an array, the C<is_struct()> and C<is_ref()> methods inquire
on the properties of the element class.

=cut

sub is_array {
    my $self = shift;

    return $self->array_type;
}

=head2 elemental_type

Returns the type of the class. For arrays, returns the array element
class.

=cut

=head2 union

Return the full type union.  For arrays, returns the union of all possible
array element classes.

    my @types = Elive::Util::Type->new(' Elive::Entity::Group::Members')->union;
    #
    # group members may contain sub-groups, user objects, or packed strings
    is(\@types, [qw(Elive::Entity::Group Str)]);

=cut

sub union {
    my $self = shift;

    return ($self->elemental_type, @{ $self->_other_types });
}

1;
