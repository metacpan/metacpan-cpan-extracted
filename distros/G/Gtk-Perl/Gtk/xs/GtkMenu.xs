
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

/* XXX attach functions */

static void menu_pos_func (GtkMenu *menu, int *x, int *y, gpointer user_data)
{
	AV * args = (AV*)user_data;
	SV * handler = *av_fetch(args, 0, 0);
	int i;
	dSP;
	
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(menu), 0)));
	for (i=1;i<=av_len(args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
	XPUSHs(sv_2mortal(newSViv(*x)));
	XPUSHs(sv_2mortal(newSViv(*y)));
	PUTBACK;

	i = perl_call_sv(handler, G_ARRAY);
	SPAGAIN;
	
	if (i>2)
		croak("MenuPosFunc must return two or less values");
	if (i==1)
		POPs;
	else {
		*x = SvIV(POPs);
		*y = SvIV(POPs);
	}
	
	PUTBACK;
	FREETMPS;
	LEAVE;
}


MODULE = Gtk::Menu		PACKAGE = Gtk::Menu		PREFIX = gtk_menu_

#ifdef GTK_MENU

Gtk::Menu_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkMenu*)(gtk_menu_new());
	OUTPUT:
	RETVAL

void
gtk_menu_append(menu, child)
	Gtk::Menu	menu
	Gtk::Widget	child
	ALIAS:
		Gtk::Menu::append = 0
		Gtk::Menu::prepend = 1
	CODE:
	if (ix == 0)
		gtk_menu_append(menu, child);
	else if (ix == 1)
		gtk_menu_prepend(menu, child);

void
gtk_menu_insert(menu, child, position)
	Gtk::Menu	menu
	Gtk::Widget	child
	int	position

 #ARG: $func subroutine (subroutine to handle positioning of the menu: it gets the widget, the x and y coordinates; it should return the x, y coordinates)
 #ARG: ... list (additional arguments that are passed to $func after the widget)
void
gtk_menu_popup(menu, parent_menu_shell, parent_menu_item, button, activate_time, func=0, ...)
	Gtk::Menu	menu
	Gtk::Widget_OrNULL	parent_menu_shell
	Gtk::Widget_OrNULL	parent_menu_item
	int	button
	int	activate_time
	SV *	func
	CODE:
	{
		AV * args = newAV();
		int i;
		if (func && SvOK(func)) {
			PackCallbackST(args, 5);
			gtk_menu_popup(menu, parent_menu_shell, parent_menu_item, menu_pos_func,
				 (void*)args, button, activate_time);
		} else {
			gtk_menu_popup(menu, parent_menu_shell, parent_menu_item, NULL,
				 NULL, button, activate_time);
		}
	}


void
gtk_menu_popdown(menu)
	Gtk::Menu	menu
	ALIAS:
		Gtk::Menu::popdown = 0
		Gtk::Menu::detach = 1
		Gtk::Menu::reposition = 2
	CODE:
	switch (ix) {
	case 0: gtk_menu_popdown(menu); break;
	case 1: gtk_menu_detach(menu); break;
	case 2: gtk_menu_reposition(menu); break;
	}

Gtk::MenuItem_OrNULL
gtk_menu_get_active(menu)
	Gtk::Menu	menu

void
gtk_menu_set_active(menu, index)
	Gtk::Menu	menu
	int	index

# FIXME: detach_handler can't be supported in 0.99.10, at least
#
#void
#gtk_menu_attach_to_widget (menu, attach_widget, detach_handler, ...)
#	Gtk::Menu   menu
#	Gtk::Widget attach_widget
#	SV *	detach_handler
#	CODE:
#	{
#		
#	}

Gtk::Widget
gtk_menu_get_attach_widget (menu)
	Gtk::Menu   menu

#if GTK_HVER >= 0x01010D

void
gtk_menu_set_title(menu, title)
	Gtk::Menu	menu
	char *	title

void
gtk_menu_set_tearoff_state(menu, torn_off)
	Gtk::Menu	menu
	bool	torn_off

#endif

#endif
