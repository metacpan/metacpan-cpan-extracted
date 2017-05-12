
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"
#include "GdkImlibTypes.h"


MODULE = Gnome::DruidPageStandard		PACKAGE = Gnome::DruidPageStandard		PREFIX = gnome_druid_page_standard_

#ifdef GNOME_DRUID_PAGE_STANDARD

Gnome::DruidPageStandard_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeDruidPageStandard*)(gnome_druid_page_standard_new());
	OUTPUT:
	RETVAL

Gnome::DruidPageStandard_Sink
new_with_vals (Class, title,logo)
	SV *	Class
	char*	title
	Gtk::Gdk::ImlibImage	logo
	CODE:
	RETVAL = (GnomeDruidPageStandard*)(gnome_druid_page_standard_new_with_vals(title, logo));
	OUTPUT:
	RETVAL


void
gnome_druid_page_standard_set_bg_color (druid_page_standard, color)
	Gnome::DruidPageStandard	druid_page_standard
	Gtk::Gdk::Color	color

void
gnome_druid_page_standard_set_logo_bg_color (druid_page_standard, color)
	Gnome::DruidPageStandard	druid_page_standard
	Gtk::Gdk::Color	color

void
gnome_druid_page_standard_set_title_color (druid_page_standard, color)
	Gnome::DruidPageStandard	druid_page_standard
	Gtk::Gdk::Color	color

void
gnome_druid_page_standard_set_title (druid_page_standard, title)
	Gnome::DruidPageStandard	druid_page_standard
	char*	title

void
gnome_druid_page_standard_set_logo (druid_page_standard, logo)
	Gnome::DruidPageStandard	druid_page_standard
	Gtk::Gdk::ImlibImage	logo

Gtk::Widget_Up
vbox(druid_page_standard)
	Gnome::DruidPageStandard	druid_page_standard
	CODE:
	RETVAL = druid_page_standard->vbox;
	OUTPUT:
	RETVAL

#endif

