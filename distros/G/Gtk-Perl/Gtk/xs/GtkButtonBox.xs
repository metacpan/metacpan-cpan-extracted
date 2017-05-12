
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::ButtonBox		PACKAGE = Gtk::ButtonBox		PREFIX = gtk_button_box_

#ifdef GTK_BUTTON_BOX

int
gtk_button_box_get_layout(buttonbox)
	Gtk::ButtonBox	buttonbox

int
gtk_button_box_get_spacing(buttonbox)
	Gtk::ButtonBox	buttonbox

void
gtk_button_box_set_spacing(buttonbox, spacing)
	Gtk::ButtonBox	buttonbox
	int	spacing

void
gtk_button_box_set_layout(buttonbox, layout_style)
	Gtk::ButtonBox	buttonbox
	Gtk::ButtonBoxStyle	layout_style

void
gtk_button_box_set_child_size(buttonbox, min_width, min_height)
	Gtk::ButtonBox	buttonbox
	int	min_width
	int	min_height

void
gtk_button_box_set_child_size_default(Class, min_width, min_height)
	SV *	Class
	int	min_width
	int	min_height
	CODE:
	gtk_button_box_set_child_size_default(min_width, min_height);

void
gtk_button_box_get_child_size_default (Class)
	SV *    Class
	PPCODE:
	{
		int min_width, min_height;
		gtk_button_box_get_child_size_default(&min_width, &min_height);
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(min_width)));
		PUSHs(sv_2mortal(newSViv(min_height)));
	}

void
gtk_button_box_get_child_size(buttonbox)
	Gtk::ButtonBox   buttonbox
	PPCODE:
	{
		int min_width, min_height;
		gtk_button_box_get_child_size(buttonbox, &min_width, &min_height);
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(min_width)));
		PUSHs(sv_2mortal(newSViv(min_height)));
	}

void
gtk_button_box_set_child_ipadding(buttonbox, ipad_x, ipad_y)
	Gtk::ButtonBox	buttonbox
	int	ipad_x
	int	ipad_y

void
gtk_button_box_set_child_ipadding_default(Class, ipad_x, ipad_y)
	Gtk::ButtonBox	Class
	int	ipad_x
	int	ipad_y
	CODE:
	gtk_button_box_set_child_ipadding_default(ipad_x, ipad_y);

void
gtk_button_box_get_child_ipadding_default (Class)
	SV *    Class
	PPCODE:
	{
		int ipad_x, ipad_y;
		gtk_button_box_get_child_ipadding_default(&ipad_x, &ipad_y);
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(ipad_x)));
		PUSHs(sv_2mortal(newSViv(ipad_y)));
	}

void
gtk_button_box_get_child_ipadding(buttonbox)
	Gtk::ButtonBox    buttonbox
	PPCODE:
	{
		int ipad_x, ipad_y;
		gtk_button_box_get_child_ipadding(buttonbox, &ipad_x, &ipad_y);
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(ipad_x)));
		PUSHs(sv_2mortal(newSViv(ipad_y)));
	}


#endif
