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


MODULE = Memphis::RuleSet  PACKAGE = Memphis::RuleSet  PREFIX = memphis_rule_set_


MemphisRuleSet_noinc*
memphis_rule_set_new (class)
	C_ARGS: /* No args */


void
memphis_rule_set_free (MemphisRuleSet *rules)


void
memphis_rule_set_load_from_file (MemphisRuleSet *rules, const gchar *filename)
	PREINIT:
		GError *error = NULL;

	CODE:
		memphis_rule_set_load_from_file(rules, filename, &error);
		if (error) {
			gperl_croak_gerror (NULL, error);
		}


void
memphis_rule_set_load_from_data (MemphisRuleSet *rules, SV *sv_data)
	PREINIT:
		STRLEN length;
		char *data;
		GError *error = NULL;

	CODE:
		data = SvPV(sv_data, length);
		memphis_rule_set_load_from_data (rules, data, length, &error);
		if (error) {
			gperl_croak_gerror (NULL, error);
		}


void
memphis_rule_set_set_bg_color (MemphisRuleSet *rules, guint8 r, guint8 g, guint8 b, guint8 a)


void
memphis_rule_set_get_bg_color (MemphisRuleSet *rules)
	PREINIT:
		guint8 r, g, b, a;

	PPCODE:
		memphis_rule_set_get_bg_color(rules, &r, &g, &b, &a);
		EXTEND (SP, 4);
		PUSHs (sv_2mortal (newSViv (r)));
		PUSHs (sv_2mortal (newSViv (g)));
		PUSHs (sv_2mortal (newSViv (b)));
		PUSHs (sv_2mortal (newSViv (a)));
		PERL_UNUSED_VAR (ax);


void
memphis_rule_set_get_rule_ids (MemphisRuleSet *rules)
	PREINIT:
		GList *list = NULL;
		GList *item = NULL;

	PPCODE:
		list = memphis_rule_set_get_rule_ids(rules);
		if (!list) {
			XSRETURN_EMPTY;
		}

		for (item = list; item != NULL; item = item->next) {
			gchar *id = (gchar *) item->data;
			XPUSHs(sv_2mortal(newSVGChar(id)));
		}

		g_list_free(list);


void
memphis_rule_set_set_rule (MemphisRuleSet *rules, MemphisRule *rule)


MemphisRule*
memphis_rule_set_get_rule (MemphisRuleSet *rules, const gchar *id)


gboolean
memphis_rule_set_remove_rule (MemphisRuleSet *rules, const gchar *id)

