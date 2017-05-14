
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

static void
svrefcnt_dec(gpointer data) {
	SvREFCNT_dec((SV*)data);
}

MODULE = Gtk::CList		PACKAGE = Gtk::CList		PREFIX = gtk_clist_

#ifdef GTK_CLIST

Gtk::CList
new(Class, columns)
	SV* Class
	int columns
	CODE:
	RETVAL = GTK_CLIST(gtk_clist_new(columns));
	OUTPUT:
	RETVAL

Gtk::CList
new_with_titles(Class, title, ...)
	SV *    Class
	SV *	title
	CODE:
	{
		int columns = items - 1;
		int i;
		char** titles = malloc(columns * sizeof(gchar*));
		for (i=1; i < items; ++i)
			titles[i-1] = SvPV(ST(i),na);
		RETVAL = GTK_CLIST(gtk_clist_new_with_titles(columns, titles));
		free(titles);
	}
	OUTPUT:
	RETVAL

void
gtk_clist_set_border(self, border)
	Gtk::CList	self
	Gtk::ShadowType	border

void
gtk_clist_set_selection_mode(self, mode)
	Gtk::CList	self
	Gtk::SelectionMode	mode

void
gtk_clist_set_policy(self, vscrollbar_policy, hscrollbar_policy)
	Gtk::CList	self
	Gtk::PolicyType	hscrollbar_policy
	Gtk::PolicyType	vscrollbar_policy

void
gtk_clist_freeze(self)
	Gtk::CList	self

void
gtk_clist_thaw(self)
	Gtk::CList	self

void
gtk_clist_column_titles_show (self)
	Gtk::CList  self

void
gtk_clist_column_titles_hide (self)
	Gtk::CList  self

void
gtk_clist_column_title_active (self, column)
	Gtk::CList  self
	int column

void
gtk_clist_column_title_passive (self, column)
	Gtk::CList  self
	int column

void
gtk_clist_column_titles_active (self)
	Gtk::CList  self

void
gtk_clist_column_titles_passive (self)
	Gtk::CList  self

void
gtk_clist_set_column_title(self, column, title)
	Gtk::CList	self
	int		column
	char*	title

void
gtk_clist_set_column_widget(self, column, widget)
	Gtk::CList	self
	int		column
	Gtk::Widget	widget

void
gtk_clist_set_column_justification(self, column, justification)
	Gtk::CList	self
	int		column
	Gtk::Justification	justification

void
gtk_clist_set_column_width(self, column, width)
	Gtk::CList	self
	int		column
	int		width

void
gtk_clist_set_row_height(self, height)
	Gtk::CList  self
	int		height

void
gtk_clist_moveto(self, row, column, row_align, column_align)
	Gtk::CList  self
	int		row
	int		column
	double	row_align
	double	column_align

bool
gtk_clist_row_is_visible (self, row)
	Gtk::CList  self
	int     row

Gtk::CellType
gtk_clist_get_cell_type (self, row, column)
	Gtk::CList  self
	int		row
	int		column

void
gtk_clist_set_text(self, row, column, text)
	Gtk::CList  self
	int		row
	int		column
	char*	text

char*
gtk_clist_get_text (self, row, column)
	Gtk::CList  self
	int		row
	int		column
	CODE:
	{
		gchar* text=NULL;
		gtk_clist_get_text(self, row, column, &text);
		RETVAL = text;
	}
	OUTPUT:
	RETVAL

void
gtk_clist_set_pixmap(self, row, column, pixmap, mask)
	Gtk::CList  self
	int		row
	int		column
	Gtk::Gdk::Pixmap		pixmap
	Gtk::Gdk::Bitmap	mask

