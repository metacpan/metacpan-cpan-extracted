
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::HRef		PACKAGE = Gnome::HRef		PREFIX = gnome_href_

#ifdef GNOME_HREF

Gnome::HRef_Sink
new (Class, url, label)
	SV *	Class
	char *	url
	char *	label
	CODE:
	RETVAL = (GnomeHRef*)(gnome_href_new(url, label));
	OUTPUT:
	RETVAL

void
gnome_href_set_url (href, url)
	Gnome::HRef	href
	char *	url

char*
gnome_href_get_url (href)
	Gnome::HRef	href

void
gnome_href_set_label (href, label)
	Gnome::HRef	href
	char *	label

char*
gnome_href_get_label (href)
	Gnome::HRef	href


#endif

