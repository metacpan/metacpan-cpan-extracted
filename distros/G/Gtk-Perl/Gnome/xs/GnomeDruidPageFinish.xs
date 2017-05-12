
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"
#include "GdkImlibTypes.h"


MODULE = Gnome::DruidPageFinish		PACKAGE = Gnome::DruidPageFinish		PREFIX = gnome_druid_page_finish_

#ifdef GNOME_DRUID_PAGE_FINISH

Gnome::DruidPageFinish_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeDruidPageFinish*)(gnome_druid_page_finish_new());
	OUTPUT:
	RETVAL

Gnome::DruidPageFinish_Sink
new_with_vals (Class, title, text, logo, watermark)
	SV *	Class
	char*	title
	char*	text
	Gtk::Gdk::ImlibImage	logo
	Gtk::Gdk::ImlibImage	watermark
	CODE:
	RETVAL = (GnomeDruidPageFinish*)(gnome_druid_page_finish_new_with_vals(title, text, logo, watermark));
	OUTPUT:
	RETVAL


void
gnome_druid_page_finish_set_bg_color (druid_page_finish, color)
	Gnome::DruidPageFinish	druid_page_finish
	Gtk::Gdk::Color	color

void
gnome_druid_page_finish_set_textbox_color (druid_page_finish, color)
	Gnome::DruidPageFinish	druid_page_finish
	Gtk::Gdk::Color	color

void
gnome_druid_page_finish_set_logo_bg_color (druid_page_finish, color)
	Gnome::DruidPageFinish	druid_page_finish
	Gtk::Gdk::Color	color

void
gnome_druid_page_finish_set_title_color (druid_page_finish, color)
	Gnome::DruidPageFinish	druid_page_finish
	Gtk::Gdk::Color	color

void
gnome_druid_page_finish_set_text_color (druid_page_finish, color)
	Gnome::DruidPageFinish	druid_page_finish
	Gtk::Gdk::Color	color

void
gnome_druid_page_finish_set_text (druid_page_finish, text)
	Gnome::DruidPageFinish	druid_page_finish
	char*	text

void
gnome_druid_page_finish_set_title (druid_page_finish, title)
	Gnome::DruidPageFinish	druid_page_finish
	char*	title

void
gnome_druid_page_finish_set_logo (druid_page_finish, logo)
	Gnome::DruidPageFinish	druid_page_finish
	Gtk::Gdk::ImlibImage	logo

void
gnome_druid_page_finish_set_watermark (druid_page_finish, watermark)
	Gnome::DruidPageFinish	druid_page_finish
	Gtk::Gdk::ImlibImage	watermark

#endif

