package IRC::Formatting::HTML;

use warnings;
use strict;

use IRC::Formatting::HTML::Output;
use IRC::Formatting::HTML::Input;

use Exporter qw/import/;

=head1 NAME

IRC::Formatting::HTML - Convert between HTML and IRC formatting

=head1 VERSION

Version 0.29

=cut

our @EXPORT_OK = qw/irc_to_html html_to_irc/;
our $VERSION = '0.29';

=head1 SYNOPSIS

Convert raw IRC formatting to HTML

    use IRC::Formatting::HTML qw/irc_to_html html_to_irc/;

    ...

    my $irctext = "\002\0031,2Iron & Wine";
    my $html = irc_to_html($irctext);
    print $html

    # the above will print:
    # <span style="font-weight: bold;color: #000; background-color: #008">Iron &amp; Wine</span>

    ...

    my $html = "<b><em>Nicotine and gravy</em></b>";
    my $irctext = html_to_irc($html);
    print $html;
    
    # the above will print:
    # \002\026Nicotine and Gravy\002\026

=head1 FUNCTIONS

=head2 irc_to_html

irc_to_html($irctext, invert => "italic")

Takes an irc formatted string and returns the HTML version. Takes an option
to treat inverted text as italic text.
=cut

sub irc_to_html {
  my ($text, %options) = @_;
  my $italic = ($options{invert} and $options{invert} eq "italic");
  my $classes = $options{classes};
  return IRC::Formatting::HTML::Output::parse($text, $italic, $classes);
}

=head2 html_to_irc

html_to_irc($html)

Takes an HTML string and returns an irc formatted string
=cut

sub html_to_irc {
  return IRC::Formatting::HTML::Input::parse(shift);
}

=head1 AUTHOR

Lee Aylward, E<lt>leedo@cpan.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-irc-formatting-html at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IRC-Formatting-HTML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IRC::Formatting::HTML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IRC-Formatting-HTML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IRC-Formatting-HTML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IRC-Formatting-HTML>

=item * Search CPAN

L<http://search.cpan.org/dist/IRC-Formatting-HTML/>

=back


=head1 ACKNOWLEDGEMENTS

This is a direct port of Sam Stephenson's ruby version.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Lee Aylward, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of IRC::Formatting::HTML
