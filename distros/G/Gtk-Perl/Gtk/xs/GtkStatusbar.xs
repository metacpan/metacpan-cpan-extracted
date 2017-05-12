
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Statusbar		PACKAGE = Gtk::Statusbar		PREFIX = gtk_statusbar_

#ifdef GTK_STATUSBAR

Gtk::Statusbar_Sink
new(Class)
	CODE:
	RETVAL = (GtkStatusbar*)(gtk_statusbar_new());
	OUTPUT:
	RETVAL

int
gtk_statusbar_get_context_id(statusbar, context_description)
	Gtk::Statusbar statusbar
	char* context_description

int
gtk_statusbar_push(statusbar, context_id, text)
	Gtk::Statusbar statusbar
	int context_id
	char* text

void
gtk_statusbar_pop(statusbar, context_id)
	Gtk::Statusbar statusbar
	int context_id

void
gtk_statusbar_remove(statusbar, context_id, message_id)
	Gtk::Statusbar statusbar
	int context_id
	int message_id

void
gtk_statusbar_messages(statusbar)
	Gtk::Statusbar	statusbar
	PPCODE:
	{
		GSList * list;
		for (list = statusbar->messages; list; list = list->next) {
			HV * hv = newHV();
			GtkStatusbarMsg * msg = (GtkStatusbarMsg*)list->data;
			
			EXTEND(sp, 1);
			
			hv_store(hv, "text", 4, newSVpv(msg->text, 0), 0);
			hv_store(hv, "context_id", 10, newSViv(msg->context_id), 0);
			hv_store(hv, "message_id", 10, newSViv(msg->message_id), 0);
			
			PUSHs(sv_2mortal(newRV_inc((SV*)hv)));
			SvREFCNT_dec(hv);
		}
	}

Gtk::Widget_Up
frame(statusbar)
	Gtk::Statusbar statusbar
	ALIAS:
		Gtk::Statusbar::frame = 0
		Gtk::Statusbar::label = 1
	CODE:
	if (ix == 0)
		RETVAL = statusbar->frame;
	else if (ix == 1)
		RETVAL = statusbar->label;
	OUTPUT:
	RETVAL

#endif

