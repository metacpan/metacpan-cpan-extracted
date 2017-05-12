
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"

MODULE = Gnome::BonoboClientSite		PACKAGE = Gnome::BonoboClientSite		PREFIX = bonobo_client_site_

#ifdef BONOBO_CLIENT_SITE

Gnome::BonoboClientSite
bonobo_client_site_new (Class, container)
	SV *	Class
	Gnome::BonoboItemContainer	container
	CODE:
	RETVAL = bonobo_client_site_new (container);
	OUTPUT:
	RETVAL

Gnome::BonoboClientSite
bonobo_client_site_construct (client_site, container)
	Gnome::BonoboClientSite	client_site
	Gnome::BonoboItemContainer	container

bool
bonobo_client_site_bind_embeddable (client_site, object)
	Gnome::BonoboClientSite	client_site
	Gnome::BonoboObjectClient	object

Gnome::BonoboObjectClient
bonobo_client_site_get_embeddable (client_site)
	Gnome::BonoboClientSite	client_site

Gnome::BonoboItemContainer
bonobo_client_site_get_container (client_site)
	Gnome::BonoboClientSite	client_site

Gnome::BonoboViewFrame
bonobo_client_site_new_view_full (client_site, uih, visible_cover, active_view)
	Gnome::BonoboClientSite	client_site
	CORBA::Object	uih
	bool	visible_cover
	bool	active_view

Gnome::BonoboViewFrame
bonobo_client_site_new_view (client_site, uih)
	Gnome::BonoboClientSite	client_site
	CORBA::Object	uih

#Gnome::CanvasItem
#bonobo_client_site_new_item (client_site, group)
#	Gnome::BonoboClientSite	client_site
#	Gnome::CanvasGroup	group

#endif

