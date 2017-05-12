=head1 NAME

HTML::Tested::JavaScript - JavaScript enabled HTML::Tested widgets.

=head1 SYNOPSIS

  use HTML::Tested::JavaScript qw(HTJ);
  
  # set location of your javascript files
  $HTML::Tested::JavaScript::Location = "/my-js-files";

=head1 DESCRIPTION

This is collection of HTML::Tested-style widgets which use JavaScript
functionality.

It presently includes:

=over

=item HTML::Tested::JavaScript::Variable

Produces simple JavaScript variable with necessary escaping.

=item HTML::Tested::JavaScript::Serializer

Which can be used to serialize data between your JS script and server.

=item HTML::Tested::JavaScript::RichEdit

Which provides infrastructure for rich text editing widget.

=back

Please see individual modules for more information.

=cut

use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript;
use base 'Exporter';

our $VERSION = '0.30';

our @EXPORT_OK = qw(HTJ $Location);

=head1 CONSTANTS

=head2 HTJ

It is shortcut for HTML::Tested::JavaScript. It is can be exported by importing
HTML::Tested::JavaScript with HTJ parameter.

=cut
use constant HTJ => __PACKAGE__;

=head1 VARIABLES

=head2 $Location

Set location of your javascript files. This is the src string in <script> HTML
tag. You probably need to alias it in your Apache configuration.

=cut
our $Location = "/html-tested-javascript";

sub Script_Include {
	return "<script src=\"$Location/serializer.js\"></script>\n"
}

1;

=head1 AUTHOR

	Boris Sukholitko
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

HTML::Tested documentation.
L<HTML::Tested::JavaScript::Serializer|HTML::Tested::JavaScript::Serializer>.

=cut

