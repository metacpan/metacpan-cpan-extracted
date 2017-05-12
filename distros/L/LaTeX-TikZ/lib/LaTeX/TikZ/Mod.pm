package LaTeX::TikZ::Mod;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Mod - Base role for LaTeX::TikZ modifiers.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

This role should be consumed by all the modifier classes.

=cut

use Mouse::Role;
use Mouse::Util::TypeConstraints;

=head1 METHODS

These methods are required by the interface :

=over 4

=item *

C<tag>

Returns an identifier for the mod object.
It is used to gather mods together when calling C<covers> on them.

=item *

C<covers $mod>

Returns true if and only if the effects of the mod C<$mod> are already ensured by the current mod object, in which case no actual TikZ code will be emitted for C<$mod>.
Both mod objects are guaranteed to have the same C<tag>.

=item *

C<declare $formatter>

Returns an array reference of TikZ code lines required to declare this mod before using it, formatted by the L<LaTeX::TikZ::Formatter> object C<$formatter> ; or C<undef> if no declarations are needed for this mod.

=item *

C<apply $formatter>

Returns the TikZ code that activates the current mod as a string formatted by the L<LaTeX::TikZ::Formatter> object C<$formatter>.

=back

=cut

requires qw<
 tag
 covers
 declare
 apply
>;

coerce 'LaTeX::TikZ::Mod'
    => from 'Str'
    => via { LaTeX::TikZ::Mod::Raw->new(content => $_) };

=head1 SEE ALSO

L<LaTeX::TikZ>.

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

1; # End of LaTeX::TikZ::Mod
