
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


MODULE = Gtk::Table		PACKAGE = Gtk::Table	PREFIX = gtk_table_

#ifdef GTK_TABLE

Gtk::Table
new(Class, rows, cols, homogeneous)
	SV *	Class
	int	rows
	int	cols
	int homogeneous
	CODE:
	RETVAL = GTK_TABLE(gtk_table_new(rows, cols, homogeneous));
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

#endif
