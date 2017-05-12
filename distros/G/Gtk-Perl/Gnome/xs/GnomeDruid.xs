
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Druid		PACKAGE = Gnome::Druid		PREFIX = gnome_druid_

#ifdef GNOME_DRUID

Gnome::Druid_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeDruid*)(gnome_druid_new());
	OUTPUT:
	RETVAL

void
gnome_druid_set_buttons_sensitive (druid, back_sensitive, next_sensitive, cancel_sensitive)
	Gnome::Druid	druid
	gboolean	back_sensitive
	gboolean	next_sensitive
	gboolean	cancel_sensitive

void
gnome_druid_set_show_finish (druid, show_finish)
	Gnome::Druid	druid
	gboolean	show_finish

void
gnome_druid_prepend_page (druid, page)
	Gnome::Druid	druid
	Gnome::DruidPage	page

void
gnome_druid_insert_page (druid, back_page, page)
	Gnome::Druid	druid
	Gnome::DruidPage	back_page
	Gnome::DruidPage	page

void
gnome_druid_append_page (druid, page)
	Gnome::Druid	druid
	Gnome::DruidPage	page

void
gnome_druid_set_page (druid, page)
	Gnome::Druid	druid
	Gnome::DruidPage	page


#endif

