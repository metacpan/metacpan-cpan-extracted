package LaTeX::TikZ::Set::Path;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Path - A role for set objects that can be part of a path.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

Paths are all the elements against which we can call the C<path> method.

=cut

use Mouse::Role;

=head1 RELATIONSHIPS

This role consumes the L<LaTeX::TikZ::Set> role, and as such implements the L</draw> method.

=cut

with 'LaTeX::TikZ::Set';

=head1 METHODS

These methods are required by the interface :

=over 4

=item *

C<path $formatter, $context>

Returns the TikZ code that builds a path out of the current set object as a string formatted by the L<LaTeX::TikZ::Formatter> object C<$formatter>.
The current evaluation context is passed as the L<LaTeX::TikZ::Context> object C<$context>.

=item *

C<begin>

Returns a L<LaTeX::TikZ::Point> object pointing to the beginning of the path, or C<undef> if this path has no beginning.

=item *

C<end>

A L<LaTeX::TikZ::Point> object pointing to the end of the path, or C<undef> if this path has no end.

=back

=cut

requires qw<
 path
 begin
 end
>;

=head2 C<draw>

=cut

sub draw {
 my $set = shift;

 [ "\\draw " . $set->path(@_) . ' ;' ];
}

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-tikz at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-TikZ>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::TikZ

=head1 COPYRIGHT & LICENSE

Copyright 2010,2011,2012,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of LaTeX::TikZ::Set::Path;
