# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Gantry::Control::Model::GEN::auth_users;
use strict; use warnings;

use base 'Gantry::Utils::Model::Auth';

use Carp;

sub get_table_name    { return 'auth_users'; }

sub get_primary_col   { return 'id'; }

sub get_essential_cols {
    return 'id, user_id, active, user_name, passwd, crypt, first_name, last_name, email';
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

sub active {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_active( $value ); }
    else                  { return $self->get_active();         }
}

sub set_active {
    my $self  = shift;
    my $value = shift;

    $self->{active} = $value;
    $self->{__DIRTY__}{active}++;

    return $value;
}

sub get_active {
    my $self = shift;

    return $self->{active};
}

sub quote_active {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub crypt {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_crypt( $value ); }
    else                  { return $self->get_crypt();         }
}

sub set_crypt {
    my $self  = shift;
    my $value = shift;

    $self->{crypt} = $value;
    $self->{__DIRTY__}{crypt}++;

    return $value;
}

sub get_crypt {
    my $self = shift;

    return $self->{crypt};
}

sub quote_crypt {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub email {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_email( $value ); }
    else                  { return $self->get_email();         }
}

sub set_email {
    my $self  = shift;
    my $value = shift;

    $self->{email} = $value;
    $self->{__DIRTY__}{email}++;

    return $value;
}

sub get_email {
    my $self = shift;

    return $self->{email};
}

sub quote_email {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub first_name {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_first_name( $value ); }
    else                  { return $self->get_first_name();         }
}

sub set_first_name {
    my $self  = shift;
    my $value = shift;

    $self->{first_name} = $value;
    $self->{__DIRTY__}{first_name}++;

    return $value;
}

sub get_first_name {
    my $self = shift;

    return $self->{first_name};
}

sub quote_first_name {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub ident {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_ident( $value ); }
    else                  { return $self->get_ident();         }
}

sub set_ident {
    my $self  = shift;
    my $value = shift;

    $self->{ident} = $value;
    $self->{__DIRTY__}{ident}++;

    return $value;
}

sub get_ident {
    my $self = shift;

    return $self->{ident};
}

sub quote_ident {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub last_name {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_last_name( $value ); }
    else                  { return $self->get_last_name();         }
}

sub set_last_name {
    my $self  = shift;
    my $value = shift;

    $self->{last_name} = $value;
    $self->{__DIRTY__}{last_name}++;

    return $value;
}

sub get_last_name {
    my $self = shift;

    return $self->{last_name};
}

sub quote_last_name {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub passwd {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_passwd( $value ); }
    else                  { return $self->get_passwd();         }
}

sub set_passwd {
    my $self  = shift;
    my $value = shift;

    $self->{passwd} = $value;
    $self->{__DIRTY__}{passwd}++;

    return $value;
}

sub get_passwd {
    my $self = shift;

    return $self->{passwd};
}

sub quote_passwd {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub user_id {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_user_id( $value ); }
    else                  { return $self->get_user_id();         }
}

sub set_user_id {
    my $self  = shift;
    my $value = shift;

    $self->{user_id} = $value;
    $self->{__DIRTY__}{user_id}++;

    return $value;
}

sub get_user_id {
    my $self = shift;

    return $self->{user_id};
}

sub quote_user_id {
    return $_[1];
}

sub user_name {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_user_name( $value ); }
    else                  { return $self->get_user_name();         }
}

sub set_user_name {
    my $self  = shift;
    my $value = shift;

    $self->{user_name} = $value;
    $self->{__DIRTY__}{user_name}++;

    return $value;
}

sub get_user_name {
    my $self = shift;

    return $self->{user_name};
}

sub quote_user_name {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub get_foreign_display_fields {
    return [ qw(  ) ];
}

sub get_foreign_tables {
    return qw(
    );
}

sub foreign_display {
    my $self = shift;

}

1;

=head1 NAME

Gantry::Control::Model::GEN::auth_users - model for auth_users table

=head1 METHODS

=over 4

=item active

=item crypt

=item email

=item first_name

=item foreign_display

=item get_active

=item get_crypt

=item get_email

=item get_essential_cols

=item get_first_name

=item get_foreign_display_fields

=item get_foreign_tables

=item get_id

=item get_ident

=item get_last_name

=item get_passwd

=item get_primary_col

=item get_primary_key

=item get_sequence_name

=item get_table_name

=item get_user_id

=item get_user_name

=item id

=item ident

=item last_name

=item passwd

=item quote_active

=item quote_crypt

=item quote_email

=item quote_first_name

=item quote_id

=item quote_ident

=item quote_last_name

=item quote_passwd

=item quote_user_id

=item quote_user_name

=item set_active

=item set_crypt

=item set_email

=item set_first_name

=item set_id

=item set_ident

=item set_last_name

=item set_passwd

=item set_user_id

=item set_user_name

=item user_id

=item user_name

=back

=head1 AUTHOR

Generated by Bigtop, please don't edit.

=cut
