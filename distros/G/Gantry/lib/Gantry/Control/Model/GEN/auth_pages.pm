# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Gantry::Control::Model::GEN::auth_pages;
use strict; use warnings;

use base 'Gantry::Utils::Model::Auth';

use Carp;

sub get_table_name    { return 'auth_pages'; }

sub get_primary_col   { return 'id'; }

sub get_essential_cols {
    return 'id, user_perm, group_perm, world_perm, owner_id, group_id, uri, title';
}

sub get_primary_key {
    goto &id;
}

sub id {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) {
        return $self->set_id( $value );
    }

    return $self->get_id();
}

sub set_id {
    croak 'Can\'t change primary key of row';
}

sub get_id {
    my $self = shift;
    return $self->{id};
}

sub quote_id {
    return $_[1];
}

sub group_id {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_group_id( $value ); }
    else                  { return $self->get_group_id();         }
}

sub set_group_id {
    my $self  = shift;
    my $value = shift;

    if ( ref $value ) {
        $self->{group_id_REF} = $value;
        $self->{group_id}     = $value->id;
    }
    elsif ( defined $value ) {
        delete $self->{group_id_REF};
        $self->{group_id}     = $value;
    }
    else {
        croak 'set_group_id requires a value';
    }

    $self->{__DIRTY__}{group_id}++;

    return $value;
}

sub get_group_id {
    my $self = shift;

    if ( not defined $self->{group_id_REF} ) {
        $self->{group_id_REF}
            = Gantry::Control::Model::auth_groups->retrieve_by_pk(
                    $self->{group_id}
              );

        $self->{group_id}     = $self->{group_id_REF}->get_primary_key()
                if ( defined $self->{group_id_REF} );
    }

    return $self->{group_id_REF};
}

sub get_group_id_raw {
    my $self = shift;

    if ( @_ ) {
        croak 'get_group_id_raw is only a get accessor, pass it nothing';
    }

    return $self->{group_id};
}

sub quote_group_id {
    return 'NULL' unless defined $_[1];
    return ( ref( $_[1] ) ) ? "$_[1]" : $_[1];
}

sub group_perm {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_group_perm( $value ); }
    else                  { return $self->get_group_perm();         }
}

sub set_group_perm {
    my $self  = shift;
    my $value = shift;

    $self->{group_perm} = $value;
    $self->{__DIRTY__}{group_perm}++;

    return $value;
}

sub get_group_perm {
    my $self = shift;

    return $self->{group_perm};
}

sub quote_group_perm {
    return $_[1];
}

sub owner_id {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_owner_id( $value ); }
    else                  { return $self->get_owner_id();         }
}

sub set_owner_id {
    my $self  = shift;
    my $value = shift;

    if ( ref $value ) {
        $self->{owner_id_REF} = $value;
        $self->{owner_id}     = $value->id;
    }
    elsif ( defined $value ) {
        delete $self->{owner_id_REF};
        $self->{owner_id}     = $value;
    }
    else {
        croak 'set_owner_id requires a value';
    }

    $self->{__DIRTY__}{owner_id}++;

    return $value;
}

sub get_owner_id {
    my $self = shift;

    if ( not defined $self->{owner_id_REF} ) {
        $self->{owner_id_REF}
            = Gantry::Control::Model::auth_users->retrieve_by_pk(
                    $self->{owner_id}
              );

        $self->{owner_id}     = $self->{owner_id_REF}->get_primary_key()
                if ( defined $self->{owner_id_REF} );
    }

    return $self->{owner_id_REF};
}

sub get_owner_id_raw {
    my $self = shift;

    if ( @_ ) {
        croak 'get_owner_id_raw is only a get accessor, pass it nothing';
    }

    return $self->{owner_id};
}

sub quote_owner_id {
    return 'NULL' unless defined $_[1];
    return ( ref( $_[1] ) ) ? "$_[1]" : $_[1];
}

sub title {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_title( $value ); }
    else                  { return $self->get_title();         }
}

sub set_title {
    my $self  = shift;
    my $value = shift;

    $self->{title} = $value;
    $self->{__DIRTY__}{title}++;

    return $value;
}

sub get_title {
    my $self = shift;

    return $self->{title};
}

sub quote_title {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub uri {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_uri( $value ); }
    else                  { return $self->get_uri();         }
}

sub set_uri {
    my $self  = shift;
    my $value = shift;

    $self->{uri} = $value;
    $self->{__DIRTY__}{uri}++;

    return $value;
}

sub get_uri {
    my $self = shift;

    return $self->{uri};
}

sub quote_uri {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub user_perm {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_user_perm( $value ); }
    else                  { return $self->get_user_perm();         }
}

sub set_user_perm {
    my $self  = shift;
    my $value = shift;

    $self->{user_perm} = $value;
    $self->{__DIRTY__}{user_perm}++;

    return $value;
}

sub get_user_perm {
    my $self = shift;

    return $self->{user_perm};
}

sub quote_user_perm {
    return $_[1];
}

sub world_perm {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_world_perm( $value ); }
    else                  { return $self->get_world_perm();         }
}

sub set_world_perm {
    my $self  = shift;
    my $value = shift;

    $self->{world_perm} = $value;
    $self->{__DIRTY__}{world_perm}++;

    return $value;
}

sub get_world_perm {
    my $self = shift;

    return $self->{world_perm};
}

sub quote_world_perm {
    return $_[1];
}

sub get_foreign_display_fields {
    return [ qw(  ) ];
}

sub get_foreign_tables {
    return qw(
        Gantry::Control::Model::auth_users
        Gantry::Control::Model::auth_groups
    );
}

sub foreign_display {
    my $self = shift;

}

1;

=head1 NAME

Gantry::Control::Model::GEN::auth_pages - model for auth_pages table

=head1 METHODS

=over 4

=item foreign_display

=item get_essential_cols

=item get_foreign_display_fields

=item get_foreign_tables

=item get_group_id

=item get_group_id_raw

=item get_group_perm

=item get_id

=item get_owner_id

=item get_owner_id_raw

=item get_primary_col

=item get_primary_key

=item get_sequence_name

=item get_table_name

=item get_title

=item get_uri

=item get_user_perm

=item get_world_perm

=item group_id

=item group_perm

=item id

=item owner_id

=item quote_group_id

=item quote_group_perm

=item quote_id

=item quote_owner_id

=item quote_title

=item quote_uri

=item quote_user_perm

=item quote_world_perm

=item set_group_id

=item set_group_perm

=item set_id

=item set_owner_id

=item set_title

=item set_uri

=item set_user_perm

=item set_world_perm

=item title

=item uri

=item user_perm

=item world_perm

=back

=head1 AUTHOR

Generated by Bigtop, please don't edit.

=cut
