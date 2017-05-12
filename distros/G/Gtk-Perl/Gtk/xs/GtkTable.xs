
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Table		PACKAGE = Gtk::Table	PREFIX = gtk_table_

#ifdef GTK_TABLE

Gtk::Table_Sink
new(Class, rows, cols, homogeneous=FALSE)
	SV *	Class
	int	rows
	int	cols
	int homogeneous
	CODE:
	RETVAL = (GtkTable*)(gtk_table_new(rows, cols, homogeneous));
	OUTPUT:
	RETVAL

void
gtk_table_attach(table, child, left_attach, right_attach, top_attach, bottom_attach, xoptions, yoptions, xpadding, ypadding)
	Gtk::Table	table
	Gtk::Widget	child
	int	left_attach
	int	right_attach
	int	top_attach
	int	bottom_attach
	Gtk::AttachOptions	xoptions
	Gtk::AttachOptions	yoptions
	int	xpadding
	int	ypadding

void
gtk_table_attach_defaults(table, child, left_attach, right_attach, top_attach, bottom_attach)
	Gtk::Table	table
	Gtk::Widget	child
	int	left_attach
	int	right_attach
	int	top_attach
	int	bottom_attach

void
gtk_table_set_row_spacing(table, row, spacing)
	Gtk::Table	table
	int	row
	int	spacing

void
gtk_table_set_col_spacing(table, col, spacing)
	Gtk::Table	table
	int	col
	int	spacing

void
gtk_table_set_row_spacings(table, spacing)
	Gtk::Table	table
	int	spacing

void
gtk_table_set_col_spacings(table, spacing)
	Gtk::Table	table
	int	spacing

void
gtk_table_set_homogeneous(table, homogeneous=TRUE)
	Gtk::Table	table
	int	homogeneous

#if GTK_HVER >= 0x010100

void
gtk_table_resize(table, rows, columns)
	Gtk::Table      table
	int             rows
	int             columns

#endif

#endif
