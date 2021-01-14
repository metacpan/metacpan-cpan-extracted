#include "unique-perl.h"

#define _FIXED_UNIQUE_CHECK_VERSION(major,minor,micro) \
        ((UNIQUE_MAJOR_VERSION > (major)) || \
         (UNIQUE_MAJOR_VERSION == (major) && UNIQUE_MINOR_VERSION > (minor)) || \
         (UNIQUE_MAJOR_VERSION == (major) && UNIQUE_MINOR_VERSION == (minor) && UNIQUE_MICRO_VERSION > (micro)))

MODULE = Gtk2::Unique  PACKAGE = Gtk2::Unique  PREFIX = unique_

=for object Gtk2::Unique Use single instance applications

=cut

PROTOTYPES: DISABLE


BOOT:
#include "register.xsh"
#include "boot.xsh"


guint
MAJOR_VERSION ()
	CODE:
		RETVAL = UNIQUE_MAJOR_VERSION;

	OUTPUT:
		RETVAL


guint
MINOR_VERSION ()
	CODE:
		RETVAL = UNIQUE_MINOR_VERSION;

	OUTPUT:
		RETVAL


guint
MICRO_VERSION ()
	CODE:
		RETVAL = UNIQUE_MICRO_VERSION;

	OUTPUT:
		RETVAL


void
GET_VERSION_INFO (class)
	PPCODE:
		EXTEND (SP, 3);
		PUSHs (sv_2mortal (newSViv (UNIQUE_MAJOR_VERSION)));
		PUSHs (sv_2mortal (newSViv (UNIQUE_MINOR_VERSION)));
		PUSHs (sv_2mortal (newSViv (UNIQUE_MICRO_VERSION)));
		PERL_UNUSED_VAR (ax);


gboolean
CHECK_VERSION (class, guint major, guint minor, guint micro)
	CODE:
/*
 * So check version is broken as it has a typo and won't compile. But we need
 * check version to see if libunique has fixed this!
 *
 * For now we define our own check version and use that one instead.
 */
#if ! _FIXED_UNIQUE_CHECK_VERSION(1, 1, 0)
		RETVAL = _FIXED_UNIQUE_CHECK_VERSION(major, minor, micro);
#else
		RETVAL = UNIQUE_CHECK_VERSION(major, minor, micro);
#endif

	OUTPUT:
		RETVAL


const gchar*
VERSION ()

	CODE:
		RETVAL = UNIQUE_VERSION_S;

	OUTPUT:
		RETVAL


guint
VERSION_HEX ()

	CODE:
		RETVAL = UNIQUE_VERSION_HEX;

	OUTPUT:
		RETVAL


const gchar*
API_VERSION ()

	CODE:
		RETVAL = UNIQUE_API_VERSION_S;

	OUTPUT:
		RETVAL


const gchar*
PROTOCOL_VERSION ()

	CODE:
		RETVAL = UNIQUE_PROTOCOL_VERSION_S;

	OUTPUT:
		RETVAL


const gchar*
DEFAULT_BACKEND ()

	CODE:
		RETVAL = UNIQUE_DEFAULT_BACKEND_S;

	OUTPUT:
		RETVAL
