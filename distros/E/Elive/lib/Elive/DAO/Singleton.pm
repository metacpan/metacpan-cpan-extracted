package Elive::DAO::Singleton;
use warnings; use strict;

use Carp;

=head1 NAME

Elive::DAO::Singleton - Singleton mixin class

=head1 DESCRIPTION

This mixin class provides a C<get> method for fetching the singleton
object. It also overrides the L<Elive::DAO> list method, to return just
the singleton object in a one element array.

Typical usage is:

    package Elive::Entity::SomeEntity;
    use warnings; use strict;

    use Mouse;

    extends 'Elive::DAO::Singleton', 'Elive::Entity';

=cut

=head1 METHODS

=head2 get

    my $server = Elive::Entity::ServerDetails->get(connection => $connection);

Gets the singleton object.

=cut

sub get {
    my ($class, %opt) = @_;

    my $object_list = $class->list(%opt);

    die "unable to get $class\n"
	unless (Elive::Util::_reftype($object_list) eq 'ARRAY'
		&& $object_list->[0]);

    return $object_list->[0];
}

=head2 list

    my $server_list = Elive::Entity::SomeEntity->list();
    my $server_obj = $server_list->[0];

Returns the singleton object in a one element array .

=cut

sub list {
    my ($class, %opt) = @_;

    croak "filter not applicable to singleton class: $class"
	if ($opt{filter});

    return $class->_fetch({}, %opt);
}

1;
