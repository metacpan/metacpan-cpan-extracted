#
# $Id$
#

package Gtk2::Spell;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '1.04';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::Spell $VERSION;

1;
__END__

=pod

=head1 NAME

Gtk2::Spell - Bindings for GtkSpell with Gtk2

=head1 SYNOPSIS

  use Gtk2;
  use Gtk2::Spell;

  $txtview = Gtk2::TextView->new;
  $spell = Gtk2::Spell->new_attach($txtview);
  $spell2 = Gtk2::Spell->get_from_text_view($txtview);
  # $spell2 will be the same object as $spell
  $spell->set_language(SOME_LANG);
  $spell->recheck_all;
  $spell->detach;

=head1 ABSTRACT

  Perl bindings to GtkSpell, used in concert with Gtk2::TextView.

=head1 DESCRIPTION

Perl bindings to GtkSpell, used in concert with Gtk2::TextView. Provides 
mis-spelled word highlighting in red and offers a right click pop-up menu with
suggested corrections.

=head1 FUNCTIONS

=over

=item $spell = Gtk2::Spell->new(GTK2_TEXT_VIEW)

=item $spell = Gtk2::Spell->new_attach(GTK2_TEXT_VIEW)

Creates and returns a new Gtk2::Spell object attached to GTK2_TEXT_VIEW. 

=item $spell->set_language(LANG_STR)

Sets the language which the underlying spell-checker will use. According to the 
GtkSpell API reference this 'appears to be a locale specifier.'

=item $spell->recheck_all

Rechecks the spelling of the entire text view buffer.

=item Gtk2::Spell->get_from_text_view(GTK2_TEXT_VIEW)

Returns the Gtk2::Spell object attached to the given Gtk2::TextBuffer or undef
if there isn't one attached.

=item $spell->detach

Detaches the Gtk2::Spell from it's associated text view.

=back

=head1 SEE ALSO

perl(1), Glib(1), Gtk2(1).

=head1 AUTHOR

rwmcfa1 E<lt>rwmcfa1@neces.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by rwmcfa1

Copyright 2003 by the gtk2-perl team.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

