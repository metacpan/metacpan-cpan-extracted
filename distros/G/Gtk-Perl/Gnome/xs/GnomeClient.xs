
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


static void interaction_handler(GnomeClient * client, gint key, GnomeDialogType dialog_type, gpointer data)
{
	AV * args = (AV*)data;
    SV * handler = *av_fetch(args, 0, 0);
    int i;
    dSP;

    PUSHMARK(SP);
    for (i=1;i<=av_len(args);i++)
            XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));

    XPUSHs(sv_2mortal(newSViv(key)));
    XPUSHs(sv_2mortal(newSVGnomeDialogType(dialog_type)));
    PUTBACK;

    perl_call_sv(handler, G_DISCARD);

}

MODULE = Gnome::Client		PACKAGE = Gnome::Client		PREFIX = gnome_client_

#ifdef GNOME_CLIENT

Gnome::Client_Sink
master(Class)
	SV *	Class
	ALIAS:
		Gnome::Client::master = 0
		Gnome::Client::cloned = 1
		Gnome::Client::new = 2
		Gnome::Client::new_without_connection = 3
	CODE:
	switch (ix) {
	case 0: RETVAL = (GnomeClient*)(gnome_master_client()); break;
	case 1: RETVAL = (GnomeClient*)(gnome_cloned_client()); break;
	case 2: RETVAL = (GnomeClient*)(gnome_client_new()); break;
	case 3: RETVAL = (GnomeClient*)(gnome_client_new_without_connection()); break;
	}
	OUTPUT:
	RETVAL

void
gnome_client_connect(client)
	Gnome::Client	client
	ALIAS:
		Gnome::Client::connect = 0
		Gnome::Client::disconnect = 1
		Gnome::Client::request_phase_2 = 2
		Gnome::Client::flush = 3
	CODE:
	switch (ix) {
	case 0: gnome_client_connect(client); break;
	case 1: gnome_client_disconnect(client); break;
	case 2: gnome_client_request_phase_2(client); break;
	case 3: gnome_client_flush(client); break;
	}

void
gnome_client_set_id(client, value)
	Gnome::Client	client
	char *	value
	ALIAS:
		Gnome::Client::set_id = 0
		Gnome::Client::set_current_directory = 1
		Gnome::Client::set_program = 2
		Gnome::Client::set_user_id = 3
		Gnome::Client::set_global_config_prefix = 4
	CODE:
	switch (ix) {
	case 0: gnome_client_set_id(client, value); break;
	case 1: gnome_client_set_current_directory(client, value); break;
	case 2: gnome_client_set_program(client, value); break;
	case 3: gnome_client_set_user_id(client, value); break;
	case 4: gnome_client_set_global_config_prefix(client, value); break;
	}

char *
gnome_client_get_id(client)
	Gnome::Client	client
	ALIAS:
		Gnome::Client::get_id = 0
		Gnome::Client::get_previous_id = 1
		Gnome::Client::get_config_prefix = 2
		Gnome::Client::get_global_config_prefix = 3
	CODE:
	switch (ix) {
	case 0: RETVAL = gnome_client_get_id(client); break;
	case 1: RETVAL = gnome_client_get_previous_id(client); break;
	case 2: RETVAL = gnome_client_get_config_prefix(client); break;
	case 3: RETVAL = gnome_client_get_global_config_prefix(client); break;
	}
	OUTPUT:
	RETVAL

void
gnome_client_set_clone_command(client, ...)
	Gnome::Client	client
	ALIAS:
		Gnome::Client::set_clone_command = 0
		Gnome::Client::set_discard_command = 1
		Gnome::Client::set_restart_command = 2
		Gnome::Client::set_resign_command = 3
		Gnome::Client::set_shutdown_command = 4
	CODE:
	{
		char ** a = (char**)malloc(sizeof(char*) + items);
		int i;
		for(i=1;i<items;i++)
			a[i-1] = SvPV(ST(i), PL_na);
		a[i-1] = 0;
		switch (ix) {
		case 0: gnome_client_set_clone_command(client, items-1, a); break;
		case 1: gnome_client_set_discard_command(client, items-1, a); break;
		case 2: gnome_client_set_restart_command(client, items-1, a); break;
		case 3: gnome_client_set_resign_command(client, items-1, a); break;
		case 4: gnome_client_set_shutdown_command(client, items-1, a); break;
		}
		free(a);
	}

void
gnome_client_set_environment(client, name, value)
	Gnome::Client client
	char *name
	char *value

void
gnome_client_set_process_id(client, pid)
	Gnome::Client	client
	int	pid

void
gnome_client_set_restart_style(client, style)
	Gnome::Client	client
	Gnome::RestartStyle	style

void
gnome_client_save_any_dialog (client, dialog)
	Gnome::Client	client
	Gnome::Dialog	dialog

void
gnome_client_save_error_dialog (client, dialog)
	Gnome::Client	client
	Gnome::Dialog	dialog

void
gnome_client_set_priority (client, priority)
	Gnome::Client	client
	guint	priority

void
gnome_client_request_interaction(client, dialog, handler, ...)
	Gnome::Client	client
	Gnome::DialogType	dialog
	SV *	handler
	CODE:
	{
		AV * args = newAV();
		PackCallbackST(args, 2);
		gnome_client_request_interaction(client, dialog, interaction_handler, (gpointer)args);
	}

void
interaction_key_return(Class, key, cancel_shutdown)
	SV *	Class
	int	key
	int	cancel_shutdown
	CODE:
	gnome_interaction_key_return(key, cancel_shutdown);

void
gnome_client_request_save(client, save_style, shutdown, interact_style, fast, global)
	Gnome::Client	client
	Gnome::SaveStyle	save_style
	bool	shutdown
	Gnome::InteractStyle	interact_style
	bool	fast
	bool	global

void
gnome_client_disable_master_connection (Class)
	SV *	Class
	CODE:
	gnome_client_disable_master_connection ();


#endif

