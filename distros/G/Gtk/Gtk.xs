
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
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

void marshal_signal (GtkObject *object, gpointer data, guint nparams, GtkArg * args, GtkType * arg_types, GtkType return_type)
{
	AV * perlargs = (AV*)data;
	SV * perlhandler = *av_fetch(perlargs, 2, 0);
	SV * sv_object = newSVGtkObjectRef(object, 0);
	char * signame;
	SV * result;
	int i;
	int encoding=0;
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	i = SvIV(*av_fetch(perlargs,3, 0));
	signame = gtk_signal_name(i);
	XPUSHs(sv_2mortal(sv_object));
	for(i=4;i<=av_len(perlargs);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(perlargs, i, 0))));
	/*printf("Handling signal %s\n", signame);*/
	/*XPUSHs(sv_2mortal(newSVpv(signame, 0)));*/
	/*if (sv_derived_from(sv_object, "Gtk::List")) {
		if (strEQ(signame, "select_child")	||
			strEQ(signame, "unselect_child")) {
			encoding=12;
			XPUSHs(sv_2mortal(newSVGtkObjectRef(GTK_VALUE_OBJECT(args[0]),0)));
			goto unpacked;
		}
	}*/
	if (sv_derived_from(sv_object, "Gtk::Window")) {
		if (strEQ(signame, "move_resize")) {
			encoding=13;
			XPUSHs(sv_2mortal(newSViv(*GTK_RETLOC_INT(args[0]))));
			XPUSHs(sv_2mortal(newSViv(*GTK_RETLOC_INT(args[1]))));
			XPUSHs(sv_2mortal(newSViv(GTK_VALUE_INT(args[2]))));
			XPUSHs(sv_2mortal(newSViv(GTK_VALUE_INT(args[3]))));
			goto unpacked;
		}
	}
	/*if (sv_derived_from(sv_object, "Gtk::Container")) {
		if (strEQ(signame, "add")		||
			strEQ(signame, "remove")	||
			strEQ(signame, "need_resize")) {
			encoding=7;
			XPUSHs(sv_2mortal(newSVGtkObjectRef(GTK_VALUE_OBJECT(args[0]),0)));
			goto unpacked;
		} else
		if (strEQ(signame, "foreach")) {
			warn("foreach not currently supported");
			encoding=8;
			goto unpacked;
		} else
		if (strEQ(signame, "focus")) {
			encoding=9;
			XPUSHs(sv_2mortal(newSVGtkDirectionType((GtkDirectionType)GTK_VALUE_ENUM(args[0]))));
			goto unpacked;
		}
	}*/
	if (sv_derived_from(sv_object, "Gtk::Entry")) {
		if (strEQ(signame, "insert_text")) {
			encoding=10;
			XPUSHs(sv_2mortal(newSVpv(GTK_VALUE_STRING(args[0]),0)));
			XPUSHs(sv_2mortal(newSViv(GTK_VALUE_INT(args[1]))));
			XPUSHs(sv_2mortal(newSViv(*GTK_RETLOC_INT(args[2]))));
			goto unpacked;
		}/* else
		if (strEQ(signame, "delete_text")) {
			encoding=11;
			XPUSHs(sv_2mortal(newSViv(GTK_VALUE_INT(args[0]))));
			XPUSHs(sv_2mortal(newSViv(GTK_VALUE_INT(args[1]))));
			goto unpacked;
		}*/
	}
	if (sv_derived_from(sv_object, "Gtk::Widget")) {
		if (strEQ(signame, "draw")) {
			encoding=1;
			XPUSHs(sv_2mortal(newSVGdkRectangle((GdkRectangle*)GTK_VALUE_POINTER(args[0]))));
			goto unpacked;
		} else
		if (strEQ(signame, "size_request")) {
			GtkRequisition * r = (GtkRequisition*)GTK_VALUE_POINTER(args[0]);
			encoding=2;
			XPUSHs(sv_2mortal(newSViv(r->width)));
			XPUSHs(sv_2mortal(newSViv(r->height)));
			goto unpacked;
		} else
		if (strEQ(signame, "size_allocate")) {
			GtkAllocation * a = (GtkAllocation*)GTK_VALUE_POINTER(args[0]);
			GdkRectangle r;
			encoding=3;
			r.x = a->x;
			r.y = a->y;
			r.width = a->width;
			r.height = a->height;
			XPUSHs(sv_2mortal(newSVGdkRectangle(&r)));
			goto unpacked;
		} else
		if (strEQ(signame, "install_accelerator")) {
			encoding=4;
			XPUSHs(sv_2mortal(newSVpv(GTK_VALUE_STRING(args[0]),0)));
			XPUSHs(sv_2mortal(newSViv(GTK_VALUE_INT(args[1]))));
			XPUSHs(sv_2mortal(newSViv(GTK_VALUE_INT(args[2]))));
			goto unpacked;
		} else
		if (strEQ(signame, "remove_accelerator")) {
			encoding=5;
			XPUSHs(sv_2mortal(newSVpv(GTK_VALUE_STRING(args[0]),0)));
			goto unpacked;
		} else
		if (strEQ(signame, "event")	||
			strEQ(signame, "button_press_event")	||
			strEQ(signame, "button_release_event")	||
			strEQ(signame, "button_notify_event")	||
			strEQ(signame, "motion_notify_event")	||
			strEQ(signame, "delete_event")	||
			strEQ(signame, "destroy_event")	||
			strEQ(signame, "expose_event")	||
			strEQ(signame, "key_press_event")	||
			strEQ(signame, "key_release_event")	||
			strEQ(signame, "enter_notify_event")	||
			strEQ(signame, "leave_notify_event")	||
			strEQ(signame, "configure_event")	||
			strEQ(signame, "focus_in_event")	||
			strEQ(signame, "focus_out_event")	||
			strEQ(signame, "map_event")	||
			strEQ(signame, "unmap_event")	||
			strEQ(signame, "property_notify_event")	||
			strEQ(signame, "selection_clear_event")	||
			strEQ(signame, "selection_request_event")	||
			strEQ(signame, "selection_notify_event")	||
			strEQ(signame, "other_event")) {
			encoding=6;
			XPUSHs(sv_2mortal(newSVGdkEvent((GdkEvent*)GTK_VALUE_POINTER(args[0]))));
			goto unpacked;
 		} else
	 		if (strEQ(signame, "selection_received")) {
 			XPUSHs(sv_2mortal(newSVGtkSelectionDataRef((GtkSelectionData*)GTK_VALUE_POINTER(args[0]))));
 			goto unpacked;
		}
	}
	for (i=0;i<nparams;i++)
		XPUSHs(sv_2mortal(GtkGetArg(args+i)));
unpacked:
	PUTBACK ;
	i = perl_call_sv(perlhandler, G_SCALAR);
	SPAGAIN;
	if (i != 1)
		croak("Aaaarrrrggghhhh");

	result = POPs;
	if (return_type != GTK_TYPE_NONE) {
		/*printf("return type is %s, value is #%d\n", gtk_type_name(args[nparams].type), SvIV(result));*/
		GtkSetRetArg(&args[nparams], result, 0, 0);
	}
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
}

void destroy_signal (gpointer data)
{
	AV * perlargs = (AV*)data;
	SvREFCNT_dec(perlargs);
}

void destroy_handler(gpointer data) {
	SvREFCNT_dec((AV*)data);
}

