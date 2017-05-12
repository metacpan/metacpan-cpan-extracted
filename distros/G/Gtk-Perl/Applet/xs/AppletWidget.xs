
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"
#include "GnomeAppletDefs.h"
#include <applet-widget.h>

#define newSVGnomePanelOrientType newSVPanelOrientType

extern int pgtk_did_we_init_gnome;
int pgtk_did_we_init_panel = 0;

static void start_new_callback(const char * param, gpointer data)
{
        AV * args = (AV*)data;
        SV * handler = *av_fetch(args, 0, 0);
        int i;
        dSP;
        
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        for (i=1;i<=av_len(args);i++)
                XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
        if (param)
	        XPUSHs(sv_2mortal(newSVpv(param, 0)));
        PUTBACK;

        i = perl_call_sv(handler, G_DISCARD);

        FREETMPS;
        LEAVE;	
}

static void
applet_handler (AppletWidget *applet, gpointer data) {
	AV * args = (AV*)data;
	SV * handler = *av_fetch(args, 0, 0);
	int i;
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(applet), 0)));
	for (i=1;i<=av_len(args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
	PUTBACK;

	perl_call_sv(handler, G_DISCARD);

	FREETMPS;
	LEAVE;	
}

/* workaround bugs in applet widget signal code */
#define sp (*_sp)
static int fixup_signals(SV ** * _sp, int match, GtkObject * object, char * signame, int nparams, GtkArg * args, GtkType return_type)
{
	dTHR;
	if (match == 0) {
		args[0].type = GTK_TYPE_INT;
		args[1].type = GTK_TYPE_STRING;
		args[2].type = GTK_TYPE_GDK_COLOR;
	} else {
		args[0].type = GTK_TYPE_INT;
	}
	return 2;
}
static int fixup_status_u(SV ** * _sp, int match, GtkObject * object, char * signame, int nparams, GtkArg * args, GtkType return_type)
{
	dTHR;
	args[0].type = GTK_TYPE_WIDGET;
	return 2;
}
#undef sp

void AppletInit_internal(char * app_id, char *version, int panel)
{
		if (!pgtk_did_we_init_gdk && !pgtk_did_we_init_gtk && !pgtk_did_we_init_gnome && !pgtk_did_we_init_panel) {
			int argc;
			char ** argv = 0;
			AV * ARGV = perl_get_av("ARGV", FALSE);
			SV * ARGV0 = perl_get_sv("0", FALSE);
			int i;

			argc = av_len(ARGV)+2;
			if (argc) {
				argv = malloc(sizeof(char*)*argc);
				argv[0] = SvPV(ARGV0, PL_na);
				for(i=0;i<=av_len(ARGV);i++)
					argv[i+1] = SvPV(*av_fetch(ARGV, i, 0), PL_na);
			}

			i = argc;
			if (panel)
				applet_widget_init(app_id, version , argc, argv, NULL, 0, NULL);
			else
				gnome_capplet_init(app_id, version , argc, argv, NULL, 0, NULL);

			pgtk_did_we_init_gdk = 1;
			pgtk_did_we_init_gtk = 1;
			pgtk_did_we_init_gnome = 1;
			pgtk_did_we_init_panel = 1;

			while (i--)
				av_shift(ARGV);

			if (argv)
				free(argv);
				
			GtkInit_internal();

			Gnome_InstallTypedefs();
			Gnome_InstallObjects();
			GnomeApplet_InstallTypedefs();
			GnomeApplet_InstallObjects();

			{
				static char * names[] = {"back-change", "change-orient", 0};
				AddSignalHelperParts(applet_widget_get_type(), names, fixup_signals, 0);
			}
			{
				static char * names[] = {"build-plug", 0};
				AddSignalHelperParts(status_docklet_get_type(), names, fixup_status_u, 0);
			}
		}
}

static void     callXS (void (*subaddr)(CV* cv), CV *cv, SV **mark) 
{
	int items;
	dSP;
	PUSHMARK (mark);
	(*subaddr)(cv);

	PUTBACK;  /* Forget the return values */
}


MODULE = Gnome::AppletWidget		PACKAGE = Gnome::AppletWidget		PREFIX = applet_widget_

#ifdef APPLET_WIDGET

void
init(Class, app_id, version="")
	SV *    Class
	char *  app_id
	char *	version
	CODE:
	{
		AppletInit_internal(app_id, version, 1);
	}

Gnome::AppletWidget
new(Class, param=0)
	SV *	Class
	char *	param
	CODE:
	RETVAL = (AppletWidget*)(applet_widget_new(param));
	OUTPUT:
	RETVAL

void
applet_widget_set_tooltip(aw, tooltip)
	Gnome::AppletWidget	aw
	char *	tooltip

void
applet_widget_set_widget_tooltip(aw, widget, tooltip)
	Gnome::AppletWidget	aw
	Gtk::Widget	widget
	char *	tooltip

void
applet_widget_add(aw, widget)
	Gnome::AppletWidget	aw
	Gtk::Widget	widget

void
applet_widget_add_full (applet, widget, bind_events)
	Gnome::AppletWidget	applet
	Gtk::Widget	widget
	bool	bind_events

void
applet_widget_bind_events (applet, widget)
	Gnome::AppletWidget	applet
	Gtk::Widget	widget

void
applet_widget_remove(aw)
	Gnome::AppletWidget	aw

void
applet_widget_sync_config(aw)
	Gnome::AppletWidget	aw


void
applet_widget_register_callback (applet, name, menutext, handler, ...)
	Gnome::AppletWidget	applet
	char *	name
	char *	menutext
	SV *	handler
	CODE:
	{
		AV *args = newAV();
		PackCallbackST(args, 3);
		applet_widget_register_callback (applet, name, menutext, applet_handler, args);
	}

void
applet_widget_register_stock_callback (applet, name, stock_type, menutext, handler, ...)
	Gnome::AppletWidget	applet
	char *	name
	char *	stock_type
	char *	menutext
	SV *	handler
	CODE:
	{
		AV *args = newAV();
		PackCallbackST(args, 4);
		applet_widget_register_stock_callback (applet, name, stock_type, menutext, applet_handler, args);
	}

void
applet_widget_unregister_callback (applet, name)
	Gnome::AppletWidget	applet
	char *	name

void
applet_widget_register_callback_dir (applet, name, menutext)
	Gnome::AppletWidget	applet
	char *	name
	char *	menutext

void
applet_widget_register_stock_callback_dir (applet, name, stock_type, menutext)
	Gnome::AppletWidget	applet
	char *	name
	char *	stock_type
	char *	menutext

void
applet_widget_unregister_callback_dir (applet, name)
	Gnome::AppletWidget	applet
	char *	name

void
applet_widget_callback_set_sensitive (applet, name, sensitive)
	Gnome::AppletWidget	applet
	char *	name
	bool	sensitive

Gnome::Panel::OrientType
applet_widget_get_panel_orient(aw)
	Gnome::AppletWidget	aw

int
applet_widget_get_panel_pixel_size (applet)
	Gnome::AppletWidget	applet

int
applet_widget_get_free_space (applet)
	Gnome::AppletWidget	applet

void
applet_widget_send_position (applet, enable)
	Gnome::AppletWidget	applet
	bool	enable

void
applet_widget_send_draw (applet, enable)
	Gnome::AppletWidget	applet
	bool	enable

void
applet_widget_queue_resize (applet)
	Gnome::AppletWidget	applet

void
applet_widget_abort_load (applet)
	Gnome::AppletWidget	applet

char*
privcfgpath (applet)
	Gnome::AppletWidget	applet
	CODE:
	RETVAL = applet->privcfgpath;
	OUTPUT:
	RETVAL

char*
globcfgpath (applet)
	Gnome::AppletWidget	applet
	CODE:
	RETVAL = applet->globcfgpath;
	OUTPUT:
	RETVAL

int
applet_widget_get_applet_count(Class)
	CODE:
	RETVAL = applet_widget_get_applet_count();
	OUTPUT:
	RETVAL

void
applet_widget_gtk_main(Class)
	CODE:
	applet_widget_gtk_main();

void
applet_widget_gtk_main_quit(Class)
	CODE:
	applet_widget_gtk_main_quit();

#endif

