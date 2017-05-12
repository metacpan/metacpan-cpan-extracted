
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

static void
svrefcnt_dec(gpointer data) {
	SvREFCNT_dec((SV*)data);
}

MODULE = Gtk::CList		PACKAGE = Gtk::CList		PREFIX = gtk_clist_

#ifdef GTK_CLIST

Gtk::CList_Sink
new(Class, columns)
	SV* Class
	int columns
	CODE:
	RETVAL = (GtkCList*)(gtk_clist_new(columns));
	OUTPUT:
	RETVAL

 #ARG: $title string (text to put in the first column title)
 #ARG: ... list (additional strings to put in the second, third... column titles)
Gtk::CList_Sink
new_with_titles(Class, title, ...)
	SV *    Class
	SV *	title
	CODE:
	{
		int columns = items - 1;
		int i;
		char** titles = malloc(columns * sizeof(gchar*));
		for (i=1; i < items; ++i)
			titles[i-1] = SvPV(ST(i),PL_na);
		RETVAL = (GtkCList*)(gtk_clist_new_with_titles(columns, titles));
		free(titles);
	}
	OUTPUT:
	RETVAL


void
gtk_clist_set_shadow_type(clist, type)
	Gtk::CList	clist
	Gtk::ShadowType	type
	ALIAS:
		Gtk::CList::set_border = 1
	CODE:
#if GTK_HVER < 0x010103
	/* DEPRECATED */
	gtk_clist_set_border(clist, type);
#else
	gtk_clist_set_shadow_type(clist, type);
#endif

void
gtk_clist_set_selection_mode(clist, mode)
	Gtk::CList	clist
	Gtk::SelectionMode	mode

#if GTK_HVER < 0x010105

void
gtk_clist_set_policy(clist, vscrollbar_policy, hscrollbar_policy)
	Gtk::CList	clist
	Gtk::PolicyType	hscrollbar_policy
	Gtk::PolicyType	vscrollbar_policy

#endif

void
gtk_clist_freeze(clist)
	Gtk::CList	clist
	ALIAS:
		Gtk::CList::freeze = 0
		Gtk::CList::thaw = 1
		Gtk::CList::column_titles_show = 2
		Gtk::CList::column_titles_hide = 3
		Gtk::CList::column_titles_active = 4
		Gtk::CList::column_titles_passive = 5
		Gtk::CList::clear = 6
		Gtk::CList::sort = 7
		Gtk::CList::select_all = 8
		Gtk::CList::unselect_all = 9
		Gtk::CList::undo_selection = 10
	CODE:
	switch (ix) {
	case 0: gtk_clist_freeze(clist); break;
	case 1: gtk_clist_thaw(clist); break;
	case 2: gtk_clist_column_titles_show(clist); break;
	case 3: gtk_clist_column_titles_hide(clist); break;
	case 4: gtk_clist_column_titles_active(clist); break;
	case 5: gtk_clist_column_titles_passive(clist); break;
	case 6: gtk_clist_clear(clist); break;
	case 7: gtk_clist_sort(clist); break;
	case 8: gtk_clist_select_all(clist); break;
	case 9: gtk_clist_unselect_all(clist); break;
	case 10: gtk_clist_undo_selection(clist); break;
	}

void
gtk_clist_column_title_active (clist, column)
	Gtk::CList  clist
	int column

void
gtk_clist_column_title_passive (clist, column)
	Gtk::CList  clist
	int column

void
gtk_clist_set_column_title(clist, column, title)
	Gtk::CList	clist
	int		column
	char*	title

void
gtk_clist_set_column_widget(clist, column, widget)
	Gtk::CList	clist
	int		column
	Gtk::Widget	widget

Gtk::Widget
gtk_clist_get_column_widget(clist, column)
	Gtk::CList	clist
	int		column

void
gtk_clist_set_column_justification(clist, column, justification)
	Gtk::CList	clist
	int		column
	Gtk::Justification	justification

void
gtk_clist_set_column_width(clist, column, width)
	Gtk::CList	clist
	int		column
	int		width


void
gtk_clist_set_row_height(clist, height)
	Gtk::CList  clist
	int		height

void
gtk_clist_moveto(clist, row, column, row_align, column_align)
	Gtk::CList  clist
	int		row
	int		column
	double	row_align
	double	column_align

Gtk::Visibility
gtk_clist_row_is_visible (clist, row)
	Gtk::CList  clist
	int     row

