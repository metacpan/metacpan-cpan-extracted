#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

#ifndef boolSV
# define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

void foreach_container_handler (GtkWidget *widget, gpointer data)
{
	AV * perlargs = (AV*)data;
	SV * perlhandler = *av_fetch(perlargs, 1, 0);
	SV * sv_object = newSVGtkObjectRef(GTK_OBJECT(widget), 0);
	int i;
	dSP;
	
	PUSHMARK(sp);
	XPUSHs(sv_2mortal(sv_object));
	for(i=2;i<=av_len(perlargs);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(perlargs, i, 0))));
   	XPUSHs(sv_2mortal(newSVsv(*av_fetch(perlargs, 0, 0))));
	PUTBACK ;
	
	perl_call_sv(perlhandler, G_DISCARD);
}


MODULE = Gtk::Container		PACKAGE = Gtk::Container		PREFIX = gtk_container_

#ifdef GTK_CONTAINER

void
border_width(self, width)
	Gtk::Container	self
	int	width
	CODE:
		gtk_container_border_width(self, width);

SV *
add(self, widget)
	Gtk::Container	self
	Gtk::Widget	widget	
	CODE:
		gtk_container_add(self, widget);
		RETVAL = newSVsv(ST(1));
	OUTPUT:
	RETVAL

Gtk::Widget
remove(self, widget)
	Gtk::Container	self
	Gtk::Widget	widget	
	CODE:
		gtk_container_remove(self, widget);
		RETVAL = widget;
	OUTPUT:
	RETVAL

bool
gtk_container_need_resize(self)
	Gtk::Container	self

void
gtk_container_disable_resize(self)
	Gtk::Container	self

void
gtk_container_enable_resize(self)
	Gtk::Container	self

void
gtk_container_block_resize(self)
	Gtk::Container	self

int
gtk_container_focus(self, direction)
	Gtk::Container	self
	Gtk::DirectionType	direction

void
gtk_container_unblock_resize(self)
	Gtk::Container	self

void
gtk_container_register_toplevel (self)
	Gtk::Container  self

void
gtk_container_unregister_toplevel (self)
	Gtk::Container  self

void
children(self)
	Gtk::Container	self
	PPCODE:
	{
		GList * c = gtk_container_children(self);
		GList * start = c;
		while(c) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT((GtkWidget*)c->data), 0)));
			c = c->next;
		}
		if (start)
			g_list_free(start);
	}

void
foreach(self, code, ...)
	Gtk::Container	self
	SV *	code
	PPCODE:
	{
		AV * args;
		SV * arg;
		int i;
		int type;
		args = newAV();
		
		av_push(args, newRV(SvRV(ST(0))));
		av_push(args, newSVsv(ST(1)));
		for (i=2;i<items;i++)
			av_push(args, newSVsv(ST(i)));

		gtk_container_foreach(self, foreach_container_handler, args);
		
		SvREFCNT_dec(args);
	}

#endif
