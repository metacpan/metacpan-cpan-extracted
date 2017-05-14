
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


MODULE = Gtk::Text		PACKAGE = Gtk::Text		PREFIX = gtk_text_

#ifdef GTK_TEXT

Gtk::Text
new(Class, hadjustment=0, vadjustment=0)
	SV *	Class
	Gtk::AdjustmentOrNULL	hadjustment
	Gtk::AdjustmentOrNULL	vadjustment
	CODE:
	RETVAL = GTK_TEXT(gtk_text_new(hadjustment, vadjustment));
	OUTPUT:
	RETVAL

void
gtk_text_set_editable(text, editable)
	Gtk::Text	text
	int	editable

void
gtk_text_set_adjustments(text, hadjustment, vadjustment)
	Gtk::Text	text
	Gtk::Adjustment	hadjustment
	Gtk::Adjustment	vadjustment

void
gtk_text_set_point(text, index)
	Gtk::Text	text
	int	index

int
gtk_text_get_point(text)
	Gtk::Text	text

int
gtk_text_get_length(text)
	Gtk::Text	text

void
gtk_text_freeze(text)
	Gtk::Text	text

void
gtk_text_thaw(text)
	Gtk::Text	text

void
gtk_text_backward_delete(text, nchars)
	Gtk::Text	text
	int	nchars

void
gtk_text_forward_delete(text, nchars)
	Gtk::Text	text
	int	nchars

void
gtk_text_insert(text, font, fg, bg, string)
	Gtk::Text	text
	Gtk::Gdk::Font	font
	Gtk::Gdk::Color	fg
	Gtk::Gdk::Color	bg
	SV *	string
	CODE:
	{
		STRLEN len;
		SvPV(string,len);
		gtk_text_insert(text, font, fg, bg, SvPV(string,na), len);
	}

Gtk::Adjustment
hadj(text)
	Gtk::Text	text
	CODE:
	RETVAL = text->hadj;
	OUTPUT:
	RETVAL

Gtk::Adjustment
vadj(text)
	Gtk::Text	text
	CODE:
	RETVAL = text->vadj;
	OUTPUT:
	RETVAL

#endif
