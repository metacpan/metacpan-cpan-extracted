/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::ComboBoxEntry	PACKAGE = Gtk2::ComboBoxEntry	PREFIX = gtk_combo_box_entry_

=for object Gtk2::ComboBoxEntry - A text entry field with a dropdown list

=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  # the easy way
  $combo_box_entry = Gtk2::ComboBoxEntry->new_text;
  foreach (qw(one two three four five)) {
      $combo_box_entry->append_text ($_);
  }

  # or the powerful way.  there always has to be at least
  # one text column in the model, but you can have anything
  # else in it that you want, just like Gtk2::ComboBox.
  $combo_box_entry = Gtk2::ComboBoxEntry->new ($model, $text_index);

  # to mess with with entry directly, get the child:
  $current_text = $combo_box_entry->child->get_text;

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

A ComboBoxEntry is a widget that allows the user to choose from a list of valid
choices or enter a different value.  It is very similar to a ComboBox, but
displays the selected value in an entry to allow modifying it.

The ComboBoxEntry has a Gtk2::Entry as its child.  To get or set the
currently-displayed text, just manipulate the entry normally.

=cut

 ## GtkWidget *gtk_combo_box_entry_new (void);
 ## GtkWidget *gtk_combo_box_entry_new_with_model (GtkTreeModel *model, gint text_column);
=for apidoc new_with_model
=for signature $entry = Gtk2::ComboBoxEntry->new_with_model ($model, $text_column)
=for arg model (GtkTreeModel)
=for arg text_column (int)
=for arg ... (__hide__)
Alias for new, with two arguments.
=cut

=for apidoc
=for signature $entry = Gtk2::ComboBoxEntry->new
=for signature $entry = Gtk2::ComboBoxEntry->new ($model, $text_column)
=for arg model (GtkTreeModel)
=for arg text_column (int)
=for arg ... (__hide__)
=cut
GtkWidget *
gtk_combo_box_entry_new (class, ...)
    ALIAS:
	new_with_model = 1
    CODE:
	if (ix == 1 || items == 3) {
		RETVAL = gtk_combo_box_entry_new_with_model
					(SvGtkTreeModel (ST (1)), SvIV (ST (2)));
	} else if (ix == 0 && items == 1) {
		RETVAL = gtk_combo_box_entry_new ();
	} else {
		croak ("Usage: Gtk2::ComboBoxEntry->new ()\n"
		       "    OR\n"
		       "       Gtk2::ComboBoxEntry->new (model, text_column)\n"
		       "    OR\n"
		       "       Gtk2::ComboBoxEntry->new_with_model (model, text_column)\n"
		       "    wrong number of arguments");
	}
    OUTPUT:
	RETVAL

gint gtk_combo_box_entry_get_text_column (GtkComboBoxEntry *entry_box);

void gtk_combo_box_entry_set_text_column (GtkComboBoxEntry *entry_box, gint text_column);

#if GTK_CHECK_VERSION (2, 4, 0)

GtkWidget *
gtk_combo_box_entry_new_text (class)
    C_ARGS:
	/* void */

#endif
