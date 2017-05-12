
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# undef printf
#endif
#include <gtk/gtk.h>
#include <gtk/gtkprivate.h>
#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# define printf PerlIO_stdoutf
#endif

#include "GtkDefs.h"

#define MY_GTK_WIDGET_SET_FLAGS(widget, flag, value) G_STMT_START{ \
	if (value) \
		GTK_WIDGET_SET_FLAGS((widget), (flag));\
	else \
		GTK_WIDGET_UNSET_FLAGS((widget), (flag)); \
	}G_STMT_END 

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
	ALIAS:
		Gtk::Widget::destroy = 0
		Gtk::Widget::ref = 1
		Gtk::Widget::unref = 2
		Gtk::Widget::unparent = 3
		Gtk::Widget::show = 4
		Gtk::Widget::show_now = 5
		Gtk::Widget::show_all = 6
		Gtk::Widget::hide = 7
		Gtk::Widget::hide_all = 8
		Gtk::Widget::map = 9
		Gtk::Widget::unmap = 10
		Gtk::Widget::realize = 11
		Gtk::Widget::unrealize = 12
		Gtk::Widget::queue_draw = 13
		Gtk::Widget::queue_resize = 14
		Gtk::Widget::draw_focus = 15
		Gtk::Widget::draw_default = 16
		Gtk::Widget::activate = 17
		Gtk::Widget::grab_focus = 18
		Gtk::Widget::grab_default = 19
		Gtk::Widget::grab_add = 20
		Gtk::Widget::grab_remove = 21
		Gtk::Widget::drag_highlight = 22
		Gtk::Widget::drag_unhighlight = 23
		Gtk::Widget::drag_dest_unset = 24
		Gtk::Widget::drag_source_unset = 25
		Gtk::Widget::unlock_accelerators = 26
		Gtk::Widget::set_rc_style = 27
		Gtk::Widget::restore_default_style = 28
		Gtk::Widget::reset_shapes = 29
		Gtk::Widget::reset_rc_styles = 30
		Gtk::Widget::queue_clear = 31
		Gtk::Widget::lock_accelerators = 32
		Gtk::Widget::ensure_style = 33
	CODE:
	switch (ix) {
	case 0: gtk_widget_destroy (widget); break;
	case 1: gtk_widget_ref (widget); break;
	case 2: gtk_widget_unref (widget); break;
	case 3: gtk_widget_unparent (widget); break;
	case 4: gtk_widget_show (widget); break;
	case 5: gtk_widget_show_now (widget); break;
	case 6: gtk_widget_show_all (widget); break;
	case 7: gtk_widget_hide (widget); break;
	case 8: gtk_widget_hide_all (widget); break;
	case 9: gtk_widget_map (widget); break;
	case 10: gtk_widget_unmap (widget); break;
	case 11: gtk_widget_realize (widget); break;
	case 12: gtk_widget_unrealize (widget); break;
	case 13: gtk_widget_queue_draw (widget); break;
	case 14: gtk_widget_queue_resize (widget); break;
	case 15: gtk_widget_draw_focus (widget); break;
	case 16: gtk_widget_draw_default (widget); break;
	case 17: gtk_widget_activate (widget); break;
	case 18: gtk_widget_grab_focus (widget); break;
	case 19: gtk_widget_grab_default (widget); break;
	case 20: gtk_grab_add (widget); break;
	case 21: gtk_grab_remove (widget); break;
	case 22: gtk_drag_highlight (widget); break;
	case 23: gtk_drag_unhighlight (widget); break;
	case 24: gtk_drag_dest_unset (widget); break;
	case 25: gtk_drag_source_unset (widget); break;
	case 26: gtk_widget_unlock_accelerators (widget); break;
	case 27: gtk_widget_set_rc_style (widget); break;
	case 28: gtk_widget_restore_default_style (widget); break;
	case 29: gtk_widget_reset_shapes (widget); break;
	case 30: gtk_widget_reset_rc_styles (widget); break;
	case 31: gtk_widget_queue_clear (widget); break;
	case 32: gtk_widget_lock_accelerators (widget); break;
	case 33: gtk_widget_ensure_style (widget); break;
	}

void
gtk_widget_destroyed(widget, ref)
	Gtk::Widget	widget
	SV *	ref
	CODE:
	{
		SV * t;
		if (ref && SvOK(ref) && (t=SvRV(ref)))
			sv_setsv(t, &PL_sv_undef);
	}

void
gtk_widget_draw(widget, area=NULL)
	Gtk::Widget	widget
	Gtk::Gdk::Rectangle	area

int
gtk_widget_event(widget, event)
	Gtk::Widget	widget
	Gtk::Gdk::Event	event

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
			RETVAL = newSVsv(&PL_sv_undef);
	}
	OUTPUT:
	RETVAL

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
	Gtk::Gdk::ExtensionMode	events

Gtk::Widget_Up
gtk_widget_get_toplevel(widget)
	Gtk::Widget	widget

