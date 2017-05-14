void menu_callback (GtkWidget *widget, gpointer user_data)
{
	SV * handler = (SV*)user_data;
	int i;
	dSP;

	PUSHMARK(sp);
	XPUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(widget), 0)));
	PUTBACK;

	i = perl_call_sv(handler, G_DISCARD);
}

MODULE = Gtk	PACKAGE = Gtk::MenuFactory	PREFIX = gtk_menu_factory_

Gtk::MenuFactory
new(Class, type)
	SV *	Class
	Gtk::MenuFactoryType	type
	CODE:
	RETVAL = gtk_menu_factory_new(type);
	OUTPUT:
	RETVAL

void
gtk_menu_factory_add_entries(factory, entry, ...)
	Gtk::MenuFactory	factory
	SV *	entry
	CODE:
	{
		GtkMenuEntry * entries = malloc(sizeof(GtkMenuEntry)*(items-1));
		int i;
		for(i=1;i<items;i++) {
			SvGtkMenuEntry(ST(i), &entries[i-1]);
			entries[i-1].callback = menu_callback;
		}
		gtk_menu_factory_add_entries(factory, entries, items-1);
		free(entries);
	}

void
gtk_menu_factory_add_subfactory(factory, subfactory, path)
	Gtk::MenuFactory	factory
	Gtk::MenuFactory	subfactory
	char *	path

void
gtk_menu_factory_remove_paths(factory, path, ...)
	Gtk::MenuFactory	factory
	SV *	path
	CODE:
	{
		char ** paths = malloc(sizeof(char*)*(items-1));
		int i;
		for(i=1;i<items;i++)
			paths[i-1] = SvPV(ST(i),na);
		gtk_menu_factory_remove_paths(factory, paths, items-1);
		free(paths);
	}

void
gtk_menu_factory_remove_entries(factory, entry, ...)
	Gtk::MenuFactory	factory
	SV *	entry
	CODE:
	{
		GtkMenuEntry * entries = malloc(sizeof(GtkMenuEntry)*(items-1));
		int i;
		for(i=1;i<items;i++) {
			SvGtkMenuEntry(ST(i), &entries[i-1]);
			entries[i-1].callback = menu_callback;
		}
		gtk_menu_factory_remove_entries(factory, entries, items-1);
		free(entries);
	}

void
gtk_menu_factory_remove_subfactory(factory, subfactory, path)
	Gtk::MenuFactory	factory
	Gtk::MenuFactory	subfactory
	char *	path

void
gtk_menu_factory_find(factory, path)
	Gtk::MenuFactory	factory
	char *	path
	PPCODE:
	{
		GtkMenuPath * p = gtk_menu_factory_find(factory, path);
		if (p) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(p->widget), 0)));
			if (GIMME == G_ARRAY) {
				EXTEND(sp,1);
				PUSHs(sv_2mortal(newSVpv(p->path, 0)));
			}
		}
	}

void
gtk_menu_factory_destroy(factory)
	Gtk::MenuFactory	factory
	CODE:
	gtk_menu_factory_destroy(factory);
	UnregisterMisc((HV*)SvRV(ST(0)), factory);

void
DESTROY(factory)
	Gtk::MenuFactory	factory
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), factory);