void generic_handler(GtkObject * object, gpointer data, guint n_args, GtkArg * args) {
	AV * stuff;
	SV * handler;
	SV * result;
	int i;
	dSP;

	stuff = (AV*)data;
	handler = *av_fetch(stuff, 0, 0);

	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	for (i=1;i<=av_len(stuff);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(stuff, i, 0))));
	/*XPUSHs(sv_2mortal(newSVsv(*av_fetch(stuff, 1, 0))));*/
	
	for(i=0;i<n_args;i++)
		XPUSHs(GtkGetArg(args+i));

	PUTBACK;
	i = perl_call_sv(handler, G_SCALAR);
	SPAGAIN;
	
	if (i!=1)
		croak("handler failed");

	result = POPs;

	if (args[n_args].type != GTK_TYPE_NONE)
		GtkSetRetArg(&args[n_args], result, 0, object);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
}

int init_handler(gpointer data) {
	AV * args = (AV*)data;
	SV * handler = *av_fetch(args, 0, 0);
	int i;
	dSP;

	PUSHMARK(sp);
	for (i=1;i<=av_len(args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
	PUTBACK;

	perl_call_sv(handler, G_DISCARD);
	
	SvREFCNT_dec(args);
	return 0;
}

/*static AV * input_handlers = 0;*/

void input_handler(gpointer data, gint source, GdkInputCondition condition) {
	AV * args = (AV*)data;
	SV * handler = *av_fetch(args, 0, 0);
	int i;
	dSP;

	PUSHMARK(sp);
	for (i=1;i<=av_len(args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
	XPUSHs(sv_2mortal(newSViv(source)));
	XPUSHs(sv_2mortal(newSVGdkInputCondition(condition)));
	PUTBACK;

	perl_call_sv(handler, G_DISCARD);
}

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

void     callXS (void (*subaddr)(CV* cv), CV *cv, SV **mark) 
{
	int items;
	dSP;
	PUSHMARK (mark);
	(*subaddr)(cv);

	PUTBACK;  /* Forget the return values */
}

static int init_gtk = 0;
static int init_gdk = 0;

void g_error_handler(char * msg) {
	croak("Gtk error: %s", msg);
}

void g_warning_handler(char * msg) {
	warn("Gtk warning: %s", msg);
}

void GtkInit() {
	int argc;
	char ** argv;
	AV * ARGV;
	SV * ARGV0;
	int i;

	if (init_gtk)
		return;
			
			g_set_error_handler(g_error_handler);
			g_set_warning_handler(g_warning_handler);
			
			argv  = 0;
			ARGV = perl_get_av("ARGV", FALSE);
			ARGV0 = perl_get_sv("0", FALSE);
			
			if (init_gdk)
				croak("GTK cannot be initalized after GDK has been initialized");
			
			argc = av_len(ARGV)+2;
			if (argc) {
				argv = malloc(sizeof(char*)*argc);
				argv[0] = SvPV(ARGV0, na);
				for(i=0;i<=av_len(ARGV);i++)
					argv[i+1] = SvPV(*av_fetch(ARGV, i, 0), na);
			}
			
			i = argc;
			gtk_init(&argc, &argv);

			init_gtk = 1;
			init_gdk = 1;
			
			while(argc<i--)
				av_shift(ARGV);
			
			if (argv)
				free(argv);
				
		gtk_signal_set_funcs(marshal_signal, destroy_signal);
		
		initPerlGtkDefs();
}



MODULE = Gtk		PACKAGE = Gtk		PREFIX = gtk_

double
constant(name,arg)
	char *		name
	int		arg

void
gc(Class)
	SV *	Class
	CODE:
	GCGtkObjects();

void
init(Class)
	SV *	Class
	CODE:
	GtkInit();


void
main(Class)
	SV *	Class
	CODE:
	gtk_main();

void
exit(Class, status)
	SV *	Class
	int status
	CODE:
	gtk_exit(status);

void
gtk_grab_add(Class, widget)
	SV *	Class
	Gtk::Widget	widget
	CODE:
	gtk_grab_add(widget);

void
gtk_grab_remove(Class, widget)
	SV *	Class
	Gtk::Widget	widget
	CODE:
	gtk_grab_remove(widget);

Gtk::Widget
gtk_grab_get_current(Class)
	SV* Class
	CODE:
	RETVAL = gtk_grab_get_current();
	OUTPUT:
	RETVAL

void
main_quit(Class)
	SV *	Class
	CODE:
	gtk_main_quit();

char *
set_locale(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_set_locale();
	OUTPUT:
	RETVAL

int
main_iteration(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_main_iteration();
	OUTPUT:
	RETVAL

void
print(Class, text)
	SV *	Class
	char *	text
	CODE:
	g_print(text);

int
timeout_add(Class, interval, handler, ...)
	SV *	Class
	int	interval
	SV *	handler
	CODE:
	{
		AV * args;
		SV * arg;
		int i,j;
		int type;
		args = newAV();
		
		av_push(args, newSVsv(ST(2)));
		for (j=3;j<items;j++)
			av_push(args, newSVsv(ST(j)));
		
		RETVAL = gtk_timeout_add_interp(interval, 
			generic_handler, (gpointer)args, destroy_handler);
		
	}
	OUTPUT:
	RETVAL

void
timeout_remove(Class, tag)
	SV *	Class
	int	tag
	CODE:
	gtk_timeout_remove(tag);

int
idle_add(Class, handler, ...)
	SV *	Class
	SV *	handler
	CODE:
	{
		AV * args;
		SV * arg;
		int i,j;
		int type;
		args = newAV();
		
		av_push(args, newSVsv(ST(1)));
		for (j=2;j<items;j++)
			av_push(args, newSVsv(ST(j)));
		
		RETVAL = gtk_idle_add_full(GTK_PRIORITY_DEFAULT, NULL, 
				generic_handler, (gpointer)args, destroy_handler);
		
	}
	OUTPUT:
	RETVAL

int
idle_add_priority (Class, priority, handler, ...)
	SV *	Class
	int     priority
	SV *	handler
	CODE:
	{
		AV * args;
		SV * arg;
		int i,j;
		int type;
		args = newAV();
		
		av_push(args, newSVsv(ST(1)));
		for (j=2;j<items;j++)
			av_push(args, newSVsv(ST(j)));
		
		RETVAL = gtk_idle_add_full(priority, NULL, 
				generic_handler, (gpointer)args, destroy_handler);
		
	}
	OUTPUT:
	RETVAL

void
idle_remove(Class, tag)
	SV *	Class
	int	tag
	CODE:
	gtk_idle_remove(tag);

void
init_add(Class, handler, ...)
	SV *	Class
	SV *	handler
	CODE:
	{
		AV * args;
		SV * arg;
		int i,j;
		int type;
		args = newAV();
		
		av_push(args, newSVsv(ST(1)));
		for (j=2;j<items;j++)
			av_push(args, newSVsv(ST(j)));
		
		gtk_init_add(init_handler, (gpointer)args);
	}

Gtk::Gdk::Event
get_current_event(Class=0)
	SV *	Class
	CODE:
	{
		RETVAL = gtk_get_current_event();
	}
	OUTPUT:
	RETVAL

upGtk::Widget
get_event_widget(Class=0, event)
	SV *	Class
	Gtk::Gdk::Event	event
	CODE:
	{
		RETVAL = gtk_get_event_widget(event);
	}
	OUTPUT:
	RETVAL


MODULE = Gtk		PACKAGE = Gtk::AcceleratorTable		PREFIX = gtk_accelerator_table_

Gtk::AcceleratorTable
new(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_accelerator_table_new();
	OUTPUT:
	RETVAL

Gtk::AcceleratorTable
gtk_accelerator_table_find(object, signal_name, key, mods)
	Gtk::Object	object
	char *	signal_name
	char	key
	int	mods

void
gtk_accelerator_table_install(self, object, signal_name, accelerator_key, accelerator_mods)
	Gtk::AcceleratorTable	self
	Gtk::Object	object
	char *	signal_name
	char	accelerator_key
	int	accelerator_mods

void
gtk_accelerator_table_remove(self, object, signal_name)
	Gtk::AcceleratorTable	self
	Gtk::Object	object
	char *	signal_name

int
gtk_accelerator_table_check(self, accelerator_key, accelerator_mods)
	Gtk::AcceleratorTable	self
	char	accelerator_key
	int	accelerator_mods

void
gtk_accelerator_table_set_mod_mask(table, modifier_mask)
	Gtk::AcceleratorTable	table
	int	modifier_mask




MODULE = Gtk		PACKAGE = Gtk::Rc	PREFIX = gtk_rc_

void
gtk_rc_parse(Class, filename)
	SV *	Class
	char *	filename
	CODE:
	gtk_rc_parse(filename);

Gtk::Style
gtk_rc_get_style(Class, widget)
	SV *	Class
	Gtk::Widget	widget
	CODE:
	RETVAL = gtk_rc_get_style(widget);
	OUTPUT:
	RETVAL

void
gtk_rc_add_widget_name_style(Class, style, pattern)
	SV *	Class
	Gtk::Style	style
	char *	pattern
	CODE:
	gtk_rc_add_widget_name_style(style, pattern);

void
gtk_rc_add_widget_class_style(Class, style, pattern)
	SV *	Class
	Gtk::Style	style
	char *	pattern
	CODE:
	gtk_rc_add_widget_class_style(style, pattern);


MODULE = Gtk		PACKAGE = Gtk::SelectionData PREFIX = gtk_selection_data_

Gtk::Gdk::Atom
selection(self)
	Gtk::SelectionData	self
	CODE:
		RETVAL = self->selection;
	OUTPUT:
	RETVAL

Gtk::Gdk::Atom
target(self)
	Gtk::SelectionData	self
	CODE:
		RETVAL = self->target;
	OUTPUT:
	RETVAL

Gtk::Gdk::Atom
type(self)
	Gtk::SelectionData	self
	CODE:
		RETVAL = self->type;
	OUTPUT:
	RETVAL

int
format(self)
	Gtk::SelectionData	self
	CODE:
		RETVAL = self->format;
	OUTPUT:
	RETVAL

SV *
data(self)
	Gtk::SelectionData	self
	CODE:
		if (self->length < 0)
			RETVAL = newSVsv(&sv_undef);
		else
			RETVAL = newSVpv(self->data, self->length);
	OUTPUT:
	RETVAL

void
set(self, type, format, data)
	Gtk::SelectionData      self
	Gtk::Gdk::Atom          type
	int                     format
	SV *                    data
	CODE:
	{
		int len;
		char *bytes;
		bytes = SvPV (data, len);
		gtk_selection_data_set (self, type, format, 
					(guchar *)bytes, len);
	}

void
DESTROY(self)
	Gtk::SelectionData	self
	CODE:
	UnregisterMisc((HV *)SvRV(ST(0)), self);


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


MODULE = Gtk		PACKAGE = Gtk::Style	PREFIX = gtk_style_

Gtk::Style
new(Class=0)
	SV *	Class
	CODE:
	RETVAL = gtk_style_new();
	OUTPUT:
	RETVAL

Gtk::Style
gtk_style_attach(self, window)
	Gtk::Style	self
	Gtk::Gdk::Window	window

void
gtk_style_detach(self)
	Gtk::Style	self

void
gtk_style_ref(self)
	Gtk::Style	self

void
gtk_style_unref(self)
	Gtk::Style	self

void
gtk_style_set_background(self, window, state_type)
	Gtk::Style	self
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type

Gtk::Gdk::Color
fg(style, state, new_color=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->fg[state];
	if (items>2) style->fg[state] = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Color
bg(style, state, new_color=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->bg[state];
	if (items>2) style->bg[state] = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Color
light(style, state, new_color=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->light[state];
	if (items>2) style->light[state] = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Color
dark(style, state, new_color=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->dark[state];
	if (items>2) style->dark[state] = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Color
mid(style, state, new_color=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->mid[state];
	if (items>2) style->mid[state] = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Color
text(style, state, new_color=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->text[state];
	if (items>2) style->text[state] = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Color
base(style, state, new_color=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->base[state];
	if (items>2) style->base[state] = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Color
black(style, new_color=0)
	Gtk::Style	style
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->black;
	if (items>1) style->black = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Color
white(style, new_color=0)
	Gtk::Style	style
	Gtk::Gdk::Color	new_color
	CODE:
	RETVAL = &style->white;
	if (items>1) style->white = *new_color;
	OUTPUT:
	RETVAL

Gtk::Gdk::Font
font(style, new_font=0)
	Gtk::Style	style
	Gtk::Gdk::Font	new_font
	CODE:
	RETVAL = style->font;
	if (items>1) style->font = new_font;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
fg_gc(style, state, new_gc=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->fg_gc[state];
	if (items>2) style->fg_gc[state] = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
bg_gc(style, state, new_gc=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->bg_gc[state];
	if (items>2) style->bg_gc[state] = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
light_gc(style, state, new_gc=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->light_gc[state];
	if (items>2) style->light_gc[state] = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
dark_gc(style, state, new_gc=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->dark_gc[state];
	if (items>2) style->dark_gc[state] = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
mid_gc(style, state, new_gc=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->mid_gc[state];
	if (items>2) style->mid_gc[state] = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
text_gc(style, state, new_gc=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->text_gc[state];
	if (items>2) style->text_gc[state] = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
base_gc(style, state, new_gc=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->base_gc[state];
	if (items>2) style->base_gc[state] = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
black_gc(style, new_gc=0)
	Gtk::Style	style
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->black_gc;
	if (items>1) style->black_gc = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::GC
white_gc(style, new_gc=0)
	Gtk::Style	style
	Gtk::Gdk::GC	new_gc
	CODE:
	RETVAL = style->white_gc;
	if (items>1) style->white_gc = new_gc;
	OUTPUT:
	RETVAL

Gtk::Gdk::Pixmap
bg_pixmap(style, state, new_pixmap=0)
	Gtk::Style	style
	Gtk::StateType	state
	Gtk::Gdk::Pixmap	new_pixmap
	CODE:
	RETVAL = style->bg_pixmap[state];
	if (items>2) style->bg_pixmap[state] = new_pixmap;
	OUTPUT:
	RETVAL

int
depth(style, new_depth=0)
	Gtk::Style	style
	int	new_depth
	CODE:
	RETVAL = style->depth;
	if (items>1) style->depth = new_depth;
	OUTPUT:
	RETVAL

Gtk::Gdk::Colormap
colormap(style, new_colormap=0)
	Gtk::Style	style
	Gtk::Gdk::Colormap	new_colormap
	CODE:
	RETVAL = style->colormap;
	if (items>2) style->colormap = new_colormap;
	OUTPUT:
	RETVAL

MODULE = Gtk		PACKAGE = Gtk::Style	PREFIX = gtk_

void
gtk_draw_hline(style, window, state_type, x1, x2, y)
	Gtk::Style	style
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type
	int	x1
	int	x2
	int	y

void
gtk_draw_vline(style, window, state_type, y1, y2, x)
	Gtk::Style	style
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type
	int	y1
	int	y2
	int	x

void
gtk_draw_shadow(style, window, state_type, shadow_type, x, y, width, height)
	Gtk::Style	style
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type
	Gtk::ShadowType	shadow_type
	int	x
	int	y
	int	width
	int	height

void
gtk_draw_polygon(style, window, state_type, shadow_type, fill, x, y, ...)
	Gtk::Style	style
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type
	Gtk::ShadowType	shadow_type
	bool fill
	int	x
	int	y
	CODE:
	{
		int npoints = (items-5)/2;
		GdkPoint * points = malloc(sizeof(GdkPoint)*npoints);
		int i,j;
		for(i=0,j=5;i<npoints;i++,j+=2) {
			points[i].x = SvIV(ST(j));
			points[i].y = SvIV(ST(j+1));
		}
		gtk_draw_polygon(style,window,state_type,shadow_type, points, npoints,fill);
		free(points);
	}

void
gtk_draw_arrow(style, window, state_type, shadow_type, arrow_type, fill, x, y, width, height)
	Gtk::Style	style
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type
	Gtk::ShadowType	shadow_type
	Gtk::ArrowType	arrow_type
	bool	fill
	int	x
	int	y
	int	width
	int	height

void
gtk_draw_diamond(style, window, state_type, shadow_type, x, y, width, height)
	Gtk::Style	style
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type
	Gtk::ShadowType	shadow_type
	int	x
	int	y
	int	width
	int	height

void
gtk_draw_oval(style, window, state_type, shadow_type, x, y, width, height)
	Gtk::Style	style
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type
	Gtk::ShadowType	shadow_type
	int	x
	int	y
	int	width
	int	height

void
gtk_draw_string(style, window, state_type, x, y, string)
	Gtk::Style	style
	Gtk::Gdk::Window	window
	Gtk::StateType	state_type
	int	x
	int	y
	char *	string


MODULE = Gtk		PACKAGE = Gtk::Type


MODULE = Gtk		PACKAGE = Gtk::Gdk		PREFIX = gdk_

double
constant(name,arg)
	char *	name
	int	arg

void
init(Class)
	SV *	Class
	CODE:
	{
		if (!init_gdk) {
			int argc;
			char ** argv = 0;
			AV * ARGV = perl_get_av("ARGV", FALSE);
			SV * ARGV0 = perl_get_sv("0", FALSE);
			int i;
			
			argc = av_len(ARGV)+2;
			if (argc) {
				argv = malloc(sizeof(char*)*argc);
				argv[0] = SvPV(ARGV0, na);
				for(i=0;i<=av_len(ARGV);i++)
					argv[i+1] = SvPV(*av_fetch(ARGV, i, 0), na);
			}
			
			i = argc;
			gdk_init(&argc, &argv);

			init_gdk = 1;
			
			while(argc<i--)
				av_shift(ARGV);
			
			if (argv)
				free(argv);
		}
	}

void
exit(Class, code)
	SV *	Class
	int	code
	CODE:
	gdk_exit(code);

int
events_pending(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_events_pending();
	OUTPUT:
	RETVAL

void
event_get(Class)
	SV *	Class
	PPCODE:
	{
		GdkEvent * e;
		HV * hash;
		GV * stash;
		int i, dohandle=0;

		if (e = gdk_event_get()) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkEvent(e)));
		} 

	}

void
gdk_event_put(Class, event)
	SV *	Class
	Gtk::Gdk::Event	event
	CODE:
	gdk_event_put(event);

void
gdk_set_show_events(Class, show_events)
	SV *	Class
	bool	show_events
	CODE:
	gdk_set_show_events(show_events);

void
gdk_set_use_xshm(Class, use_xshm)
	SV *	Class
	bool	use_xshm
	CODE:
	gdk_set_use_xshm(use_xshm);

#if 0

int
gdk_get_debug_level(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_get_debug_level();
	OUTPUT:
	RETVAL

#endif

int
gdk_get_show_events(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_get_show_events();
	OUTPUT:
	RETVAL

int
gdk_get_use_xshm(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_get_use_xshm();
	OUTPUT:
	RETVAL


int
gdk_time_get(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_time_get();
	OUTPUT:
	RETVAL

int
gdk_timer_get(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_timer_get();
	OUTPUT:
	RETVAL


void
gdk_timer_set(Class, value)
	SV *	Class
	int value
	CODE:
	gdk_timer_set(value);


void
gdk_timer_enable(Class)
	SV *	Class
	CODE:
	gdk_timer_enable();

void
gdk_timer_disable(Class)
	SV *	Class
	CODE:
	gdk_timer_disable();

int
input_add(Class, source, condition, handler, ...)
	SV *	Class
	int	source
	Gtk::Gdk::InputCondition	condition
	SV *	handler
	CODE:
	{
		AV * args;
		SV * arg;
		int i,j;
		int type;
		args = newAV();
		
		av_push(args, newSVsv(ST(3)));
		for (j=4;j<items;j++)
			av_push(args, newSVsv(ST(j)));
		
		/*if (!input_handlers)
			input_handlers = newAV();*/

		RETVAL = gdk_input_add_full(source, condition, input_handler, (gpointer)args, destroy_handler);
		/*RETVAL = gdk_input_add(source, condition, input_handler, (gpointer)args);*/
		
		/*arg = newRV((SV*)args);
		
		av_extend(input_handlers, RETVAL);
		av_store(input_handlers, RETVAL, arg);*/
	}
	OUTPUT:
	RETVAL

void
input_remove(Class, tag)
	SV *	Class
	int	tag
	CODE:
	{
		/*if (!input_handlers)
			input_handlers = newAV();*/

		gdk_input_remove(tag);
		
		/*av_extend(input_handlers, tag);
		av_store(input_handlers, tag, newSVsv(&sv_undef));*/
	}

int
gdk_pointer_grab(Class, window, owner_events, event_mask, confine_to, cursor, time)
	SV *	Class
	Gtk::Gdk::Window	window
	int	owner_events
	Gtk::Gdk::EventMask	event_mask
	Gtk::Gdk::Window	confine_to
	Gtk::Gdk::Cursor	cursor
	int	time
	CODE:
	RETVAL = gdk_pointer_grab(window, owner_events, event_mask, confine_to, cursor, time);
	OUTPUT:
	RETVAL

void
gdk_pointer_ungrab(Class, value)
	SV *	Class
	int value
	CODE:
	gdk_pointer_ungrab(value);

int
gdk_keyboard_grab(window, owner_events, time)
	Gtk::Gdk::Window	window
	int	owner_events
	int	time

void
gdk_keyboard_ungrab(time)
	int	time

int
gdk_screen_width(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_screen_width();
	OUTPUT:
	RETVAL

int
gdk_screen_height(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_screen_height();
	OUTPUT:
	RETVAL

void
gdk_flush(Class)
	SV *	Class
	CODE:
	gdk_flush();

void
gdk_beep(Class)
	SV *	Class
	CODE:
	gdk_beep();

void
gdk_key_repeat_disable(Class)
	SV *	Class
	CODE:
	gdk_key_repeat_disable();

void
gdk_key_repeat_restore(Class)
	SV *	Class
	CODE:
	gdk_key_repeat_restore();


MODULE = Gtk		PACKAGE = Gtk::Gdk::Window	PREFIX = gdk_window_

Gtk::Gdk::Window
new(Self, attr)
	SV *	Self
	SV *	attr
	CODE:
	{
		GdkWindow * parent = 0;
		GdkWindowAttr a;
		gint mask;
		if (Self && SvOK(Self) && SvRV(Self))
			parent = SvGdkWindow(Self);

		SvGdkWindowAttr(attr, &a, &mask);
		
		RETVAL = gdk_window_new(parent, &a, mask);
		if (!RETVAL)
			croak("gdk_window_new failed");
	}
	OUTPUT:
	RETVAL

void
gdk_window_destroy(window)
	Gtk::Gdk::Window	window

void
gdk_window_show(window)
	Gtk::Gdk::Window	window

void
gdk_window_hide(window)
	Gtk::Gdk::Window	window

void
gdk_window_withdraw(window)
	Gtk::Gdk::Window	window

void
gdk_window_move(window, x, y)
	Gtk::Gdk::Window	window
	int	x
	int	y


void
gdk_window_resize(window, width, height)
	Gtk::Gdk::Window	window
	int	width
	int	height


void
gdk_window_move_resize(window, x, y, width, height)
	Gtk::Gdk::Window	window
	int	x
	int	y
	int	width
	int	height

void
gdk_window_reparent(window, new_parent, x, y)
	Gtk::Gdk::Window	window
	Gtk::Gdk::Window	new_parent
	int	x
	int	y

void
gdk_window_clear(window)
	Gtk::Gdk::Window	window

void
gdk_window_clear_area(window, x, y, width, height)
	Gtk::Gdk::Window	window
	int	x
	int	y
	int	width
	int	height

void
gdk_window_clear_area_e(window, x, y, width, height)
	Gtk::Gdk::Window	window
	int	x
	int	y
	int	width
	int	height

void
gdk_window_copy_area(window, gc, x, y, source_window, source_x, source_y, width, height)
	Gtk::Gdk::Window	window
	Gtk::Gdk::GC  gc
	int	x
	int	y
	Gtk::Gdk::Window    source_window
	int	source_x
	int	source_y
	int	width
	int	height

void
gdk_window_raise(window)
	Gtk::Gdk::Window	window

void
gdk_window_lower(window)
	Gtk::Gdk::Window	window

void
gdk_window_set_override_redirect(window, override_redirect)
	Gtk::Gdk::Window	window
	bool	override_redirect

void
gdk_window_shape_combine_mask(window, shape_mask, offset_x, offset_y)
	Gtk::Gdk::Window	window
	Gtk::Gdk::Bitmap	shape_mask
	int	offset_x
	int	offset_y

void
gdk_window_set_hints(window, x, y, min_width, min_height, max_width, max_height, flags)
	Gtk::Gdk::Window	window
	int	x
	int	y
	int min_width
	int	min_height
	int	max_width
	int	max_height
	Gtk::Gdk::WindowHints	flags

void
gdk_window_set_title(window, title)
	Gtk::Gdk::Window	window
	char *	title

void
gdk_window_set_background(window, color)
	Gtk::Gdk::Window	window
	Gtk::Gdk::Color	color

void
gdk_window_set_back_pixmap(window, pixmap, parent_relative)
	Gtk::Gdk::Window	window
	Gtk::Gdk::Pixmap	pixmap
	int	parent_relative

void
gdk_window_get_geometry(window)
	Gtk::Gdk::Window	window
	PPCODE:
	{
		int x,y,width,height,depth;
		gdk_window_get_geometry(window,&x,&y,&width,&height,&depth);
		if (GIMME != G_ARRAY)
			croak("must accept array");
		EXTEND(sp,5);
		PUSHs(sv_2mortal(newSViv(x)));
		PUSHs(sv_2mortal(newSViv(y)));
		PUSHs(sv_2mortal(newSViv(width)));
		PUSHs(sv_2mortal(newSViv(height)));
		PUSHs(sv_2mortal(newSViv(depth)));
	}

void
gdk_window_get_position(window)
	Gtk::Gdk::Window	window
	PPCODE:
	{
		int x,y;
		gdk_window_get_position(window,&x,&y);
		if (GIMME != G_ARRAY)
			croak("must accept array");
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(x)));
		PUSHs(sv_2mortal(newSViv(y)));
	}

Gtk::Gdk::Visual
gdk_window_get_visual(window)
	Gtk::Gdk::Window	window

Gtk::Gdk::Colormap
gdk_window_get_colormap(window)
	Gtk::Gdk::Window	window

void
gdk_window_get_origin(window)
	Gtk::Gdk::Window	window
	PPCODE:
	{
		int x,y;
		gdk_window_get_origin(window,&x,&y);
		if (GIMME != G_ARRAY)
			croak("must accept array");
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(x)));
		PUSHs(sv_2mortal(newSViv(y)));
	}

void
gdk_window_get_pointer(window)
	Gtk::Gdk::Window	window
	PPCODE:
	{
		int x,y;
		GdkModifierType mask;
		GdkWindow * w = gdk_window_get_pointer(window,&x,&y,&mask);
		if (GIMME != G_ARRAY)
			croak("must accept array");
		EXTEND(sp,4);
		PUSHs(sv_2mortal(newSViv(x)));
		PUSHs(sv_2mortal(newSViv(y)));
		PUSHs(sv_2mortal(newSVGdkWindow(w)));
		PUSHs(sv_2mortal(newSVGdkModifierType(mask)));
	}

void
gdk_window_set_cursor(Self, Cursor)
	Gtk::Gdk::Window	Self
	Gtk::Gdk::Cursor	Cursor

Gtk::Gdk::Window
gdk_window_get_parent(window)
	Gtk::Gdk::Window	window

Gtk::Gdk::Window
gdk_window_get_toplevel(window)
	Gtk::Gdk::Window	window

void
gdk_window_get_children(window)
	Gtk::Gdk::Window	window
	PPCODE:
	{
		GList * l = gdk_window_get_children(window);
		while(l) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkWindow((GdkWindow*)l->data)));
			l=l->next;
		}
	}

Gtk::Gdk::EventMask
gdk_window_get_events (window)
	Gtk::Gdk::Window    window

void
gdk_window_set_events (window, event_mask)
	Gtk::Gdk::Window    window
	Gtk::Gdk::EventMask event_mask

void
gdk_window_set_icon (window, icon_window, pixmap, mask)
	Gtk::Gdk::Window    window
	Gtk::Gdk::Window    icon_window
	Gtk::Gdk::Pixmap    pixmap
	Gtk::Gdk::Bitmap    mask

void
gdk_window_set_icon_name (window, name)
	Gtk::Gdk::Window    window
	char*  name

void
gdk_window_set_group (window, leader)
	Gtk::Gdk::Window    window
	Gtk::Gdk::Window    leader

void
gdk_window_set_decorations (window, decorations)
	Gtk::Gdk::Window    window
	Gtk::Gdk::WMDecoration decorations

void
gdk_window_set_functions (window, functions)
	Gtk::Gdk::Window    window
	Gtk::Gdk::WMFunction  functions	

MODULE = Gtk        PACKAGE = Gtk::Gdk::Pixmap  PREFIX = gdk_window_

Gtk::Gdk::WindowType
gdk_window_get_type(window)
	Gtk::Gdk::Window	window

void
gdk_window_get_size(window)
	Gtk::Gdk::Window	window
	PPCODE:
	{
		int width,height;
		gdk_window_get_size(window,&width,&height);
		if (GIMME != G_ARRAY)
			croak("must accept array");
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(height)));
		PUSHs(sv_2mortal(newSViv(width)));
	}


MODULE = Gtk		PACKAGE = Gtk::Gdk::Pixmap	PREFIX = gdk_


void
gdk_draw_point(pixmap, gc, x, y)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	int	x
	int y

void
gdk_draw_line(pixmap, gc, x1, y1, x2, y2)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	int	x1
	int y1
	int	x2
	int	y2

void
gdk_draw_rectangle(pixmap, gc, filled, x, y, width, height)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	bool	filled
	int	x
	int y
	int	width
	int	height

void
gdk_draw_arc(pixmap, gc, filled, x, y, width, height, angle1, angle2)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	bool	filled
	int	x
	int y
	int	width
	int	height
	int	angle1
	int	angle2

void
gdk_draw_polygon(pixmap, gc, filled, x, y, ...)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	bool filled
	int	x
	int	y
	CODE:
	{
		int npoints = (items-3)/2;
		GdkPoint * points = malloc(sizeof(GdkPoint)*npoints);
		int i,j;
		for(i=0,j=3;i<npoints;i++,j+=2) {
			points[i].x = SvIV(ST(j));
			points[i].y = SvIV(ST(j+1));
		}
		gdk_draw_polygon(pixmap, gc, filled, points, npoints);
		free(points);
	}

void
gdk_draw_string(pixmap, font, gc, x, y, string)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::Font	font
	Gtk::Gdk::GC	gc
	int	x
	int y
	SV *	string
	CODE:
	{
		STRLEN len;
		char *bytes = SvPV (string, len);
		gdk_draw_text(pixmap, font, gc, x, y, bytes, len);
	}

void
gdk_draw_text(pixmap, font, gc, x, y, string, text_length)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::Font	font
	Gtk::Gdk::GC	gc
	int	x
	int y
	char *	string
	int     text_length

void
gdk_draw_pixmap(pixmap, gc, src, xsrc, ysrc, xdest, ydest, width, height)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Pixmap	src
	int	xsrc
	int	ysrc
	int	xdest
	int	ydest
	int	width
	int	height

void
gdk_draw_image(pixmap, gc, image, xsrc, ysrc, xdest, ydest, width, height)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Image	image
	int	xsrc
	int	ysrc
	int	xdest
	int	ydest
	int	width
	int	height

void
gdk_draw_points(pixmap, gc, x, y, ...)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	int	x
	int	y
	CODE:
	{
		int npoints = (items-2)/2;
		GdkPoint * points = malloc(sizeof(GdkPoint)*npoints);
		int i,j;
		for(i=0,j=2;i<npoints;i++,j+=2) {
			points[i].x = SvIV(ST(j));
			points[i].y = SvIV(ST(j+1));
		}
		gdk_draw_points(pixmap, gc, points, npoints);
		free(points);
	}

void
gdk_draw_segments(pixmap, gc, x1, y1, x2, y2, ...)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	int	x1
	int	y1
	int	x2
	int	y2
	CODE:
	{
		int npoints = (items-2)/4;
		GdkSegment * points = malloc(sizeof(GdkSegment)*npoints);
		int i,j;
		for(i=0,j=2;i<npoints;i++,j+=4) {
			points[i].x1 = SvIV(ST(j));
			points[i].y1 = SvIV(ST(j+1));
			points[i].x2 = SvIV(ST(j+2));
			points[i].y2 = SvIV(ST(j+3));
		}
		gdk_draw_segments(pixmap, gc, points, npoints);
		free(points);
	}

MODULE = Gtk		PACKAGE = Gtk::Gdk::Colormap	PREFIX = gdk_colormap_

Gtk::Gdk::Colormap
new(Class, visual, allocate)
	SV *	Class
	Gtk::Gdk::Visual	visual
	int	allocate
	CODE:
	RETVAL = gdk_colormap_new(visual, allocate);
	OUTPUT:
	RETVAL

Gtk::Gdk::Colormap
gdk_colormap_get_system(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_colormap_get_system();
	OUTPUT:
	RETVAL

int
gdk_colormap_get_system_size(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_colormap_get_system_size();
	OUTPUT:
	RETVAL

void
gdk_colormap_change(colormap, ncolors)
	Gtk::Gdk::Colormap	colormap
	int	ncolors

SV *
color(colormap, idx)
	Gtk::Gdk::Colormap	colormap
	int	idx
	CODE:
	RETVAL = newSVGdkColor(&colormap->colors[idx]);
	hv_store((HV*)SvRV(RETVAL), "_parent", 7, ST(0), 0);
	OUTPUT:
	RETVAL

MODULE = Gtk		PACKAGE = Gtk::Gdk::Color

int
red(color, new_value=0)
	Gtk::Gdk::Color	color
	int	new_value
	CODE:
	RETVAL=color->red;
	if (items>1)	color->red = new_value;
	OUTPUT:
	RETVAL
		
int
green(color, new_value=0)
	Gtk::Gdk::Color	color
	int	new_value
	CODE:
	RETVAL=color->green;
	if (items>1)	color->green = new_value;
	OUTPUT:
	RETVAL

int
blue(color, new_value=0)
	Gtk::Gdk::Color	color
	int	new_value
	CODE:
	RETVAL=color->blue;
	if (items>1)	color->blue = new_value;
	OUTPUT:
	RETVAL

int
pixel(color, new_value=0)
	Gtk::Gdk::Color	color
	int	new_value
	CODE:
	RETVAL=color->pixel;
	if (items>1)	color->pixel = new_value;
	OUTPUT:
	RETVAL

void
DESTROY(self)
	Gtk::Gdk::Color	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)),self);

MODULE = Gtk		PACKAGE = Gtk::Gdk::Cursor

Gtk::Gdk::Cursor
new(Class, type)
	SV *	Class
	SV *	type
	CODE:
	RETVAL = gdk_cursor_new(SvGdkCursorType(type));
	OUTPUT:
	RETVAL

Gtk::Gdk::Cursor
gdk_cursor_new_from_pixmap (Class, source, mask, fg, bg, x, y)
	SV *    Class
	Gtk::Gdk::Pixmap  source
	Gtk::Gdk::Pixmap  mask
	Gtk::Gdk::Color   fg
	Gtk::Gdk::Color   bg
	int   x
	int   y
	CODE:
	RETVAL = gdk_cursor_new_from_pixmap(source, mask, fg, bg, x, y);
	OUTPUT:
	RETVAL

void
destroy(self)
	Gtk::Gdk::Cursor	self
	CODE:
	gdk_cursor_destroy(self);
	UnregisterMisc((HV*)SvRV(ST(0)),self);

void
DESTROY(self)
	Gtk::Gdk::Cursor	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)),self);

MODULE = Gtk		PACKAGE = Gtk::Gdk::Pixmap	PREFIX = gdk_pixmap_

Gtk::Gdk::Pixmap
new(Class, window, width, height, depth)
	SV *	Class
	Gtk::Gdk::Window	window
	int	width
	int	height
	int	depth
	CODE:
	RETVAL = gdk_pixmap_new(window, width, height, depth);
	OUTPUT:
	RETVAL

Gtk::Gdk::Pixmap
create_from_data(Class, window, data, width, height, depth, fg, bg)
	SV *	Class
	Gtk::Gdk::Window	window
	SV *	data
	int	width
	int	height
	int	depth
	Gtk::Gdk::Color	fg
	Gtk::Gdk::Color	bg
	CODE:
	RETVAL = gdk_pixmap_create_from_data(window, SvPV(data,na), width, height, depth, fg, bg);
	OUTPUT:
	RETVAL

void
create_from_xpm(Class, window, transparent_color, filename)
	SV *	Class
	Gtk::Gdk::Window	window
	Gtk::Gdk::Color	transparent_color
	char *	filename
	PPCODE:
	{
		GdkPixmap * result = 0;
		GdkBitmap * mask = 0;
		result = gdk_pixmap_create_from_xpm(window, (GIMME == G_ARRAY) ? &mask : 0,
			transparent_color, filename); 
		if (result) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkPixmap(result)));
		}
		if (mask) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkBitmap(mask)));
		}
	}

void
create_from_xpm_d(Class, window, transparent_color, data, ...)
	SV *	Class
	Gtk::Gdk::Window	window
	Gtk::Gdk::Color	transparent_color
	SV *	data
	PPCODE:
	{
		GdkPixmap * result = 0;
		GdkBitmap * mask = 0;
		char ** lines = (char**)malloc(sizeof(char*)*(items-3));
		int i;
		for(i=3;i<items;i++)
			lines[i-3] = SvPV(ST(i),na);
		result = gdk_pixmap_create_from_xpm_d(window, (GIMME == G_ARRAY) ? &mask : 0,
			transparent_color, lines); 
		free(lines);
		if (result) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkPixmap(result)));
		}
		if (mask) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkBitmap(mask)));
		}
	}

MODULE = Gtk		PACKAGE = Gtk::Gdk::Image	PREFIX = gdk_image_

Gtk::Gdk::Image
new(Class, type, visual, width, height)
	SV *	Class
	Gtk::Gdk::ImageType	type
	Gtk::Gdk::Visual	visual
	int	width
	int	height
	CODE:
	RETVAL = gdk_image_new(type, visual, width, height);
	OUTPUT:
	RETVAL

Gtk::Gdk::Image
get(Class, window, x, y, width, height)
	SV *	Class
	Gtk::Gdk::Window	window
	int	x
	int	y
	int	width
	int	height
	CODE:
	RETVAL = gdk_image_get(window, x, y, width, height);
	OUTPUT:
	RETVAL

void
destroy(image)
	Gtk::Gdk::Image	image
	CODE:
	gdk_image_destroy(image);

void
gdk_image_put_pixel(image, x, y, pixel)
	Gtk::Gdk::Image	image
	int	x
	int	y
	int	pixel

int
gdk_image_get_pixel(image, x, y)
	Gtk::Gdk::Image	image
	int	x
	int	y

MODULE = Gtk		PACKAGE = Gtk::Gdk::Bitmap	PREFIX = gdk_bitmap_

Gtk::Gdk::Bitmap
create_from_data(Class, window, data, width, height)
	SV *	Class
	Gtk::Gdk::Window	window
	SV *	data
	int	width
	int	height
	CODE:
	RETVAL = gdk_bitmap_create_from_data(window, SvPV(data,na), width, height);
	OUTPUT:
	RETVAL

MODULE = Gtk		PACKAGE = Gtk::Gdk::GC	PREFIX = gdk_gc_

Gtk::Gdk::GC
new(Class, window, values=0)
	SV *	Class
	Gtk::Gdk::Window	window
	SV *	values
	CODE:
	if (items>2) {
		GdkGCValuesMask m;
		GdkGCValues * v = SvGdkGCValues(values, 0, &m);
		RETVAL = gdk_gc_new_with_values(window, v, m);
	}
	else
		RETVAL = gdk_gc_new(window);
	OUTPUT:
	RETVAL

Gtk::Gdk::GCValues
gdk_gc_get_values(self)
	Gtk::Gdk::GC	self
	CODE:
	{
		GdkGCValues values;
		gdk_gc_get_values(self, &values);
		RETVAL = &values;
	}

void
gdk_gc_set_foreground(gc, color)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Color	color

void
gdk_gc_set_background(gc, color)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Color	color

void
gdk_gc_set_font(gc, font)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Font	font

void
gdk_gc_set_function(gc, function)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Function	function

void
gdk_gc_set_fill(gc, fill)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Fill	fill

void
gdk_gc_set_tile(gc, tile)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Pixmap	tile

void
gdk_gc_set_stipple(gc, stipple)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Pixmap	stipple

void
gdk_gc_set_ts_origin(gc, x, y)
	Gtk::Gdk::GC	gc
	int	x
	int	y

void
gdk_gc_set_clip_origin(gc, x, y)
	Gtk::Gdk::GC	gc
	int	x
	int	y

void
gdk_gc_set_clip_mask(gc, mask)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::Bitmap	mask

void
gdk_gc_set_clip_rectangle (gc, rectangle)
	Gtk::Gdk::GC    gc
	Gtk::Gdk::Rectangle  rectangle

void
gdk_gc_set_clip_region (gc, region)
	Gtk::Gdk::GC      gc
	Gtk::Gdk::Region  region

void
gdk_gc_set_subwindow(gc, mode)
	Gtk::Gdk::GC	gc
	Gtk::Gdk::SubwindowMode	mode

void
gdk_gc_set_exposures(gc, exposures)
	Gtk::Gdk::GC	gc
	int	exposures

void
gdk_gc_set_line_attributes(gc, line_width, line_style, cap_style, join_style)
	Gtk::Gdk::GC	gc
	int	line_width
	Gtk::Gdk::LineStyle	line_style
	Gtk::Gdk::CapStyle	cap_style
	Gtk::Gdk::JoinStyle	join_style

void
destroy(self)
	Gtk::Gdk::GC	self
	CODE:
	gdk_gc_destroy(self);
	UnregisterMisc((HV*)SvRV(ST(0)),self);

void
DESTROY(self)
	Gtk::Gdk::GC	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)),self);

