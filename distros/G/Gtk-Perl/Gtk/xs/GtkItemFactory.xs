
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

typedef GtkItemFactoryEntry* Gtk__ItemFactory__Entry;

static void default_ifactory_callback (gpointer callback_data, guint callback_action, GtkWidget *widget);


GtkItemFactoryEntry* 
SvGtkItemFactoryEntry(SV *data) {
	HV * h;
	AV * a;
	SV ** s;
	GtkItemFactoryEntry* e;
	STRLEN len;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || 
			(SvTYPE(SvRV(data)) != SVt_PVHV && SvTYPE(SvRV(data)) != SVt_PVAV))
		return NULL;

	e = pgtk_alloc_temp(sizeof(GtkItemFactoryEntry));
	memset(e,0,sizeof(GtkItemFactoryEntry));

	/* path, accelerator, callback_action, item_type */
	if (SvTYPE(SvRV(data)) == SVt_PVHV) {
		h = (HV*)SvRV(data);
		if ((s=hv_fetch(h, "path", 4, 0)) && SvOK(*s))
			e->path = SvPV(*s, len);
		if ((s=hv_fetch(h, "accelerator", 11, 0)) && SvOK(*s))
			e->accelerator = SvPV(*s, len);
		if ((s=hv_fetch(h, "action", 6, 0)) && SvOK(*s))
			e->callback_action = SvIV(*s);
		if ((s=hv_fetch(h, "type", 4, 0)) && SvOK(*s))
			e->item_type = SvPV(*s, len);
	} else { /* array */
		a = (AV*)SvRV(data);
		if ((s=av_fetch(a, 0, 0)) && SvOK(*s))
			e->path = SvPV(*s, len);
		if ((s=av_fetch(a, 1, 0)) && SvOK(*s))
			e->accelerator = SvPV(*s, len);
		if ((s=av_fetch(a, 2, 0)) && SvOK(*s))
			e->callback_action = SvIV(*s);
		if ((s=av_fetch(a, 3, 0)) && SvOK(*s))
			e->item_type = SvPV(*s, len);
	}

	if (e->item_type && (!strcmp(e->item_type, "<Branch>") ||
			!strcmp(e->item_type, "<LastBranch>")) )
		e->callback = NULL;
	else
		e->callback = default_ifactory_callback;

	return e;
}

/* The GtkItemFactoryEntry struct does not have a separate
   callback_data member for each item.  Instead, the callback_data is
   passed into gtk_item_factory_create_item(s), and, to make matters
   even worse, gtk_item_factory_create_items() only has a single
   callback_data argument. Therefore, we have to get the actual
   callback data in a separate function from the one above. */

static SV*
ifactory_sv_get_handler(SV* data)
{
	SV* handler = NULL;

	if (SvTYPE(SvRV(data)) == SVt_PVHV) {
		HV *h = (HV*)SvRV(data);
		SV **s;
		if ((s = hv_fetch(h, "callback", 8, 0)) && SvOK(*s))
			handler = *s;
	} else if (SvTYPE(SvRV(data)) == SVt_PVAV) {
		AV *a = (AV*)SvRV(data);
		SV **s;
		if ((s = av_fetch(a, 4, 0)) && SvOK(*s))
			handler = *s;
	}
	return handler;
}

