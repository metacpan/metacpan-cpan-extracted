package MetaStore::Auth;


=head1 NAME

MetaStore::Auth - Auth class.

=head1 SYNOPSIS

    use MetaStore::Auth;

    my $auth = new MetaStore::Auth:: users => $users, session => $opt{session};


=head1 DESCRIPTION

Auth class.

=head1 METHODS

=cut

use strict;
use warnings;
use Data::Dumper;
use base 'MetaStore::Base';
our $VERSION = '0.01';
__PACKAGE__->attributes( qw(  current_user _users));

sub init {
    my $self = shift;
    my %opt  = @_;
    my ( $users, $sess, ) =
      @opt{qw/ users session  /};
    my $sess_id = $sess->get_id;
    $self->_users($users);
    $self->current_user( $users->get_by_sess($sess_id) || $users->get_guest );
    return 1;
}


=head2 auth_by_login_pass

=cut

sub auth_by_login_pass {
    my $self = shift;
    my %args = @_;
    my ( $login, $pass, $sess_obj ) = @args{qw/  usr pass session/};
    my $user = $self->_users->get_by_log_pass( lg => $login, pw => $pass )
      || return;
    $user->session_id ( $sess_obj->get_id );
    return $user;
}

=head2 is_authed

=cut

sub is_authed {
    my $self = shift;
    my $user = shift || $self->current_user;
    return not $user->isa('MetaStore::Auth::UserGuest');
}

=head2 logout

=cut

sub logout {
    my $self = shift;
    my $user = shift || $self->current_user || return;
    $user->session_id('');
    return 1;
}

sub commit {
    my $self = shift;
    $self->_users->store_changed;
}

=head2 is_access

Abstract method for check permissions

=cut

sub is_access {
    return 1    
}

1;
__END__

=head1 SEE ALSO

MetaStore, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

