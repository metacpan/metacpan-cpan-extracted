/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/xs/GdkGLQuery.xs,v 1.3 2004/03/07 02:42:25 muppetman Exp $
 */

#include "gtkglextperl.h"

MODULE = Gtk2::Gdk::GLExt::Query	PACKAGE = Gtk2::Gdk::GLExt::Query	PREFIX = gdk_gl_query_

void
gdk_gl_query_version (class)
    PREINIT:
	int major;
	int minor;
    PPCODE:
	gdk_gl_query_version(&major, &minor);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (major)));
	PUSHs (sv_2mortal (newSViv (minor)));
	PERL_UNUSED_VAR (ax);

#if GTK_CHECK_VERSION(2,2,0)

gboolean
gdk_gl_query_extension_for_display (class, display)
	GdkDisplay *display
    C_ARGS:
    	display

void
gdk_gl_query_version_for_display (class, display)
	GdkDisplay * display
    PREINIT:
	int major;
	int minor;
    CODE:
	gdk_gl_query_version_for_display(display, &major, &minor);
	XPUSHs (newSViv (major));
	XPUSHs (newSViv (minor));

#endif

gboolean
gdk_gl_query_extension (class)
    C_ARGS:
        /* void */

gboolean
gdk_gl_query_gl_extension (extension)
	const char * extension

##  GdkGLProc gdk_gl_get_proc_address (const char *proc_name) 
#GdkGLProc
#gdk_gl_get_proc_address (proc_name)
#	const char *proc_name

