
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::DruidPage		PACKAGE = Gnome::DruidPage		PREFIX = gnome_druid_page_

#ifdef GNOME_DRUID_PAGE

gboolean
gnome_druid_page_next (druid_page)
	Gnome::DruidPage	druid_page

void
gnome_druid_page_prepare (druid_page)
	Gnome::DruidPage	druid_page

gboolean
gnome_druid_page_back (druid_page)
	Gnome::DruidPage	druid_page

gboolean
gnome_druid_page_cancel (druid_page)
	Gnome::DruidPage	druid_page

void
gnome_druid_page_finish (druid_page)
	Gnome::DruidPage	druid_page

#endif

