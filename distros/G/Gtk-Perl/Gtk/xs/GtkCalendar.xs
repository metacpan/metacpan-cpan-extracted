
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"

MODULE = Gtk::Calendar		PACKAGE = Gtk::Calendar		PREFIX = gtk_calendar_

#ifdef GTK_CALENDAR

Gtk::Calendar_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GtkCalendar*)(gtk_calendar_new());
	OUTPUT:
	RETVAL

int
gtk_calendar_select_month (calendar, month, year)
	Gtk::Calendar	calendar
	unsigned int	month
	unsigned int	year

void
gtk_calendar_select_day (calendar, day)
	Gtk::Calendar	calendar
	unsigned int	day

int
gtk_calendar_mark_day (calendar, day)
	Gtk::Calendar	calendar
	unsigned int	day

int
gtk_calendar_unmark_day (calendar, day)
	Gtk::Calendar	calendar
	unsigned int	day

void
gtk_calendar_clear_marks (calendar)
	Gtk::Calendar	calendar

void
gtk_calendar_display_options (calendar, flags)
	Gtk::Calendar	calendar
	Gtk::CalendarDisplayOptions	flags

void
gtk_calendar_get_date (calendar)
	Gtk::Calendar	calendar
	PPCODE:
	{
		guint year, month, day;
		gtk_calendar_get_date(calendar, &year, &month, &day);
		XPUSHs(sv_2mortal(newSViv(year)));
		XPUSHs(sv_2mortal(newSViv(month)));
		XPUSHs(sv_2mortal(newSViv(day)));
	}

void
gtk_calendar_freeze (calendar)
	Gtk::Calendar	calendar

void
gtk_calendar_thaw (calendar)
	Gtk::Calendar	calendar


#endif