MODULE = Gtk		PACKAGE = Gtk::Gdk::Visual

Gtk::Gdk::Visual
system(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_visual_get_system();
	OUTPUT:
	RETVAL

int
best_depth(Class)
	SV *	Class
	CODE:
	RETVAL = gdk_visual_get_best_depth();
	OUTPUT:
	RETVAL

SV *
best_type(Class)
	SV *	Class
	CODE:
	RETVAL = newSVGdkVisualType(gdk_visual_get_best_type());
	OUTPUT:
	RETVAL

Gtk::Gdk::Visual
best(Class, depth=0, type=0)
	SV *	Class
	SV *	depth
	SV *	type
	CODE:
	{
		gint d;
		GdkVisualType t;

		if (depth && SvOK(depth))
			d = SvIV(depth);
		else
			depth = 0;

		if (type && SvOK(type))
			t = SvGdkVisualType(type);
		else
			type = 0;

		if (type) 
			if (depth)
				RETVAL = gdk_visual_get_best_with_both(d, t);
			else
				RETVAL = gdk_visual_get_best_with_type(t);
		else
			if (depth)
				RETVAL = gdk_visual_get_best_with_depth(d);
			else
				RETVAL = gdk_visual_get_best();
	}
	OUTPUT:
	RETVAL

void
depths(Class)
	SV *	Class
	PPCODE:
	{
		gint *depths;
		gint count;
		int i;
		gdk_query_depths(&depths, &count);
		for(i=0;i<count;i++) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSViv(depths[i])));
		}
	}

