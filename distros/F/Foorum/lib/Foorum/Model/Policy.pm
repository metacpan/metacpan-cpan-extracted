package Foorum::Model::Policy;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Model';

sub fill_user_role {
    my ( $self, $c, $field ) = @_;

    my $roles = {};
    $roles = $c->user->{roles} if $c->user_exists;
    $field ||= 'site';

    if ( $roles->{$field}->{user} ) {
        $roles->{is_member} = 1;
    }

    if ( $roles->{site}->{moderator} || $roles->{$field}->{moderator} ) {
        $roles->{is_member}    = 1;
        $roles->{is_moderator} = 1;
    }

    if ( $roles->{site}->{admin} || $roles->{$field}->{admin} ) {
        $roles->{is_member}    = 1;
        $roles->{is_moderator} = 1;
        $roles->{is_admin}     = 1;
    }

    if ( $roles->{$field}->{blocked} ) {
        $roles->{is_member}  = 0;
        $roles->{is_blocked} = 1;
    }

    if ( $roles->{$field}->{pending} ) {
        $roles->{is_member}  = 0;
        $roles->{is_pending} = 1;
    }

    if ( $roles->{$field}->{rejected} ) {
        $roles->{is_member}   = 0;
        $roles->{is_rejected} = 1;
    }

    $c->stash->{roles} = $roles;
    return $roles;
}

sub is_admin {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_admin};
}

sub is_moderator {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_moderator};
}

sub is_user {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_member};
}

sub is_pending {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_pending};
}

sub is_rejected {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_rejected};
}

sub is_blocked {
    my ( $self, $c, $field ) = @_;

    &fill_user_role(@_) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_blocked};
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
