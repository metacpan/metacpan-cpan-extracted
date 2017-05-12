/* Reimplementation of Daniel J. Bernsteins tai library.
 * (C) 2001 Uwe Ohse, <uwe@ohse.de>.
 *   Report any bugs to <uwe@ohse.de>.
 * Placed in the public domain.
 */
/* @(#) $Id: tai_uint.c 1.3 01/05/02 09:55:31+00:00 uwe@fjoras.ohse.de $ */
#include "tai.h"

void
tai_uint (struct tai *target, unsigned int ui)
{
	target->x = ui;
}