void
visual_types(Class)
	SV *	Class
	PPCODE:
	{
		GdkVisualType *types;
		gint count;
		int i;
		gdk_query_visual_types(&types, &count);
		for(i=0;i<count;i++) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkVisualType(types[i])));
		}
	}

void
visuals(Class)
	SV *	Class
	PPCODE:
	{
		GList *list, *tmp;
		list = gdk_list_visuals();
		tmp = list;
		while (tmp) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkVisual((GdkVisual*)tmp->data)));
			tmp = tmp->next;
		}
		g_list_free(list);
	}


MODULE = Gtk		PACKAGE = Gtk::Gdk::Font	PREFIX = gdk_font_

Gtk::Gdk::Font
load(Class, font_name)
	SV *	Class
	char *	font_name
	CODE:
	RETVAL = gdk_font_load(font_name);
	OUTPUT:
	RETVAL

Gtk::Gdk::Font
fontset_load(Class, fontset_name)
	SV *	Class
	char *	fontset_name
	CODE:
	RETVAL = gdk_fontset_load(fontset_name);
	OUTPUT:
	RETVAL

int
gdk_font_id(font)
	Gtk::Gdk::Font	font

void
gdk_font_ref(font)
	Gtk::Gdk::Font	font

bool
gdk_font_equal(fonta, fontb)
	Gtk::Gdk::Font	fonta
	Gtk::Gdk::Font	fontb

