package Flickr::API::People;

use strict;
use warnings;
use Carp;

use parent qw( Flickr::API );
our $VERSION = '1.28';


sub _initialize {

    my $self=shift;
    my $check;

        #if $self->api_permissions . . .
        my $rsp = $self->execute_method('flickr.auth.oauth.checkToken');

        if (!$rsp->success()) {

            $rsp->_propagate_status($self->{flickr}->{status});

            carp "\nUnable to validate token. Flickr error: ",
                $self->{flickr}->{status}->{error_code}," - \"",
                $self->{flickr}->{status}->{error_message},"\" \n";

            $self->_set_status(0,"Unable to validate token, Flickr API call not successful.");

        }
        else {

            $check = $rsp->as_hash();
            $self->{flickr}->{token} = $check->{oauth};
            $self->_set_status(1,"Token validated.");

        }

    return;

}

sub findByEmail {

    my $self  = shift;
    my $email = shift;

    $self->clear_user;

    unless ($email) { croak 'Usage: $api->findByEmail("an-email-address")'; }

    my $rsp = $self->execute_method('flickr.people.findByEmail',{'find_email' => $email});
    $rsp->_propagate_status($self->{flickr}->{status});

    if ($rsp->success == 1) {

        my $eresult = $rsp->as_hash();
        $self->_set_status(1,"flickr.people.findByEmail successfully found " . $email);
        $self->{flickr}->{user} = $eresult->{user};

    }
    else {

        $self->_set_status(0,"Unable to find user with: " . $email);

    }

    return $self->username;
}

sub findByUsername {

    my $self = shift;
    my $user = shift;

    $self->clear_user;

    unless ($user) { croak 'Usage: $api->findByUsername("a_user_name")'; }

    my $rsp = $self->execute_method('flickr.people.findByUsername',{'username' => $user});
    $rsp->_propagate_status($self->{flickr}->{status});

    if ($rsp->success == 1) {

       my $uresult = $rsp->as_hash();
       $self->_set_status(1,"flickr.people.findByUsername successfully found " . $user);
       $self->{flickr}->{user} = $uresult->{user};

    }
    else {

        $self->_set_status(0,"Unable to find user with: " . $user);

    }

    return $self->username;
}


sub perms {
    my $self=shift;
    return $self->{flickr}->{token}->{perms};
}

sub perms_caller {
    my $self=shift;
    return $self->{flickr}->{token}->{user}->{username};
}

sub perms_nsid {
    my $self=shift;
    return $self->{flickr}->{token}->{user}->{nsid};
}

sub perms_token {
    my $self=shift;
    return $self->{flickr}->{token}->{token};
}

sub nsid {
    my $self=shift;
    return $self->{flickr}->{user}->{nsid};
}

sub username {
    my $self=shift;
    return $self->{flickr}->{user}->{username};
}

sub user {
    my $self=shift;
    return $self->{flickr}->{user};
}

sub clear_user {
    my $self=shift;
    delete $self->{flickr}->{user};
    return;
}



1;

__END__


=head1 NAME

Flickr::API::People - Perl interface to the Flickr API's flickr.people.* methods.

=head1 SYNOPSIS

  use Flickr::API::People;

  my $api = Flickr::API::People->new({'consumer_key' => 'your_api_key'});

or

  my $api = Flickr::API::People->import_storable_config($config_file);


=head1 DESCRIPTION

This object encapsulates the flickr people methods.

C<Flickr::API::People> is a subclass of L<Flickr::API>, so you can access
Flickr's people information easily.


=head1 SUBROUTINES/METHODS

=over

=item C<findByEmail()>

Populates user info with that found for the given email

=item C<findByUsername()>

Populates user info with that found for the given username

=item C<perms()>

Returns the permission returned by checking this supplied token

=item C<perms_caller>

Returns the username for which the permission applies

=item C<perms_token>

Returns the token for which the permission applies

=item C<perms_nsid>

Returns the nsid for which the permission applies

=item C<nsid()>

Returns the nsid of the supplied mail or username

=item C<username()>

Returns the username of the supplied mail or username

=back


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015-2016, Louis B. Moore

This program is released under the Artistic License 2.0 by The Perl Foundation.

Original version was Copyright (C) 2005 Nuno Nunes, C<< <nfmnunes@cpan.org> >>
This version is much changed and built on the Flickr::API as it appears in
2015. Many thanks to Nuno Nunes for getting this ball rolling.

=head1 SEE ALSO

L<Flickr::API>.
L<Flickr|http://www.flickr.com/>,
L<http://www.flickr.com/services/api/>
L<https://github.com/iamcal/perl-Flickr-API>


=cut
