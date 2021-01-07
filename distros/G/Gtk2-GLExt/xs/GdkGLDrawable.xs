/*
 * $Id$
 */

#include "gtkglextperl.h"

MODULE = Gtk2::Gdk::GLExt::Drawable	PACKAGE = Gtk2::Gdk::GLExt::Drawable	PREFIX = gdk_gl_drawable_

gboolean
gdk_gl_drawable_make_current (gldrawable, glcontext)
	GdkGLDrawable * gldrawable
	GdkGLContext  * glcontext

gboolean
gdk_gl_drawable_is_double_buffered (gldrawable)
	GdkGLDrawable * gldrawable

void
gdk_gl_drawable_swap_buffers (gldrawable)
	GdkGLDrawable * gldrawable

void
gdk_gl_drawable_wait_gl (gldrawable)
	GdkGLDrawable * gldrawable

void
gdk_gl_drawable_wait_gdk (gldrawable)
	GdkGLDrawable * gldrawable

gboolean
gdk_gl_drawable_gl_begin (gldrawable, glcontext)
	GdkGLDrawable * gldrawable
	GdkGLContext  * glcontext

void
gdk_gl_drawable_gl_end (gldrawable)
	GdkGLDrawable * gldrawable

GdkGLConfig *
gdk_gl_drawable_get_gl_config (gldrawable)
	GdkGLDrawable * gldrawable

void
gdk_gl_drawable_get_size (gldrawable)
	GdkGLDrawable * gldrawable
    PREINIT:
	int width;
	int height;
    CODE:
	gdk_gl_drawable_get_size(gldrawable, &width, &height);
	XPUSHs (newSViv(width));
	XPUSHs (newSViv(height));

GdkGLDrawable *
gdk_gl_drawable_get_current (class)
    C_ARGS:
	/* void */

