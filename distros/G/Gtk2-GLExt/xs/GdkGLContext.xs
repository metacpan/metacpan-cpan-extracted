/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GdkGLContext.xs,v 1.2 2003/11/25 03:08:08 rwmcfa1 Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::Gdk::GLExt::Context	PACKAGE = Gtk2::Gdk::GLExt::Context	PREFIX = gdk_gl_context_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_GL_CONTEXT, TRUE);

##  GdkGLContext *gdk_gl_context_new (GdkGLDrawable *gldrawable, GdkGLContext *share_list, gboolean direct, int render_type) 
GdkGLContext *
gdk_gl_context_new (class, gldrawable, share_list, direct, render_type)
	GdkGLDrawable * gldrawable
	GdkGLContext  * share_list
	gboolean        direct
	GdkGLRenderType render_type
    C_ARGS:
	gldrawable, share_list, direct, render_type

void
gdk_gl_context_destroy (glcontext)
	GdkGLContext * glcontext

gboolean
gdk_gl_context_copy (glcontext, src, mask)
	GdkGLContext  * glcontext
	GdkGLContext  * src
	unsigned long   mask

GdkGLDrawable *
gdk_gl_context_get_gl_drawable (glcontext)
	GdkGLContext * glcontext

GdkGLConfig *
gdk_gl_context_get_gl_config (glcontext)
	GdkGLContext * glcontext

GdkGLContext *
gdk_gl_context_get_share_list (glcontext)
	GdkGLContext * glcontext

gboolean
gdk_gl_context_is_direct (glcontext)
	GdkGLContext * glcontext

GdkGLRenderType
gdk_gl_context_get_render_type (glcontext)
	GdkGLContext * glcontext

##  GdkGLContext *gdk_gl_context_get_current (void) 
GdkGLContext *
gdk_gl_context_get_current (class)
    C_ARGS:
	/* void */

