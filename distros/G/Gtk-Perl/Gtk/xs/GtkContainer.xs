#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

/* Still missing: argument, vector &c functions */

void foreach_container_handler (GtkWidget *widget, gpointer data)
{
	AV * perlargs = (AV*)data;
	SV * perlhandler = *av_fetch(perlargs, 1, 0);
	SV * sv_object = newSVGtkObjectRef(GTK_OBJECT(widget), 0);
	int i;
	dSP;
	
	PUSHMARK(SP);
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
set_border_width(container, width)
	Gtk::Container	container
	int	width
	ALIAS:
		Gtk::Container::set_border_width = 0
		Gtk::Container::border_width = 1
	CODE:
#if GTK_HVER < 0x010106
	/* DEPRECATED */
	gtk_container_border_width(container, width);
#else
	gtk_container_set_border_width(container, width);
#endif

 #OUTPUT: Gtk::Widget
SV *
add(container, widget)
	Gtk::Container	container
	Gtk::Widget	widget	
	CODE:
		gtk_container_add(container, widget);
		RETVAL = newSVsv(ST(1));
	OUTPUT:
	RETVAL

Gtk::Widget
remove(container, widget)
	Gtk::Container	container
	Gtk::Widget	widget	
	CODE:
		gtk_container_remove(container, widget);
		RETVAL = widget;
	OUTPUT:
	RETVAL

 #ARG: $handler subroutine (a subroutine that will get each children of the container)
 #ARG: ... list (additional arguments for $handler)
void
foreach(container, handler, ...)
	Gtk::Container	container
	SV *	handler
	ALIAS:
		Gtk::Container::foreach = 0
		Gtk::Container::forall = 1
	PPCODE:
	{
		AV * args;
		SV * arg;
		int i;
		int type;
		args = newAV();
		
		av_push(args, newRV_inc(SvRV(ST(0))));
		PackCallbackST(args, 1);

		if (ix == 0)
			gtk_container_foreach(container, foreach_container_handler, args);
		else
			gtk_container_forall(container, foreach_container_handler, args);
		
		SvREFCNT_dec(args);
	}

void
children(container)
	Gtk::Container	container
	PPCODE:
	{
		GList * c = gtk_container_children(container);
		GList * start = c;
		while(c) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT((GtkWidget*)c->data), 0)));
			c = c->next;
		}
		if (start)
			g_list_free(start);
	}


int
gtk_container_focus(container, direction)
	Gtk::Container	container
	Gtk::DirectionType	direction


#ifdef GTK_HAVE_CONTAINER_FOCUS_ADJUSTMENTS

void
gtk_container_set_focus_vadjustment(container, adjustment)
	Gtk::Container	container
	Gtk::Adjustment	adjustment

void
gtk_container_set_focus_hadjustment(container, adjustment)
	Gtk::Container	container
	Gtk::Adjustment	adjustment

#endif

void
gtk_container_register_toplevel (container)
	Gtk::Container  container

void
gtk_container_unregister_toplevel (container)
	Gtk::Container  container

#if GTK_HVER < 0x010105

void
gtk_container_disable_resize(container)
	Gtk::Container	container

void
gtk_container_enable_resize(container)
	Gtk::Container	container

void
gtk_container_block_resize(container)
	Gtk::Container	container

void
gtk_container_unblock_resize(container)
	Gtk::Container	container

bool
gtk_container_need_resize(container)
	Gtk::Container	container

#endif

#if GTK_HVER >= 0x010100

void
gtk_container_resize_children(container)
	Gtk::Container container

void
gtk_container_set_focus_child(container, child)
	Gtk::Container	container
	Gtk::Widget	child

#endif

#if GTK_HVER >= 0x010200

char*
gtk_container_child_type (container)
	Gtk::Container	container
	CODE:
	RETVAL = ptname_for_gtnumber(gtk_container_child_type(container));
	OUTPUT:
	RETVAL

char *
gtk_container_child_composite_name (container, child)
	Gtk::Container	container
	Gtk::Widget	child

void
gtk_container_set_resize_mode(container, resize_mode)
	Gtk::Container	container
	Gtk::ResizeMode resize_mode

void
gtk_container_check_resize(container)
	Gtk::Container	container


void
gtk_container_dequeue_resize_handler (container)
	Gtk::Container	container

void
gtk_container_queue_resize (container)
	Gtk::Container	container

void
gtk_container_clear_resize_widgets (container)
	Gtk::Container	container

void
gtk_container_get_toplevels (Class)
	SV *	Class
	PPCODE:
	{
		GList * tmp = gtk_container_get_toplevels ();
		while (tmp) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(tmp->data), 0)));
			tmp = tmp->next;
		}
	}

#endif

#endif
