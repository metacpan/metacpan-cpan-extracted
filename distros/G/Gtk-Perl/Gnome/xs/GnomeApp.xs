
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"

/* XXX Add dock, etc */

#define fill_uiinfo(index, count, infos) \
		count = items - index; \
		infos = pgtk_alloc_temp(sizeof(GnomeUIInfo) * (count+1)); \
		memset(infos, 0, sizeof(GnomeUIInfo) * (count+1)); \
		/* Because we accept a list rather than an array, we \
                   have to unroll the outer layer of recursion */ \
		for (i = 0; i < count; i++) { \
			SvGnomeUIInfo(ST(i+index), infos + i); \
		} \
		infos[count].type = GNOME_APP_UI_ENDOFINFO; \


#define refill_uiinfo(index, count, infos) \
		count = items - index; \
		for (i = 0; i < count; i++) { \
			refill_one (ST(i+index),  &infos[i]); \
		} \


static void
refill_one (SV *data, GnomeUIInfo *info) {

	if (info->widget) {
		if (SvTYPE(SvRV(data)) == SVt_PVHV) {
			hv_store ((HV*)SvRV(data), "widget", 6, newSVGtkObjectRef(GTK_OBJECT(info->widget), 0), 0);
		} else {
			/* Always on the last psoition */
			int pos = av_len((AV*)SvRV(data)) + 1;
			av_store ((AV*)SvRV(data), pos, newSVGtkObjectRef(GTK_OBJECT(info->widget), 0));
		}
	}
	switch (info->type) {
	case GNOME_APP_UI_SUBTREE:
	case GNOME_APP_UI_SUBTREE_STOCK:
	case GNOME_APP_UI_RADIOITEMS:
	{
		int i, count;
		GnomeUIInfo *subtree = info->moreinfo;
		AV* a = (AV*)SvRV((SV*)info->user_data);
		count = av_len(a) + 1;
		for (i = 0; i < count; i++) {
			SV** s = av_fetch(a, i, 0);
			refill_one (*s, subtree + i);
		}
	}
	default:
		break;
	}
}

static void
string_callback (gchar * string, gpointer data) {
	SV * handler;
	AV *stuff = (AV*)data;
	int i;
	dSP;

	handler = *av_fetch(stuff, 0, 0);

	ENTER;
	SAVETMPS;
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(string, 0)));
	for (i=1;i<=av_len(stuff);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(stuff, i, 0))));
	PUTBACK;
	perl_call_sv(handler, G_DISCARD);
	FREETMPS;
	LEAVE;
}

static void
reply_callback (gint reply, gpointer data) {
	SV * handler;
	AV *stuff = (AV*)data;
	int i;
	dSP;

	handler = *av_fetch(stuff, 0, 0);

	ENTER;
	SAVETMPS;
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSViv(reply)));
	for (i=1;i<=av_len(stuff);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(stuff, i, 0))));
	PUTBACK;
	perl_call_sv(handler, G_DISCARD);
	FREETMPS;
	LEAVE;
}


MODULE = Gnome::App		PACKAGE = Gnome::App		PREFIX = gnome_app_

#ifdef GNOME_APP

Gnome::App_Sink
new(Class, appname, title)
	SV *	Class
	char *	appname
	char *	title
	CODE:
	RETVAL = (GnomeApp*)(gnome_app_new(appname, title));
	OUTPUT:
	RETVAL

void
gnome_app_set_menus(app, menubar)
	Gnome::App	app
	Gtk::MenuBar	menubar

void
gnome_app_create_menus(app, info, ...)
	Gnome::App	app
	ALIAS:
		Gnome::App::create_toolbar = 1
	CODE:
	{
		int i, count;
		GnomeUIInfo *infos;

		fill_uiinfo(1, count, infos);
		if (ix == 1)
			gnome_app_create_toolbar(app, infos);
		else
			gnome_app_create_menus(app, infos);
		refill_uiinfo(1, count, infos);
	}


void
gnome_app_fill_menu (Class, menu_shell, uiinfo, accel_group, uline_accels, pos, ...)
	SV *	Class
	Gtk::MenuShell	menu_shell
	Gtk::AccelGroup_OrNULL	accel_group
	bool	uline_accels
	int	pos
	CODE:
	{
		int i, count;
		GnomeUIInfo *infos;

		fill_uiinfo(6, count, infos);
		gnome_app_fill_menu (menu_shell, infos, accel_group, uline_accels, pos);
		refill_uiinfo(6, count, infos);
	}

void
gnome_app_fill_toolbar (Class, toolbar, accel_group, ...)
	SV *	Class
	Gtk::Toolbar	toolbar
	Gtk::AccelGroup_OrNULL	accel_group
	CODE:
	{
		int i, count;
		GnomeUIInfo *infos;

		fill_uiinfo(3, count, infos);
		gnome_app_fill_toolbar (toolbar, infos, accel_group);
		refill_uiinfo(3, count, infos);
	}

void
gnome_app_set_toolbar(app, toolbar)
	Gnome::App	app
	Gtk::Toolbar	toolbar

void
gnome_app_set_statusbar(app, contents)
	Gnome::App	app
	Gtk::Widget	contents

void
gnome_app_set_contents(app, contents)
	Gnome::App	app
	Gtk::Widget	contents

void
gnome_app_set_statusbar_custom(app, container, statusbar)
	Gnome::App	app
	Gtk::Widget	container
	Gtk::Widget	statusbar

