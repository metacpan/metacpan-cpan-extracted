/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GtkGLWidget.xs,v 1.3 2004/03/07 02:44:14 muppetman Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::GLExt::Widget	PACKAGE = Gtk2::Widget	PREFIX = gtk_widget_


=for object Gtk2::GLExt::Widget

=cut

gboolean
gtk_widget_set_gl_capability (widget, glconfig, share_list, direct, render_type);
	GtkWidget           * widget
	GdkGLConfig         * glconfig
	GdkGLContext_ornull * share_list
	gboolean              direct
	GdkGLRenderType       render_type

gboolean
gtk_widget_is_gl_capable (widget)
	GtkWidget * widget

GdkGLConfig *
gtk_widget_get_gl_config (widget)
	GtkWidget * widget

GdkGLContext *
gtk_widget_create_gl_context (widget, share_list, direct, render_type)
	GtkWidget           * widget
	GdkGLContext_ornull * share_list
	gboolean              direct
	GdkGLRenderType       render_type

GdkGLContext *
gtk_widget_get_gl_context (widget)
	GtkWidget * widget

=for apidoc
=signature glwindow = $widget->get_gl_window
=cut
GdkGLWindow *
gtk_widget_get_gl_window (widget)
	GtkWidget * widget

##define       gtk_widget_get_gl_drawable(widget)        \
##  GDK_GL_DRAWABLE (gtk_widget_get_gl_window (widget))
=for apidoc
=signature gldrawable = $widget->get_gl_drawable
=cut
GdkGLDrawable *
gtk_widget_get_gl_drawable(widget)
	GtkWidget * widget