MODULE = Gtk		PACKAGE = Gtk::Gdk::Atom	PREFIX = gdk_atom_

Gtk::Gdk::Atom
gdk_atom_intern(Class, atom_name, only_if_exists)
	SV *	Class
	char *	atom_name
	int	only_if_exists
	CODE:
	RETVAL = gdk_atom_intern(atom_name, only_if_exists);
	OUTPUT:
	RETVAL

SV *
gdk_atom_name(Class, atom)
	SV *            Class
	Gtk::Gdk::Atom	atom
	CODE:
	{
		char *result = gdk_atom_name(atom);
		if (result) {
			RETVAL = newSVpv(result, 0);
			g_free (result);
		} else
			RETVAL = newSVsv(&sv_undef);
	}
	OUTPUT:
	RETVAL

MODULE = Gtk		PACKAGE = Gtk::Gdk::Property	PREFIX = gdk_property_

void
gdk_property_get(Class, window, property, type, offset, length, pdelete)
	SV *	Class
	Gtk::Gdk::Window	window
	Gtk::Gdk::Atom	property
	Gtk::Gdk::Atom	type
	int	offset
	int	length
	int	pdelete
	PPCODE:
	{
		guchar * data;
		GdkAtom actual_type;
		int actual_format, actual_length;
		int result = gdk_property_get(window, property, type, offset, length, pdelete, &actual_type, &actual_format, &actual_length, &data);
		if (result) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVpv(data,0)));
			if (GIMME == G_ARRAY) {
				EXTEND(sp,2);
				PUSHs(sv_2mortal(newSVGdkAtom(actual_type)));
				PUSHs(sv_2mortal(newSViv(actual_format)));
			}
			g_free(data);
		}
	}

