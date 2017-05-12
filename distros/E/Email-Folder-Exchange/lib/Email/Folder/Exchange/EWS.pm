package Email::Folder::Exchange::EWS;
use base qw(Email::Folder);

use strict;
use warnings;

use Email::Folder;
use URI::Escape;
use LWP::UserAgent;
use Carp qw(croak cluck);
use LWP::Debug;

use constant TYPES_NS => 'http://schemas.microsoft.com/exchange/services/2006/types';
use constant MESSAGES_NS => 'http://schemas.microsoft.com/exchange/services/2006/messages';

use SOAP::Lite;
use SOAP::Lite::Utils qw(__mk_accessors);

use HTTP::Request;
use HTTP::Headers;
use MIME::Base64;

#SOAP::Lite->import( +trace => 'all' );

BEGIN {
  __PACKAGE__->__mk_accessors(qw(soap folder_id unread_count display_name child_folder_count total_count _folder_ids _message_ids));
};

sub new {
  my ($self, $class, $url, $username, $password) = ({}, @_);
  bless $self, $class;

  croak "URL required" unless $url;

  my $uri = URI->new($url);

  # guess the path to the exchange web service
  if(! $uri->path) {
    $uri->path('/EWS/Exchange.asmx');
  }

  # build soap accessor
  my $soap = SOAP::Lite->proxy(
    $uri->as_string,
    keep_alive => 1, 
    credentials => [
      $uri->host . ':' . ( $uri->scheme eq 'https' ? '443' : '80' ),
  #    $uri->host,
	'',
			$username,
			$password
    ],
		requests_redirectable => [ 'GET', 'POST', 'HEAD' ],
  );
  $self->soap($soap);
  # EWS requires the path and method to be separated by slash, not pound
  $soap->on_action( sub { MESSAGES_NS . "/$_[1]" });
  # setup the schemas
  $soap->ns(TYPES_NS, 't');
  $soap->default_ns(MESSAGES_NS);
  $soap->uri(MESSAGES_NS);
  # EWS does not like the encodingStyle attribute
  $soap->encodingStyle("");

	$self->folder_id('inbox');
	$self->refresh;

  return $self;
}

sub new_from_id {
  my ($self, $class, $soap, $folder_id) = ({}, @_);
	bless $self, $class;

	$self->soap($soap);
	$self->folder_id($folder_id);
	$self->refresh;

	return $self;
}

sub refresh {
  my ($self) = @_;

  my $soap = $self->soap;

  my $som = do {
	  local $^W; # disable warnings from SOAP::Transport::HTTP

		$soap->GetFolder( 
			SOAP::Data
				->name('FolderShape')
				->value(
					\SOAP::Data
						->name('BaseShape')
						->value('Default')
						->prefix('t')
						->type('')
				),
			SOAP::Data
				->name('FolderIds')
				->value(
					\SOAP::Data
						# CAUTION: cheap hack!
						# if the folder id is longer than 64 characters then treat it as a folder id. otherwise, treat it as a named folder like 'inbox'
						->name( ( length($self->folder_id) > 64 ? 'FolderId' : 'DistinguishedFolderId' ) )
						->prefix('t')
						->attr({ Id => $self->folder_id })
				)
		);
	};

	# handle SOAP-level fault
	if($som->fault) {
		die $som->faultstring;
	}

	# handle method-level fault [why!?!!]
	my $response_message = $som->valueof('//MessageText');
	die $response_message if $response_message;
	
	# map the return data into myself
	$self->folder_id( $som->dataof('//FolderId')->attr->{Id} );
	$self->unread_count( $som->valueof('//Folder/UnreadCount') );
	$self->display_name( $som->valueof('//Folder/DisplayName') );
	$self->child_folder_count( $som->valueof('//Folder/ChildFolderCount') );
	$self->total_count( $som->valueof('//Folder/TotalCount') );
}

sub refresh_folders {
  my ($self) = @_;

  my $soap = $self->soap;

  # example of using FindFolder to get subfolders
  my $method = SOAP::Data
    ->name('FindFolder')
    ->attr({ Traversal => 'Shallow', xmlns => MESSAGES_NS });

  my $som = do {
	  local $^W; # disable warnings from SOAP::Transport::HTTP

		$soap->call( $method,
			SOAP::Data
				->name('FolderShape')
				->value(
					\SOAP::Data
						->name('BaseShape')
						->value('IdOnly')
						->prefix('t')
						->type('')
				),
			SOAP::Data
				->name('ParentFolderIds')
				->value(
					\SOAP::Data
						# CAUTION: cheap hack!
						# if the folder id is longer than 64 characters then treat it as a folder id. otherwise, treat it as a named folder like 'inbox'
						->name( ( length($self->folder_id) > 64 ? 'FolderId' : 'DistinguishedFolderId' ) )
						->prefix('t')
						->attr({ Id => $self->folder_id })
				)
		);
	};

	# handle SOAP-level fault
	if($som->fault) {
		die $som->faultstring;
	}

	# handle method-level fault [why!?!!]
	my $response_message = $som->valueof('//MessageText');
	die $response_message if $response_message;

	my @folder_ids;
	for my $folderid_som ( $som->dataof('//FolderId') ) {
		push @folder_ids, $folderid_som->attr->{Id};
	}
	$self->_folder_ids(\@folder_ids);
	return @folder_ids;
}

