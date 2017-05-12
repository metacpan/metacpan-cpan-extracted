package Email::Folder::Exchange;
use base qw(Email::Folder);

use strict;
use warnings;

our $VERSION = '2.0';

use Email::Folder;
use Email::Folder::Exchange::WebDAV;
use Email::Folder::Exchange::EWS;
use Data::Dumper;

use URI;
use LWP::UserAgent;

sub new {
  my ($self, $class, $url, $username, $password) = ({}, @_);
	bless $self, $class;

	# try EWS first
	my $folder;
	eval {
		$folder = Email::Folder::Exchange::EWS->new($url, $username, $password);
	};
	if($@ =~ /Not Found/) {
	  # try WebDAV second
    $folder = Email::Folder::Exchange::WebDAV->new($url, $username, $password);
	}
	# re-raise
	die $@ if $@;

	return $folder;
}

1;

__END__

=head1 NAME

Email::Folder::Exchange - Access your Microsoft Exchange 2000/2003/2007/2010 email from perl

=head1 SYNOPSIS

  use Email::Folder::Exchange;

	# Access Exchange 2000/2003 via WebDAV
  my $folder = Email::Folder::Exchange->new('http://owa.myorg.com/user/Inbox', 'user', 'password');

	# Access Exchange 2007/2010 via Exchange Web Services
  my $folder = Email::Folder::Exchange->new('http://owa.myorg.com', 'user', 'password');

  for my $message ($folder->messages) {
    print "subject: " . $subject->header('Subject');
  }

  for my $folder ($folder->folders) {
    print "folder uri: " . $folder->uri->as_string;
    print " contains " . scalar($folder->messages) . " messages";
    print " contains " . scalar($folder->folders) . " folders";
  }


=head1 DESCRIPTION

Add access to Microsoft Exchange to L<Email::Folder>. Contains API enhancements
to allow folder browsing.

Email::Folder::Exchange is a wrapper around two modules [included]:

=over

=item L<Email::Folder::Exchange::WebDAV> - Access Exchange 2000/2003 via WebDAV

=item L<Email::Folder::Exchange::EWS> - Access Exchange 2007/2010 via EWS

=back

Each module has its own extensions to the Email:Folder protocol.

First, the module tries to connect via EWS. If the server reports a 404 error,
the module attempts to fallback to WebDAV.

=head2 new($url, [$username, $password])

Create Email::Folder::Exchange object and login to OWA site.

=over

=item url 

URL of the target folder.

=item username

Username to authenticate as. Generally in the form of 'domain\username'.
Overrides URL-supplied username if given.

=item password

Password to authenticate with. Overrides URL-supplied password.

=back

=head2 messages()

Return a list containing all of the messages in the folder. Can only be called
once as it drains the iterator.

=head2 next_message()

Return next message as L<Email::Simple> object from folder. Acts as iterator.
Returns undef at end of folder contents.

=head2 folders()

Return a list of L<Email::Folder::Exchange> objects contained within base
folder. Can only be called once as it drains the iterator.

=head2 next_folder()

Return next folder under base folder as L<Email::Folder::Exchange> object. Acts
as iterator. Returns undef at end of list.

=head2 uri()

Return L<URI> locator object for current folder.

=head1 CAVEATS

  Can't locate object method "new" via package "LWP::Protocol::https::Socket"

Install the Crypt::SSLeay module in order to support SSL URLs

 The server cannot service this request right now. Try again later.

This error indicates the mailbox is has too many messages or the specified
message is too large to retrieve via web services.

=head1 SEE ALSO

L<Email::Folder>, L<URI>, L<Email::Simple>, L<Crypt::SSLeay>

=head1 AUTHOR

Warren Smith <lt>wsmith@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Warren Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
