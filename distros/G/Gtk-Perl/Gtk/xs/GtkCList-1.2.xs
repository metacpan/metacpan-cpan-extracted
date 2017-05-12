
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

static void 
destroy_handler(gpointer data) {
        SvREFCNT_dec((AV*)data);
}

static int
my_clist_compare(GtkCList * clist, gconstpointer a, gconstpointer b) {
	GtkCListRow *row1 = (GtkCListRow *) a;
	GtkCListRow *row2 = (GtkCListRow *) b;
	AV * args;
	SV * handler;
	char * t1=NULL, *t2=NULL;
	int result, i;
	dSP;

	args = gtk_object_get_data(GTK_OBJECT(clist), "_perl_sort_cb");
	handler = *av_fetch(args, 0, 0);

	switch (row1->cell[clist->sort_column].type) {
	case GTK_CELL_TEXT:
		t1 = GTK_CELL_TEXT (row1->cell[clist->sort_column])->text;
		break;
	case GTK_CELL_PIXTEXT:
		t1 = GTK_CELL_PIXTEXT (row1->cell[clist->sort_column])->text;
		break;
	default:
		break;
	}
	switch (row2->cell[clist->sort_column].type) {
	case GTK_CELL_TEXT:
		t2 = GTK_CELL_TEXT (row2->cell[clist->sort_column])->text;
		break;
	case GTK_CELL_PIXTEXT:
		t2 = GTK_CELL_PIXTEXT (row2->cell[clist->sort_column])->text;
		break;
	default:
		break;
	}

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	/* we may want to push all the columns text in an array ref ... */
	XPUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(clist), 0)));
	XPUSHs(sv_2mortal(t1?newSVpv(t1, 0):newSVsv(&PL_sv_undef)));
	XPUSHs(sv_2mortal(t2?newSVpv(t2, 0):newSVsv(&PL_sv_undef)));
	for (i=1;i<=av_len(args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
	PUTBACK;
	i = perl_call_sv(handler, G_SCALAR);
	if (i!=1)
		croak("handler failed");

	SPAGAIN;
	result = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;

	return result;
}


MODULE = Gtk::CList12		PACKAGE = Gtk::CList		PREFIX = gtk_clist_

#ifdef GTK_CLIST

 #ARG: $text string (text to put in the first column)
 #ARG: ... list (additional strings to put in the second, third... columns)
int
gtk_clist_prepend(clist, text, ...)
	Gtk::CList	clist
	SV *	text
	CODE:
	{
		int num = items-1;
		int i;
		char** val = malloc(num*sizeof(char*));
		for (i=1; i < items; ++i)
			val[i-1] = SvPV(ST(i),PL_na);
		RETVAL = gtk_clist_prepend(clist, val);
		free(val);
	}
	OUTPUT:
	RETVAL

void
gtk_clist_set_sort_type (clist, sort_type)
	Gtk::CList	clist
	Gtk::SortType	sort_type

void
gtk_clist_set_sort_column (clist, column)
	Gtk::CList	clist
	int		column

Gtk::SortType
sort_type (clist)
	Gtk::CList	clist
	CODE:
	RETVAL=clist->sort_type;
	OUTPUT:
	RETVAL

int
sort_column (clist)
	Gtk::CList	clist
	CODE:
	RETVAL=clist->sort_column;
	OUTPUT:
	RETVAL

void
gtk_clist_set_auto_sort (clist, auto_sort=TRUE)
	Gtk::CList	clist
	bool		auto_sort

int
gtk_clist_columns_autosize(clist)
	Gtk::CList	clist

char*
gtk_clist_get_column_title (clist, column)
	Gtk::CList	clist
	gint	column

Gtk::Adjustment
gtk_clist_get_hadjustment (clist)
	Gtk::CList	clist

Gtk::Adjustment
gtk_clist_get_vadjustment (clist)
	Gtk::CList	clist

gboolean
gtk_clist_get_selectable (clist, row)
	Gtk::CList	clist
	int	row

gint
gtk_clist_optimal_column_width (clist, column)
	Gtk::CList	clist
	gint	column

void
gtk_clist_row_move (clist, source_row, dest_row)
	Gtk::CList  clist
	gint	source_row
	gint	dest_row

void
gtk_clist_set_button_actions (clist, button, button_actions)
	Gtk::CList  clist
	gint	button
	Gtk::ButtonAction	button_actions

void
gtk_clist_set_column_max_width (clist, column, max_width)
	Gtk::CList  clist
	gint	column
	gint	max_width

void
gtk_clist_set_column_min_width (clist, column, min_width)
	Gtk::CList  clist
	gint	column
	gint	min_width

void
gtk_clist_set_hadjustment (clist, adj)
	Gtk::CList	clist
	Gtk::Adjustment	adj

void
gtk_clist_set_vadjustment (clist, adj)
	Gtk::CList	clist
	Gtk::Adjustment	adj

void
gtk_clist_set_selectable (clist, row, selectable=TRUE)
	Gtk::CList	clist
	gint	row
	gboolean	selectable

void
gtk_clist_set_use_drag_icons (clist, use_icons=TRUE)
	Gtk::CList	clist
	gboolean	use_icons

void
gtk_clist_swap_rows (clist, row1, row2)
	Gtk::CList	clist
	gint	row1
	gint	row2

 #ARG: ... list (additional arguments to the compare function)
 #ARG: $handler subroutine (a compare subroutine that will get the text of the sort_column column of each of the rows being compared)
void
gtk_clist_set_compare_func (clist, handler, ...)
	Gtk::CList	clist
	SV *	handler
	CODE:
	{
		AV * args = newAV();

		PackCallbackST(args, 1);
		gtk_clist_set_compare_func (clist, my_clist_compare);
		gtk_object_set_data_full(GTK_OBJECT(clist), "_perl_sort_cb", args, destroy_handler);
	}

int
focus_row (clist)
	Gtk::CList clist
	CODE:
	RETVAL=clist->focus_row;
	OUTPUT:
	RETVAL


void
set_focus_row(clist, row)
	Gtk::CList	clist
	int		row
	CODE:
	if (row >= 0 && row < clist->rows)
		clist->focus_row = row;
	else
		warn("incorrect row %d", row);
	if (clist->freeze_count == 0)
		gtk_widget_draw (GTK_WIDGET (clist), NULL);

#endif
