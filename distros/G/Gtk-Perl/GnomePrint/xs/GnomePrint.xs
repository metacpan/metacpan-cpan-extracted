
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GnomePrintDefs.h"

#include <libart_lgpl/art_affine.h>

static void     callXS (void (*subaddr)(CV* cv), CV *cv, SV **mark)
{
	int items;
	dSP;
	PUSHMARK (mark);
	(*subaddr)(cv);

	PUTBACK;  /* Forget the return values */
}

MODULE = Gnome::Print	PACKAGE = Gnome::Print	PREFIX = gnome_print_

void
_boot_all ()
	CODE:
	{
#include "GnomePrintobjects.xsh"
	}

void
init (Class)
	SV	*Class
	CODE:
	{
		static int did_it = 0;
		if (did_it)
			return;

		did_it = 1;
		GnomePrint_InstallTypedefs();
		GnomePrint_InstallObjects();
	}

# convenience functions ...

void
affine_rotate (Class, angle)
	SV *	Class
	double	angle
	PPCODE:
	{
		double m[6];
		int i;
		art_affine_rotate (m, angle);
		EXTEND(sp, 6);
		for (i=0; i < 6; ++i)
			PUSHs(sv_2mortal(newSVnv(m[i])));
	}

void
affine_scale (Class, sx, sy)
	SV *	Class
	double	sx
	double	sy
	PPCODE:
	{
		double m[6];
		int i;
		art_affine_scale (m, sx, sy);
		EXTEND(sp, 6);
		for (i=0; i < 6; ++i)
			PUSHs(sv_2mortal(newSVnv(m[i])));
	}

void
affine_translate (Class, dx, dy)
	SV *	Class
	double	dx
	double	dy
	PPCODE:
	{
		double m[6];
		int i;
		art_affine_translate (m, dx, dy);
		EXTEND(sp, 6);
		for (i=0; i < 6; ++i)
			PUSHs(sv_2mortal(newSVnv(m[i])));
	}

INCLUDE: ../build/boxed.xsh

INCLUDE: ../build/extension.xsh
