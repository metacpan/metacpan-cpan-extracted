#
# $Id$
#

package Gnome2::Canvas;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '1.006';

sub import {
	my $class = shift;
	$class->VERSION (@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

bootstrap Gnome2::Canvas $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Gnome2::Canvas - (DEPRECATED) A structured graphics canvas

=head1 SYNOPSIS

  use strict;
  use Gtk2 -init;
  use Gnome2::Canvas;
  my $window = Gtk2::Window->new;
  my $scroller = Gtk2::ScrolledWindow->new;
  my $canvas = Gnome2::Canvas->new;
  $scroller->add ($canvas);
  $window->add ($scroller);
  $window->set_default_size (150, 150);
  $canvas->set_scroll_region (0, 0, 200, 200);
  $window->show_all;

  my $root = $canvas->root;
  Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Text',
                             x => 20,
                             y => 15,
                             fill_color => 'black',
                             font => 'Sans 14',
                             anchor => 'GTK_ANCHOR_NW',
                             text => 'Hello, World!');
  my $box = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Rect',
                                       x1 => 10, y1 => 5,
                                       x2 => 150, y2 => 135,
                                       fill_color => 'red',
                                       outline_color => 'black');
  $box->lower_to_bottom;
  $box->signal_connect (event => sub {
          my ($item, $event) = @_;
          warn "event ".$event->type."\n";
  });

  Gtk2->main;

=head1 ABSTRACT

B<(DEPRECATED)> A structured graphics canvas

=head1 DESCRIPTION

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

=over

=item *

Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-canvas

=item *

Upstream URL: https://gitlab.gnome.org/Archive/libgnomecanvas

=item *

Last upstream version: 2.30.3

=item *

Last upstream release date: 2011-01-31

=item *

Migration path for this module: No upstream replacement

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

The Gnome Canvas is an engine for structured graphics that offers a
rich imaging model, high-performance rendering, and a powerful,
high level API.  It offers a choice of two rendering back-ends,
one based on GDK for extremely fast display, and another based on
Libart, a sophisticated, antialiased, alpha-compositing engine.
This widget can be used for flexible display of graphics and for
creating interactive user interface elements.

To create a new Gnome2::Canvas widget call C<< Gnome2::Canvas->new >> or
C<< Gnome2::Canvas->new_aa >> for an anti-aliased mode canvas.

A Gnome2::Canvas contains one or more Gnome2::CanvasItem
objects. Items consist of graphing elements like lines, ellipses,
polygons, images, text, and curves.  These items are organized using
Gnome2::CanvasGroup objects, which are themselves derived from
Gnome2::CanvasItem.  Since a group is an item it can be contained within
other groups, forming a tree of canvas items.  Certain operations, like
translating and scaling, can be performed on all items in a group.

There is a special root group created by a Gnome2::Canvas.  This is the top
level group under which all items in a canvas are contained.  The root group
is available as C<< $canvas->root >>.

There are several different coordinate systems used by Gnome2::Canvas
widgets.  The primary system is a logical, abstract coordinate space
called world coordinates.  World coordinates are expressed as unbounded
double floating point numbers.  When it comes to rendering to a screen
the canvas pixel coordinate system (also referred to as just canvas
coordinates) is used.  This system uses integers to specify screen
pixel positions.  A user defined scaling factor and offset are used to
convert between world coordinates and canvas coordinates.  Each item in
a canvas has its own coordinate system called item coordinates.  This
system is specified in world coordinates but they are relative to an
item (0.0, 0.0 would be the top left corner of the item).  The final
coordinate system of interest is window coordinates.  These are like
canvas coordinates but are offsets from within a window a canvas is
displayed in.  This last system is rarely used, but is useful when
manually handling GDK events (such as drag and drop) which are
specified in window coordinates (the events processed by the canvas
are already converted for you).

Along with different coordinate systems come methods to convert
between them.  C<< $canvas->w2c >> converts world to canvas pixel
coordinates and C<< canvas->c2w >> converts from canvas to
world.  To get the affine transform matrix for converting
from world coordinates to canvas coordinates call C<< $canvas->w2c_affine >>.
C<< $canvas->window_to_world >> converts from window to world
coordinates and C<< $canvas->world_to_window >> converts in the other
direction.  There are no methods for converting between canvas and
window coordinates, since this is just a matter of subtracting the
canvas scrolling offset.  To convert to/from item coordinates use the
methods defined for Gnome2::CanvasItem objects.

To set the canvas zoom factor (canvas pixels per world unit, the
scaling factor) call C<< $canvas->set_pixels_per_unit >>; setting this
to 1.0 will cause the two coordinate systems to correspond (e.g., [5, 6]
in pixel units would be [5.0, 6.0] in world units).

Defining the scrollable area of a canvas widget is done by calling
C<< $canvas->set_scroll_region >> and to get the current region
C<< $canvas->get_scroll_region >> can be used.  If the window is
larger than the canvas scrolling region it can optionally be centered
in the window.  Use C<< $canvas->set_center_scroll_region >> to enable or
disable this behavior.  To scroll to a particular canvas pixel coordinate
use C<< $canvas->scroll_to >> (typically not used since scrollbars are
usually set up to handle the scrolling), and to get the current canvas pixel
scroll offset call C<< $canvas->get_scroll_offsets >>.

=head1 SEE ALSO

Gnome2::Canvas::index(3pm) lists the generated Perl API reference PODs.

Gnome2::Canvas::main(3pm), in particular, lists the API in the Gnome2::Canvas
package.

Frederico Mena Quintero's whitepaper on the GNOME Canvas:
http://developer.gnome.org/doc/whitepapers/canvas/canvas.html

The real GnomeCanvas is implemented in a C library; the Gnome2::Canvas module
allows a Perl developer to use the canvas like a normal gtk2-perl object.
Like the Gtk2 module on which it depends, Gnome2::Canvas follows the C API of
libgnomecanvas-2.0 as closely as possible while still being perlish.
Thus, the C API reference remains the canonical documentation; the Perl
reference documentation lists call signatures and argument types, and is
meant to be used in conjunction with the C API reference.

GNOME Canvas Library Reference Manual
http://developer.gnome.org/doc/API/2.0/libgnomecanvas/index.html

perl(1), Glib(3pm), Gtk2(3pm).

To discuss gtk2-perl, ask questions and flame/praise the authors,
join gtk-perl-list@gnome.org at lists.gnome.org.

=cut

=for position COPYRIGHT

=head1 AUTHOR

muppet <scott at asofyet dot org>, with patches from
Torsten Schoenfeld <kaffetisch at web dot de>.

The DESCRIPTION section of this page is adapted from the documentation of
libgnomecanvas.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 by the gtk2-perl team.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, see
<https://www.gnu.org/licenses>.

=cut
