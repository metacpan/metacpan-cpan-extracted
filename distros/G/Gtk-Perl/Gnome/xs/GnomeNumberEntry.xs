
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::NumberEntry		PACKAGE = Gnome::NumberEntry		PREFIX = gnome_number_entry_

#ifdef GNOME_NUMBER_ENTRY

Gnome::NumberEntry_Sink
new(Class, history_id, calc_dialog_title)
	SV *	Class
	char *	history_id
	char *	calc_dialog_title
	CODE:
	RETVAL = (GnomeNumberEntry*)(gnome_number_entry_new(history_id, calc_dialog_title));
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gnome_number_entry_gnome_entry(nentry)
	Gnome::NumberEntry	nentry

Gtk::Widget_Up
gnome_number_entry_gtk_entry(nentry)
	Gnome::NumberEntry	nentry

void
gnome_number_entry_set_title(nentry, calc_dialog_title)
	Gnome::NumberEntry	nentry
	char *	calc_dialog_title

gdouble
gnome_number_entry_get_number(nentry)
	Gnome::NumberEntry	nentry

#endif

