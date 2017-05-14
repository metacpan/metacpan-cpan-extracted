
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

static void generic_perl_gtk_class_init(GtkObjectClass * klass)
{
	dSP;
	SV * perlClass;
	SV ** s = av_fetch(gtk_typecasts, klass->type, 0);
	
	if (s)
		perlClass = *s;
	else {
		fprintf(stderr, "Class is not registered\n");
		return;
	}
	PUSHMARK(sp);
	XPUSHs(sv_2mortal(newSVsv(perlClass)));
	PUTBACK;
	perl_call_method("class_init", G_DISCARD);

}

static void generic_perl_gtk_object_init(GtkObject * object)
{
	SV * s = newSVGtkObjectRef(object, 0);
	dSP;

	if (!s) {
		fprintf(stderr, "Object is not of registered type\n");
		return;
	}

	PUSHMARK(sp);
	XPUSHs(sv_2mortal(s));
	PUTBACK;
	perl_call_method("init", G_DISCARD);
	
}

static void generic_perl_gtk_arg_get_func(GtkObject * object, GtkArg * arg, guint arg_id)
{
	SV * s = newSVGtkObjectRef(object, 0);
	int count;
	dSP;

	if (!s) {
		fprintf(stderr, "Object is not of registered type\n");
		return;
	}

	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XPUSHs(sv_2mortal(s));
	XPUSHs(sv_2mortal(newSVpv(arg->name,0)));
	XPUSHs(sv_2mortal(newSViv(arg_id)));
	PUTBACK;
	count = perl_call_method("get_arg", G_SCALAR); 
	SPAGAIN;
	if (count != 1)
		croak("Big trouble\n");
	
	GtkSetArg(arg, POPs, s, object);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
}

static void generic_perl_gtk_arg_set_func(GtkObject * object, GtkArg * arg, guint arg_id)
{
	SV * s = newSVGtkObjectRef(object, 0);
	dSP;

	if (!s) {
		fprintf(stderr, "Object is not of registered type\n");
		return;
	}

	PUSHMARK(sp);
	XPUSHs(sv_2mortal(s));
	XPUSHs(sv_2mortal(newSVpv(arg->name,0)));	
	XPUSHs(sv_2mortal(newSViv(arg_id)));
	XPUSHs(sv_2mortal(GtkGetArg(arg)));
	PUTBACK;
	perl_call_method("set_arg", G_DISCARD); 
	/* Errors are OK ! */
	
}


MODULE = Gtk::Object		PACKAGE = Gtk::Object

#ifdef GTK_OBJECT

int
signal_connect(self, event, handler, ...)
	Gtk::Object	self
	char *	event
	SV *	handler
	CODE:
	{
		AV * args;
		SV * arg;
		int i,j;
		int type;
		args = newAV();
		
		type = gtk_signal_lookup(event, self->klass->type);
		
		i = gtk_signal_connect (GTK_OBJECT (self), event,
				NULL, (void*)args);
		/*i = gtk_signal_connect_interp(self, event, generic_handler, args, destroy_handler, 0);*/
				
		av_push(args, newRV(SvRV(ST(0))));
		av_push(args, newSVsv(ST(1)));
		av_push(args, newSVsv(ST(2)));
		av_push(args, newSViv(type));
		for (j=3;j<items;j++)
			av_push(args, newSVsv(ST(j)));
		
		RETVAL = i;
	}
	OUTPUT:
	RETVAL

int
signal_connect_after(self, event, handler, ...)
	Gtk::Object	self
	char *	event
	SV *	handler
	CODE:
	{
		AV * args;
		SV * arg;
		int i,j;
		int type;
		args = newAV();
		
		type = gtk_signal_lookup(event, self->klass->type);
		
		i = gtk_signal_connect_after (GTK_OBJECT (self), event,
				NULL, (void*)args);
		/*i = gtk_signal_connect_interp(self, event, generic_handler, args, destroy_handler, 1);*/
				
		av_push(args, newRV(SvRV(ST(0))));
		av_push(args, newSVsv(ST(1)));
		av_push(args, newSVsv(ST(2)));
		av_push(args, newSViv(type));
		for (j=3;j<items;j++)
			av_push(args, newSVsv(ST(j)));
		
		RETVAL = i;
	}
	OUTPUT:
	RETVAL

void
signal_disconnect(self, id)
	Gtk::Object	self
	int	id
	CODE:
	gtk_signal_disconnect(self, id);

void
signal_handlers_destroy(self)
	Gtk::Object	self
	CODE:
	gtk_signal_handlers_destroy(self);

