
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"
#include "GdkImlibTypes.h"


MODULE = Gnome::DruidPageStart		PACKAGE = Gnome::DruidPageStart		PREFIX = gnome_druid_page_start_

#ifdef GNOME_DRUID_PAGE_START

Gnome::DruidPageStart_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeDruidPageStart*)(gnome_druid_page_start_new());
	OUTPUT:
	RETVAL

Gnome::DruidPageStart_Sink
new_with_vals (Class, title, text, logo, watermark)
	SV *	Class
	char*	title
	char*	text
	Gtk::Gdk::ImlibImage	logo
	Gtk::Gdk::ImlibImage	watermark
	CODE:
	RETVAL = (GnomeDruidPageStart*)(gnome_druid_page_start_new_with_vals(title, text, logo, watermark));
	OUTPUT:
	RETVAL


void
gnome_druid_page_start_set_bg_color (druid_page_start, color)
	Gnome::DruidPageStart	druid_page_start
	Gtk::Gdk::Color	color

void
gnome_druid_page_start_set_textbox_color (druid_page_start, color)
	Gnome::DruidPageStart	druid_page_start
	Gtk::Gdk::Color	color

void
gnome_druid_page_start_set_logo_bg_color (druid_page_start, color)
	Gnome::DruidPageStart	druid_page_start
	Gtk::Gdk::Color	color

void
gnome_druid_page_start_set_title_color (druid_page_start, color)
	Gnome::DruidPageStart	druid_page_start
	Gtk::Gdk::Color	color

void
gnome_druid_page_start_set_text_color (druid_page_start, color)
	Gnome::DruidPageStart	druid_page_start
	Gtk::Gdk::Color	color

void
gnome_druid_page_start_set_text (druid_page_start, text)
	Gnome::DruidPageStart	druid_page_start
	char*	text

void
gnome_druid_page_start_set_title (druid_page_start, title)
	Gnome::DruidPageStart	druid_page_start
	char*	title

void
gnome_druid_page_start_set_logo (druid_page_start, logo)
	Gnome::DruidPageStart	druid_page_start
	Gtk::Gdk::ImlibImage	logo

void
gnome_druid_page_start_set_watermark (druid_page_start, watermark)
	Gnome::DruidPageStart	druid_page_start
	Gtk::Gdk::ImlibImage	watermark

#endif

