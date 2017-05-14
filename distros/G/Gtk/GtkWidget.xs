
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>
#include <gtk/gtkprivate.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

#ifndef boolSV
# define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

void selection_handler(GtkWidget *widget, GtkSelectionData *selection_data,
		       gpointer data)
{
	AV * args = (AV *)data;
	SV * handler = *av_fetch(args, 0, 0);
	int i;
	dSP;

	PUSHMARK(sp);
	for (i=1;i<=av_len(args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
	XPUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(widget),0)));
	XPUSHs(sv_2mortal(newSVGtkSelectionDataRef(selection_data)));
	PUTBACK;

	perl_call_sv(handler, G_DISCARD);
}

void selection_handler_remove (gpointer data)
{
	AV * args = (AV *)data;
	SvREFCNT_dec(args);
}


MODULE = Gtk::Widget		PACKAGE = Gtk::Widget		PREFIX = gtk_widget_

#ifdef GTK_WIDGET

Gtk::Style
style(widget)
	Gtk::Widget	widget
	CODE:
	RETVAL = widget->style;
	OUTPUT:
	RETVAL

SV *
allocation(widget)
	Gtk::Widget	widget
	CODE:
	{
		GdkRectangle r;
		r.x = widget->allocation.x;
		r.y = widget->allocation.y;
		r.width = widget->allocation.width;
		r.height = widget->allocation.height;
		RETVAL = newSVGdkRectangle(&r);
	}
	OUTPUT:
	RETVAL

void
gtk_widget_destroy(widget)
	Gtk::Widget	widget

void
gtk_widget_unparent(widget)
	Gtk::Widget	widget

void
gtk_widget_show(widget)
	Gtk::Widget	widget

void
gtk_widget_hide(widget)
	Gtk::Widget	widget

void
gtk_widget_map(widget)
	Gtk::Widget	widget
	
void
gtk_widget_unmap(widget)
	Gtk::Widget	widget

void
gtk_widget_realize(widget)
	Gtk::Widget	widget

void
gtk_widget_unrealize(widget)
	Gtk::Widget	widget

void
gtk_widget_draw(widget, area)
	Gtk::Widget	widget
	Gtk::Gdk::Rectangle	area

void
gtk_widget_draw_focus(widget)
	Gtk::Widget	widget

void
gtk_widget_draw_default(widget)
	Gtk::Widget	widget

void
gtk_widget_draw_children(widget)
	Gtk::Widget	widget

void
gtk_widget_install_accelerator(widget, table, signal_name, key, modifiers)
	Gtk::Widget	widget
	Gtk::AcceleratorTable	table
	char *	signal_name
	int	key
	int	modifiers

void
gtk_widget_remove_accelerator(widget, table, signal_name)
	Gtk::Widget	widget
	Gtk::AcceleratorTable	table
	char *	signal_name

int
gtk_widget_event(widget, event)
	Gtk::Widget	widget
	Gtk::Gdk::Event	event

void
gtk_widget_activate(widget)
	Gtk::Widget	widget

void
gtk_widget_reparent(widget, reparent)
	Gtk::Widget	widget
	Gtk::Widget	reparent

void
gtk_widget_popup(widget, x, y)
	Gtk::Widget	widget
	int	x
	int	y

SV *
gtk_widget_intersect(widget, area)
	Gtk::Widget	widget
	Gtk::Gdk::Rectangle	area
	CODE:
	{
		GdkRectangle intersection;
		int result = gtk_widget_intersect(widget, area, &intersection);
		if (result)
			RETVAL = newSVGdkRectangle(&intersection);
		else
			RETVAL = newSVsv(&sv_undef);
	}
	OUTPUT:
	RETVAL

void
gtk_widget_basic(widget)
	Gtk::Widget	widget

void
gtk_widget_grab_focus(widget)
	Gtk::Widget	widget

void
gtk_widget_grab_default(widget)
	Gtk::Widget	widget

void
gtk_widget_set_name(widget, name)
	Gtk::Widget	widget
	char *	name

