package MMS::Mail::Message::Parsed;

use warnings;
use strict;

use base 'MMS::Mail::Message';

=head1 NAME

MMS::Mail::Message::Parsed - A class representing a parsed MMS (or picture) message, that has been parsed by an MMS::Mail::Provider class.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

This class is used by MMS::Mail::Parser to provide a final data storage class after the MMS has been parsed by the MMS::Mail::Provider class.  It inherits from the MMS::Mail::Message class and extends it's methods to allow access to parsed properties.

=head1 METHODS

The MMS::Mail::Message::Parsed class inherits all the methods from it's parent class MMS::Mail::Message.

=head2 Constructor

=over

=item C<new()>

Return a new MMS::Mail::Message::Parsed object.

=back

=head2 Regular Methods

=over

=item C<add_image> MIME::Entity

Instance method - Adds the supplied MIME::Entity attachment to the image stack for the message.  This method is mainly used by the MMS::Mail::Provider class to add images while parsing.

=item C<add_video> MIME::Entity

Instance method - Adds the supplied MIME::Entity attachment to the video stack for the message.  This method is mainly used by the MMS::Mail::Provider class to add videos while parsing.

=item C<images>

Instance method - Returns an array reference to an array of images from the message.

=item C<videos>

Instance method - Returns an array reference to an array of videos from the message.

=item C<phone_number> STRING

Instance method - Returns the MMS mobile number the message was sent from when invoked with no supplied parameter.  When supplied with a parameter it sets the object property to the supplied parameter.  This property is not set by the MMS::Mail::Provider class but is set by it's subclasses.

=item C<retrieve_attachments> STRING

Instance method - Expects a mime-type to be passed as an argument and a regular expression match using the supplied string is applied to each attachment in the attachment stack of the message object and a reference to an array of objects where the mime-type matches the supplied string is returned.  In the event no attachment was matched to the supplied mime-type an undef value is returned.

=back

=head1 AUTHOR

Rob Lee, C<< <robl at robl.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mms-mail-message-parsed@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MMS-Mail-Message-Parsed>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 NOTES

Please read the Perl artistic license ('perldoc perlartistic') :

10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
    WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES
    OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 ACKNOWLEDGEMENTS

As per usual this module is sprinkled with a little Deb magic.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rob Lee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<MMS::Mail::Message>, L<MMS::Mail::Message::Parsed>, L<MMS::Mail::Provider>

=cut

my @Accessors=(	"phone_number",
		"images",
		"videos"
		);

# Class data retrieval
sub _Accessors {
  return \@Accessors;
}

__PACKAGE__->mk_accessors(@{__PACKAGE__->_Accessors});

sub new {

  my $type = shift;

  my $self = {};
  $self = SUPER::new $type( @_ );

  if (defined($self->{message})) {
    $self->SUPER::_clone_data($self->{message});
  }

  $self->{images} = [];
  $self->{videos} = [];

  return $self;
}

sub add_image {

  my $self = shift;
  my $image = shift;

  unless (defined($image)) {
    return 0;
  }

  push @{$self->{images}}, $image;

  return 1;

}

sub add_video {

  my $self = shift;
  my $video = shift;

  unless(defined $video) {
    return 0;
  }

  push @{$self->{videos}}, $video;

  return 1;

}

sub retrieve_attachments {

  my $self = shift;
  my $type = shift;

  unless (defined $type) {
    return [];
  }
  
  my @mimeattachments;
  foreach my $attachment (@{$self->attachments}) {
    if ($attachment->mime_type =~ /$type/) {
      push @mimeattachments, $attachment;
    }
  }

  if (@mimeattachments>0) {
    return \@mimeattachments;
  } else {
    return [];
  } 

}

1; # End of MMS::Mail::Message::Parsed