void
gnome_app_add_toolbar(app, toolbar, name, behavior, placement, band_num, band_position, offset)
	Gnome::App	app
	Gtk::Toolbar	toolbar
	char*	name
	Gnome::DockItemBehavior	behavior
	Gnome::DockPlacement	placement
	int	band_num
	int	band_position
	int	offset

void
gnome_app_add_docked(app, widget, name, behavior, placement, band_num, band_position, offset)
	Gnome::App	app
	Gtk::Widget	widget
	char*	name
	Gnome::DockItemBehavior	behavior
	Gnome::DockPlacement	placement
	int	band_num
	int	band_position
	int	offset

void
gnome_app_add_dock_item(app, item, placement, band_num, band_position, offset)
	Gnome::App	app
	Gnome::DockItem	item
	Gnome::DockPlacement	placement
	int	band_num
	int	band_position
	int	offset

void
gnome_app_enable_layout_config(app, enable)
	Gnome::App	app
	bool	enable

Gnome::Dock
gnome_app_get_dock(app)
	Gnome::App	app

Gnome::DockItem
gnome_app_get_dock_item_by_name(app, name)
	Gnome::App	app
	char*	name


void
gnome_app_flash (app, flash)
	Gnome::App	app
	char *	flash

Gtk::Widget_Up
gnome_app_message (app, message)
	Gnome::App	app
	char *	message
	ALIAS:
		Gnome::App::message = 0
		Gnome::App::error = 1
		Gnome::App::warning = 2
	CODE:
	switch (ix) {
	case 0: RETVAL = gnome_app_message (app, message); break;
	case 1: RETVAL = gnome_app_error (app, message); break;
	case 2: RETVAL = gnome_app_warning (app, message); break;
	}
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gnome_app_question (app, question, callback, ...)
	Gnome::App	app
	char *	question
	SV *	callback
	ALIAS:
		Gnome::App::question = 0
		Gnome::App::question_modal = 1
		Gnome::App::ok_cancel = 2
		Gnome::App::ok_cancel_modal = 3
	CODE:
	{
		AV * args = newAV();
		PackCallbackST(args, 2);
		switch (ix) {
		case 0: RETVAL = gnome_app_question (app, question, reply_callback, args); break;
		case 1: RETVAL = gnome_app_question_modal (app, question, reply_callback, args); break;
		case 2: RETVAL = gnome_app_ok_cancel (app, question, reply_callback, args); break;
		case 3: RETVAL = gnome_app_ok_cancel_modal (app, question, reply_callback, args); break;
		}
	}
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gnome_app_request_string (app, prompt, callback, ...)
	Gnome::App	app
	char *	prompt
	SV *	callback
	ALIAS:
		Gnome::App::request_string = 0
		Gnome::App::request_password = 1
	CODE:
	{
		AV * args = newAV();
		PackCallbackST(args, 2);
		if (ix == 0)
			RETVAL = gnome_app_request_string (app, prompt, string_callback, args);
		else if (ix == 1)
			RETVAL = gnome_app_request_password (app, prompt, string_callback, args);
	}
	OUTPUT:
	RETVAL

void
gnome_app_remove_menus (app, path, items)
	Gnome::App	app
	char *	path
	int	items

void
gnome_app_remove_menu_range (app, path, start, items)
	Gnome::App	app
	char *	path
	int	start
	int	items

#endif

MODULE = Gnome::App		PACKAGE = Gnome::DialogUtil PREFIX = gnome_

Gtk::Widget_Up
gnome_question_dialog (Class, message, handler, ...)
	SV *	Class
	char *	message
	SV *	handler
	ALIAS:
		Gnome::DialogUtil::question_dialog = 0
		Gnome::DialogUtil::question_dialog_modal = 1
		Gnome::DialogUtil::ok_cancel_dialog = 2
		Gnome::DialogUtil::ok_cancel_dialog_modal = 3
	CODE:
	{
		AV * args = newAV();
		PackCallbackST(args, 2);
		switch (ix) {
		case 0: RETVAL = gnome_question_dialog (message, reply_callback, args); break;
		case 1: RETVAL = gnome_question_dialog_modal (message, reply_callback, args); break;
		case 2: RETVAL = gnome_ok_cancel_dialog (message, reply_callback, args); break;
		case 3: RETVAL = gnome_ok_cancel_dialog_modal (message, reply_callback, args); break;
		}
	}
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gnome_question_dialog_parented (Class, message, parent, handler, ...)
	SV *	Class
	char *	message
	Gtk::Window	parent
	SV *	handler
	ALIAS:
		Gnome::DialogUtil::question_dialog_parented = 0
		Gnome::DialogUtil::question_dialog_modal_parented = 1
		Gnome::DialogUtil::ok_cancel_dialog_parented = 2
		Gnome::DialogUtil::ok_cancel_dialog_modal_parented = 3
	CODE:
	{
		AV * args = newAV();
		PackCallbackST(args, 3);
		switch (ix) {
		case 0: RETVAL = gnome_question_dialog_parented (message, reply_callback, args, parent); break;
		case 1: RETVAL = gnome_question_dialog_modal_parented (message, reply_callback, args, parent); break;
		case 2: RETVAL = gnome_ok_cancel_dialog_parented (message, reply_callback, args, parent); break;
		case 3: RETVAL = gnome_ok_cancel_dialog_modal_parented (message, reply_callback, args, parent); break;
		}
	}
	OUTPUT:
	RETVAL

