package Interchange6::Schema::Populate::Role;

=head1 NAME

Interchange6::Schema::Populate::Role

=head1 DESCRIPTION

This module provides population capabilities for the Role result class

=cut

use Moo::Role;

=head1 METHODS

=head2 populate_roles

=over

=item * admin

Shop administrator with full permissions.

=item * user

All non-anonymous users have this role.

=item * anonymous

Anonymous users.

=back

=cut

sub populate_roles {
    my $self = shift;
    my $rset = $self->schema->resultset('Role');
    $rset->create(
        {
            name        => "admin",
            label       => "Admin",
            description => "Shop administrator with full permissions",
        }
    );
    $rset->create(
        {
            name        => "user",
            label       => "User",
            description => "All users have this role",
        }
    );
    $rset->create(
        {
            name        => "anonymous",
            label       => "Anonymous",
            description => "Anonymous users",
        }
    );
}

1;
