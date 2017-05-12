#include "sexyperl.h"

MODULE = Gtk2::Sexy::UrlLabel	PACKAGE = Gtk2::Sexy::UrlLabel	PREFIX = sexy_url_label_

PROTOTYPES: disable

GtkWidget *
sexy_url_label_new (class);
	C_ARGS:

void
sexy_url_label_set_markup (url_label, markup)
		SexyUrlLabel *url_label
		const gchar *markup
