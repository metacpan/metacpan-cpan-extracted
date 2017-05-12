package MetaStore::Users;

=head1 NAME

MetaStore::Users - abstract class for collections of users.

=head1 SYNOPSIS

    use MetaStore::Users;

=head1 DESCRIPTION

MetaStore::Users - abstract class for collections of users.

=head1 METHODS

=cut

use strict;
use warnings;
use Collection::AutoSQL;
use Data::Dumper;
use MetaStore::Auth::User;
use MetaStore::Auth::UserGuest;

our @ISA     = qw(Collection::AutoSQL );
our $VERSION = '0.01';

sub _init {
    my $self = shift;
    my %args = @_;
    $args{sub_ref} = sub { $self->_create_obj(@_) };
    $self->SUPER::_init(%args);
}

sub _create_obj {
    my $self = shift;
    my ( $id, $refs ) = @_;
    return new MetaStore::Auth::User { id => $id, attr => $refs }, $refs;
}

=head2 get_by_log_pass

get_by_log_pass

=cut

sub get_by_log_pass {
    my $self = shift;
    my %args = @_;
    my ( $login, $passwd ) = @args{qw/ lg pw /};
    $self->fetch_one( { login => $login, password => $passwd } );
}

=head2 get_by_sess

get_by_sess

=cut

sub get_by_sess {
    my $self = shift;
    my $sess_id = shift || return undef;
    $self->fetch_one( { sess_id => $sess_id } );
}

=head2 get_guest

get_guest

=cut

sub get_guest {
    my $self = shift;
    return new MetaStore::Auth::UserGuest::;
}

1;
__END__


=head1 SEE ALSO

MetaStore, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

