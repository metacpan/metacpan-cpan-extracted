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


MODULE = Memphis::Renderer  PACKAGE = Memphis::Renderer  PREFIX = memphis_renderer_


MemphisRenderer_noinc*
memphis_renderer_new (class)
	C_ARGS: /* No args */


MemphisRenderer_noinc*
memphis_renderer_new_full (class, MemphisRuleSet *rules, MemphisMap *map)
	C_ARGS: rules, map


void
memphis_renderer_free (MemphisRenderer *renderer)


void
memphis_renderer_set_resolution (MemphisRenderer *renderer, guint resolution)


void
memphis_renderer_set_map (MemphisRenderer *renderer, MemphisMap* map)


void
memphis_renderer_set_rule_set (MemphisRenderer *renderer, MemphisRuleSet* rules)

guint
memphis_renderer_get_resolution (MemphisRenderer *renderer)


MemphisMap*
memphis_renderer_get_map (MemphisRenderer *renderer)


MemphisRuleSet*
memphis_renderer_get_rule_set (MemphisRenderer *renderer)


void
memphis_renderer_draw_png (MemphisRenderer *renderer, gchar *filename, guint zoom_level);

void
memphis_renderer_draw_tile (MemphisRenderer *renderer, cairo_t *cr, guint x, guint y, guint zoom_level);


gint
memphis_renderer_get_row_count (MemphisRenderer *renderer, guint zoom_level)


gint
memphis_renderer_get_column_count (MemphisRenderer *renderer, guint zoom_level)


gint
memphis_renderer_get_min_x_tile (MemphisRenderer *renderer, guint zoom_level)


gint
memphis_renderer_get_max_x_tile (MemphisRenderer *renderer, guint zoom_level)


gint
memphis_renderer_get_min_y_tile (MemphisRenderer *renderer, guint zoom_level)


gint
memphis_renderer_get_max_y_tile (MemphisRenderer *renderer, guint zoom_level)


gboolean
memphis_renderer_tile_has_data (MemphisRenderer *renderer, guint x, guint y, guint zoom_level)
