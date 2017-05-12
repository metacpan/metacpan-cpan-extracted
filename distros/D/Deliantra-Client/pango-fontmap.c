/* Pango
 * OpenGL fonts handling
 *
 * Copyright (C) 2000 Red Hat Software
 * Copyright (C) 2000 Tor Lillqvist
 * Copyright (C) 2006 Marc Lehmann <pcg@goof.com>
 *
 * This file is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <glib.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <fontconfig/fontconfig.h>

#include "pangoopengl.h"

struct _PangoOpenGLFontMap
{
  PangoFcFontMap parent_instance;

  FT_Library library;

  /* Function to call on prepared patterns to do final
   * config tweaking.
   */
  PangoOpenGLSubstituteFunc substitute_func;
  gpointer substitute_data;
  GDestroyNotify substitute_destroy;

  PangoRenderer *renderer;
};

struct _PangoOpenGLFontMapClass
{
  PangoFcFontMapClass parent_class;
};

G_DEFINE_TYPE (PangoOpenGLFontMap, pango_opengl_font_map, PANGO_TYPE_FC_FONT_MAP)

static void
pango_opengl_font_map_finalize (GObject *object)
{
  PangoOpenGLFontMap *fontmap = PANGO_OPENGL_FONT_MAP (object);
  
  if (fontmap->renderer)
    g_object_unref (fontmap->renderer);

  if (fontmap->substitute_destroy)
    fontmap->substitute_destroy (fontmap->substitute_data);

  FT_Done_FreeType (fontmap->library);

  G_OBJECT_CLASS (pango_opengl_font_map_parent_class)->finalize (object);
}

PangoFontMap *
pango_opengl_font_map_new (void)
{
  PangoOpenGLFontMap *fontmap;
  FT_Error error;
  
  /* Make sure that the type system is initialized */
  g_type_init ();
  
  fontmap = g_object_new (PANGO_TYPE_OPENGL_FONT_MAP, NULL);
  
  error = FT_Init_FreeType (&fontmap->library);
  if (error != FT_Err_Ok)
    g_critical ("pango_opengl_font_map_new: Could not initialize freetype");

  return (PangoFontMap *)fontmap;
}

void
pango_opengl_font_map_set_default_substitute (PangoOpenGLFontMap        *fontmap,
					      PangoOpenGLSubstituteFunc  func,
					      gpointer                   data,
					      GDestroyNotify             notify)
{
  if (fontmap->substitute_destroy)
    fontmap->substitute_destroy (fontmap->substitute_data);

  fontmap->substitute_func = func;
  fontmap->substitute_data = data;
  fontmap->substitute_destroy = notify;
  
  pango_fc_font_map_cache_clear (PANGO_FC_FONT_MAP (fontmap));
}

/**
 * pango_opengl_font_map_substitute_changed:
 * @fontmap: a #PangoOpenGLFontmap
 * 
 * Call this function any time the results of the
 * default substitution function set with
 * pango_opengl_font_map_set_default_substitute() change.
 * That is, if your subsitution function will return different
 * results for the same input pattern, you must call this function.
 *
 * Since: 1.2
 **/
void
pango_opengl_font_map_substitute_changed (PangoOpenGLFontMap *fontmap)
{
  pango_fc_font_map_cache_clear (PANGO_FC_FONT_MAP (fontmap));
}

/**
 * pango_opengl_font_map_create_context:
 * @fontmap: a #PangoOpenGLFontmap
 * 
 * Create a #PangoContext for the given fontmap.
 * 
 * Return value: the newly created context; free with g_object_unref().
 *
 * Since: 1.2
 **/
PangoContext *
pango_opengl_font_map_create_context (PangoOpenGLFontMap *fontmap)
{
  g_return_val_if_fail (PANGO_OPENGL_IS_FONT_MAP (fontmap), NULL);
  
  return pango_fc_font_map_create_context (PANGO_FC_FONT_MAP (fontmap));
}

FT_Library
_pango_opengl_font_map_get_library (PangoFontMap *fontmap_)
{
  PangoOpenGLFontMap *fontmap = (PangoOpenGLFontMap *)fontmap_;
  
  return fontmap->library;
}

/**
 * _pango_opengl_font_map_get_renderer:
 * @fontmap: a #PangoOpenGLFontmap
 * 
 * Gets the singleton PangoOpenGLRenderer for this fontmap.
 * 
 * Return value: 
 **/
PangoRenderer *
_pango_opengl_font_map_get_renderer (PangoOpenGLFontMap *fontmap)
{
  if (!fontmap->renderer)
    fontmap->renderer = g_object_new (PANGO_TYPE_OPENGL_RENDERER, NULL);

  return fontmap->renderer;
}

static void
pango_opengl_font_map_default_substitute (PangoFcFontMap *fcfontmap,
				       FcPattern      *pattern)
{
  PangoOpenGLFontMap *fontmap = PANGO_OPENGL_FONT_MAP (fcfontmap);

  FcConfigSubstitute (NULL, pattern, FcMatchPattern);

  if (fontmap->substitute_func)
    fontmap->substitute_func (pattern, fontmap->substitute_data);

#if 0
  FcValue v;
  if (FcPatternGet (pattern, FC_DPI, 0, &v) == FcResultNoMatch)
    FcPatternAddDouble (pattern, FC_DPI, fontmap->dpi_y);
#endif
  FcDefaultSubstitute (pattern);
}

static PangoFcFont *
pango_opengl_font_map_new_font (PangoFcFontMap  *fcfontmap,
			        FcPattern       *pattern)
{
  return (PangoFcFont *)_pango_opengl_font_new (PANGO_OPENGL_FONT_MAP (fcfontmap), pattern);
}

static void
pango_opengl_font_map_class_init (PangoOpenGLFontMapClass *class)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (class);
  PangoFcFontMapClass *fcfontmap_class = PANGO_FC_FONT_MAP_CLASS (class);
  
  gobject_class->finalize = pango_opengl_font_map_finalize;
  fcfontmap_class->default_substitute = pango_opengl_font_map_default_substitute;
  fcfontmap_class->new_font = pango_opengl_font_map_new_font;
}

static void
pango_opengl_font_map_init (PangoOpenGLFontMap *fontmap)
{
  fontmap->library = NULL;
}