void
gdk_property_delete(Class, window, property)
	SV *	Class
	Gtk::Gdk::Window	window
	Gtk::Gdk::Atom	property
	CODE:
	gdk_property_delete(window, property);

MODULE = Gtk		PACKAGE = Gtk::Gdk::Selection	PREFIX = gdk_selection_

Gtk::Gdk::Window
gdk_selection_owner_get(Class, selection)
	SV *	Class
	Gtk::Gdk::Atom	selection
	CODE:
	RETVAL = gdk_selection_owner_get(selection);
	OUTPUT:
	RETVAL

MODULE = Gtk		PACKAGE = Gtk::Gdk::Rectangle	PREFIX = gdk_rectangle_

void
gdk_rectangle_intersect(Class, src1, src2)
	SV *	Class
	Gtk::Gdk::Rectangle	src1
	Gtk::Gdk::Rectangle	src2
	PPCODE:
	{
		GdkRectangle dest;
		int result = gdk_rectangle_intersect(src1,src2,&dest);
		if (result) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkRectangle(&dest)));
		}
	}

MODULE = Gtk		PACKAGE = Gtk::Gdk::Event	PREFIX = gdk_event_

void
DESTROY(self)
	Gtk::Gdk::Event self
	CODE:
	gdk_event_free(self);
	/*printf("Freeing GdkEvent copyed to %d, HV %d\n", self, SvRV(ST(0)));*/