SV *
get_user_data(object)
	Gtk::Object	object
	CODE:
	{
		int type = (int)gtk_object_get_data(object, "user_data_type_Perl");
		gpointer data = gtk_object_get_user_data(object);
		if (!data)
			RETVAL = newSVsv(&sv_undef);
		else {
			if (!type)
				croak("Unable to retrieve arbitrary user data");
			switch(type) {
			case 1:
				RETVAL = newSVGtkObjectRef((GtkObject*)data,0);
				break;
			default:
				croak("Unknown user data type");
			}
		}
	}
	OUTPUT:
	RETVAL

void
set_user_data(object, data)
	Gtk::Object	object
	SV *	data
	CODE:
	{
		if (!data || !SvOK(data)) {
			gtk_object_set_user_data(object, 0);
			gtk_object_set_data(object, "user_data_type_Perl", 0);
		} else {
			int type=0;
			gpointer ptr=0;
			if (SvRV(data)) {
				if (sv_derived_from(data, "Gtk::Object")) {
					type = 1;
					ptr = SvGtkObjectRef(data, 0);
				}
			}
			if (!type)
				croak("Unable to store user data of that type");
			gtk_object_set_user_data(object, ptr);
			gtk_object_set_data(object, "user_data_type_Perl", (gpointer)type);
		}
	}

void
DESTROY(self)
	SV *	self
	CODE:
	disconnect_GtkObjectRef(ST(0));

SV *
set(self, name, value, ...)
	Gtk::Object	self
	SV *	name
	SV *	value
	CODE:
	{
		GtkType t;
		GtkArg	argv[3];
		int p;
		int argc;
		RETVAL = newSVsv(ST(0));
		
		for(p=1;p<items;) {
		
			if ((p+1)>=items)
				croak("too few arguments");

			argv[0].name = SvPV(ST(p),na);
			t = gtk_object_get_arg_type(argv[0].name);
			argv[0].type = t;
			value = ST(p+1);
		
			argc = 1;
			
			GtkSetArg(&argv[0], value, ST(0), self);

			gtk_object_setv(self, argc, argv);
			p += 1 + argc;
		}
	}
	OUTPUT:
	RETVAL

void
get(self, name, ...)
	Gtk::Object	self
	SV *	name
	PPCODE:
	{
		GtkType t;
		GtkArg	argv[3];
		int p;
		int argc;
		
		for(p=1;p<items;) {
		
			argv[0].name = SvPV(ST(p),na);
			t = gtk_object_get_arg_type(argv[0].name);
			argv[0].type = t;
		
			argc = 1;
			
			gtk_object_getv(self, argc, argv);
			
			EXTEND(sp,1);
			PUSHs(sv_2mortal(GtkGetArg(&argv[0])));
			
			if (t == GTK_TYPE_STRING)
				g_free(GTK_VALUE_STRING(argv[0]));
			
			p++;
		}
	}

SV *
new(klass, ...)
	SV *	klass
	CODE:
	{
		GtkType t;
		GtkArg	argv[3];
		int p;
		int argc;
		
		int type = type_name(SvPV(klass, na));
		
		GtkObject *	object = gtk_object_new(type, NULL);
		
		RETVAL = newSVGtkObjectRef(object, SvPV(klass, na));
		
		for(p=1;p<items;) {
		
			if ((p+1)>=items)
				croak("too few arguments");

			argv[0].name = SvPV(ST(p),na);
			t = gtk_object_get_arg_type(argv[0].name);
			argv[0].type = t;
		
			argc = 1;
			
			GtkSetArg(&argv[0], ST(p+1), RETVAL, object);

			gtk_object_setv(object, argc, argv);
			p += 1 + argc;
		}
	}
	OUTPUT:
	RETVAL

void
add_arg_type(Class, name, type, flags, num=1)
	SV *	Class
	SV *	name
	char *	type
	int     flags
	int	num
	CODE:
	{
		SV * name2 = name;
		int typeval;
		char * typename = gtk_type_name(type_name(SvPV(Class,na)));
		if (strncmp(SvPV(name2,na), typename, strlen(typename)) != 0) {
			/* Not prefixed with typename */
			name2 = sv_2mortal(newSVpv(typename, 0));
			sv_catpv(name2, "::");
			sv_catsv(name2, name);
		}
		if (!(typeval = type_name(type))) {
			typeval = gtk_type_from_name(type);
		}
		gtk_object_add_arg_type(SvPV(name2,na), typeval, flags, num);
	}

