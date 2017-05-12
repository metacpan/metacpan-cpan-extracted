/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GdkGLWindow.xs,v 1.3 2004/03/07 02:42:19 muppetman Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::Gdk::GLExt::Window	PACKAGE = Gtk2::Gdk::GLExt::Window	PREFIX = gdk_gl_window_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_GL_WINDOW, TRUE);
	gperl_prepend_isa("Gtk2::Gdk::GLExt::Window", "Gtk2::Gdk::GLExt::Drawable");


##  GdkGLWindow *gdk_gl_window_new (GdkGLConfig *glconfig, GdkWindow *window, const int *attrib_list) 
#
# From GtkGLExt documentation:
#  attrib-list is currently unused.  This must be set to NULL or empty.
#
# In this mapping, we don't require this parameter
=for apidoc
=signature glwindow = Gtk2::Gdk::GLExt::Window->new ($glconfig, $window)
=arg attrib_list (__hide__)
=cut
GdkGLWindow *
gdk_gl_window_new (class, glconfig, window, attrib_list=NULL)
	GdkGLConfig * glconfig
	GdkWindow   * window
    C_ARGS:
	glconfig, window, NULL

void
gdk_gl_window_destroy (glwindow)
	GdkGLWindow * glwindow

GdkWindow *
gdk_gl_window_get_window (glwindow)
	GdkGLWindow * glwindow

GdkGLDrawable *
gdk_window_get_gl_drawable (window)
	GdkWindow * window

MODULE = Gtk2::Gdk::GLExt::Window	PACKAGE = Gtk2::Gdk::Window	PREFIX = gdk_window_

=for object Gtk2::Gdk::GLExt::Window

=cut

##  GdkGLWindow *gdk_window_set_gl_capability (GdkWindow *window, GdkGLConfig *glconfig, const int *attrib_list) 
#
# From GtkGLExt documentation:
#  attrib-list is currently unused.  This must be set to NULL or empty.
#
# In this mapping, we don't require this parameter
=for apidoc
=signature glwindow = $window->set_gl_capability ($glconfig)
=arg attrib_list (__hide__)
=cut
GdkGLWindow *
gdk_window_set_gl_capability (window, glconfig, attrib_list=NULL)
	GdkWindow   * window
	GdkGLConfig * glconfig
    C_ARGS:
	window, glconfig, NULL

void
gdk_window_unset_gl_capability (window)
	GdkWindow * window

gboolean
gdk_window_is_gl_capable (window)
	GdkWindow * window

 ## override the return type's name to resolve ambiguity
=for apidoc
=for signature glwindow = $window->get_gl_window
=cut
GdkGLWindow *
gdk_window_get_gl_window (window)
	GdkWindow * window
