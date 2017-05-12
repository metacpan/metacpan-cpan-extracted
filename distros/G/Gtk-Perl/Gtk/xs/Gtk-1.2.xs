
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define G_LOG_DOMAIN "Gtk"

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# undef printf
#endif

#include <gtk/gtk.h>

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# define printf PerlIO_stdoutf
#endif

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

static char **
XS_unpack_charPtrPtr (SV * sv) {
	char ** result;
	AV * av;
	int i;

	if (!sv || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
		return NULL;
	av = (AV*)SvRV(sv);
	result = pgtk_alloc_temp(sizeof(char*)*(av_len(av)+1));
	for (i=0; i < av_len(av); ++i)
		result[i] = SvPV(*av_fetch(av, i, 0), PL_na);
	result[i] = NULL;
	return result;
}

MODULE = Gtk12		PACKAGE = Gtk::Gdk::Window	PREFIX = gdk_window_

void
gdk_window_set_geometry_hints (window, geometry, flags)
	Gtk::Gdk::Window	window
	Gtk::Gdk::Geometry	geometry
	Gtk::Gdk::WindowHints	flags

void
gdk_window_register_dnd (window)
	Gtk::Gdk::Window	window

MODULE = Gtk12		PACKAGE = Gtk::Window		PREFIX = gtk_window_

void
gtk_window_set_geometry_hints (window, geometry_widget, geometry, flags)
	Gtk::Window	window
	Gtk::Widget	geometry_widget
	Gtk::Gdk::Geometry	geometry
	Gtk::Gdk::WindowHints	flags

#if GTK_HVER >= 0x010206

void
gtk_window_reposition (window, x, y)
	Gtk::Window	window
	gint	x
	gint	y

#endif

void
gtk_window_add_embedded_xid (window, xid)
	Gtk::Window	window
	guint	xid
	ALIAS:
		Gtk::Window::add_embedded_xid = 0
		Gtk::Window::remove_embedded_xid = 1
	CODE:
	if (ix == 0)
		gtk_window_add_embedded_xid (window, xid);
	else if (ix == 1)
		gtk_window_remove_embedded_xid (window, xid);

void
gtk_window_add_accel_group(window, accel_group)
	Gtk::Window	window
	Gtk::AccelGroup	accel_group

void
gtk_window_remove_accel_group(window, accel_group)
	Gtk::Window	window
	Gtk::AccelGroup	accel_group

MODULE = Gtk12		PACKAGE = Gtk::Menu		PREFIX = gtk_menu_

void
gtk_menu_set_accel_group (menu, accel_group)
	Gtk::Menu	menu
	Gtk::AccelGroup	accel_group

Gtk::AccelGroup_OrNULL
gtk_menu_get_accel_group (menu)
	Gtk::Menu	menu
	ALIAS:
		Gtk::Menu::get_accel_group = 0
		Gtk::Menu::get_unline_accel_group = 1
		Gtk::Menu::ensure_unline_accel_group = 2
	CODE:
	switch (ix) {
	case 0: gtk_menu_get_accel_group (menu); break;
	case 1: gtk_menu_get_uline_accel_group (menu); break;
	case 2: gtk_menu_ensure_uline_accel_group (menu); break;
	}

void
gtk_menu_reorder_child (menu, child, position)
	Gtk::Menu	menu
	Gtk::Widget	child
	gint	position

MODULE = Gtk12		PACKAGE = Gtk::Widget		PREFIX = gtk_

void
gtk_drag_get_data (widget, context, target, time)
	Gtk::Widget	widget
	Gtk::Gdk::DragContext	context
	Gtk::Gdk::Atom	target
	int	time

void
gtk_drag_dest_set (widget, flags, actions, ...)
	Gtk::Widget	widget
	Gtk::DestDefaults	flags
	Gtk::Gdk::DragAction	actions
	CODE:
	{
		int nt = items - 3;
		int i;
		GtkTargetEntry * targets = (GtkTargetEntry*)g_malloc(sizeof(GtkTargetEntry)*nt);
		for (i=3; i <items;++i)
			targets[i-3] = *SvGtkTargetEntry(ST(i));
		gtk_drag_dest_set(widget, flags, targets, nt, actions);
		g_free(targets);
	}

void
gtk_drag_dest_set_proxy (widget, proxy_window, protocol, use_coordinates)
	Gtk::Widget	widget
	Gtk::Gdk::Window	proxy_window
	Gtk::Gdk::DragProtocol	protocol
	gboolean	use_coordinates

void
gtk_drag_source_set (widget, start_button_mask, actions, ...)
	Gtk::Widget	widget
	Gtk::Gdk::ModifierType	start_button_mask
	Gtk::Gdk::DragAction	actions
	CODE:
	{
		int nt = items - 3;
		int i;
		GtkTargetEntry * targets = (GtkTargetEntry*)g_malloc(sizeof(GtkTargetEntry)*nt);
		for (i=3; i <items;++i)
			targets[i-3] = *SvGtkTargetEntry(ST(i));
		gtk_drag_source_set(widget, start_button_mask, targets, nt, actions);
		g_free(targets);
	}

void
gtk_drag_source_set_icon (widget, colormap=NULL, pixmap=NULL, mask=NULL)
	Gtk::Widget	widget
	Gtk::Gdk::Colormap_OrNULL	colormap
	Gtk::Gdk::Pixmap_OrNULL		pixmap
	Gtk::Gdk::Bitmap_OrNULL		mask

Gtk::Gdk::DragContext
gtk_drag_begin(widget, targets, actions, button, event)
	Gtk::Widget	widget
	Gtk::TargetList	targets
	Gtk::Gdk::DragAction	actions
	int	button
	Gtk::Gdk::Event	event

MODULE = Gtk12		PACKAGE = Gtk::Gdk::DragContext		PREFIX = gdk_drag_context_

Gtk::Gdk::DragContext
gdk_drag_context_new (Class)
	SV *	Class
	CODE:
	RETVAL = gdk_drag_context_new();
	sv_2mortal(newSVGdkDragContext(RETVAL));
	gdk_drag_context_unref(RETVAL);
	OUTPUT:
	RETVAL

void
gdk_drag_context_ref (context)
	Gtk::Gdk::DragContext	context

void
gdk_drag_context_unref (context)
	Gtk::Gdk::DragContext	context

MODULE = Gtk12		PACKAGE = Gtk::Gdk::DragContext		PREFIX = gdk_drag_

 #ARG: ... list (list of Gtk::Gdk::Atom)
Gtk::Gdk::DragContext
gdk_drag_begin (Class, window, ...)
	SV *	Class
	Gtk::Gdk::Window	window
	CODE:
	{
		GList * tmp_list = NULL;
		int i;
		for (i= 2; i < items; ++i) {
			tmp_list = g_list_prepend(tmp_list, GUINT_TO_POINTER(SvGdkAtom(ST(i))));
		}
		tmp_list = g_list_reverse(tmp_list);
		RETVAL = gdk_drag_begin(window, tmp_list);
		g_list_free(tmp_list);
	}
	OUTPUT:
	RETVAL

void
gdk_drag_status (context, action, time=GDK_CURRENT_TIME)
	Gtk::Gdk::DragContext	context
	Gtk::Gdk::DragAction	action
	int	time

void
gdk_drop_reply (context, ok, time=GDK_CURRENT_TIME)
	Gtk::Gdk::DragContext	context
	gboolean	ok
	int	time

void
gdk_drop_finish (context, success, time=GDK_CURRENT_TIME)
	Gtk::Gdk::DragContext	context
	gboolean	success
	int	time

Gtk::Gdk::Atom
gdk_drag_get_selection (context)
	Gtk::Gdk::DragContext	context

void
gdk_drag_get_protocol (Class, xid)
	SV *	Class
	guint32	xid
	PPCODE:
	{
		GdkDragProtocol protocol;
		guint32 retval;

		retval = gdk_drag_get_protocol(xid, &protocol);
		XPUSHs(sv_2mortal(newSViv(retval)));
		XPUSHs(sv_2mortal(newSVGdkDragProtocol(protocol)));
	}

void
gdk_drag_find_window (context, drag_window, x_root, y_root)
	Gtk::Gdk::DragContext	context
	Gtk::Gdk::Window	drag_window
	int	x_root
	int	y_root
	PPCODE:
	{
		GdkWindow * dest_window;
		GdkDragProtocol protocol;
		gdk_drag_find_window (context, drag_window, x_root, y_root, &dest_window, &protocol);
		XPUSHs(sv_2mortal(newSVGdkWindow(dest_window)));
		XPUSHs(sv_2mortal(newSVGdkDragProtocol(protocol)));
	}

gboolean
gdk_drag_motion (context, dest_window, protocol, x_root, y_root, suggested_action, possible_action, time=GDK_CURRENT_TIME)
	Gtk::Gdk::DragContext	context
	Gtk::Gdk::Window	dest_window
	Gtk::Gdk::DragProtocol	protocol
	int	x_root
	int	y_root
	Gtk::Gdk::DragAction	suggested_action
	Gtk::Gdk::DragAction	possible_action
	guint32	time

void
gdk_drag_drop (context, time=GDK_CURRENT_TIME)
	Gtk::Gdk::DragContext	context
	guint32	time

void
gdk_drag_abort (context, time=GDK_CURRENT_TIME)
	Gtk::Gdk::DragContext	context
	guint32	time

Gtk::Gdk::DragAction
suggested_action (context)
	Gtk::Gdk::DragContext	context
	CODE:
	RETVAL = context->suggested_action;
	OUTPUT:
	RETVAL

 #OUTPUT: list
 #RETURNS: a list of targets (integers)
void
targets (context)
	Gtk::Gdk::DragContext	context
	PPCODE:
	{
		GList * tmpl = context->targets;
		while(tmpl) {
			XPUSHs(sv_2mortal(newSViv(GPOINTER_TO_UINT(tmpl->data))));
			tmpl = tmpl->next;
		}
	}


MODULE = Gtk12		PACKAGE = Gtk::Gdk::DragContext		PREFIX = gtk_drag_

void
gtk_drag_finish(context, success, del, time=GDK_CURRENT_TIME)
	Gtk::Gdk::DragContext	context
	gboolean	success
	gboolean	del
	int	time

Gtk::Widget_OrNULL_Up
gtk_drag_get_source_widget (context)
	Gtk::Gdk::DragContext	context

void
gtk_drag_set_icon_widget (context, widget, hot_x, hot_y)
	Gtk::Gdk::DragContext	context
	Gtk::Widget	widget
	int	hot_x
	int	hot_y

void
gtk_drag_set_icon_pixmap (context, colormap, pixmap, mask, hot_x, hot_y)
	Gtk::Gdk::DragContext	context
	Gtk::Gdk::Colormap_OrNULL	colormap
	Gtk::Gdk::Pixmap_OrNULL		pixmap
	Gtk::Gdk::Bitmap_OrNULL		mask
	int	hot_x
	int	hot_y

void
gtk_drag_set_icon_default (context)
	Gtk::Gdk::DragContext	context

void
gtk_drag_set_default_icon (Class, colormap, pixmap, mask, hot_x, hot_y) 
	SV *	Class
	Gtk::Gdk::Colormap_OrNULL	colormap
	Gtk::Gdk::Pixmap_OrNULL		pixmap
	Gtk::Gdk::Bitmap_OrNULL		mask
	int	hot_x
	int	hot_y
	CODE:
	gtk_drag_set_default_icon (colormap, pixmap, mask, hot_x, hot_y);


MODULE = Gtk12		PACKAGE = Gtk::TargetList		PREFIX = gtk_target_list_

Gtk::TargetList
gtk_target_list_new (Class, ...)
	SV *	Class
	CODE:
	{
		int nt = items - 1;
		int i;
		GtkTargetEntry * targets = (GtkTargetEntry*)g_malloc(sizeof(GtkTargetEntry)*nt);
		for (i=1; i <items;++i)
			targets[i-1] = *SvGtkTargetEntry(ST(i));
		RETVAL = gtk_target_list_new(targets, nt);
		g_free(targets);
	
	}
	OUTPUT:
	RETVAL

void
gtk_target_list_ref (target_list)
	Gtk::TargetList target_list

void
gtk_target_list_unref (target_list)
	Gtk::TargetList target_list

void
gtk_target_list_add (target_list, target, flags, info)
	Gtk::TargetList target_list
	Gtk::Gdk::Atom	target
	int	flags
	int	info

void
gtk_target_list_add_table (target_list, ...)
	Gtk::TargetList target_list
	CODE:
	{
		int nt = items - 1;
		int i;
		GtkTargetEntry * targets = (GtkTargetEntry*)g_malloc(sizeof(GtkTargetEntry)*nt);
		for (i=1; i <items;++i)
			targets[i-1] = *SvGtkTargetEntry(ST(i));
		gtk_target_list_add_table(target_list, targets, nt);
		g_free(targets);
	}

void
gtk_target_list_remove (target_list, target)
	Gtk::TargetList target_list
	Gtk::Gdk::Atom	target

void
gtk_target_list_find (target_list, target)
	Gtk::TargetList target_list
	Gtk::Gdk::Atom	target
	PPCODE:
	{
		guint info;
		if (gtk_target_list_find(target_list, target, &info))
			XPUSHs(sv_2mortal(newSViv(info)));
	}

MODULE = Gtk12		PACKAGE = Gtk::Button		PREFIX = gtk_button_

Gtk::ReliefStyle
gtk_button_get_relief (button)
	Gtk::Button	button

void
gtk_button_set_relief (button, style)
	Gtk::Button	button
	Gtk::ReliefStyle	style

MODULE = Gtk12		PACKAGE = Gtk::ScrolledWindow	PREFIX = gtk_scrolled_window_

void
gtk_scrolled_window_set_hadjustment (scrolled_window, adj)
	Gtk::ScrolledWindow	scrolled_window
	Gtk::Adjustment adj

void
gtk_scrolled_window_set_vadjustment (scrolled_window, adj)
	Gtk::ScrolledWindow	scrolled_window
	Gtk::Adjustment adj

void
gtk_scrolled_window_set_placement (scrolled_window, window_placement)
	Gtk::ScrolledWindow scrolled_window
	Gtk::CornerType	window_placement

MODULE = Gtk12		PACKAGE = Gtk::Widget		PREFIX = gtk_widget_

void
gtk_widget_size_allocate (widget, allocation)
	Gtk::Widget	widget
	Gtk::Allocation	allocation

void
gtk_widget_size_request (widget, request=0)
	Gtk::Widget	widget
	Gtk::Requisition	request
	PPCODE:
	{
		gtk_widget_size_request (widget, request);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSViv(request->width)));
		PUSHs(sv_2mortal(newSViv(request->height)));
	}