char *
gtk_widget_get_name(widget)
	Gtk::Widget	widget

void
gtk_widget_set_state(widget, state)
	Gtk::Widget	widget
	Gtk::StateType	state

void
gtk_widget_set_sensitive(widget, sensitive)
	Gtk::Widget	widget
	int	sensitive

void
gtk_widget_set_parent(widget, parent)
	Gtk::Widget	widget
	Gtk::Widget	parent

void
gtk_widget_set_style(widget, style)
	Gtk::Widget	widget
	Gtk::Style	style

void
gtk_widget_set_uposition(widget, x, y)
	Gtk::Widget	widget
	int	x
	int	y

void
gtk_widget_set_usize(widget, width, height)
	Gtk::Widget	widget
	int	width
	int	height

void
gtk_widget_set_events(widget, events)
	Gtk::Widget	widget
	Gtk::Gdk::EventMask	events

void
gtk_widget_set_extension_events(widget, events)
	Gtk::Widget	widget
	Gtk::Gdk::EventMask	events

upGtk::Widget
gtk_widget_get_toplevel(widget)
	Gtk::Widget	widget

upGtk::Widget
gtk_widget_get_ancestor(widget, type_name)
	Gtk::Widget	widget
	char *	type_name
	CODE:
	{
		int t = gtk_type_from_name(type_name);
		RETVAL = gtk_widget_get_ancestor(widget, t);
	}
	OUTPUT:
	RETVAL

Gtk::Gdk::Colormap
gtk_widget_get_colormap(widget)
	Gtk::Widget	widget

Gtk::Gdk::Visual
gtk_widget_get_visual(widget)
	Gtk::Widget	widget

Gtk::Style
gtk_widget_get_style(widget)
	Gtk::Widget	widget

int
gtk_widget_get_events(widget)
	Gtk::Widget	widget

int
gtk_widget_get_extension_events(widget)
	Gtk::Widget	widget

void
gtk_widget_get_pointer(widget)
	Gtk::Widget	widget
	PPCODE:
	{
		int x,y;
		gtk_widget_get_pointer(widget, &x, &y);
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(x)));
		PUSHs(sv_2mortal(newSViv(y)));
	}

void
gtk_widget_push_colormap(Class, colormap)
	SV *	Class
	Gtk::Gdk::Colormap	colormap
	CODE:
	gtk_widget_push_colormap(colormap);

void
gtk_widget_push_visual(Class, visual)
	SV *	Class
	Gtk::Gdk::Visual	visual
	CODE:
	gtk_widget_push_visual(visual);

void
gtk_widget_push_style(Class, style)
	SV *	Class
	Gtk::Style	style
	CODE:
	gtk_widget_push_style(style);

void
gtk_widget_pop_colormap(Class)
	SV *	Class
	CODE:
	gtk_widget_pop_colormap();

void
gtk_widget_pop_visual(Class)
	SV *	Class
	CODE:
	gtk_widget_pop_visual();

void
gtk_widget_pop_style(Class)
	SV *	Class
	CODE:
	gtk_widget_pop_style();

void
gtk_widget_set_default_colormap(Class, colormap)
	SV *	Class
	Gtk::Gdk::Colormap	colormap
	CODE:
	gtk_widget_set_default_colormap(colormap);

void
gtk_widget_set_default_visual(Class, visual)
	SV *	Class
	Gtk::Gdk::Visual	visual
	CODE:
	gtk_widget_set_default_visual(visual);

void
gtk_widget_set_default_style(Class, style)
	SV *	Class
	Gtk::Style	style
	CODE:
	gtk_widget_set_default_style(style);