void
gtk_clist_get_pixmap (self, row, column)
	Gtk::CList  self
	int		row
	int		column
	PPCODE:
	{
		GdkPixmap * pixmap = NULL;
		GdkBitmap * bitmap = NULL;
		int result;
		result = gtk_clist_get_pixmap(self, row, column, &pixmap, (GIMME == G_ARRAY) ?&bitmap: NULL);
		if ( result ) {
			if ( pixmap ) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVGdkPixmap(pixmap)));
			}
			if (bitmap ) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVGdkBitmap(bitmap)));
			}
		}
	}

void
gtk_clist_set_pixtext(self, row, column, text, spacing, pixmap, mask)
	Gtk::CList  self
	int		row
	int		column
	char*	text
	int		spacing
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::Bitmap	mask

void
gtk_clist_get_pixtext (self, row, column)
	Gtk::CList  self
	int		row
	int		column
	PPCODE:
	{
		gchar* text = NULL;
		guint8 spacing;
		GdkPixmap * pixmap = NULL;
		GdkBitmap * bitmap = NULL;
		int result;
		/* FIXME: require GIMME == G_ARRAY? */
		result = gtk_clist_get_pixtext(self, row, column, &text, &spacing, &pixmap, &bitmap);
		if ( result ) {
			EXTEND(sp, 4);
			if ( text )
				PUSHs(sv_2mortal(newSVpv(text, 0)));
			else
				PUSHs(sv_2mortal(newSVsv(&sv_undef)));
			PUSHs(sv_2mortal(newSViv(spacing)));
			if ( pixmap )
				PUSHs(sv_2mortal(newSVGdkPixmap(pixmap)));
			else
				PUSHs(sv_2mortal(newSVsv(&sv_undef)));
			if (bitmap )
				PUSHs(sv_2mortal(newSVGdkBitmap(bitmap)));
			else
				PUSHs(sv_2mortal(newSVsv(&sv_undef)));
		}
	}


void
gtk_clist_set_foreground(self, row, color)
	Gtk::CList  self
	int		row
	Gtk::Gdk::Color	color

void
gtk_clist_set_background(self, row, color)
	Gtk::CList  self
	int		row
	Gtk::Gdk::Color	color

void
gtk_clist_set_shift(self, row, column, verticle, horizontal)
	Gtk::CList  self
	int		row
	int		column
	int 	verticle
	int		horizontal

int
gtk_clist_append(self, text, ...)
	Gtk::CList  self
	SV *	text
	CODE:
	{
		int num = items-1;
		int i;
		char** val = malloc(num*sizeof(char*));
		for (i=1; i < items; ++i)
			val[i-1] = SvPV(ST(i),na);
		RETVAL = gtk_clist_append(self, val);
		free(val);
	}
	OUTPUT:
	RETVAL

void
gtk_clist_insert(self, row, text, ...)
	Gtk::CList  self
	int		row
	SV *	text
	CODE:
	{
		int num = items-2;
		int i;
		char** val = malloc(num*sizeof(char*));
		for (i=2; i < items; ++i)
			val[i-2] = SvPV(ST(i),na);
		gtk_clist_insert(self, row, val);
		free(val);
	}

void
gtk_clist_remove(self, row)
	Gtk::CList  self
	int		row

void
gtk_clist_set_row_data(self, row, data)
	Gtk::CList  self
	int		row
	SV *	data
	CODE:
	gtk_clist_set_row_data_full(self, row, data, svrefcnt_dec);

SV*
gtk_clist_get_row_data(self, row)
	Gtk::CList  self
	int		row

int
gtk_clist_find_row_from_data (self, data)
	Gtk::CList  self
	SV *    data

void
gtk_clist_select_row(self, row, column)
	Gtk::CList  self
	int		row
	int		column

void
gtk_clist_unselect_row(self, row, column)
	Gtk::CList  self
	int		row
	int		column

void
gtk_clist_clear(self)
	Gtk::CList  self

#if 0

void
gtk_clist_get_selection_info (self, x, y)
	Gtk::CList  self
	int x
	int y
	PPCODE:
	{
		int row, column;
		gtk_clist_get_selection_info (self, x, y, &row, &column);
	}

#endif

#endif