void
gtk_widget_set_visual (widget, visual)
	Gtk::Widget	widget
	Gtk::Gdk::Visual	visual

void
gtk_widget_set_colormap (widget, colormap)
	Gtk::Widget	widget
	Gtk::Gdk::Colormap	colormap

gboolean
gtk_widget_set_scroll_adjustments (widget, hadj, vadj)
	Gtk::Widget	widget
	Gtk::Adjustment	hadj
	Gtk::Adjustment	vadj

void
gtk_widget_set_parent_window (widget, window)
	Gtk::Widget	widget
	Gtk::Gdk::Window	window

Gtk::Gdk::Window_OrNULL
gtk_widget_get_parent_window (widget)
	Gtk::Widget	widget

gstring
gtk_widget_get_composite_name (widget)
	Gtk::Widget	widget

void
gtk_widget_set_composite_name (widget, name)
	Gtk::Widget	widget
	char *	name

void
gtk_widget_set_app_paintable (widget, paintable)
	Gtk::Widget	widget
	gboolean	paintable

gboolean
gtk_widget_accelerators_locked (widget)
    Gtk::Widget widget

void
gtk_widget_remove_accelerator (widget, accel_group, accel_key, accel_mods)
	Gtk::Widget widget
	Gtk::AccelGroup	accel_group
	guint	accel_key
	Gtk::Gdk::ModifierType	accel_mods

