
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Text		PACKAGE = Gtk::Text		PREFIX = gtk_text_

#ifdef GTK_TEXT

Gtk::Text_Sink
new(Class, hadjustment=0, vadjustment=0)
	SV *	Class
	Gtk::Adjustment_OrNULL	hadjustment
	Gtk::Adjustment_OrNULL	vadjustment
	CODE:
	RETVAL = (GtkText*)(gtk_text_new(hadjustment, vadjustment));
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
gtk_text_set_word_wrap(text, word_wrap)
	Gtk::Text	text
	int	word_wrap

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
	Gtk::Gdk::Font_OrNULL	font
	Gtk::Gdk::Color_OrNULL	fg
	Gtk::Gdk::Color_OrNULL	bg
	SV *	string
	CODE:
	{
		STRLEN len;
		char * s = SvPV(string,len);
		gtk_text_insert(text, font, fg, bg, s, len);
	}

#if GTK_HVER >= 0x010200

void
gtk_text_set_line_wrap (text, line_wrap)
	Gtk::Text	text
	gint	line_wrap

#endif

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
