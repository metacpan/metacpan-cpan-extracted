package MMS::Mail::Provider::UKTMobile;

use warnings;
use strict;

use base 'MMS::Mail::Provider';

use MMS::Mail::Message::Parsed;

=head1 NAME

MMS::Mail::Provider::UKTMobile - This provides a class for parsing an MMS::Mail::Message object that has been sent via the UK T-Mobile network.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

This class provides a parse method for parsing an MMS::Mail::Message object into an MMS::Mail::Message::Parsed object for MMS messages sent from the UK T-Mobile network.

=head1 METHODS

The following are the top-level methods of the MMS::Mail::Parser::UKTMobile class.

=head2 Constructor

=over

=item C<new()>

Return a new MMS::Mail::Provider::UKTMobile object.

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
C<bug-mms-mail-provider-uktmobile at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MMS-Mail-Provider-UKTMobile>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MMS::Mail::Provider::UKTMobile

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MMS-Mail-Provider-UKTMobile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MMS-Mail-Provider-UKTMobile>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MMS-Mail-Provider-UKTMobile>

=item * Search CPAN

L<http://search.cpan.org/dist/MMS-Mail-Provider-UKTMobile>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Rob Lee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub parse {

  my $self = shift;
  my $message = shift;

  unless (defined $message) {
    return undef;
  }

  my $parsed = new MMS::Mail::Message::Parsed(message=>$message);

  my $text=undef;
  foreach my $element (@{$parsed->attachments}) {
    if ($element->mime_type eq 'text/plain') {
      my $header = $element->head;
      if ((defined $header->recommended_filename) && ($header->recommended_filename eq 'mms.txt')) {
        $text = $element->bodyhandle->as_string;
      }
    } elsif ($element->mime_type =~ /jpeg$/) {
      my $header = $element->head;
      if ( (defined $header->recommended_filename) && ($header->recommended_filename ne '')) {
        $parsed->add_image($element);
      }
    } elsif ($element->mime_type =~ /^video/) {
        $parsed->add_video($element);
    }
  }

  unless (defined $text) {
    return undef;
  }

  $parsed->header_subject($message->header_subject);
  $parsed->body_text($text);

  # Cleanup the header_from and set phone number
  $parsed->header_from =~ /\"(.+)\"/;
  $parsed->header_from($1);
  my ($num,undef) = split(/@/, $parsed->header_from);
  $parsed->phone_number($num);

  return $parsed;

}


1; # End of MMS::Mail::Provider::UKTMobile