void
gtk_widget_remove_accelerators (widget, accel_signal, visible_only)
	Gtk::Widget widget
	char*	accel_signal
	gboolean	visible_only

void
gtk_widget_add_accelerator (widget, accel_signal, accel_group, accel_key, accel_mods, accel_flags)
	Gtk::Widget widget
	char*	accel_signal
	Gtk::AccelGroup	accel_group
	guint	accel_key
	Gtk::Gdk::ModifierType	accel_mods
	Gtk::AccelFlags	accel_flags

guint
gtk_widget_accelerator_signal (widget, accel_group, accel_key, accel_mods)
	Gtk::Widget widget
	Gtk::AccelGroup	accel_group
	guint	accel_key
	Gtk::Gdk::ModifierType	accel_mods

void
gtk_widget_queue_draw_area (widget, x, y, width, height)
	Gtk::Widget widget
	int	x
	int	y
	int	width
	int	height

void
gtk_widget_queue_clear_area (widget, x, y, width, height)
	Gtk::Widget widget
	int	x
	int	y
	int	width
	int	height

void
gtk_widget_push_composite_child (Class)
	SV *	Class
	CODE:
	gtk_widget_push_composite_child();

void
gtk_widget_pop_composite_child (Class)
	SV *	Class
	CODE:
	gtk_widget_pop_composite_child();