MODULE = Gtk		PACKAGE = Gtk::Gdk::Font	PREFIX = gdk_

int
gdk_string_width(font, string)
	Gtk::Gdk::Font	font
	char *	string

int
gdk_text_width(font, text, text_length)
	Gtk::Gdk::Font	font
	char *	text
	int	text_length

int
gdk_char_width(font, character)
	Gtk::Gdk::Font	font
	int	character

int
gdk_string_measure(font, string)
	Gtk::Gdk::Font	font
	char *	string

int
gdk_text_measure(font, text, text_length)
	Gtk::Gdk::Font	font
	char *	text
	int	text_length

int
gdk_char_measure(font, character)
	Gtk::Gdk::Font	font
	int	character

int
ascent(font)
	Gtk::Gdk::Font	font
	CODE:
	RETVAL = font->ascent;
	OUTPUT:
	RETVAL

int
descent(font)
	Gtk::Gdk::Font	font
	CODE:
	RETVAL = font->descent;
	OUTPUT:
	RETVAL

MODULE = Gtk		PACKAGE = Gtk::Gdk::Region		PREFIX = gdk_region_

Gtk::Gdk::Region
new(Class)
	SV * Class
	CODE:
	RETVAL = gdk_region_new();
	OUTPUT:
	RETVAL

