
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"

MODULE = Gnome::AppBar		PACKAGE = Gnome::AppBar		PREFIX = gnome_appbar_

#ifdef GNOME_APPBAR

Gnome::AppBar_Sink
new(Class, has_progress, has_status, interactivity)
	SV *	Class
	gboolean	has_progress
	gboolean	has_status
	Gnome::PreferencesType	interactivity
	CODE:
	RETVAL = (GnomeAppBar*)(gnome_appbar_new(has_progress, has_status, interactivity));
	OUTPUT:
	RETVAL

void
gnome_appbar_set_status(appbar, status)
	Gnome::AppBar	appbar
	char *	status

void
gnome_appbar_set_default(appbar, default_status)
	Gnome::AppBar	appbar
	char *	default_status

void
gnome_appbar_push(appbar, status)
	Gnome::AppBar	appbar
	char *	status

void
gnome_appbar_pop(appbar)
	Gnome::AppBar	appbar

void
gnome_appbar_clear_stack(appbar)
	Gnome::AppBar	appbar

void
gnome_appbar_set_progress(appbar, percentage)
	Gnome::AppBar	appbar
	gfloat	percentage

void
gnome_appbar_refresh(appbar)
	Gnome::AppBar	appbar


void
gnome_appbar_set_prompt(appbar, prompt, modal)
	Gnome::AppBar	appbar
	char *	prompt
	gboolean	modal

void
gnome_appbar_clear_prompt(appbar)
	Gnome::AppBar	appbar

void
gnome_appbar_get_response(appbar)
	Gnome::AppBar	appbar

#endif

