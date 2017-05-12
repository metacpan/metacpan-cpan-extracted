use strict;
use warnings;

package Gtk2::Sexy;

our $VERSION = '0.05';

use Gtk2;
use base 'DynaLoader';

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

=head1 NAME

Gtk2::Sexy - Perl interface to the sexy widget collection

=head1 DESCRIPTION

This module allows a perl developer to access the widgets of the sexy widget
collection, which currently includes the following widgets:

=over 2

=item SexyIconEntry

SexyIconEntry is a GtkEntry with support for inline icons. They can appear on
either side of the entry or on both sides. There's also built-in support for
adding a clear button for clearing the entry. This widget is particularly
useful as search fields.

=item SexySpellEntry

SexySpellEntry is a GtkEntry with inline spell checking. This makes use of
Enchant and allows the user to see what they've typed wrong as they type it. A
right-click menu is provided for misspelled words offering suggestions.

=item SexyUrlLabel

SexyUrlLabel is a GtkLabel with support for embedded hyperlinks. It uses a
modified form of the Pango markup format that supports the

  <a href="...">...</a>

tag. The hyperlink will appear in blue and can be activated by clicking it.
Right-clicking the hyperlink displays a menu offering the ability to activate
it or to copy the URL.

=back

=head1 SEE ALSO

L<Gtk2>(3pm), L<Gtk2::Sexy::index>(3pm)

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Florian Ragwitz

This is free software, licensed under:

  The GNU Lesser General Public License Version 2.1, February 1999

=cut

1;
