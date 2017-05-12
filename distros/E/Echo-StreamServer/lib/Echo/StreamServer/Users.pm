package Echo::StreamServer::Users;

use 5.008008;
use strict;
use warnings;

use Echo::StreamServer::Client;
our @ISA = ( 'Echo::StreamServer::Client' );

use Echo::StreamServer::Core;
$Echo::StreamServer::Core::DEBUG=0;

our $VERSION = '0.01';

# ======================================================================
# JSON.pm calls TO_JSON() method on the blessed hash.
#
# NOTE: The convert_blessed flag must be set (false by default).
#	my $json = JSON->new->convert_blessed;
# ======================================================================
use JSON;
my $json = JSON->new->convert_blessed;

our @USER_SUBJECTS = ( 'roles', 'state', 'markers', 'poco' );

sub get {
	my ($self, $identity_url, $raise_not_found) = @_;

	my %params = (
		'identityURL' => $identity_url,
	);

	my $json_hash_ref;
	eval {
		$json_hash_ref = send_request($self->{'account'}, 'users/get', \%params);
	};
        # Re-raise not_found StreamServer error.
        if ($@) {
                if ((not defined($raise_not_found)) and ($@ =~ m/\[not_found\]/)) {
                        # not_found OK
                }
                else {
                        die($@);
                }
        }
	return $json_hash_ref;
}

sub update {
	my ($self, $identity_url, $subject, $content) = @_;

	unless (grep(m/^$subject$/, @USER_SUBJECTS)) {
		die("Users API must update a valid subject (" . join(', ', @USER_SUBJECTS) . "), not '$subject'");
	}

	# Convert content to a JSON document.
	my %params = (
		'identityURL' => $identity_url,
		'subject' => $subject,
		'content' => $json->encode($content),
	);

	my $json_hash_ref = send_request($self->{'account'}, 'users/update', \%params, 'post');
	return $json_hash_ref;
}

sub whoami {
	my ($self, $session_id) = @_;

	my %params = (
		'appkey' => $self->{'account'}->{'appkey'},
		'sessionID' => $session_id,
	);

	my $json_hash_ref = send_request($self->{'account'}, 'users/whoami', \%params);
	return $json_hash_ref;
}

1;
__END__

=head1 NAME

Echo::StreamServer::Users - Users API

=head1 SYNOPSIS

  use Echo::StreamServer::Account;
  use Echo::StreamServer::Users;

  my $acct = new Echo::StreamServer::Account($appkey, $secret);
  my $client = new Echo::StreamServer::Users($acct);

  my $user_ref = $client->get("http://users.example.com/poco/sam");

=head1 DESCRIPTION

The Users API is Echo::StreamServer::Users and requires an Echo::StreamServer::Account.

Echo Users API is designed for providing interface for working with user identities along with core permission information.

The core data element of this API is a User Account Record. The user account is created automatically when the user logs in for the first time. 

The user account contains one or more identities (E.g. Twitter, Facebook, Acme Widgets) which are represented by identity URLs. A URL is considered to be a valid identity URL if it is either well-known (recognized by Social Graph Node Mapper) or is an OpenID.

User Accounts are stored in a namespace - essentially each namespace is a different user database.

One can think of user accounts as boxes where business cards (identities) are put. When a new user gets logged in to the system, a new box is allocated and the user's business cards (identities) are placed into it. Echo allows to add multiple identities to an account, but removing identities or binding them to a different account is not yet supported.

User properties (roles, markers etc) are associated with accounts, not identities. However it is possible to reference a user account in API methods by referencing any of the identities bound to the account. This is conceptually equivalent to checking every single box looking for a particular business card and then marking the box appropriately.

=head2 Client Methods

=over

=item C<get>

Fetch user information for C<$identity_url>.

=item C<update>

Update (or insert new) user information in the C<$subject> area to the value of C<$content>.

=item C<whoami>

Retrieve currently logged in user information.

=back

=head1 SEE ALSO

Echo::StreamServer::Client
Echo::StreamServer::Items
Echo::StreamServer::Feeds
Echo::StreamServer::Users

=head1 AUTHOR

Andrew Droffner, E<lt>adroffne@advance.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Droffner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