Gtk::Gdk::Colormap
gtk_widget_get_default_colormap(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_widget_get_default_colormap();
	OUTPUT:
	RETVAL

Gtk::Gdk::Visual
gtk_widget_get_default_visual(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_widget_get_default_visual();
	OUTPUT:
	RETVAL

Gtk::Style
gtk_widget_get_default_style(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_widget_get_default_style();
	OUTPUT:
	RETVAL

Gtk::StateType
gtk_widget_state(widget, newvalue=0)
	Gtk::Widget	widget
	Gtk::StateType	newvalue
	CODE:
	RETVAL = GTK_WIDGET_STATE(widget);
	if (items>1)
		GTK_WIDGET_STATE(widget) = newvalue;
	OUTPUT:
	RETVAL


Gtk::StateType
gtk_widget_saved_state(widget, newvalue=0)
	Gtk::Widget	widget
	Gtk::StateType	newvalue
	CODE:
	RETVAL = GTK_WIDGET_SAVED_STATE(widget);
	if (items>1)
		GTK_WIDGET_SAVED_STATE(widget) = newvalue;
	OUTPUT:
	RETVAL

int
gtk_widget_visible(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_VISIBLE(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_VISIBLE);
	OUTPUT:
	RETVAL

int
gtk_widget_mapped(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_MAPPED(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_MAPPED);
	OUTPUT:
	RETVAL

#if 0

int
gtk_widget_unmapped(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_UNMAPPED(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_UNMAPPED);
	OUTPUT:
	RETVAL

#endif 

int
gtk_widget_realized(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_REALIZED(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_REALIZED);
	OUTPUT:
	RETVAL

int
gtk_widget_sensitive(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_SENSITIVE(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_SENSITIVE);
	OUTPUT:
	RETVAL

int
gtk_widget_parent_sensitive(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_PARENT_SENSITIVE(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_PARENT_SENSITIVE);
	OUTPUT:
	RETVAL

int
gtk_widget_is_sensitive(widget)
	Gtk::Widget	widget
	CODE:
	RETVAL = GTK_WIDGET_IS_SENSITIVE(widget);
	OUTPUT:
	RETVAL

int
gtk_widget_no_window(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_NO_WINDOW(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_NO_WINDOW);
	OUTPUT:
	RETVAL

int
gtk_widget_has_focus(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_HAS_FOCUS(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_HAS_FOCUS);
	OUTPUT:
	RETVAL


int
gtk_widget_can_focus(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_CAN_FOCUS(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_CAN_FOCUS);
	OUTPUT:
	RETVAL

int
gtk_widget_has_default(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_HAS_DEFAULT(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_HAS_DEFAULT);
	OUTPUT:
	RETVAL


int
gtk_widget_can_default(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_CAN_DEFAULT(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_CAN_DEFAULT);
	OUTPUT:
	RETVAL

#if 0

int
gtk_widget_propagate_state(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_PROPAGATE_STATE(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_PROPAGATE_STATE);
	OUTPUT:
	RETVAL

#endif

int
gtk_widget_drawable(widget)
	Gtk::Widget	widget
	CODE:
	RETVAL = GTK_WIDGET_DRAWABLE(widget);
	OUTPUT:
	RETVAL

#if 0

int
gtk_widget_anchored(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_ANCHORED(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_ANCHORED);
	OUTPUT:
	RETVAL

#endif

int
gtk_widget_BASIC(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_BASIC(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_BASIC);
	OUTPUT:
	RETVAL

#if 0
int
gtk_widget_user_style(widget, newvalue=0)
	Gtk::Widget	widget
	int	newvalue
	CODE:
	RETVAL = GTK_WIDGET_USER_STYLE(widget);
	if (items>1)
		GTK_WIDGET_SET_FLAGS(widget, GTK_USER_STYLE);
	OUTPUT:
	RETVAL

#endif

upGtk::Widget
parent(self)
	Gtk::Widget	self
	CODE:
		RETVAL = self->parent;
	OUTPUT:
	RETVAL

Gtk::Gdk::Window
window(self)
	Gtk::Widget	self
	CODE:
		RETVAL = self->window;
	OUTPUT:
	RETVAL

int
motion_notify_event(widget, event)
	Gtk::Widget	widget
	Gtk::Gdk::Event	event
	CODE:
	/*printf("GdkEventMotion->is_hint %d\n", ((GdkEventMotion*)event)->is_hint);*/
	RETVAL = GTK_WIDGET_CLASS(GTK_OBJECT(widget)->klass)->motion_notify_event(widget, (GdkEventMotion*)event);
	OUTPUT:
	RETVAL


void
grab_add(self)
	Gtk::Widget	self
	CODE:
	gtk_grab_add(self);

void
grab_remove(self)
	Gtk::Widget	self
	CODE:
	gtk_grab_remove(self);

upGtk::Widget
new(Class, widget_class, ...)
	SV *	Class
	char *	widget_class
	CODE:
	{
		GtkType t;
		GtkArg	argv[3];
		int p;
		int argc;
		int widget_type;
		GtkObject * o;
		SV *	value;
		
		widget_type = gtk_type_from_name(widget_class);
		o = GTK_OBJECT(gtk_widget_new(widget_type, NULL));
		RETVAL = GTK_WIDGET(o);
		
		for(p=2;p<items;) {
		
			if ((p+1)>=items)
				croak("too few arguments");

			argv[0].name = SvPV(ST(p),na);
			t = gtk_object_get_arg_type(argv[0].name);
			argv[0].type = t;
			value = ST(p+1);
		
			argc = 1;
			
			GtkSetArg(&argv[0], value, ST(0), o);

			gtk_object_setv(o, argc, argv);
			p += 1 + argc;
		}
	}
	OUTPUT:
	RETVAL

void
gtk_widget_dnd_drag_set(widget, drag_enable, type_name, ...)
	Gtk::Widget	widget
	int	drag_enable
	SV *	type_name
	CODE:
	{
		char ** names = malloc((sizeof(char*))*(items-2)) ;
		int i;
		for(i=2;i<items;i++)
			names[i] = SvPV(ST(i),na);
		gtk_widget_dnd_drag_set(widget, drag_enable, names, items-2);
		free(names);
	}

void
gtk_widget_dnd_drop_set(widget, drop_enable, is_destructive_operation, type_name, ...)
	Gtk::Widget	widget
	int	drop_enable
	int	is_destructive_operation
	SV *	type_name
	CODE:
	{
		char ** names = malloc((sizeof(char*))*(items-3)) ;
		int i;
		for(i=3;i<items;i++)
			names[i] = SvPV(ST(i),na);
		gtk_widget_dnd_drop_set(widget, drop_enable, names, items-3, is_destructive_operation);
		free(names);
	}

void
gtk_widget_dnd_data_set(widget, event, data)
	Gtk::Widget	widget
	Gtk::Gdk::Event	event
	SV *	data
	CODE:
	{
		STRLEN len;
		gpointer dataptr = SvPV(data, len);
		gtk_widget_dnd_data_set(widget, event, dataptr, len);
	}

int
selection_owner_set (self, selection, time)
	Gtk::Widget	self
	Gtk::Gdk::Atom  selection
	I32		time
	CODE:
	RETVAL = gtk_selection_owner_set (self, selection, time);
	OUTPUT:
	RETVAL

void
selection_add_handler (self, selection, target, handler, ...)
	Gtk::Widget	self
	Gtk::Gdk::Atom	selection
	Gtk::Gdk::Atom	target
	SV * 		handler
	CODE:
	{
		AV * args;
		SV * arg;
		int i,j;
		int type;
		args = newAV();

		if (SvOK(handler))
		{
			av_push(args, newSVsv(ST(3)));
			for (j=4;j<items;j++)
				av_push(args, newSVsv(ST(j)));

			gtk_selection_add_handler_full (self, selection, target,
						   selection_handler, NULL, (gpointer) args,
						   selection_handler_remove);
		} else {
			gtk_selection_add_handler (self, selection, target,
						   NULL, NULL);
		}
	}

int
selection_convert (self, selection, target, time)
	Gtk::Widget	self
	Gtk::Gdk::Atom	selection
	Gtk::Gdk::Atom  target
	I32		time
	CODE:
	RETVAL = gtk_selection_convert (self, selection, target, time);
	OUTPUT:
	RETVAL

#endif
