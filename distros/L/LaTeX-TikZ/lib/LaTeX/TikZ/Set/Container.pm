package LaTeX::TikZ::Set::Container;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Container - A role for set objects that are made of subobjects.

=head1 VERSION

Version 0.03

=head1 DESCRIPTION

L<LaTeX::TikZ::Set> objects that group other objects together consume this role.
This forces them to implement :

=over 4

=item *

a C<kids> method that returns the list of subobjects ;

=item *

an C<add> method describing how more elements can be added to the set.

=back

=cut

our $VERSION = '0.03';

use Mouse::Role;

=head1 METHODS

This method is required by the interface :

=over 4

=item *

C<add>

=back

=cut

requires qw<
 add
 kids
>;

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

1; # End of LaTeX::TikZ::Set::Container
