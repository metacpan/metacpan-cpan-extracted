/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"
#include <gperl_marshal.h>

/*
GtkEditable's insert-text signal uses an integer pointer as a write-through
parameter; unlike GtkWidget's size-request signal, we can't just pass an
editable object, because an integer is an integral type.

   void user_function  (GtkEditable *editable,
                        gchar *new_text,
                        gint new_text_length,
                        gint *position,  <<=== that's the problem
                        gpointer user_data);
*/
static void
gtk2perl_editable_insert_text_marshal (GClosure * closure,
                                       GValue * return_value,
                                       guint n_param_values,
                                       const GValue * param_values,
                                       gpointer invocation_hint,
                                       gpointer marshal_data)
{
	STRLEN len;
	gint * position_p;
	SV * string, * position;
	dGPERL_CLOSURE_MARSHAL_ARGS;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	PERL_UNUSED_VAR (return_value);
	PERL_UNUSED_VAR (n_param_values);
	PERL_UNUSED_VAR (invocation_hint);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	/* string and position are cleaned up manually further down, so they
	 * don't need sv_2mortal. */

	/* new_text */
	string = newSVGChar (g_value_get_string (param_values+1));
	XPUSHs (string);

	/* text length is redundant, but documented.  it doesn't hurt
	 * anything to include it, but would be a doc hassle to omit it. */
	XPUSHs (sv_2mortal (newSViv (g_value_get_int (param_values+2))));

	/* insert position */
	position_p = g_value_get_pointer (param_values+3);
	position = newSViv (*position_p);
	XPUSHs (position);

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_ARRAY);

	/* refresh the param_values with whatever changes the callback may
	 * have made.  values returned on the stack take precedence over
	 * modifications to @_. */
	if (count == 2) {
		SV * sv;
		/* get the values off the end of the stack.  why do my
		 * attempts to use ST() result in segfaults? */
		*position_p = POPi;
		sv = POPs;
		sv_utf8_upgrade (sv);
		g_value_set_string ((GValue*)param_values+1, SvPV (sv, len));
		g_value_set_int ((GValue*)param_values+2, len);
		PUTBACK;

	} else if (count == 0) {
		/* returned no values, then refresh string and position
		 * params from the callback's args, which may have been
		 * modified. */
		sv_utf8_upgrade (string);
		g_value_set_string ((GValue*)param_values+1,
		                    SvPV (string, len));
		g_value_set_int ((GValue*)param_values+2, len);
		*position_p = SvIV (position);
		if (*position_p < 0)
			*position_p = 0;

	} else {
		/* NOTE: croaking here can cause bad things to happen to the
		 * app, because croaking in signal handlers is bad juju. */
		croak ("an insert-text signal handler must either return"
		       " two items (text and position)\nor return no items"
		       " and possibly modify its @_ parameters.\n"
		       "  callback returned %d items", count);
	}

	/*
	 * clean up
	 */
	SvREFCNT_dec (string);
	SvREFCNT_dec (position);

	PUTBACK;
	FREETMPS;
	LEAVE;
}


MODULE = Gtk2::Editable	PACKAGE = Gtk2::Editable	PREFIX = gtk_editable_

=for position post_signals

The C<insert-text> signal handler can optionally alter the text to be
inserted.  It may

=over 4

=item

Return no values for no change.  Be sure to end with an empty
C<return>.

    sub my_insert_text_handler {
      my ($widget, $text, $len, $pos, $userdata) = @_;
      print "inserting '$text' at char position '$pos'\n";
      return;  # no values
    }

=item

Return two values C<($text, $pos)> which are the new text and
character position.

    sub my_insert_text_handler {
      my ($widget, $text, $len, $pos, $userdata) = @_;
      return (uc($text), $pos);  # force to upper case
    }

=item

Return no values and modify the text in C<$_[1]> and/or position in
C<$_[3]>.  For example,

    sub my_insert_text_handler {
      $_[1] = uc($_[1]);   # force to upper case
      $_[3] = 0;           # force position to the start
      return;  # no values
    }

=back

Note that currently in a Perl subclass of a C<Gtk2::Editable> widget,
a class closure (ie. class default signal handler) for C<insert-text>
does not work this way.  It instead sees the C level C<($text, $len,
$pos_pointer)>, where C<$pos_pointer> is a machine address and cannot
be used easily.  Hopefully this will change in the future.
A C<signal_chain_from_overridden> with the args as passed works, but
for anything else the suggestion is to use a C<signal_connect>
instead.

=cut

BOOT:
	gperl_signal_set_marshaller_for (GTK_TYPE_EDITABLE, "insert_text",
	                                 gtk2perl_editable_insert_text_marshal);

void
gtk_editable_select_region (editable, start, end)
	GtkEditable *editable
	gint start
	gint end


 ## returns an empty list if there is no selection
=for apidoc
=for signature (start, end) = $editable->get_selection_bounds
Returns integers, start and end.
=cut
void
gtk_editable_get_selection_bounds (editable)
	GtkEditable *editable
    PREINIT:
	gint start;
	gint end;
    PPCODE:
	if (!gtk_editable_get_selection_bounds (editable, &start, &end))
		XSRETURN_EMPTY;
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (start)));
	PUSHs (sv_2mortal (newSViv (end)));

=for apidoc
=for signature new_position = $editable->insert_text (new_text, position)
=cut
 ## returns position of next char after inserted text
gint
gtk_editable_insert_text (editable, new_text, ...)
	GtkEditable *editable
	gchar *new_text
    PREINIT:
	gint new_text_length;
	gint position;
    CODE:
	if (items == 3) {
		new_text_length = strlen (new_text);
		position = SvIV (ST (2));
	} else if (items == 4) {
		new_text_length = SvIV (ST (2));
		position = SvIV (ST (3));
	} else {
		croak ("Usage: Gtk2::Editable::insert_text(editable, new_text, position)");
	}

	gtk_editable_insert_text (editable, new_text,
				  new_text_length, &position);
	RETVAL = position;
    OUTPUT:
	RETVAL

void
gtk_editable_delete_text (editable, start_pos, end_pos)
	GtkEditable *editable
	gint start_pos
	gint end_pos

gchar_own *
gtk_editable_get_chars (editable, start_pos, end_pos)
	GtkEditable *editable
	gint start_pos
	gint end_pos

void
gtk_editable_cut_clipboard (editable)
	GtkEditable *editable

void
gtk_editable_copy_clipboard (editable)
	GtkEditable *editable

void
gtk_editable_paste_clipboard (editable)
	GtkEditable *editable

void
gtk_editable_delete_selection (editable)
	GtkEditable *editable

void
gtk_editable_set_position (editable, position)
	GtkEditable *editable
	gint position

gint
gtk_editable_get_position (editable)
	GtkEditable *editable

void
gtk_editable_set_editable (editable, is_editable)
	GtkEditable *editable
	gboolean is_editable

gboolean
gtk_editable_get_editable (editable)
	GtkEditable *editable

