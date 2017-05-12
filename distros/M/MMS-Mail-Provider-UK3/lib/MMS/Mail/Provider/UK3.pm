package MMS::Mail::Provider::UK3;

use warnings;
use strict;

use base 'MMS::Mail::Provider';

use MMS::Mail::Message::Parsed;
use HTML::TableExtract;

=head1 NAME

MMS::Mail::Provider::UK3 - This provides a class for parsing an MMS::Mail::Message object that has been sent via the UK 3 network.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This class provides a parse method for parsing an MMS::Mail::Message object into an MMS::Mail::Message::Parsed object for MMS messages sent from the UK 3 network.

=head1 METHODS

The following are the top-level methods of the MMS::Mail::Parser::UK3 class.

=head2 Constructor

=over

=item C<new()>

Return a new MMS::Mail::Provider::UK3 object.

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
C<bug-mms-mail-provider-uk3 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MMS-Mail-Provider-UK3>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MMS::Mail::Provider::UK3

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MMS-Mail-Provider-UK3>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MMS-Mail-Provider-UK3>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MMS-Mail-Provider-UK3>

=item * Search CPAN

L<http://search.cpan.org/dist/MMS-Mail-Provider-UK3>

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

  my $htmltext=undef;
  foreach my $element (@{$parsed->attachments}) {
    if ($element->mime_type eq 'text/html') {
      $htmltext = $element->bodyhandle->as_string;
    } elsif ($element->mime_type =~ /jpeg$/) {
      my $header = $element->head;
      if ($header->recommended_filename() !~ /^images\//) {
        $parsed->add_image($element);
      }
    } elsif ($element->mime_type =~ /^video/) {
        $parsed->add_video($element);
    }
  }

  unless (defined $htmltext) {
    return undef;
  }

  my $te1 = new HTML::TableExtract( depth => 2, count => 2 );
  $te1->parse($htmltext);
  foreach my $ts1 ($te1->table_states) {
    foreach my $row1 ($ts1->rows) {
      foreach my $ele (@$row1) {
        if ((defined $ele) && ($ele ne '')) {
          $parsed->header_subject($ele);
        }
      }
    }
  }

  my $te2 = new HTML::TableExtract( depth => 3, count => 2 );
  $te2->parse($htmltext);
  my $text;
  foreach my $ts2 ($te2->table_states) {
    foreach my $row2 ($ts2->rows) {
      $text = join('\n', @$row2);
    }
    if ((defined $text) && $text ne "") {
      $parsed->body_text($text);
    }
  }

  # Set mobile number property to a VALID number
  if ($parsed->header_from =~ /<(.+)\/(.+)>/) {
    $parsed->phone_number('00'.$1);
    return $parsed;
  } else {
    return undef;
  }

}


1; # End of MMS::Mail::Provider::UK3
