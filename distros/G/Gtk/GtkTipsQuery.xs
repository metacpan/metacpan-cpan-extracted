
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

MODULE = Gtk::TipsQuery		PACKAGE = Gtk::TipsQuery		PREFIX = gtk_tips_query_

#ifdef GTK_TIPS_QUERY

Gtk::TipsQuery
new(Class)
	SV * Class
	CODE:
	RETVAL = GTK_TIPS_QUERY(gtk_tips_query_new());
	OUTPUT:
	RETVAL

void
gtk_tips_query_start_query(self)
	Gtk::TipsQuery self

void
gtk_tips_query_stop_query(self)
	Gtk::TipsQuery self

void
gtk_tips_query_set_caller(self, caller)
	Gtk::TipsQuery self
	Gtk::Widget caller

void
gtk_tips_query_set_labels(self, label_inactive, label_no_tip)
	Gtk::TipsQuery self
	char* label_inactive
	char* label_no_tip

#endif

