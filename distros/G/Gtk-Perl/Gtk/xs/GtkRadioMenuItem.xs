
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::RadioMenuItem		PACKAGE = Gtk::RadioMenuItem		PREFIX = gtk_menu_item_

#ifdef GTK_RADIO_MENU_ITEM

Gtk::RadioMenuItem_Sink
new(Class, label=0, previous=0)
	SV *	Class
	SV *	label
	Gtk::RadioMenuItem_OrNULL	previous
	ALIAS:
		Gtk::RadioMenuItem::new = 0
		Gtk::RadioMenuItem::new_with_label = 1
	CODE:
	{
		GSList * group = 0;
		if (previous)	
			group = gtk_radio_menu_item_group(previous);
		if (label && SvOK(label))
			RETVAL = (GtkRadioMenuItem*)(gtk_radio_menu_item_new_with_label(group, SvPV(label,PL_na)));
		else
			RETVAL = (GtkRadioMenuItem*)(gtk_radio_menu_item_new(group));
	}
	OUTPUT:
	RETVAL

void
group(radiomenuitem)
	Gtk::RadioMenuItem	radiomenuitem
	PPCODE:
	{
		GSList * group = 0;
		group = gtk_radio_menu_item_group(radiomenuitem);
		while(group) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkRadioMenuItem(group->data)));
			group=group->next;
		}
	}

#endif
