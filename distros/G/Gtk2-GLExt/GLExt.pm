#
# $Id$
#

package Gtk2::GLExt;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.92';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::GLExt $VERSION;

1;
__END__

=head1 NAME

Gtk2::GLExt - (DEPRECATED) An OpenGL extension to Gtk2-Perl

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

=head1 ABSTRACT

B<DEPRECATED> The Gtk2::GLExt module allows a Perl developer to use GtkGLExt,
an OpenGL extension to GTK+ by Naofumi Yasufuku, with Gtk2-Perl.

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-glext

=item *

Upstream URL: https://gitlab.gnome.org/Archive/gtkglext

=item *

Last upstream version: N/A

=item *

Last upstream release date: N/A

=item *

Migration path for this module: Gtk3::GLArea

=item *

Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

=back

B<NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE>

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

=head1 SEE ALSO

Gtk2::GLExt::index(3pm) - index of the Perl API reference for this module.

perl(1), Glib(3pm), Gtk2(3pm), OpenGL(3pm), SDL::OpenGL(3pm),
PDL::Graphics::OpenGL(3pm), L<http://gtkglext.sourceforge.net>,
L<http://gtk2-perl.sourceforge.net>

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
License along with this library; if not, see
<https://www.gnu.org/licenses/>.

=cut
