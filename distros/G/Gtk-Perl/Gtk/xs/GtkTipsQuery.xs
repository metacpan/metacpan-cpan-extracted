
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::TipsQuery		PACKAGE = Gtk::TipsQuery		PREFIX = gtk_tips_query_

#ifdef GTK_TIPS_QUERY

Gtk::TipsQuery_Sink
new(Class)
	SV * Class
	CODE:
	RETVAL = (GtkTipsQuery*)(gtk_tips_query_new());
	OUTPUT:
	RETVAL

void
gtk_tips_query_start_query(tips_query)
	Gtk::TipsQuery tips_query

void
gtk_tips_query_stop_query(tips_query)
	Gtk::TipsQuery tips_query

void
gtk_tips_query_set_caller(tips_query, caller)
	Gtk::TipsQuery tips_query
	Gtk::Widget caller

void
gtk_tips_query_set_labels(tips_query, label_inactive, label_no_tip)
	Gtk::TipsQuery tips_query
	char* label_inactive
	char* label_no_tip

#endif