sub folders {
  my ($self) = @_;

	# lazy-refresh of subfolders
	if(! defined $self->_folder_ids) {
	  $self->refresh_folders;
	}

	# fetch folder details
	return map {
	  __PACKAGE__->new_from_id($self->soap, $_)
	} @{ $self->_folder_ids };
}

sub next_folder {
  my ($self) = @_;

	# lazy-refresh of subfolders
	if(! defined $self->_folder_ids) {
	  $self->refresh_folders;
	}

	# fetch folder details
	my $folder_id = shift @{ $self->_folder_ids };
	return unless $folder_id;

	return __PACKAGE__->new_from_id($self->soap, $folder_id);
}

sub refresh_messages {
  my ($self) = @_;

	my $soap = $self->soap;

  my $method = SOAP::Data
    ->name('FindItem')
    ->attr({ Traversal => 'Shallow', xmlns => MESSAGES_NS });

  my $som = do {
	  local $^W; # disable warnings from SOAP::Transport::HTTP

		$soap->call( $method,
			SOAP::Data
				->name('ItemShape' =>
				\SOAP::Data->value(
					SOAP::Data
						->name('BaseShape')
						->value('IdOnly')
						->prefix('t')
						->type(''),
				)),
			SOAP::Data
				->name('ParentFolderIds')
				->value(
					\SOAP::Data
						# CAUTION: cheap hack!
						# if the folder id is longer than 64 characters then treat it as a folder id. otherwise, treat it as a named folder like 'inbox'
						->name( ( length($self->folder_id) > 64 ? 'FolderId' : 'DistinguishedFolderId' ) )
						->prefix('t')
						->attr({ Id => $self->folder_id })
				)
		);
  };
		
	# handle soap-level fault
	if($som->fault) {
		die $som->faultstring;
	}

	# handle method-level fault [why!?!!]
	my $response_message = $som->valueof('//MessageText');
	die $response_message if $response_message;
	
	my @message_ids;
	for my $itemid_som ( $som->dataof('//ItemId') ) {
		push @message_ids, $itemid_som->attr->{'Id'};
	}
	$self->_message_ids(\@message_ids);

	return @message_ids;
}

sub _get_message {
  my ($self, $message_id) = @_;


	my $soap = $self->soap;

  my $method = SOAP::Data
    ->name('GetItem')
    ->attr({ xmlns => MESSAGES_NS });

  my $som = do {
	  local $^W; # disable warnings from SOAP::Transport::HTTP

		$soap->call( $method,
			SOAP::Data
				->name('ItemShape' =>
				\SOAP::Data->value(
					SOAP::Data
						->name('BaseShape')
						->value('IdOnly')
						->prefix('t')
						->type(''),
					SOAP::Data
						->name('IncludeMimeContent')
						->value('true')
						->prefix('t')
						->type('')
				)),
			SOAP::Data
				->name('ItemIds')
				->value(
					\SOAP::Data
						->name('ItemId')
						->prefix('t')
						->attr({ Id => $message_id })
				)
		);
	};

	# handle SOAP-level fault
	if($som->fault) {
		die $som->faultstring;
	}

	# handle method-level fault [why!?!!]
	my $response_message = $som->valueof('//MessageText');
	die $response_message if $response_message;

	# find the MIME content
	my $content = $som->valueof('//MimeContent');
	my $msg = $self->bless_message(decode_base64($content));
	return $self->bless_message(decode_base64($content));
}

sub messages {
  my ($self) = @_;

	# lazy-refresh of messages
	if(! defined $self->_message_ids) {
	  $self->refresh_messages;
	}

	# fetch folder details
	return map {
	  $self->_get_message($_)
	} @{ $self->_message_ids };
}

sub next_message {
  my ($self) = @_;

	# lazy-refresh of messages
	if(! defined $self->_message_ids) {
	  $self->refresh_messages;
	}

	# fetch message details
	my $message_id = shift @{ $self->_message_ids };
	return unless $message_id;

	return $self->_get_message($message_id);
}

1;

__END__
=head1 NAME

Email::Folder::Exchange::EWS - Email::Folder access to exchange folders via Web Services [SOAP]

=head1 SYNOPSIS

  use Email::Folder::Exchange::EWS;

  my $folder = Email::Folder::Exchange::EWS->new('http://owa.myorg.com', 'user', 'password');

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

=head2 new($url, [$username, $password])

Create Email::Folder::Exchange::EWS object and login to OWA site.

=over

=item url

URL of the main OWA site, usually in the form of "https://owa.myorg.com"

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

=head2 soap()

Returns L<SOAP::Lite> underlying SOAP object for custom queries.

=head2 folder_id()

Returns Exchange binary folder ID

=head2 display_name()

Returns folder's user-friendly display name

=head2 child_folder_count()

Returns the number of child folders

=head2 unread_count()

Returns the number of unread messages in the current folder.

=head2 total_count()

Returns the number of messages in the current folder.

=head1 CAVEATS

  Can't locate object method "new" via package "LWP::Protocol::https::Socket"

Install the Crypt::SSLeay module in order to support SSL URLs

 The server cannot service this request right now. Try again later.

This error indicates the mailbox is has too many messages or the specified
message is too large to retrieve via web services.

=head1 SEE ALSO

L<Email::Folder::Exchange>, L<Email::Folder>, L<URI>, L<Email::Simple>, L<Crypt::SSLeay>

=head1 AUTHOR

Warren Smith <lt>wsmith@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Warren Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

