/*
 * $Id$
 */

#include "gtkglextperl.h"

MODULE = Gtk2::GLExt	PACKAGE = Gtk2::GLExt	PREFIX = gtk_gl_

BOOT:
{
#include "register.xsh"
#include "boot.xsh"
}

=for object Gtk2::GLExt::main - An OpenGL extension to Gtk2-Perl

=cut