void
gdk_region_destroy (self)
	Gtk::Gdk::Region self

bool
gdk_region_empty (self)
	Gtk::Gdk::Region self

bool
gdk_region_equal (region1, region2)
	Gtk::Gdk::Region region1
	Gtk::Gdk::Region region2

bool
gdk_region_point_in (self, x, y)
	Gtk::Gdk::Region self
	int x
	int y

Gtk::Gdk::OverlapType
gdk_region_rect_in (self, rectangle)
	Gtk::Gdk::Region self
	Gtk::Gdk::Rectangle rectangle

void
gdk_region_offset (self, dx, dy)
	Gtk::Gdk::Region self
	int dx
	int dy

void
gdk_region_shrink (self, dx, dy)
	Gtk::Gdk::Region self
	int dx
	int dy

Gtk::Gdk::Region
gdk_region_union_with_rect (self, rectangle)
	Gtk::Gdk::Region self
	Gtk::Gdk::Rectangle rectangle

Gtk::Gdk::Region
gdk_regions_intersect (self, region)
	Gtk::Gdk::Region self
	Gtk::Gdk::Region region

Gtk::Gdk::Region
gdk_regions_union (self, region)
	Gtk::Gdk::Region self
	Gtk::Gdk::Region region

Gtk::Gdk::Region
gdk_regions_subtract (self, region)
	Gtk::Gdk::Region self
	Gtk::Gdk::Region region

Gtk::Gdk::Region
gdk_regions_xor (self, region)
	Gtk::Gdk::Region self
	Gtk::Gdk::Region region


INCLUDE: boxed.xsh

INCLUDE: objects.xsh

INCLUDE: extension.xsh

BOOT:
{
}
