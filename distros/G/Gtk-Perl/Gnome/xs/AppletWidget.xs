
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"
#include <applet-widget.h>

extern int did_we_init_gnome;
int did_we_init_panel = 0;

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

void AppletInit_internal(char * app_id, AV * args)
{
		if (!did_we_init_gdk && !did_we_init_gtk && !did_we_init_gnome && !did_we_init_panel) {
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
			applet_widget_init(app_id, NULL , argc, argv, NULL, 0, NULL);

			did_we_init_gdk = 1;
			did_we_init_gtk = 1;
			did_we_init_gnome = 1;
			did_we_init_panel = 1;

			while (i--)
				av_shift(ARGV);

			if (argv)
				free(argv);
				
			GtkInit_internal();

			Gnome_InstallTypedefs();

			Gnome_InstallObjects();


		}
}



MODULE = Gnome::Panel::AppletWidget		PACKAGE = Gnome::Panel::AppletWidget		PREFIX = applet_widget_

#ifdef APPLET_WIDGET

void
init(Class, app_id, start_func=0, ...)
	SV *    Class
	char *  app_id
	SV *	start_func
	CODE:
	{
		AV * args = 0;
		
		if (start_func) {
			args = newAV();
			PackCallbackST(args, 2);
		}
		AppletInit_internal(app_id, args);
	}

Gnome::Panel::AppletWidget
new(Class, param=0)
	SV *	Class
	char *	param
	CODE:
	RETVAL = (AppletWidget*)(applet_widget_new(param));
	OUTPUT:
	RETVAL

void
applet_widget_set_tooltip(aw, tooltip)
	Gnome::Panel::AppletWidget	aw
	char *	tooltip

void
applet_widget_set_widget_tooltip(aw, widget, tooltip)
	Gnome::Panel::AppletWidget	aw
	Gtk::Widget	widget
	char *	tooltip

void
applet_widget_add(aw, widget)
	Gnome::Panel::AppletWidget	aw
	Gtk::Widget	widget

#if 0

void
applet_widget_remove_from_panel(aw)
	Gnome::Panel::AppletWidget	aw

#endif

void
applet_widget_sync_config(aw)
	Gnome::Panel::AppletWidget	aw

#if 0

Gnome::Panel::OrientType
applet_widget_get_panel_orient(aw)
	Gnome::Panel::AppletWidget	aw

#endif

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

#endif

