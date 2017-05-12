#!/usr/bin/perl

package KiokuX::User::ID;
use MooseX::Role::Parameterized;

use namespace::clean -except => 'meta';

parameter id_attribute => (
    isa     => 'Str',
    default => 'id',
);

parameter user_prefix => (
    isa     => 'Str',
    default => 'user:',
);

role {
    my ($p) = @_;
    my $id_attr = $p->id_attribute;
    my $user_prefix = $p->user_prefix;

    with qw(KiokuDB::Role::ID);

    method id_for_user => sub {
        my ( $self, $id ) = @_;
        return $user_prefix . $id;
    };

    method kiokudb_object_id => sub {
        my $self = shift;
        $self->id_for_user($self->$id_attr);
    };

    has $id_attr => (
        isa      => "Str",
        is       => "ro",
        required => 1,
    );
};

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuX::User::ID - L<KiokuDB::Role::ID> integration for user objects

=head1 SYNOPSIS

    with qw(KiokuX::User::ID);

=head1 DESCRIPTION

This role provides an C<id> attribute for user objects, and self registers in
the L<KiokuDB> directory with the object ID C<user:$user_id>.

Using this role implies that user IDs are immutable.

=head1 METHODS

=over 4

=item kiokudb_object_id

Implements the required method from L<KiokuX::User::ID> by prefixing the C<id>
attribute with C<user:>.

=item id_for_user $username

Mangles the username into an ID by prefixing the string C<user:>.

Can be overriden to provide custom namespacing.

Can also be used as a class method from the model:

    sub get_identity_by_username {
        my ( $self, $username ) = @_;

        my $object_id = MyFoo::Schema::Identity::Username->id_for_user($username);

        return $self->lookup($object_id);
    }

=back

=head1 ATTRIBUTES

=over 4

=item id

This is the user's ID in the system. It is not the object ID, but the object ID
is derived from it.

=back

=cut

# ex: set sw=4 et:

