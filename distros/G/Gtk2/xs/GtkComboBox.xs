/*
 * Copyright (c) 2003-2006, 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

#if GTK_CHECK_VERSION (2, 6, 0)
# include "gtk2perl-private.h" /* For the row separator callback. */
#endif

MODULE = Gtk2::ComboBox	PACKAGE = Gtk2::ComboBox	PREFIX = gtk_combo_box_

=for object Gtk2::ComboBox - A widget used to choose from a list of items

=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  # the easy way:
  $combobox = Gtk2::ComboBox->new_text;
  foreach (@strings) {
      $combobox->append_text ($_);
  }
  $combobox->prepend_text ($another_string);
  $combobox->insert_text ($index, $yet_another_string);
  $combobox->remove_text ($index);
  $text = $combobox->get_active_text;


  # the full-featured way.  
  # a combo box that shows stock ids and their images:
  use constant ID_COLUMN => 0;
  $model = Gtk2::ListStore->new ('Glib::String');
  foreach (qw(gtk-ok gtk-cancel gtk-yes gtk-no gtk-save gtk-open)) {
      $model->set ($model->append, ID_COLUMN, $_);
  }
  $combo_box = Gtk2::ComboBox->new ($model);
  # to display anything, you must pack cell renderers into
  # the combobox, which implements the Gtk2::CellLayout interface.
  $renderer = Gtk2::CellRendererPixbuf->new;
  $combo_box->pack_start ($renderer, FALSE);
  $combo_box->add_attribute ($renderer, stock_id => ID_COLUMN);
  $renderer = Gtk2::CellRendererText->new;
  $combo_box->pack_start ($renderer, TRUE);
  $combo_box->add_attribute ($renderer, text => ID_COLUMN);

  # select by index
  $combo_box->set_active ($index);
  $active_index = $combo_box->get_active;

  # or by iter
  $combo_box->set_active_iter ($iter);
  $active_iter = $combo_box->get_active_iter;

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Gtk2::ComboBox is a widget that allows the user to choose from a list of valid
choices.  The ComboBox displays the selected choice.  When activated, the
ComboBox displays a popup which allows the user to make a new choice.

Unlike its predecessors Gtk2::Combo and Gtk2::OptionMenu, the Gtk2::ComboBox
uses the model-view pattern; the list of valid choices is specified in the form
of a tree model, and the display of the choices can be adapted to the data in
the model by using cell renderers, as you would in a tree view.  This is
possible since ComboBox implements the Gtk2::CellLayout interface.  The tree
model holding the valid choices is not restricted to a flat list; it can be a
real tree, and the popup will reflect the tree structure.

In addition to the model-view API, ComboBox offers a simple API which is
suitable for text-only combo boxes, and hides the complexity of managing the
data in a model.  It consists of the methods C<new_text>, C<append_text>,
C<insert_text>, C<prepend_text>, C<remove_text> and C<get_active_text>.

=cut

GtkWidget *gtk_combo_box_new (class, GtkTreeModel *model=NULL)
    ALIAS:
	new_with_model = 1
    CODE:
	if (model)
		RETVAL = gtk_combo_box_new_with_model (model);
	else
		RETVAL = gtk_combo_box_new ();
    OUTPUT:
	RETVAL
    CLEANUP:
	PERL_UNUSED_VAR (ix);

##/* grids */

void gtk_combo_box_set_wrap_width (GtkComboBox *combo_box, gint width);

void gtk_combo_box_set_row_span_column (GtkComboBox *combo_box, gint row_span);

void gtk_combo_box_set_column_span_column (GtkComboBox *combo_box, gint column_span);

##/* get/set active item */
gint gtk_combo_box_get_active (GtkComboBox *combo_box);

void gtk_combo_box_set_active (GtkComboBox *combo_box, gint index);

 ## gboolean gtk_combo_box_get_active_iter (GtkComboBox *combo_box, GtkTreeIter *iter);
GtkTreeIter_copy *
gtk_combo_box_get_active_iter (GtkComboBox * combo_box)
    PREINIT:
	GtkTreeIter iter;
    CODE:
	if (!gtk_combo_box_get_active_iter (combo_box, &iter))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

void gtk_combo_box_set_active_iter (GtkComboBox *combo_box, GtkTreeIter_ornull *iter);

##/* getters and setters */

=for apidoc
Note that setting C<undef> for no model is new in Gtk 2.6.  (Both here
or via C<set_property>.)
=cut
void gtk_combo_box_set_model (GtkComboBox *combo_box, GtkTreeModel_ornull *model)

GtkTreeModel *gtk_combo_box_get_model (GtkComboBox *combo_box);

##/* convenience -- text */
GtkWidget *gtk_combo_box_new_text (class);
    C_ARGS:
	/* void */

void gtk_combo_box_append_text (GtkComboBox *combo_box, const gchar *text);

void gtk_combo_box_insert_text (GtkComboBox *combo_box, gint position, const gchar *text);

void gtk_combo_box_prepend_text (GtkComboBox *combo_box, const gchar *text);

void gtk_combo_box_remove_text (GtkComboBox *combo_box, gint position);

##/* programmatic control */
void gtk_combo_box_popup (GtkComboBox *combo_box);

void gtk_combo_box_popdown (GtkComboBox *combo_box);

#if GTK_CHECK_VERSION (2, 6, 0)

gint gtk_combo_box_get_wrap_width (GtkComboBox *combo_box);

gint gtk_combo_box_get_row_span_column (GtkComboBox *combo_box);

gint gtk_combo_box_get_column_span_column (GtkComboBox *combo_box);

#endif

#if GTK_CHECK_VERSION (2, 6, 0)

gchar_own * gtk_combo_box_get_active_text (GtkComboBox *combo_box);

gboolean gtk_combo_box_get_add_tearoffs (GtkComboBox *combo_box);

void gtk_combo_box_set_add_tearoffs (GtkComboBox *combo_box, gboolean add_tearoffs);

#GtkTreeViewRowSeparatorFunc gtk_combo_box_get_row_separator_func (GtkComboBox *combo_box);

 ## void gtk_combo_box_set_row_separator_func (GtkComboBox *combo_box, GtkTreeViewRowSeparatorFunc func, gpointer data, GtkDestroyNotify destroy)
void
gtk_combo_box_set_row_separator_func (GtkComboBox *combo_box, SV *func, SV *data = NULL)
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_tree_view_row_separator_func_create (func, data);
	gtk_combo_box_set_row_separator_func (
		combo_box,
		(GtkTreeViewRowSeparatorFunc)
		  gtk2perl_tree_view_row_separator_func,
		callback,
		(GtkDestroyNotify)
		  gperl_callback_destroy);

void gtk_combo_box_set_focus_on_click (GtkComboBox *combo_box, gboolean focus_on_click);

gboolean gtk_combo_box_get_focus_on_click (GtkComboBox *combo_box);

#AtkObject * gtk_combo_box_get_popup_accessible (GtkComboBox *combo_box);

#endif

#if GTK_CHECK_VERSION (2, 10, 0)

void gtk_combo_box_set_title (GtkComboBox *combo_box, const gchar * title);

const gchar * gtk_combo_box_get_title (GtkComboBox *combo_box);

#endif

#if GTK_CHECK_VERSION (2, 14, 0)

void gtk_combo_box_set_button_sensitivity (GtkComboBox *combo_box, GtkSensitivityType sensitivity);

GtkSensitivityType gtk_combo_box_get_button_sensitivity (GtkComboBox *combo_box);

#endif /* 2.14 */
