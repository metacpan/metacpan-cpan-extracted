/* Pango
 * pangoopengl.h: OpenGL/Freetype2 backend
 *
 * Copyright (C) 1999 Red Hat Software
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

#ifndef PANGOOPENGL_H__
#define PANGOOPENGL_H__

#include <glib-object.h>

#include <fontconfig/fontconfig.h>

#include <pango/pango-layout.h>
#include <pango/pangofc-font.h>

G_BEGIN_DECLS

#define PANGO_TYPE_OPENGL_FONT_MAP              (pango_opengl_font_map_get_type ())
#define PANGO_OPENGL_FONT_MAP(object)           (G_TYPE_CHECK_INSTANCE_CAST ((object), PANGO_TYPE_OPENGL_FONT_MAP, PangoOpenGLFontMap))
#define PANGO_OPENGL_IS_FONT_MAP(object)        (G_TYPE_CHECK_INSTANCE_TYPE ((object), PANGO_TYPE_OPENGL_FONT_MAP))

typedef struct _PangoOpenGLFontMap PangoOpenGLFontMap;
typedef struct _PangoOpenGLFont PangoOpenGLFont;
typedef struct _PangoOpenGLGlyphInfo PangoOpenGLGlyphInfo;
typedef struct _PangoOpenGLRenderer PangoOpenGLRenderer;
typedef struct _PangoOpenGLFontMapClass PangoOpenGLFontMapClass;

typedef void (*PangoOpenGLSubstituteFunc) (FcPattern *pattern, gpointer data);

#define FLAG_INVERSE 1
#define FLAG_OUTLINE 2 // not yet implemented

/* Calls for applications */

void
pango_opengl_render_layout_subpixel (PangoLayout *layout,
                                     rc_t *rc,
                                     int x, int y,
                                     float r, float g, float b, float a,
                                     int flags);

void
pango_opengl_render_layout (PangoLayout *layout,
                            rc_t *rc,
                            int x, int y,
                            float r, float g, float b, float a,
                            int flags);

GType pango_opengl_font_map_get_type (void);

PangoFontMap *pango_opengl_font_map_new                    (void);
void          pango_opengl_font_map_set_default_substitute (PangoOpenGLFontMap        *fontmap,
							    PangoOpenGLSubstituteFunc  func,
							    gpointer                   data,
							    GDestroyNotify             notify);
void          pango_opengl_font_map_substitute_changed (PangoOpenGLFontMap *fontmap);
PangoContext *pango_opengl_font_map_create_context     (PangoOpenGLFontMap *fontmap);

struct _PangoOpenGLFont
{
  PangoFcFont font;

  FT_Face face;
  int load_flags;

  int size;

  GSList *metrics_by_lang;

  GHashTable *glyph_info;
  GDestroyNotify glyph_cache_destroy;
};

struct _PangoOpenGLGlyphInfo
{
  PangoRectangle logical_rect;
  PangoRectangle ink_rect;
  void *cached_glyph;
};

#define PANGO_TYPE_OPENGL_FONT              (pango_opengl_font_get_type ())
#define PANGO_OPENGL_FONT(object)           (G_TYPE_CHECK_INSTANCE_CAST ((object), PANGO_TYPE_OPENGL_FONT, PangoOpenGLFont))
#define PANGO_OPENGL_IS_FONT(object)        (G_TYPE_CHECK_INSTANCE_TYPE ((object), PANGO_TYPE_OPENGL_FONT))

#define PANGO_SCALE_26_6 (PANGO_SCALE / (1<<6))
#define PANGO_PIXELS_26_6(d)                            \
  (((d) >= 0) ?                                         \
   ((d) + PANGO_SCALE_26_6 / 2) / PANGO_SCALE_26_6 :    \
   ((d) - PANGO_SCALE_26_6 / 2) / PANGO_SCALE_26_6)
#define PANGO_UNITS_26_6(d) (PANGO_SCALE_26_6 * (d))

GType pango_opengl_font_get_type (void);

PangoOpenGLFont *_pango_opengl_font_new (PangoOpenGLFontMap *fontmap, FcPattern *pattern);
FT_Library _pango_opengl_font_map_get_library (PangoFontMap *fontmap);

void *_pango_opengl_font_get_cache_glyph_data (PangoFont *font, int glyph_index);
void _pango_opengl_font_set_cache_glyph_data (PangoFont *font, int glyph_index, void *cached_glyph);
void _pango_opengl_font_set_glyph_cache_destroy (PangoFont *font, GDestroyNotify destroy_notify);

#define PANGO_TYPE_OPENGL_RENDERER            (pango_opengl_renderer_get_type())
#define PANGO_OPENGL_RENDERER(object)         (G_TYPE_CHECK_INSTANCE_CAST ((object), PANGO_TYPE_OPENGL_RENDERER, PangoOpenGLRenderer))
#define PANGO_IS_OPENGL_RENDERER(object)      (G_TYPE_CHECK_INSTANCE_TYPE ((object), PANGO_TYPE_OPENGL_RENDERER))

GType pango_opengl_renderer_get_type (void);

PangoRenderer *_pango_opengl_font_map_get_renderer (PangoOpenGLFontMap *fontmap);

// ERROR/TODO: this is not public. this means we have to reimplement
// not just all of pangoft2, but all of pangofc. Whats the point
// of adding 3 layers of abstractions if you can't extend it in any way?
void pango_fc_font_get_raw_extents (PangoFcFont *font, FT_Int32 load_flags, PangoGlyph glyph, PangoRectangle *ink_rect, PangoRectangle *logical_rect);

G_END_DECLS

#endif
