/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GdkGLConfig.xs,v 1.3 2004/03/07 02:42:19 muppetman Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::Gdk::GLExt::Config	PACKAGE = Gtk2::Gdk::GLExt::Config	PREFIX = gdk_gl_config_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_GL_CONFIG, TRUE);

=head1 ATTRIB_LIST

The attribute lists in new() and new_for_screen() are handed directly over to
glXChooseVisual() by GtkGLExt.  Boolean attributes in the list will be
interpreted as TRUE (don't use them at all if you want them to continue being
FALSE), while other attributes may take integer values.  While the C API
documentation for GtkGLExt states that the attribute list should be terminated
by GDK_GL_ATTRIB_LIST_NONE, this is not needed (and indeed is an error) when
called from perl.

=cut

##  GdkGLConfig *gdk_gl_config_new (const int *attrib_list) 
=for apidoc
=for arg attrib1 (string) first attribute
=for arg ... more attributes or attribute pairs (see above)
Create a new config with the given attributes, for the default screen.
For example:

  $config = Gtk2::Gdk::GLExt::Config->new (
    'use_gl', 'blue-size' => 8, 'rgba'
  );

=cut
GdkGLConfig * 
gdk_gl_config_new (class, attrib1, ...)
    PREINIT:
	int * attrib_list = NULL;
	gint n_attribs, i;
    CODE:
#define FIRST_IN_LIST 1
	n_attribs = items - FIRST_IN_LIST;
	attrib_list = g_new (int, n_attribs + 1);
	for (i = 0 ; i < n_attribs; i++) {
	    # The list is a mish-mash of strings (enum values
	    # from GdkGLConfigAttrib) and integer values.
	    if (looks_like_number(ST (FIRST_IN_LIST + i)))
		attrib_list[i] = SvIV (ST (FIRST_IN_LIST + i));
	    else
		attrib_list[i] = SvGdkGLConfigAttrib (ST (FIRST_IN_LIST + i));
	}
#undef FIRST_IN_LIST
	attrib_list[i] = GDK_GL_ATTRIB_LIST_NONE;
    	RETVAL = gdk_gl_config_new (attrib_list);
	g_free (attrib_list);
    OUTPUT:
	RETVAL

GdkGLConfig_ornull *
gdk_gl_config_new_by_mode (class, mode)
	GdkGLConfigMode mode
    C_ARGS:
	mode

#if GTK_CHECK_VERSION(2,2,0)

=for apidoc
=for arg attrib1 (string) first attribute
=for arg ... more attributes (see above)

Create a new config for a particular Gtk2::Gdk::Screen.  Fro example:

  $config = Gtk2::Gdk::GLExt::Config->new_for_screen (
    $screen, 'use_gl', 'blue-size' => 8, 'rgba'
  );

=cut
GdkGLConfig_ornull *
gdk_gl_config_new_for_screen (class, screen, attrib1, ...)
	GdkScreen         * screen
    PREINIT:
	int * attrib_list = NULL;
	gint n_attribs, i;
    CODE:
#define FIRST_IN_LIST 1
	n_attribs = items - FIRST_IN_LIST;
	attrib_list = g_new (int, n_attribs + 1);
	for (i = 0 ; i < n_attribs; i++) {
	    # The list is a mish-mash of strings (enum values
	    # from GdkGLConfigAttrib) and integer values.
	    if (looks_like_number(ST (FIRST_IN_LIST + i)))
		attrib_list[i] = SvIV (ST (FIRST_IN_LIST + i));
	    else
		attrib_list[i] = SvGdkGLConfigAttrib (ST (FIRST_IN_LIST + i));
	}
	attrib_list[i] = GDK_GL_ATTRIB_LIST_NONE;
    	RETVAL = gdk_gl_config_new_for_screen (screen, attrib_list);
    OUTPUT:
	RETVAL

GdkGLConfig_ornull *
gdk_gl_config_new_by_mode_for_screen (class, screen, mode)
	GdkScreen       * screen
	GdkGLConfigMode   mode
    C_ARGS:
	screen, mode

GdkScreen *
gdk_gl_config_get_screen (glconfig)
	GdkGLConfig * glconfig

#endif

int
gdk_gl_config_get_attrib (glconfig, attribute)
	GdkGLConfig       * glconfig
	GdkGLConfigAttrib   attribute
    CODE:
	if( !gdk_gl_config_get_attrib(glconfig, attribute, &RETVAL) )
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

GdkColormap *
gdk_gl_config_get_colormap (glconfig)
	GdkGLConfig * glconfig

GdkVisual *
gdk_gl_config_get_visual (glconfig)
	GdkGLConfig * glconfig

gint
gdk_gl_config_get_depth (glconfig)
	GdkGLConfig * glconfig

gint
gdk_gl_config_get_layer_plane (glconfig)
	GdkGLConfig * glconfig

gint
gdk_gl_config_get_n_aux_buffers (glconfig)
	GdkGLConfig * glconfig

gint
gdk_gl_config_get_n_sample_buffers (glconfig)
	GdkGLConfig * glconfig

gboolean
gdk_gl_config_is_rgba (glconfig)
	GdkGLConfig * glconfig

gboolean
gdk_gl_config_is_double_buffered (glconfig)
	GdkGLConfig * glconfig

gboolean
gdk_gl_config_is_stereo (glconfig)
	GdkGLConfig * glconfig

gboolean
gdk_gl_config_has_alpha (glconfig)
	GdkGLConfig * glconfig

gboolean
gdk_gl_config_has_depth_buffer (glconfig)
	GdkGLConfig * glconfig

gboolean
gdk_gl_config_has_stencil_buffer (glconfig)
	GdkGLConfig * glconfig

gboolean
gdk_gl_config_has_accum_buffer (glconfig)
	GdkGLConfig * glconfig

