#ifndef _PERL_GTK_POLLUTION_H_
#define _PERL_GTK_POLLUTION_H_

/* POLLUTION */

#ifndef __PATCHLEVEL_H_INCLUDED__
#include "patchlevel.h"
#endif

#if (PATCHLEVEL < 5)
#	define PL_sv_undef	sv_undef
#	define PL_sv_yes	sv_yes
#	define PL_sv_no		sv_no
#	define PL_na		na
#	define dTHR		(void)0
#endif

#ifndef boolSV
#	define boolSV(b) ((b) ? &PL_sv_yes : &PL_sv_no)
#endif

/* END POLLUTION */

#endif
