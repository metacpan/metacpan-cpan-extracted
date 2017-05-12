package MMS::Mail::Message;

use warnings;
use strict;

=head1 NAME

MMS::Mail::Message - A class representing an MMS (or picture) message sent via email.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

This class is used by MMS::Mail::Parser to provide an itermediate data storage class after the MMS has been parsed by the C<parse> method but before it has been through the second stage of parsing (the MMS::Mail::Parser C<provider_parse> method).  If this doesn't make sense then take a look at L<MMS::Mail::Parser> to get an idea where this module fits in before progressing any further.

=head1 METHODS

The following are the top-level methods of the MMS::Mail::Message class.

=head2 Constructor

=over

=item C<new()>

Return a new MMS::Mail::Message object.  Valid attributes are any public accessor outlined in the Regular Methods section below.

=back

=head2 Regular Methods

=over

=item C<header_datetime> STRING

Instance method - Returns the time and date the MMS was received when invoked with no supplied parameter.  When supplied with a parameter it sets the object property to the supplied parameter.

=item C<header_from> STRING

Instance method - Returns the sending email address the MMS was sent from when invoked with no supplied parameter.  When supplied with a parameter it sets the object property to the supplied parameter.

=item C<header_to> STRING

Instance method - Returns the recieving email address the MMS was sent to when invoked with no supplied parameter.  When supplied with a parameter it sets the object property to the supplied parameter.

=item C<header_subject> STRING

Instance method - Returns the MMS subject when invoked with no supplied parameter.  When supplied with a parameter it sets the object property to the supplied parameter.

=item C<header_received_from> STRING

Instance method - Returns the email server that (last) sent the mms when invoked with no supplied parameter.  When supplied with a parameter it sets the object property to the supplied parameter.

=item C<body_text> STRING

Instance method - Returns the MMS bodytext when invoked with no supplied parameter.  When supplied with a paramater it sets the object property to the supplied parameter.

=item C<strip_characters> STRING

Instance method - The supplied string should be a set of characters valid for use in a regular expression character class C<s/[]//g>.  When set with a value the property is used by the C<header_from>, C<header_to>, C<header_datetime>, C<body_text> and C<header_subject> methods to remove these characters from their respective properties (in both the C<MMS::Mail::Message> and C<MMS::Mail::Message::Parsed> classes).

=item C<cleanse_map> HASHREF

Instance method - This method allows a regular expression or subroutine reference to be applied when an accessor sets a value, allowing message values to be cleansed or modified. These accessors are C<header_from>, C<header_to>, C<body_text>, C<header_datetime> and C<header_subject>.

The method expects a hash reference with key values as one of the above public accessor method names and values as a scalar in the form of a regular expression or as a subroutine reference.

=item C<attachments> ARRAYREF

Instance method - Returns an array reference to the array of MMS message attachments.  When supplied with a parameter it sets the object property to the supplied parameter.

=item C<add_attachment> MIME::Entity

Instance method - Adds the supplied C<MIME::Entity> attachment to the attachment stack for the message.  This method is mainly used by the C<MMS::Mail::Parser> class to add attachments while parsing.

=item C<is_valid>

Instance method - Returns true or false depending if the C<header_datetime>, C<header_from> and C<header_to> fields are all populated or not.

=item C<set>

Instance method - Overides the Class::Accessor superclass set method to apply cleanse_map and strip_character functionality to accessors.

=back

=head1 AUTHOR

Rob Lee, C<< <robl at robl.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mms-mail-message@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MMS-Mail-Message>.
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

use base "Class::Accessor";

# Class data
my @Accessors=(	"header_from",
		"header_to",
		"body_text",
		"header_datetime",
		"header_subject",
		"header_received_from",
		"cleanse_map",
		"strip_characters",
		"attachments"
		);
my @NoClone=(	"body_text",
		"header_subject"
		);

# Class data retrieval
sub _Accessors {
  return \@Accessors;
}
sub _NoClone {
  return \@NoClone;
}

__PACKAGE__->mk_accessors(@{__PACKAGE__->_Accessors});

sub new {

  my $type = shift;
  my $self = SUPER::new $type( {@_} );

  $self->SUPER::set('attachments', []);
  $self->SUPER::set('cleanse_map', {});
  $self->SUPER::set('strip_characters', '');

  return $self;

}

# Override Class::Accessor default set method
sub set {

  my $self = shift;
  my $key = shift;
  my $element = shift;
  my $strippers = $self->strip_characters;
  if ((defined $strippers) && ($strippers ne '')) {
    $element =~ s/[$strippers]//g;
  }
  if (exists $self->cleanse_map->{$key}) {
    # CODE REFERENCE
    if (ref $self->cleanse_map->{$key} eq "CODE") {
      my $ref = $self->cleanse_map->{$key};
      $element = &$ref($element);
    } else {
      # REGEX
      my $strippers = $self->cleanse_map->{$key};
      eval '$element=~'.$strippers;
    }
  }

  $self->SUPER::set($key, $element);

}

# Overide accessors so strip_characters and cleanse_map not applied
sub cleanse_map {
  my $self = shift;
  if (@_) { $self->SUPER::set('cleanse_map', shift) }
  return $self->SUPER::get('cleanse_map');
}
sub attachments {
  my $self = shift;
  if (@_) { $self->SUPER::set('attachments', shift) }
  return $self->SUPER::get('attachments');
}
sub strip_characters {
  my $self = shift;
  if (@_) { $self->SUPER::set('strip_characters', shift) }
  return $self->SUPER::get('strip_characters');
}

sub add_attachment {

  my $self = shift;
  my $attachment = shift;

  unless (defined $attachment) {
    return 0;
  }

  my $attach = $self->attachments;
  push @{$attach}, $attachment;
  $self->SUPER::set('attachments', $attach);

  return 1;

}

sub is_valid {

  my $self = shift;

  unless ($self->header_from) {
    return 0;
  }
  unless ($self->header_to) {
    return 0;
  }
  unless ($self->header_datetime) {
    return 0;
  }

  return 1;

}

sub _clone_data {

  my $self = shift;
  my $message = shift;

  my %seen;
  @seen{@{$self->_NoClone}} = ();
   
  foreach my $field (@{__PACKAGE__->_Accessors()}) {
    unless (exists $seen{$field}) {
      $self->{$field} = $message->{$field};
    }
  }
 
}

sub DESTROY {

  my $self = shift;

  foreach my $attach (@{$self->attachments}) {
    $attach->bodyhandle->purge;
  }

}

1; # End of MMS::Mail::Message
