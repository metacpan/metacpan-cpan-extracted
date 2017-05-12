
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Dialog		PACKAGE = Gnome::Dialog		PREFIX = gnome_dialog_

#ifdef GNOME_DIALOG

Gnome::Dialog_Sink
new(Class, title, ...)
	SV *	Class
	char *	title
	CODE:
	{
		int count = items-2;
		const char ** b = malloc(sizeof(char*) * (count+1));
		int i;
		
		for(i=0;i<count;i++)
			b[i] = SvPV(ST(i+2), PL_na);
		b[i] = 0;
#if GNOME_HVER >= 0x010200
		RETVAL = (GnomeDialog*)(gnome_dialog_newv(title, b));
#else
		/* I don't think this is right... */
		RETVAL = (GnomeDialog*)(gnome_dialog_new(title, b));
#endif
		free(b);
	}
	OUTPUT:
	RETVAL

void
gnome_dialog_set_parent(dialog, parent)
	Gnome::Dialog	dialog
	Gtk::Window	parent

#if 0

void
gnome_dialog_set_modal(dialog)
	Gnome::Dialog	dialog

#endif

int
gnome_dialog_run(dialog)
	Gnome::Dialog	dialog

int
gnome_dialog_run_and_close(dialog)
	Gnome::Dialog	dialog

#if 0

int
gnome_dialog_run_modal(dialog)
	Gnome::Dialog	dialog


int
gnome_dialog_run_and_hide(dialog)
	Gnome::Dialog	dialog

int
gnome_dialog_run_and_destroy(dialog)
	Gnome::Dialog	dialog

#endif

void
gnome_dialog_set_default(dialog, button)
	Gnome::Dialog	dialog
	int	button

void
gnome_dialog_set_sensitive(dialog, button, setting=1)
	Gnome::Dialog	dialog
	gint	button
	gboolean	setting

void
gnome_dialog_set_accelerator (dialog, button, key, mods)
	Gnome::Dialog	dialog
	int	button
	unsigned char	key
	Gtk::Gdk::ModifierType	mods

void
gnome_dialog_close(dialog)
	Gnome::Dialog	dialog

void
gnome_dialog_close_hides(dialog, just_hide=1)
	Gnome::Dialog	dialog
	gboolean	just_hide

void
gnome_dialog_set_close(dialog, click_closes=1)
	Gnome::Dialog	dialog
	gboolean	click_closes

void
gnome_dialog_editable_enters(dialog, editable)
	Gnome::Dialog	dialog
	Gtk::Editable	editable

Gtk::Widget_Up
vbox(dialog)
	Gnome::Dialog dialog
	CODE:
	RETVAL = GTK_WIDGET(dialog->vbox);
	OUTPUT:
	RETVAL

void
gnome_dialog_append_button (dialog, name)
	Gnome::Dialog dialog
	char *	name

void
gnome_dialog_append_buttons (dialog, first, ...)
	Gnome::Dialog	dialog
	SV *	first
	CODE:
	{
		int count = items-1;
		const char ** b = malloc(sizeof(char*) * (count+1));
		int i;
		
		for(i=0;i<count;i++)
			b[i] = SvPV(ST(i+1), PL_na);
		b[i] = 0;
		gnome_dialog_append_buttonsv(dialog, b);
		free(b);
	}

void
gnome_dialog_append_button_with_pixmap (dialog, name, pixmap)
	Gnome::Dialog dialog
	char *	name
	char *	pixmap

void
gnome_dialog_append_buttons_with_pixmaps (dialog, first_name, first_pixmap, ...)
	Gnome::Dialog	dialog
	SV *	first_name
	SV *	first_pixmap
	CODE:
	{
		int count = items-1;
		const char ** b;
		const char ** p;
		int i;
		
		if (count % 2)
			croak("need an even number of buttons and pixmaps");
		count /= 2;
		b = malloc(sizeof(char*) * (count+1));
		p = malloc(sizeof(char*) * (count+1));
		for(i=0;i<count;i+=2) {
			b[i] = SvPV(ST(i+1), PL_na);
			p[i] = SvPV(ST(i+2), PL_na);
		}
		b[i] = 0;
		p[i] = 0;
		gnome_dialog_append_buttons_with_pixmaps(dialog, b, p);
		free(b);
		free(p);
	}

Gtk::Widget_OrNULL_Up
action_area(dialog)
	Gnome::Dialog dialog
	CODE:
	RETVAL = GTK_WIDGET(dialog->action_area);
	OUTPUT:
	RETVAL

void
buttons(dialog)
	Gnome::Dialog	dialog
	PPCODE:
	{
		GList * l = dialog->buttons;
		while(l) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGtkWidget((GtkWidget*)l->data)));
			l=l->next;
		}
	}

#endif

