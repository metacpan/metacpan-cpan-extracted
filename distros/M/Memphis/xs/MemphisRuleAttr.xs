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

#define SETTER_guint8(index, field) \
			case index: \
				RETVAL = newSViv(attr->field); \
				if (items > 1) attr->field = (guint8) SvIV(ST(1)); \
			break


MODULE = Memphis::RuleAttr  PACKAGE = Memphis::RuleAttr  PREFIX = memphis_rule_attr_


MemphisRuleAttr*
memphis_rule_attr_new (class)
	C_ARGS: /* No args */


MemphisRuleAttr*
memphis_rule_attr_copy (const MemphisRuleAttr *attr)


void
memphis_rule_attr_free (MemphisRuleAttr *attr)
ALIAS:
	DESTROY = 1


SV*
z_min (MemphisRuleAttr *attr, ...)
	ALIAS:
		z_max       = 1
		color_red   = 2
		color_green = 3
		color_blue  = 4
		color_alpha = 5
		style       = 6
		size        = 7

	CODE:
		switch (ix) {

			SETTER_guint8(0, z_min);
			SETTER_guint8(1, z_max);
			SETTER_guint8(2, color_red);
			SETTER_guint8(3, color_green);
			SETTER_guint8(4, color_blue);
			SETTER_guint8(5, color_alpha);

			case 6:
				RETVAL = newSVGChar(attr->style);
				if (items > 1) {
					g_free(attr->style);
					attr->style = g_strdup(SvGChar(ST(1)));
				}
			break;

			case 7:
				RETVAL = newSVnv(attr->size);
				if (items > 1) attr->size = (gdouble) SvNV(ST(1));
			break;

			default:
				RETVAL = &PL_sv_undef;
				g_assert_not_reached();
			break;
		}

	OUTPUT:
		RETVAL		
