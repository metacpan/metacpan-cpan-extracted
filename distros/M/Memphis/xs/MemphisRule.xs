/* Memphis.
 *
 * Perl bindings for libmemphis; a generic glib/cairo based OSM renderer
 * library. It draws maps on arbitrary cairo surfaces.
 *
 * Perl bindings by Emmanuel Rodriguez <emmanuel.rodriguez@gmail.com>
 *
 * Copyright (C) 2010 Emmanuel Rodriguez
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


#include "memphis-perl.h"


MODULE = Memphis::Rule  PACKAGE = Memphis::Rule  PREFIX = memphis_rule_


MemphisRule*
memphis_rule_new (class)
	C_ARGS: /* No args */


MemphisRule*
memphis_rule_copy (const MemphisRule *rule)


void
memphis_rule_free (MemphisRule *rule)
ALIAS:
	DESTROY = 1


#
# Accessor for the struct members that handle string lists.
#
void
keys (MemphisRule *rule, ...)
	ALIAS:
		values = 1

	PREINIT:
		gchar **list = NULL;

	PPCODE:
		switch (ix) {
			case 0:
				list = rule->keys;
			break;

			case 1:
				list = rule->values;
			break;
		}

		if (items > 1) {
			SV *sv_data = ST(1);
			AV *av;
			gchar **iter;
			gsize length;
			size_t i;

			if (SvTYPE(SvRV(sv_data)) != SVt_PVAV) {
				croak("Arguments must be passed as an arrayref");
			}


			/* Free the previous data */
			if (list != NULL) {
				for (iter = list; *iter != NULL; ++iter) {
					g_free(*iter);
				}
				g_free(list);
			}


			/* Convert the Perl array into a C array of strings */
			av = (AV*) SvRV(sv_data);
			length = av_len(av) + 2; /* last index + extra NULL padding */

			list = g_new(gchar *, length);
			list[length - 1] = NULL;
			for (i = 0; i < length - 1; ++i) {
				SV **data_sv = av_fetch(av, i, FALSE);
				list[i] = strdup(SvGChar(*data_sv));
			}

			/* Save back the new list */
			switch (ix) {
				case 0:
					rule->keys = list;
				break;

				case 1:
					rule->values = list;
				break;
			}
		}
		else {
			AV *av = newAV();
			if (list != NULL) {
				gchar **iter;
				for (iter = list; *iter != NULL; ++iter) {
					av_push(av, newSVGChar(*iter));
				}
			}

			XPUSHs(sv_2mortal(newRV((SV *) av)));
		}


SV*
type (MemphisRule *rule, ...)
	CODE:
		RETVAL = newSVMemphisRuleType(rule->type);
		if (items > 1) rule->type = SvMemphisRuleType(ST(1));

	OUTPUT:
		RETVAL