Gtk::CellType
gtk_clist_get_cell_type (clist, row, column)
	Gtk::CList  clist
	int		row
	int		column

#if GTK_HVER >= 0x010108

void
gtk_clist_set_reorderable(clist, reorderable)
	Gtk::CList	clist
	gboolean	reorderable

#endif

void
gtk_clist_set_text(clist, row, column, text)
	Gtk::CList  clist
	int		row
	int		column
	char*	text

char*
gtk_clist_get_text (clist, row, column)
	Gtk::CList  clist
	int		row
	int		column
	CODE:
	{
		gchar* text=NULL;
		gtk_clist_get_text(clist, row, column, &text);
		RETVAL = text;
	}
	OUTPUT:
	RETVAL

void
gtk_clist_set_pixmap(clist, row, column, pixmap, mask)
	Gtk::CList		clist
	int			row
	int			column
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::Bitmap_OrNULL	mask

void
gtk_clist_get_pixmap (clist, row, column)
	Gtk::CList	clist
	int		row
	int		column
	PPCODE:
	{
		GdkPixmap * pixmap = NULL;
		GdkBitmap * bitmap = NULL;
		int result;
		result = gtk_clist_get_pixmap(clist, row, column, &pixmap, (GIMME == G_ARRAY) ?&bitmap: NULL);
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
gtk_clist_set_pixtext(clist, row, column, text, spacing, pixmap, mask)
	Gtk::CList  clist
	int		row
	int		column
	char*	text
	int		spacing
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::Bitmap_OrNULL	mask

void
gtk_clist_get_pixtext (clist, row, column)
	Gtk::CList  clist
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
		result = gtk_clist_get_pixtext(clist, row, column, &text, &spacing, &pixmap, &bitmap);
		if ( result ) {
			EXTEND(sp, 4);
			if ( text )
				PUSHs(sv_2mortal(newSVpv(text, 0)));
			else
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
			PUSHs(sv_2mortal(newSViv(spacing)));
			if ( pixmap )
				PUSHs(sv_2mortal(newSVGdkPixmap(pixmap)));
			else
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
			if (bitmap )
				PUSHs(sv_2mortal(newSVGdkBitmap(bitmap)));
			else
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
		}
	}


void
gtk_clist_set_foreground(clist, row, color)
	Gtk::CList  clist
	int		row
	Gtk::Gdk::Color	color

void
gtk_clist_set_background(clist, row, color)
	Gtk::CList  clist
	int		row
	Gtk::Gdk::Color	color

void
gtk_clist_set_shift(clist, row, column, verticle, horizontal)
	Gtk::CList  clist
	int		row
	int		column
	int 	verticle
	int		horizontal

 #ARG: $text string (text to put in the first column)
 #ARG: ... list (additional strings to put in the second, third... columns)
int
gtk_clist_append(clist, text, ...)
	Gtk::CList  clist
	SV *	text
	CODE:
	{
		int num = items-1;
		int i;
		char** val = malloc(clist->columns*sizeof(char*));
		if (num > clist->columns)
			num = clist->columns;
		for (i=0; i < num; ++i)
			val[i] = SvPV(ST(i+1),PL_na);
		for(i=num; i < clist->columns; i++)
			val[i] = "";
		RETVAL = gtk_clist_append(clist, val);
		free(val);
	}
	OUTPUT:
	RETVAL

 #ARG: $text string (text to put in the first column)
 #ARG: ... list (additional strings to put in the second, third... columns)
void
gtk_clist_insert(clist, row, text, ...)
	Gtk::CList  clist
	int		row
	SV *	text
	CODE:
	{
		int num = items-2;
		int i;
		char** val = malloc(clist->columns*sizeof(char*));
		if (num > clist->columns)
			num = clist->columns;
		for (i=0; i < num; ++i)
			val[i] = SvPV(ST(i+2),PL_na);
		for(i=num; i < clist->columns; i++)
			val[i] = "";
		gtk_clist_insert(clist, row, val);
		free(val);
	}

void
gtk_clist_remove(clist, row)
	Gtk::CList  clist
	int		row

 #ARG: $row integer (row number)
 #ARG: $data reference (reference to the data you want to associate with $row)