Gtk::Widget_Up
gtk_widget_get_ancestor(widget, type_name)
	Gtk::Widget	widget
	char *	type_name
	CODE:
	{
		int t = gtnumber_for_gtname(type_name);
		if (!t)
			t = gtnumber_for_ptname(type_name);
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

Gtk::Gdk::EventMask
gtk_widget_get_events(widget)
	Gtk::Widget	widget

Gtk::Gdk::ExtensionMode
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
	ALIAS:
		Gtk::Widget::pop_colormap = 0
		Gtk::Widget::pop_visual = 1
		Gtk::Widget::pop_style = 2
	CODE:
	switch (ix) {
	case 0: gtk_widget_pop_colormap(); break;
	case 1: gtk_widget_pop_visual(); break;
	case 2: gtk_widget_pop_style(); break;
	}

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
	ALIAS:
		Gtk::Widget::visible = 0
		Gtk::Widget::mapped = 1
		Gtk::Widget::realized = 2
		Gtk::Widget::sensitive = 3
		Gtk::Widget::parent_sensitive = 4
		Gtk::Widget::no_window = 5
		Gtk::Widget::has_focus = 6
		Gtk::Widget::can_focus = 7
		Gtk::Widget::has_default = 8
		Gtk::Widget::can_default = 9
	CODE:
	{
		static const int flagval[] = {
			GTK_VISIBLE, GTK_MAPPED, GTK_REALIZED, GTK_SENSITIVE,
			GTK_PARENT_SENSITIVE, GTK_NO_WINDOW, GTK_HAS_FOCUS,
			GTK_CAN_FOCUS, GTK_HAS_DEFAULT, GTK_CAN_DEFAULT
		};
		RETVAL = GTK_WIDGET_FLAGS(widget) & flagval[ix];
		if (items>1)
			MY_GTK_WIDGET_SET_FLAGS(widget, flagval[ix], newvalue);
	}
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
gtk_widget_is_sensitive(widget)
	Gtk::Widget	widget
	CODE:
	RETVAL = GTK_WIDGET_IS_SENSITIVE(widget);
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

Gtk::Widget_OrNULL_Up
parent(widget)
	Gtk::Widget	widget
	CODE:
		RETVAL = widget->parent;
	OUTPUT:
	RETVAL

Gtk::Gdk::Window
window(widget)
	Gtk::Widget	widget
	CODE:
		RETVAL = widget->window;
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


Gtk::Widget_Sink_Up
new_from_pointer(klass, pointer)
	SV *	klass
	unsigned long	pointer
	CODE:
	RETVAL = (GtkWidget*)pointer;
	OUTPUT:
	RETVAL


unsigned long
_return_pointer(widget)
	Gtk::Widget	widget
	CODE:
	RETVAL = (unsigned long)widget;
	OUTPUT:
	RETVAL

#if 0

SV*
new(Class, widget_class, ...)
	SV *	Class
	char *	widget_class
	ALIAS:
		Gtk::Widget::new = 0
		Gtk::Widget::new_child = 1
	CODE:
	{
		GtkType t;
		GtkArg	argv[3];
		int p;
		int argc;
		int widget_type;
		GtkObject * o;
		SV *	value;
		
		widget_type = gtnumber_for_gtname(widget_class);
		if (!widget_type)
			widget_type = gtnumber_for_ptname(widget_class);
		gtk_type_class(widget_type);
		o = GTK_OBJECT(gtk_object_new(widget_type, NULL));
		/*RETVAL = GTK_WIDGET(o);*/
		RETVAL = newSVGtkObjectRef(o, NULL);
#if 1
		printf("created widget SV %p for object %p from perltype %s (gtktype: %d -> %s)\n", RETVAL, o, widget_class, widget_type, gtk_type_name(widget_type));
#endif
		
		gtk_object_sink(o);
		
		for(p=2;p<items;) {
		
			if ((p+1)>=items)
				croak("too few arguments");
			
			FindArgumentTypeWithObject(o, ST(p), &argv[0]);

			value = ST(p+1);
		
			argc = 1;
			
			GtkSetArg(&argv[0], value, ST(0), o);

			gtk_object_setv(o, argc, argv);
			p += 1 + argc;
		}
		
		if (SvOK(Class) && SvRV(Class)) {
			GtkObject * parent = SvGtkObjectRef(Class, 0);
			if (parent)
				gtk_container_add(GTK_CONTAINER(parent), GTK_WIDGET(o));
		}
	}
	OUTPUT:
	RETVAL

#endif

void
gtk_widget_shape_combine_mask(widget, shape_mask, offset_x, offset_y)
	Gtk::Widget	widget
	Gtk::Gdk::Bitmap	shape_mask
	gint	offset_x
	gint	offset_y

#if GTK_HVER < 0x010100

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
			names[i] = SvPV(ST(i),PL_na);
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
			names[i] = SvPV(ST(i),PL_na);
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

#endif

#endif
