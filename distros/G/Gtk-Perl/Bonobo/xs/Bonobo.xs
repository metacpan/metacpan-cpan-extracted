
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"
#include "GtkDefs.h"

#define POPT_AUTOHELP
#include <liboaf/liboaf.h>
#undef POPT_AUTOHELP
#include <libgnome/libgnome.h>

static void     callXS (void (*subaddr)(CV* cv), CV *cv, SV **mark) 
{
        int items;
        dSP;
        PUSHMARK (mark);
        (*subaddr)(cv);

        PUTBACK;  /* Forget the return values */
}

#define CHECK_EXCEPTION(ev)                   \
   if (ev._major != CORBA_NO_EXCEPTION) {     \
      SV *__sv = porbit_builtin_except (&ev); \
      porbit_throw (__sv);                    \
   }


BonoboUINode* SvBonoboUINode (SV *data, BonoboUINode* n) {
}

MODULE = Bonobo		PACKAGE = Bonobo		PREFIX = bonobo_

BOOT:
	gnomelib_register_popt_table(oaf_popt_options, "Oaf options");

gboolean
bonobo_init(Class, orb=NULL, poa=NULL, manager=NULL)
	SV *	Class
	CORBA::ORB	orb
	PortableServer::POA	poa
	PortableServer::POAManager	manager
	CODE:
	{
		/* oaf_init() */
		if (!orb) {
			int argc, i;
			char **argv;
			AV * ARGV;
			SV * ARGV0;

			ARGV = perl_get_av("ARGV", FALSE);
			ARGV0 = perl_get_sv("0", FALSE);
			argc = av_len(ARGV)+2;
			argv = (char **)malloc (sizeof(char *)*argc);
			argv[0] = SvPV (ARGV0, PL_na);
			for (i=0;i<=av_len(ARGV);i++)
				argv[i+1] = SvPV(*av_fetch(ARGV, i, 0), PL_na);
			orb = oaf_init(argc, argv);
			free(argv);
		}

		RETVAL = bonobo_init(orb, poa, manager);
		bonobo_object_init();
		bonobo_context_init();
		Bonobo_InstallObjects();
		Bonobo_InstallTypedefs();
	}
	OUTPUT:
	RETVAL

void
bonobo_main(Class)
	SV *	Class
	CODE:
	bonobo_main();

gboolean
bonobo_activate(Class)
	SV *	Class
	CODE:
	RETVAL = bonobo_activate();
	OUTPUT:
	RETVAL

void
bonobo_setup_x_error_handler(Class)
	SV *	Class
	CODE:
	bonobo_setup_x_error_handler();

CORBA::ORB
bonobo_orb(Class)
	SV *	Class
	CODE:
	RETVAL = bonobo_orb();
	OUTPUT:
	RETVAL

PortableServer::POA
bonobo_poa(Class)
	SV *	Class
	CODE:
	RETVAL = bonobo_poa();
	OUTPUT:
	RETVAL

PortableServer::POAManager
bonobo_poa_manager(Class)
	SV *	Class
	CODE:
	RETVAL = bonobo_poa_manager();
	OUTPUT:
	RETVAL

CORBA::Object
bonobo_get_object (Class, name, interface=NULL)
	SV *	Class
	char *	name
	char *	interface
	CODE:
	TRY(RETVAL = bonobo_get_object ( name, interface, &ev));
	OUTPUT:
	RETVAL


INCLUDE: ../build/boxed.xsh

INCLUDE: ../build/objects.xsh

INCLUDE: ../build/extension.xsh

