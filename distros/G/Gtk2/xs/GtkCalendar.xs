/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

#if GTK_CHECK_VERSION (2, 14, 0)

static GPerlCallback *
gtk2perl_calendar_detail_func_create (SV * func, SV * data)
{
	GType param_types [4];
	param_types[0] = GTK_TYPE_CALENDAR;
	param_types[1] = G_TYPE_UINT;
	param_types[2] = G_TYPE_UINT;
	param_types[3] = G_TYPE_UINT;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_STRING);
}

static gchar *
gtk2perl_calendar_detail_func (GtkCalendar *calendar,
			       guint year,
			       guint month,
			       guint day,
			       gpointer user_data)
{
	GPerlCallback * callback = (GPerlCallback*)user_data;
	GValue value = {0,};
	gchar * retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, calendar, year, month, day);
	/* caller owns return value */
	retval = g_value_dup_string (&value);
	g_value_unset (&value);

	return retval;
}

#endif /* 2.14 */

MODULE = Gtk2::Calendar	PACKAGE = Gtk2::Calendar	PREFIX = gtk_calendar_

=for apidoc marked_date
=for signature $widget->marked_date ($value)
=for signature value = $widget->marked_date
=cut

=for apidoc year
=for signature $widget->year ($value)
=for signature value = $widget->year
=cut

=for apidoc month
=for signature $widget->month ($value)
=for signature value = $widget->month
=cut

=for apidoc selected_day
=for signature $widget->selected_day ($value)
=for signature value = $widget->selected_day
=cut

=for apidoc
=for signature $widget->num_marked_dates ($value)
=for signature value = $widget->num_marked_dates
=cut
void
num_marked_dates (cal)
	GtkCalendar* cal
    ALIAS:
	marked_date       = 1
	year              = 2
	month             = 3
	selected_day      = 4
    PPCODE:
	switch (ix) {
	    case 0:
		PUSHs (sv_2mortal (newSViv (cal->num_marked_dates)));
		break;
 	    case 1:
		{
		int i;
		EXTEND (SP, 31);
		for (i = 0; i < 31; i++) {
			PUSHs (sv_2mortal (newSViv (cal->marked_date[i])));
		}
		}
		break;
	    case 2:
		PUSHs (sv_2mortal (newSViv (cal->year)));
		break;
	    case 3:
		PUSHs (sv_2mortal (newSViv (cal->month)));
		break;
	    case 4:
		PUSHs (sv_2mortal (newSViv (cal->selected_day)));
		break;
	    default:
		g_assert_not_reached ();
	}

## GtkWidget* gtk_calendar_new (void)
GtkWidget*
gtk_calendar_new (class)
    C_ARGS:
	/*void*/

## gboolean gtk_calendar_select_month (GtkCalendar *calendar, guint month, guint year)
gboolean
gtk_calendar_select_month (calendar, month, year)
	GtkCalendar * calendar
	guint         month
	guint         year

## void gtk_calendar_select_day (GtkCalendar *calendar, guint day)
void
gtk_calendar_select_day (calendar, day)
	GtkCalendar * calendar
	guint         day

## gboolean gtk_calendar_mark_day (GtkCalendar *calendar, guint day)
gboolean
gtk_calendar_mark_day (calendar, day)
	GtkCalendar * calendar
	guint         day

## gboolean gtk_calendar_unmark_day (GtkCalendar *calendar, guint day)
gboolean
gtk_calendar_unmark_day (calendar, day)
	GtkCalendar * calendar
	guint         day

## void gtk_calendar_clear_marks (GtkCalendar *calendar)
void
gtk_calendar_clear_marks (calendar)
	GtkCalendar * calendar

## void gtk_calendar_set_display_options (GtkCalendar *calendar, GtkCalendarDisplayOptions flags)
## void gtk_calendar_display_options (GtkCalendar *calendar, GtkCalendarDisplayOptions flags)
=for apidoc display_options
The old name for C<set_display_options>.
=cut

void
gtk_calendar_set_display_options (calendar, flags)
	GtkCalendar               * calendar
	GtkCalendarDisplayOptions   flags
    ALIAS:
	display_options = 1
    CODE:
#if GTK_CHECK_VERSION(2,4,0)
	gtk_calendar_set_display_options (calendar, flags);
#else
	gtk_calendar_display_options (calendar, flags);
#endif
    CLEANUP:
	PERL_UNUSED_VAR (ix);

GtkCalendarDisplayOptions
gtk_calendar_get_display_options (GtkCalendar * calendar)
    CODE:
#if GTK_CHECK_VERSION(2,4,0)
	RETVAL = gtk_calendar_get_display_options (calendar);
#else
	RETVAL = calendar->display_flags;
#endif
    OUTPUT:
	RETVAL

## void gtk_calendar_get_date (GtkCalendar *calendar, guint *year, guint *month, guint *day)
void
gtk_calendar_get_date (GtkCalendar * calendar, OUTLIST guint year, OUTLIST guint month, OUTLIST guint day)

## void gtk_calendar_freeze (GtkCalendar *calendar)
void
gtk_calendar_freeze (calendar)
	GtkCalendar * calendar

## void gtk_calendar_thaw (GtkCalendar *calendar)
void
gtk_calendar_thaw (calendar)
	GtkCalendar * calendar

#if GTK_CHECK_VERSION (2, 14, 0)

## void gtk_calendar_set_detail_func (GtkCalendar *calendar, GtkCalendarDetailFunc func, gpointer data, GDestroyNotify destroy)
void gtk_calendar_set_detail_func (GtkCalendar *calendar, SV *func, SV *data=NULL)
    PREINIT:
	GPerlCallback * callback;
    CODE:
	callback = gtk2perl_calendar_detail_func_create (func, data);
	gtk_calendar_set_detail_func (calendar,
				      gtk2perl_calendar_detail_func,
				      callback,
				      (GDestroyNotify) gperl_callback_destroy);

gint gtk_calendar_get_detail_width_chars (GtkCalendar *calendar);

void gtk_calendar_set_detail_width_chars (GtkCalendar *calendar, gint chars);

gint gtk_calendar_get_detail_height_rows (GtkCalendar *calendar);

void gtk_calendar_set_detail_height_rows (GtkCalendar *calendar, gint rows);


#endif /* 2.14 */
