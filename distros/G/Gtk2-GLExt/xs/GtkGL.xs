/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GtkGL.xs,v 1.2 2004/03/07 02:45:15 muppetman Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::GLExt	PACKAGE = Gtk2::GLExt	PREFIX = gtk_gl_

BOOT:
{
#include "register.xsh"
#include "boot.xsh"
}

=for object Gtk2::GLExt - An OpenGL extension to Gtk2-Perl

=head1 SYNOPSIS

  use Gtk2 -init;
  use Gtk2::GLExt;

  $glconfig = Gtk2::Gdk::GLExt::Config->new_by_mode ([qw/rgb depth double/]);

  $drawing_area = Gtk2::DrawingArea->new;
  $drawing_area->set_gl_capability ($glconfig, undef, 1, 'rgba_type');
  
  $gldrawable = $widget->get_gl_drawable;
  $gldrawable->gl_begin ($widget->get_gl_context);
  # do OpenGL stuff...
  $gldrawable->gl_end;

=head1 DESCRIPTION

The Gtk2::GLExt module allows a Perl developer to use GtkGLExt, an OpenGL
extension to GTK+ by Naofumi Yasufuku, with Gtk2-Perl.

Like the Gtk2 module on which it depends, Gtk2::GLExt follows the C API
of gtkglext as closely as possible while still being perlish.
Thus, the C API reference remains the canonical documentation.

You can find out everything you need to know about GtkGLExt at its homepage,
http://gtkglext.sourceforge.net

This module does not include actual OpenGL bindings; you need to get those
separately.  Search CPAN for OpenGL, SDL::OpenGL, and PDL::Graphics::OpenGL;
your mileage may vary.

=cut

=for position SEE_ALSO

=head1 SEE ALSO

Gtk2::GLExt::index(3pm) - index of the Perl API reference for this module.

perl(1), Glib(3pm), Gtk2(3pm), OpenGL(3pm), SDL::OpenGL(3pm),
PDL::Graphics::OpenGL(3pm), L<http://gtkglext.sourceforge.net>,
L<http://gtk2-perl.sourceforge.net>

=cut

=for position COPYRIGHT

=head1 AUTHOR

 Ross McFarland <rwmcfa1@neces.com>
 muppet <scott@asofyet.org>

If you want to own this project, please let us know.

=head1 COPYRIGHT

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
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

=cut
