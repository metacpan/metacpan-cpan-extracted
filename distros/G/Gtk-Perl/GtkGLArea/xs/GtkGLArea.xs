
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GtkGLAreaDefs.h"

static void     callXS (void (*subaddr)(CV* cv), CV *cv, SV **mark)
{
        int items;
        dSP;
        PUSHMARK (mark);
        (*subaddr)(cv);

        PUTBACK;  /* Forget the return values */
}

MODULE = Gtk::GLArea		PACKAGE = Gtk::GLArea		PREFIX = gtk_gl_area_

void
init(Class)
	SV *	Class
	CODE:
	{
		static int did_it = 0;
		if (did_it)
			return;
		did_it = 1;
		GtkGLArea_InstallTypedefs();
		GtkGLArea_InstallObjects();
	}

Gtk::GLArea_Sink
new(Class,...)
	SV * Class
	CODE:
	{
		GtkWidget * g;
		int * attr = malloc(sizeof(int)*(items));
		int i;
		for (i=0; i < items -1; ++i)
			attr[i] = SvIV(ST(i+1));
		attr[i] = 0;
		g = gtk_gl_area_new(attr);
		RETVAL = g ? GTK_GL_AREA(g) : 0;
		free(attr);
	}
	OUTPUT:
	RETVAL

Gtk::GLArea_Sink
share_new(Class, share, ...)
	SV * Class
	Gtk::GLArea	share
	CODE:
	{
		int * attr = malloc(sizeof(int)*(items-1));
		int i;
		for (i=0; i < items -2; ++i)
			attr[i] = SvIV(ST(i+2));
		attr[i] = 0;
		RETVAL = (GtkGLArea*)(gtk_gl_area_share_new(attr, share));
		free(attr);
	}
	OUTPUT:
	RETVAL

int
gtk_gl_area_begingl(self)
	Gtk::GLArea self

void
gtk_gl_area_endgl(self)
	Gtk::GLArea self

void
gtk_gl_area_swapbuffers(self)
	Gtk::GLArea self

void
gtk_gl_area_size(self, width, height)
	Gtk::GLArea self
	gint	width
	gint	height

Gtk::Gdk::GL::Context
glcontext(self)
 	Gtk::GLArea	self
 	CODE:
 	RETVAL = self->glcontext;
 	OUTPUT:
 	RETVAL

INCLUDE: ../build/boxed.xsh

INCLUDE: ../build/objects.xsh

INCLUDE: ../build/extension.xsh