void
gtk_widget_path (widget)
	Gtk::Widget	widget
	PPCODE:
	{
		guint len;
		gchar * path;
		gchar * rpath;
		gtk_widget_path(widget, &len, &path, &rpath);
		XPUSHs(sv_2mortal(newSVpv(path, len)));
		XPUSHs(sv_2mortal(newSVpv(rpath, len)));
		g_free(path);
		g_free(rpath);
	}

void
gtk_widget_class_path (widget)
	Gtk::Widget	widget
	PPCODE:
	{
		guint len;
		gchar * path;
		gchar * rpath;
		gtk_widget_class_path(widget, &len, &path, &rpath);
		XPUSHs(sv_2mortal(newSVpv(path, len)));
		XPUSHs(sv_2mortal(newSVpv(rpath, len)));
		g_free(path);
		g_free(rpath);
	}

void
gtk_widget_modify_style (widget, rcstyle)
	Gtk::Widget	widget
	Gtk::RcStyle	rcstyle

gint
gtk_widget_is_ancestor (widget, ancestor)
	Gtk::Widget	widget
	Gtk::Widget	ancestor

gint
gtk_widget_hide_on_delete (widget)
	Gtk::Widget	widget

#if 0
# FIXME: destroyed is already mapped to a widget flag :-(
void
gtk_widget_destroyed (widget)
	Gtk::Widget widget
	PPCODE:
	{
		GtkWidget * res=NULL;
		gtk_widget_destroyed (widget, &res);
		if (res)
			XPUSHs(sv_2mortal(newSVGtkWidget(res)));
	}

