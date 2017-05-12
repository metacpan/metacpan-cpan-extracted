package MMS::Mail::Provider;

use warnings;
use strict;

use MMS::Mail::Message::Parsed;

=head1 NAME

MMS::Mail::Provider - This provides a base class for parsing an MMS::Mail::Message object into a MMS::Mail::Message::Parsed object.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

This class provides a parse method for parsing an MMS::Mail::Message object into an MMS::Mail::Message::Parsed object for 'generic' MMS messages (or ones that cannot be identified as coming from a specific provider).

=head1 METHODS

The following are the top-level methods of the MMS::Mail::Provider class.

=head2 Constructor

=over

=item C<new()>

Return a new MMS::Mail::Provider object.

=back

=head2 Regular Methods

=over

=item C<parse> MMS::Mail::Message

Instance method - The C<parse> method parses the MMS::Mail::Message and returns an MMS::Mail::Message::Parsed.

=item C<retrieve_phone_number> STRING

Instance method - This method splits the provided string on @ and returns the first list element from the split, replacing any leading + character with 00.  This seems to be the convention used by most UK providers and may work for other non-UK providers.

=back

=head1 AUTHOR

Rob Lee, C<< <robl at robl.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mms-mail-provider@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MMS-Mail-Provider>.
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

sub new {
  my $type = shift;
  my $self = {};
  bless $self, $type;

  return $self;
}

sub parse {

  my $self = shift;
  my $message = shift;

  my $parsed =  new MMS::Mail::Message::Parsed( message=>$message);

  $parsed->header_subject($message->header_subject);
  $parsed->body_text($message->body_text);

  $parsed->images($parsed->retrieve_attachments('^image'));
  $parsed->videos($parsed->retrieve_attachments('^video'));

  return $parsed;

}

sub retrieve_phone_number {

  my $self = shift;
  my $from = shift;

  unless (defined($from)) {
    return undef;
  }

  # Set mobile number property to a VALID number
  #
  # This works on the idea the form is in format
  # 0000000000@someprovider.net
  #
 
  my ($number, undef) = split /\@/, $from;
  if ($number =~ /^\+/) {
    $number =~ s/^\+/00/;
  } else {
    $number = "00".$number;
  }
  unless ($number =~ /\D+/) {
    return $number;
  } 
  return undef;

}


1; # End of MMS::Mail::Provider
