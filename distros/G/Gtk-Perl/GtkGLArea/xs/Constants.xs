
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GtkGLAreaDefs.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'G':
    	if (strEQ(name, "GDK_GL_NONE")) return GDK_GL_NONE;
    	if (strEQ(name, "GDK_GL_USE_GL")) return GDK_GL_USE_GL;
    	if (strEQ(name, "GDK_GL_BUFFER_SIZE")) return GDK_GL_BUFFER_SIZE;
    	if (strEQ(name, "GDK_GL_LEVEL")) return GDK_GL_LEVEL;
    	if (strEQ(name, "GDK_GL_RGBA")) return GDK_GL_RGBA;
    	if (strEQ(name, "GDK_GL_DOUBLEBUFFER")) return GDK_GL_DOUBLEBUFFER;
    	if (strEQ(name, "GDK_GL_STEREO")) return GDK_GL_STEREO;
    	if (strEQ(name, "GDK_GL_AUX_BUFFERS")) return GDK_GL_AUX_BUFFERS;
    	if (strEQ(name, "GDK_GL_RED_SIZE")) return GDK_GL_RED_SIZE;
    	if (strEQ(name, "GDK_GL_GREEN_SIZE")) return GDK_GL_GREEN_SIZE;
    	if (strEQ(name, "GDK_GL_BLUE_SIZE")) return GDK_GL_BLUE_SIZE;
    	if (strEQ(name, "GDK_GL_ALPHA_SIZE")) return GDK_GL_ALPHA_SIZE;
    	if (strEQ(name, "GDK_GL_DEPTH_SIZE")) return GDK_GL_DEPTH_SIZE;
    	if (strEQ(name, "GDK_GL_STENCIL_SIZE")) return GDK_GL_STENCIL_SIZE;
    	if (strEQ(name, "GDK_GL_ACCUM_RED_SIZE")) return GDK_GL_ACCUM_RED_SIZE;
    	if (strEQ(name, "GDK_GL_ACCUM_GREEN_SIZE")) return GDK_GL_ACCUM_GREEN_SIZE;
    	if (strEQ(name, "GDK_GL_ACCUM_BLUE_SIZE")) return GDK_GL_ACCUM_BLUE_SIZE;
    	if (strEQ(name, "GDK_GL_ACCUM_ALPHA_SIZE")) return GDK_GL_ACCUM_ALPHA_SIZE;

    	if (strEQ(name, "GDK_GL_X_VISUAL_TYPE_EXT")) return GDK_GL_X_VISUAL_TYPE_EXT;
    	if (strEQ(name, "GDK_GL_TRANSPARENT_TYPE_EXT")) return GDK_GL_TRANSPARENT_TYPE_EXT;
    	if (strEQ(name, "GDK_GL_TRANSPARENT_INDEX_VALUE_EXT")) return GDK_GL_TRANSPARENT_INDEX_VALUE_EXT;
    	if (strEQ(name, "GDK_GL_TRANSPARENT_RED_VALUE_EXT")) return GDK_GL_TRANSPARENT_RED_VALUE_EXT;
    	if (strEQ(name, "GDK_GL_TRANSPARENT_GREEN_VALUE_EXT")) return GDK_GL_TRANSPARENT_GREEN_VALUE_EXT;
    	if (strEQ(name, "GDK_GL_TRANSPARENT_BLUE_VALUE_EXT")) return GDK_GL_TRANSPARENT_BLUE_VALUE_EXT;
    	if (strEQ(name, "GDK_GL_TRANSPARENT_ALPHA_VALUE_EXT")) return GDK_GL_TRANSPARENT_ALPHA_VALUE_EXT;

    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

	
MODULE = Gtk::GLArea::Constants		PACKAGE = Gtk::GLArea::Constants		PREFIX = gtk_gl_area_

double
constant(name,arg)
	char *		name
	int		arg
