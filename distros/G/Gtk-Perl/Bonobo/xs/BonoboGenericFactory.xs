
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "GtkDefs.h"
#include "BonoboDefs.h"
#include "MiscTypes.h"

static BonoboObject * 
factory_handler(BonoboGenericFactory *Factory, void *data) {
	AV * stuff;
	SV * handler;
	SV * result;
	BonoboObject * obj;
	int i;
	dSP;

	stuff = (AV*)data;
	handler = *av_fetch(stuff, 0, 0);

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	for (i=1;i<=av_len(stuff);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(stuff, i, 0))));
	PUTBACK;
	i = perl_call_sv(handler, G_SCALAR);
	SPAGAIN;
	if (i!=1)
		croak("handler failed");
	result = POPs;
	obj = SvGtkObjectRef(result, "Gnome::BonoboObject");
	PUTBACK;
	FREETMPS;
	LEAVE;
	return obj;
}


MODULE = Gnome::BonoboGenericFactory		PACKAGE = Gnome::BonoboGenericFactory		PREFIX = bonobo_generic_factory_

#ifdef BONOBO_GENERIC_FACTORY

Gnome::BonoboGenericFactory
bonobo_generic_factory_new (Class, goad_id, handler, ...)
	SV *	Class
	char *	goad_id
	SV *	handler
	CODE:
	{
		AV *args;
		args = newAV();
		PackCallbackST(args, 2);
		RETVAL = bonobo_generic_factory_new (goad_id, factory_handler, args);
	}
	OUTPUT:
	RETVAL

#endif