void
signal_new(Class, name, run_type)
	SV *	Class
	SV *	name
	Gtk::SignalRunType	run_type
	CODE:
	{
		SV * temp;
		SV * s;
		int sig, signals, type, sigtype;
		
		temp = newSVsv(Class);
		sv_catpv(temp, "::_signal");
		
		s = perl_get_sv(SvPV(temp, na), TRUE);
		sig = SvIV(s);

		sv_setsv(temp, Class);
		sv_catpv(temp, "::_signals");
		
		s = perl_get_sv(SvPV(temp, na), TRUE);
		signals = SvIV(s);
		
		
		if ((sig < 0) || (sig >= signals))
			croak("Cannot set signals (ran out of signals, or damaged $%s::_signal(s).", SvPV(Class, na));
			
		type = type_name(SvPV(Class,na));

		gtk_signal_new(SvPV(newSVsv(Class),na), run_type, type, sig * sizeof(GtkSignalFunc), gtk_signal_default_marshaller, GTK_TYPE_NONE, 0);

		printf("Installing signal %d, called %s, as run type %d\n", sig, SvPV(name,na), run_type);
		/*sigtype = gtk_signal_new(SvPV(newSVsv(name),na), run_type, type, gtk_type_class(type) + sig * sizeof(GtkSignalFunc), gtk_signal_default_marshaller, GTK_TYPE_NONE, 0);
		
		gtk_object_class_add_signals(gtk_type_class(type), &sigtype, 1);*/
		
		
		
		sig++;
		
		sv_setsv(temp, Class);
		sv_catpv(temp, "::_signal");
		
		s = perl_get_sv(SvPV(temp, na), TRUE);
		sv_setiv(s, sig);

		SvREFCNT_dec(temp);

	}

void
signal_emit(self, name)
	Gtk::Object	self
	SV *	name
	CODE:
	{
		gtk_signal_emit_by_name(self, SvPV(name,na), NULL);
	}
	

int
register_type(perlClass, signals=0, gtkName=0, parentClass=0)
	SV *	perlClass
	int	signals
	SV *	gtkName
	SV *	parentClass
	CODE:
	{
		dSP;
		int count;
		int parent_type;
		GtkTypeInfo info;
		SV * temp;
		SV * s;
		
		if (!gtkName) {
			int i;
			char *d, *s;
			gtkName = sv_2mortal(newSVsv(perlClass));
			d = s = SvPV(gtkName,na);
			do {
				if (*s == ':')
					continue;
				*d++ = *s++;
			} while(*s);
		}
		
		if (!parentClass) {
			parentClass = perlClass;
		}
		
		info.type_name = SvPV(newSVsv(gtkName), na); /* Yes, this leaks until interpreter cleanup */
		
		ENTER;
		SAVETMPS;
		
		PUSHMARK(sp);
		XPUSHs(sv_2mortal(newSVsv(parentClass)));
		PUTBACK;
		count = perl_call_method("get_type", G_SCALAR);
		SPAGAIN;
		if (count != 1)
			croak("Big trouble\n");
		
		parent_type = POPi;
		
		PUTBACK;
		FREETMPS;
		LEAVE;
		
		
		ENTER;
		SAVETMPS;
		
		PUSHMARK(sp);
		XPUSHs(sv_2mortal(newSVsv(parentClass)));
		PUTBACK;
		count = perl_call_method("get_size", G_SCALAR);
		SPAGAIN;
		if (count != 1)
			croak("Big trouble\n");
		
		info.object_size = POPi+sizeof(SV*);
		
		PUTBACK;
		FREETMPS;
		LEAVE;
		
		ENTER;
		SAVETMPS;
		
		PUSHMARK(sp);
		XPUSHs(sv_2mortal(newSVsv(parentClass)));
		PUTBACK;
		count = perl_call_method("get_class_size", G_SCALAR);
		SPAGAIN;
		if (count != 1)
			croak("Big trouble\n");
		
		info.class_size = POPi;
		
		PUTBACK;
		FREETMPS;
		LEAVE;

		temp = newSVsv(perlClass);
		sv_catpv(temp, "::_signals");
		
		s = perl_get_sv(SvPV(temp, na), TRUE);
		sv_setiv(s, signals);
		
		sv_setsv(temp, perlClass);
		sv_catpv(temp, "::_signal");
		
		s = perl_get_sv(SvPV(temp, na), TRUE);
		sv_setiv(s, 0);

		sv_setsv(temp, perlClass);
		sv_catpv(temp, "::_signalbase");
		
		s = perl_get_sv(SvPV(temp, na), TRUE);
		sv_setiv(s, info.class_size);
		
		SvREFCNT_dec(temp);

		info.class_size += sizeof(GtkSignalFunc) * signals;
		
		info.class_init_func = (GtkClassInitFunc)generic_perl_gtk_class_init;
		info.object_init_func = (GtkObjectInitFunc)generic_perl_gtk_object_init;
		info.arg_set_func = (GtkArgSetFunc)generic_perl_gtk_arg_set_func;
		info.arg_get_func = (GtkArgSetFunc)generic_perl_gtk_arg_get_func;
		
		RETVAL = gtk_type_unique(parent_type, &info);
		
		add_typecast(RETVAL, SvPV(perlClass,na));
		
	}
	OUTPUT:
	RETVAL



void
destroy(self)
	Gtk::Object	self
	CODE:
	gtk_object_destroy(self);
	disconnect_GtkObjectRef(ST(0));

#endif
