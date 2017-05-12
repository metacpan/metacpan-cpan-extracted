package MMS::Mail::Provider::UKOrange;

use warnings;
use strict;

use base 'MMS::Mail::Provider';

use MMS::Mail::Message::Parsed;

=head1 NAME

MMS::Mail::Provider::UKOrange - This provides a class for parsing an MMS::Mail::Message object that has been sent via the UK Orange network.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

This class provides a parse method for parsing an MMS::Mail::Message object into an MMS::Mail::Message::Parsed object for MMS messages sent from the UK Orange network.

=head1 METHODS

The following are the top-level methods of the MMS::Mail::Parser::0range class.

=head2 Constructor

=over

=item C<new()>

Return a new MMS::Mail::Provider::0range object.

=back

=head2 Regular Methods

=over

=item C<parse> MMS::Mail::Message

The C<parse> method is called as an instance method.  It parses the MMS::Mail::Message object and returns an MMS::Mail::Message::Parsed object.

=back

=head1 AUTHOR

Rob Lee, C<< <robl at robl.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mms-mail-provider-ukorange@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MMS-Mail-Provider-UKOrange>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 NOTES

Please read the Perl artistic license ('perldoc perlartistic') :

10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
    WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES
    OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 ACKNOWLEDGEMENTS

Thanks to Paul and Nige for the sample messages.

As per usual this module is sprinkled with a little Deb magic.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rob Lee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<MMS::Mail::Message>, L<MMS::Mail::Message::Parsed>, L<MMS::Mail::Provider>


=cut

sub parse {

  my $self = shift;
  my $message = shift;

  unless (defined $message) {
    return undef;
  }

  my $skiptext = "This Orange Multi Media Message was sent wirefree";

  my $parsed = new MMS::Mail::Message::Parsed(message=>$message);

  $parsed->header_subject($message->header_subject);

  foreach my $element (@{$parsed->attachments}) {
    if ($element->mime_type eq 'text/plain') {
      if ($element->bodyhandle->as_string ne "") {
        if ($element->bodyhandle->as_string !~ /$skiptext/m) {
          $parsed->body_text($element->bodyhandle->as_string);
        }
      }
    } elsif ($element->mime_type =~ /jpeg$/) {
      $parsed->add_image($element);
    } elsif ($element->mime_type =~ /^video/) {
      $parsed->add_video($element);
    }
  }

  # Set mobile number property to a VALID number
  $parsed->phone_number($self->retrieve_phone_number($parsed->header_from));
  return $parsed;
}


1; # End of MMS::Mail::Provider::UKOrange
