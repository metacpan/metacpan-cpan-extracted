
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkMozEmbedInt.h"

#include "GtkMozEmbedDefs.h"
#include "GtkDefs.h"

static void
pgtk_mozembed_init () {
	static int inited = 0;
	if (inited)
		return;
	inited = 1;
	GtkMozEmbed_InstallObjects();
	GtkMozEmbed_InstallTypedefs();
}

MODULE = Gtk::MozEmbed		PACKAGE = Gtk::MozEmbed		PREFIX = gtk_moz_embed_

#ifdef GTK_MOZ_EMBED

Gtk::MozEmbed_Sink
gtk_moz_embed_new (Class)
	SV *	Class
	CODE:
	pgtk_mozembed_init ();
	RETVAL = (GtkMozEmbed*)(gtk_moz_embed_new ());
	OUTPUT:
	RETVAL

#if 0

void
gtk_moz_embed_set_profile_path (Class, aDir, aName)
	SV *	Class
	char *	aDir
	char *	aName
	CODE:
	gtk_moz_embed_set_profile_path (aDir, aName);
	
#endif
	
void
gtk_moz_embed_push_startup (Class)
	SV *	Class
	CODE:
	gtk_moz_embed_push_startup ();

void
gtk_moz_embed_pop_startup (Class)
	SV *	Class
	CODE:
	gtk_moz_embed_pop_startup ();

void
gtk_moz_embed_set_comp_path (Class, aPath)
	SV *	Class
	char *	aPath
	CODE:
	gtk_moz_embed_set_comp_path(aPath);

void
gtk_moz_embed_load_url (embed, url)
	Gtk::MozEmbed	embed
	char *	url

void
gtk_moz_embed_stop_load (embed)
	Gtk::MozEmbed	embed

bool
gtk_moz_embed_can_go_back (embed)
	Gtk::MozEmbed	embed

bool
gtk_moz_embed_can_go_forward (embed)
	Gtk::MozEmbed	embed

void
gtk_moz_embed_go_back (embed)
	Gtk::MozEmbed	embed

void
gtk_moz_embed_go_forward (embed)
	Gtk::MozEmbed	embed

void
gtk_moz_embed_render_data (embed, data, len, base_uri, mime_type)
	Gtk::MozEmbed	embed
	char *	data
	char *	base_uri
	char *	mime_type
	CODE:
	{
		STRLEN len;
		char * p = SvPV(data, len);
		gtk_moz_embed_render_data (embed, p, len,  base_uri, mime_type);
	}

void
gtk_moz_embed_open_stream (embed, base_uri, mime_type)
	Gtk::MozEmbed	embed
	char *	base_uri
	char *	mime_type

void
gtk_moz_embed_append_data (embed, data, len)
	Gtk::MozEmbed	embed
	char *	data
	guint	len
	CODE:
	{
		STRLEN len;
		char * p = SvPV(data, len);
		gtk_moz_embed_append_data (embed, p, len);
	}

void
gtk_moz_embed_close_stream (embed)
	Gtk::MozEmbed	embed

char *
gtk_moz_embed_get_link_message (embed)
	Gtk::MozEmbed	embed

char *
gtk_moz_embed_get_js_status (embed)
	Gtk::MozEmbed	embed

char *
gtk_moz_embed_get_title (embed)
	Gtk::MozEmbed	embed

char *
gtk_moz_embed_get_location (embed)
	Gtk::MozEmbed	embed

void
gtk_moz_embed_reload (embed, flags)
	Gtk::MozEmbed	embed
	int	flags

void
gtk_moz_embed_set_chrome_mask (embed, flags)
	Gtk::MozEmbed	embed
	guint	flags

guint
gtk_moz_embed_get_chrome_mask (embed)
	Gtk::MozEmbed	embed

MODULE = Gtk::MozEmbed		PACKAGE = Gtk::MozEmbed		PREFIX = mozilla_

bool
mozilla_preference_set (Class, preference_name, new_value)
	SV *	Class
	char *	preference_name
	char *	new_value
	CODE:
	RETVAL = mozilla_preference_set (preference_name, new_value);
	OUTPUT:
	RETVAL

bool
mozilla_preference_set_boolean (Class, preference_name, new_boolean_value)
	SV *	Class
	char *	preference_name
	bool	new_boolean_value
	CODE:
	RETVAL = mozilla_preference_set_boolean (preference_name, new_boolean_value);
	OUTPUT:
	RETVAL

bool
mozilla_preference_set_int (Class, preference_name, new_int_value)
	SV *	Class
	char *	preference_name
	int	new_int_value
	CODE:
	RETVAL = mozilla_preference_set_int (preference_name, new_int_value);
	OUTPUT:
	RETVAL

#endif