static void
default_ifactory_callback (gpointer callback_data, guint callback_action, GtkWidget *widget)
{
	AV * args;
	SV * handler;
	SV * sv_widget;
	int i;

	dSP; 

	if (callback_data == NULL)
		return;

	PUSHMARK(SP);
	args = (AV*)callback_data;
	handler = *av_fetch(args, 0, 0); 
	sv_widget = newSVGtkObjectRef(GTK_OBJECT(widget), 0);

	XPUSHs(sv_2mortal(sv_widget));
	XPUSHs(sv_2mortal(newSViv(callback_action)));
	for (i=1;i<=av_len(args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
	PUTBACK;

	perl_call_sv(handler, G_DISCARD);
}

MODULE = Gtk::ItemFactory	PACKAGE = Gtk::ItemFactory	PREFIX = gtk_item_factory_

#ifdef GTK_ITEM_FACTORY

Gtk::ItemFactory_Sink
gtk_item_factory_new(Class, container_type, path, accel_group)
	SV *		Class
	char*		container_type
	char*		path
	Gtk::AccelGroup	accel_group
	CODE:
	{
		GtkType wtype;
		wtype = gtnumber_for_gtname(container_type); 
		if (!wtype)
			wtype = gtnumber_for_ptname(container_type);
		RETVAL = (GtkItemFactory*)(gtk_item_factory_new(wtype, path, accel_group));
	}
	OUTPUT:
	RETVAL

void
gtk_item_factory_construct(item_factory, container_type, path, accel_group)
	Gtk::ItemFactory	item_factory
	char*		container_type
	char*		path
	Gtk::AccelGroup	accel_group
	CODE:
	{
		GtkType wtype;
		wtype = gtnumber_for_gtname(container_type); 
		if (!wtype)
			wtype = gtnumber_for_ptname(container_type);
		gtk_item_factory_construct(item_factory, wtype, path, accel_group);
	}

void
gtk_item_factory_parse_rc(Class, file_name)
	SV*	Class
	char*			file_name
	CODE:
	gtk_item_factory_parse_rc(file_name);

void
gtk_item_factory_parse_rc_string(Class, rc_string)
	SV*	Class
	char*			rc_string
	CODE:
	gtk_item_factory_parse_rc_string(rc_string);


#	gtk_item_factory_parse_rc_scanner()
#	gtk_item_factory_from_widget()

void
gtk_item_factory_add_foreign(Class, accel_widget, full_path, accel_group, keyval, modifiers)
	SV *	Class
	Gtk::Widget	accel_widget
	char *	full_path
	Gtk::AccelGroup	accel_group
	unsigned int	keyval
	Gtk::Gdk::ModifierType	modifiers
	CODE:
	gtk_item_factory_add_foreign(accel_widget, full_path, accel_group, keyval, modifiers);


Gtk::Widget_Up
gtk_item_factory_get_widget(item_factory, path)
	Gtk::ItemFactory	item_factory
	char*			path

Gtk::Widget_Up
gtk_item_factory_get_item(item_factory, path)
	Gtk::ItemFactory	item_factory
	char*			path

Gtk::Widget_Up
gtk_item_factory_get_widget_by_action(item_factory, action)
	Gtk::ItemFactory	item_factory
	unsigned int		action

Gtk::Widget_Up
gtk_item_factory_get_item_by_action(item_factory, action)
	Gtk::ItemFactory	item_factory
	unsigned int		action

void
gtk_item_factory_create_item(item_factory, entry, ...)
	Gtk::ItemFactory	item_factory
	Gtk::ItemFactory::Entry	entry
	CODE:
	{
		AV *args = NULL;
		/* Need to unref args when the item is destroyed.
		   Should be fixed at the Gtk+ level with a _full
		   version of the function.  */

		if (items > 2) {
			/* If we have a handler and arg-list, use it */
			args = newAV();
			PackCallbackST(args, 2);
		} else {
			SV *handler = ifactory_sv_get_handler(ST(1)); /* entry */
			if (handler) {
				args = newAV();
				PackCallback(args, handler);
			} else
				entry->callback = NULL;
		}
		gtk_item_factory_create_item(item_factory, entry, args, 1);
	}

void
gtk_item_factory_create_items(item_factory, ...)
	Gtk::ItemFactory	item_factory
	CODE:
	{
		int i;
		for (i = 1; i < items; i++) {
			GtkItemFactoryEntry *entry = SvGtkItemFactoryEntry(ST(i));
			SV *handler = ifactory_sv_get_handler(ST(i));
			AV *args = NULL;

			/* As above, args will leak memory :( */
			if (handler) {
				args = newAV();
				PackCallback(args, handler);
			} else
				entry->callback = NULL;
			gtk_item_factory_create_item(item_factory, entry, args, 1);
		}
	}

void
gtk_item_factory_delete_item(item_factory, path)
	Gtk::ItemFactory	item_factory
	char *	path

void
gtk_item_factory_delete_entry(item_factory, entry)
	Gtk::ItemFactory	item_factory
	Gtk::ItemFactory::Entry	entry

void
gtk_item_factory_popup(item_factory, x, y, mouse_button, time)
	Gtk::ItemFactory	item_factory
	unsigned int	x
	unsigned int	y
	unsigned int	mouse_button
	unsigned int	time

#	gtk_item_factory_set_translate_func

#endif

MODULE = Gtk::ItemFactory	PACKAGE = Gtk::Widget

#ifdef GTK_ITEM_FACTORY

Gtk::ItemFactory
item_factory(widget)
	Gtk::Widget	widget
	CODE:
	RETVAL = gtk_item_factory_from_widget (widget);
	OUTPUT:
	RETVAL

char*
item_factory_path(widget)
	Gtk::Widget	widget
	CODE:
	RETVAL = gtk_item_factory_path_from_widget (widget);
	OUTPUT:
	RETVAL

#endif
