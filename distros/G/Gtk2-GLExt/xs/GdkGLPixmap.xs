/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GdkGLPixmap.xs,v 1.3 2004/03/07 02:42:19 muppetman Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::Gdk::GLExt::Pixmap	PACKAGE = Gtk2::Gdk::GLExt::Pixmap	PREFIX = gdk_gl_pixmap_

##  GdkGLPixmap *gdk_gl_pixmap_new (GdkGLConfig *glconfig, GdkPixmap *pixmap, const int *attrib_list) 
#
# From GtkGLExt documentation:
#  attrib-list is currently unused.  This must be set to NULL or empty.
#
# In this mapping, we don't require this parameter
=for apidoc
=signature glpixmap = Gtk2::Gdk::GLExt::Pixmap->new ($glconfig, $pixmap)
=arg attrib_list (__hide__)
=cut
GdkGLPixmap *
gdk_gl_pixmap_new (class, glconfig, pixmap, attrib_list=NULL)
	GdkGLConfig * glconfig
	GdkPixmap   * pixmap
    C_ARGS:
	glconfig, pixmap, NULL

void
gdk_gl_pixmap_destroy (glpixmap)
	GdkGLPixmap * glpixmap

GdkPixmap *
gdk_gl_pixmap_get_pixmap (glpixmap)
	GdkGLPixmap * glpixmap

GdkGLDrawable *
gdk_pixmap_get_gl_drawable (pixmap)
	GdkPixmap * pixmap

MODULE = Gtk2::Gdk::GLExt::Pixmap	PACKAGE = Gtk2::Gdk::Pixmap	PREFIX = gdk_pixmap_

=for object Gtk2::Gdk::GLExt::Pixmap

=cut

##  GdkGLPixmap *gdk_pixmap_set_gl_capability (GdkPixmap *pixmap, GdkGLConfig *glconfig, const int *attrib_list) 
#
# From GtkGLExt documentation:
#  attrib-list is currently unused.  This must be set to NULL or empty.
#
# In this mapping, we don't require this parameter
=for apidoc
=signature glpixmap = $pixmap->set_gl_capability ($glconfig)
=arg attrib_list (__hide__)
=cut
GdkGLPixmap *
gdk_pixmap_set_gl_capability (pixmap, glconfig, attrib_list=NULL)
	GdkPixmap   * pixmap
	GdkGLConfig * glconfig
    C_ARGS:
	pixmap, glconfig, NULL

void
gdk_pixmap_unset_gl_capability (pixmap)
	GdkPixmap * pixmap

gboolean
gdk_pixmap_is_gl_capable (pixmap)
	GdkPixmap * pixmap

 ## override the return value in this signature to show that it's a glpixmap,
 ## otherwise the default name mangling makes it say "pixmap", which is
 ## confusing.
=for apidoc
=for signature glpixmap = $pixmap->get_gl_pixmap
=cut
GdkGLPixmap *
gdk_pixmap_get_gl_pixmap (pixmap)
	GdkPixmap * pixmap