void
gtk_clist_set_row_data(clist, row, data)
	Gtk::CList  clist
	int		row
	SV *	data
	CODE:
	{
		SV * sv = (SV*)SvRV(data);
		
		/*\ Hearken: we are given a reference, called 'data', which refers to
		 *          some SV, called 'sv'. The RV is ephemeral, and we must
		 *          not form a permanent reference to it. Instead, we
		 *          increment the refcount of the target sv, and store that
		 *          sv's pointer as the row data. When the row data is
		 *          deallocated, the sv's refcount will be decremented.
		\*/

		if (!sv)
			croak("Data must be a reference");
			
		SvREFCNT_inc(sv);
		
		gtk_clist_set_row_data_full(clist, row, sv, svrefcnt_dec);
	}

 #RETURNS: the reference set with $clist->set_row_data().
SV*
gtk_clist_get_row_data(clist, row)
	Gtk::CList  clist
	int		row
	CODE:
	{
		SV * sv = (SV*)gtk_clist_get_row_data(clist, row);
		RETVAL = sv ? newRV_inc(sv) : newSVsv(&PL_sv_undef);
	}
	OUTPUT:
	RETVAL

int
gtk_clist_find_row_from_data (clist, data)
	Gtk::CList  clist
	SV *    data
	CODE:
	{
		SV * sv = (SV*)SvRV(data);
		
		if (!sv)
			croak("Data must be a reference");
		
		RETVAL = gtk_clist_find_row_from_data(clist, sv);
	}
	OUTPUT:
	RETVAL
	
void
gtk_clist_select_row(clist, row, column)
	Gtk::CList  clist
	int		row
	int		column

void
gtk_clist_unselect_row(clist, row, column)
	Gtk::CList  clist
	int		row
	int		column

void
gtk_clist_get_selection_info (clist, x, y)
	Gtk::CList  clist
	int x
	int y
   	PPCODE:
	{
		int row, column;
		if (gtk_clist_get_selection_info (clist, x, y, &row, &column)) {
			EXTEND(sp, 2);
			PUSHs(sv_2mortal(newSViv(row)));
			PUSHs(sv_2mortal(newSViv(column)));
		}
	}

Gtk::Gdk::Window
clist_window (clist)
	Gtk::CList      clist
	CODE:
	RETVAL = clist->clist_window;
	OUTPUT:
	RETVAL

int
rows(clist)
	Gtk::CList	clist
	CODE:
	RETVAL=clist->rows;
	OUTPUT:
	RETVAL

int
columns(clist)
	Gtk::CList	clist
	CODE:
	RETVAL=clist->columns;
	OUTPUT:
	RETVAL

Gtk::SelectionMode
selection_mode (clist)
	Gtk::CList	clist
	CODE:
	RETVAL=clist->selection_mode;
	OUTPUT:
	RETVAL

 #RETURNS: a list of the row numbers of the current selection
void
selection (clist)
	Gtk::CList      clist
	PPCODE:
	{
		GList * selection = clist->selection;
		while(selection) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVgint(GPOINTER_TO_INT(selection->data))));
			selection=g_list_next(selection);
		}
	}

 #RETURNS: a list of Gtk::CListRow
void
row_list (clist)
	Gtk::CList	clist
	PPCODE:
	{
		GList * row_list = clist->row_list;
		while(row_list) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGtkCListRow(row_list->data)));
			row_list=g_list_next(row_list);
		}

	}

#if GTK_HVER >= 0x010103

void
gtk_clist_set_column_resizeable(clist, column, resizeable=TRUE)
	Gtk::CList	clist
	int		column
	bool		resizeable

void
gtk_clist_set_column_visibility(clist, column, visible=TRUE)
	Gtk::CList	clist
	int		column
	bool		visible

void
gtk_clist_set_column_auto_resize(clist, column, resize=TRUE)
	Gtk::CList	clist
	int		column
	bool		resize

#endif	

#if GTK_HVER >= 0x010200

void
gtk_clist_set_cell_style(clist, row, column, style)
	Gtk::CList	clist
	int	row
	int	column
	Gtk::Style	style

Gtk::Style
gtk_clist_get_cell_style(clist, row, column)
	Gtk::CList	clist
	int	row
	int	column

void
gtk_clist_set_row_style(clist, row, style)
	Gtk::CList	clist
	int	row
	Gtk::Style	style

Gtk::Style
gtk_clist_get_row_style(clist, row)
	Gtk::CList	clist
	int	row

#endif

#endif