#endif

void
gtk_widget_add_events (widget, events)
	Gtk::Widget widget
	Gtk::Gdk::EventMask	events


MODULE = Gtk12		PACKAGE = Gtk::FontSelection	PREFIX = gtk_font_selection_

 #ARG: $foundries reference (reference to an array of foundries; may be undef)
 #ARG: $weights reference (reference to an array of weights; may be undef)
 #ARG: $slants reference (reference to an array of slants; may be undef)
 #ARG: $setwidths reference (reference to an array of setwidths; may be undef)
 #ARG: $spacings reference (reference to an array of spacings; may be undef)
 #ARG: $charsets reference (reference to an array of charsets; may be undef)
void
gtk_font_selection_set_filter (fsel, filter_type, font_type, foundries, weights, slants, setwidths, spacings, charsets)
	Gtk::FontSelection	fsel
	Gtk::FontFilterType	filter_type
	Gtk::FontType	font_type
	char **	foundries
	char **	weights
	char **	slants
	char **	setwidths
	char **	spacings
	char **	charsets

MODULE = Gtk12		PACKAGE = Gtk::FontSelectionDialog	PREFIX = gtk_font_selection_dialog_

 #ARG: $foundries reference (reference to an array of foundries; may be undef)
 #ARG: $weights reference (reference to an array of weights; may be undef)
 #ARG: $slants reference (reference to an array of slants; may be undef)
 #ARG: $setwidths reference (reference to an array of setwidths; may be undef)
 #ARG: $spacings reference (reference to an array of spacings; may be undef)
 #ARG: $charsets reference (reference to an array of charsets; may be undef)
void
gtk_font_selection_dialog_set_filter (fsel, filter_type, font_type, foundries, weights, slants, setwidths, spacings, charsets)
	Gtk::FontSelectionDialog	fsel
	Gtk::FontFilterType	filter_type
	Gtk::FontType	font_type
	char **	foundries
	char **	weights
	char **	slants
	char **	setwidths
	char **	spacings
	char **	charsets

