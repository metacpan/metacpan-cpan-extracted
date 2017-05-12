package Elive::Entity::Role;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::Entity';

=head1 NAME

Elive::Entity::Role - Elluminate Role entity class

=head1 DESCRIPTION

This is a structural class for Elive roles. It is a component of the
L<Elive::Entity::User> and L<Elive::Entity::Participants::Participant>
entities.

=cut

__PACKAGE__->entity_name('Role');

has 'roleId' => (is => 'rw', isa => 'Int', required => 1);
__PACKAGE__->primary_key('roleId');

our ( $SYSTEM_ADMIN, $APPLICATION_ADMIN, $MODERATOR, $PARTICIPANT );
BEGIN {
    $SYSTEM_ADMIN      = 0;
    $APPLICATION_ADMIN = 1;
    $MODERATOR         = 2;
    $PARTICIPANT       = 3;
}

sub BUILDARGS {
    my $class = shift;
    my $spec = shift;

    my $args;
    if (defined $spec && ! ref $spec) {
	$args = {roleId => $spec};
    }
    else {
	$args = $spec;
    }

    return $args;
}

coerce 'Elive::Entity::Role' => from 'HashRef|Int'
          => via {Elive::Entity::Role->new($_) };

1;
