/* Pango
 * Rendering routines to OpenGL
 *
 * Copyright (C) 2006 Marc Lehmann <pcg@goof.com>
 * Copyright (C) 2004 Red Hat Software
 * Copyright (C) 2000 Tor Lillqvist
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

#include <math.h>

#include "pangoopengl.h"

#define PANGO_OPENGL_RENDERER_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), PANGO_TYPE_OPENGL_RENDERER, PangoOpenGLRendererClass))
#define PANGO_IS_OPENGL_RENDERER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), PANGO_TYPE_OPENGL_RENDERER))
#define PANGO_OPENGL_RENDERER_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), PANGO_TYPE_OPENGL_RENDERER, PangoOpenGLRendererClass))

typedef struct {
  PangoRendererClass parent_class;
} PangoOpenGLRendererClass;

struct _PangoOpenGLRenderer
{
  PangoRenderer parent_instance;
  float r, g, b, a; // modulate
  int flags;
  rc_t *rc; // rendercache
  rc_key_t key; // current render key
  rc_array_t *arr;
};

G_DEFINE_TYPE (PangoOpenGLRenderer, pango_opengl_renderer, PANGO_TYPE_RENDERER)

typedef struct
{
  uint8_t *bitmap;
  int width, stride, height, top, left;
} Glyph;

static void *
temp_buffer (size_t size)
{
  static char *buffer;
  static size_t alloc;

  if (size > alloc)
    {
      size = (size + 4095) & ~4095;
      free (buffer);
      alloc = size;
      buffer = malloc (size);
    }

  return buffer;
}

static void
render_box (Glyph *glyph, int width, int height, int top)
{
  int i;
  int left = 0;

  if (height > 2)
    {
      height -= 2;
      top++;
    }

  if (width > 2)
    {
      width -= 2;
      left++;
    }

  glyph->stride = (width + 3) & ~3;
  glyph->width  = width;
  glyph->height = height;
  glyph->top    = top;
  glyph->left   = left;

  glyph->bitmap = temp_buffer (width * height);
  memset (glyph->bitmap, 0, glyph->stride * height);

  for (i = width; i--; )
    glyph->bitmap [i] = glyph->bitmap [i + (height - 1) * glyph->stride] = 0xff;

  for (i = height; i--; )
    glyph->bitmap [i * glyph->stride] = glyph->bitmap [i * glyph->stride + (width - 1)] = 0xff;
}

static void
font_render_glyph (Glyph *glyph, PangoFont *font, int glyph_index)
{
  FT_Face face;

  if (glyph_index & PANGO_GLYPH_UNKNOWN_FLAG)
    {
      PangoFontMetrics *metrics;

      if (!font)
	goto generic_box;

      metrics = pango_font_get_metrics (font, NULL);
      if (!metrics)
	goto generic_box;

      render_box (glyph, PANGO_PIXELS (metrics->approximate_char_width),
		         PANGO_PIXELS (metrics->ascent + metrics->descent),
		         PANGO_PIXELS (metrics->ascent));

      pango_font_metrics_unref (metrics);

      return;
    }

  face = pango_opengl_font_get_face (font);
  
  if (face)
    {
      PangoOpenGLFont *glfont = (PangoOpenGLFont *)font;

      FT_Load_Glyph (face, glyph_index, glfont->load_flags);
      FT_Render_Glyph (face->glyph, ft_render_mode_normal);

      glyph->width  = face->glyph->bitmap.width;
      glyph->stride = face->glyph->bitmap.pitch;
      glyph->height = face->glyph->bitmap.rows;
      glyph->top    = face->glyph->bitmap_top;
      glyph->left   = face->glyph->bitmap_left;
      glyph->bitmap = face->glyph->bitmap.buffer;
    }
  else
    generic_box:
      render_box (glyph, PANGO_UNKNOWN_GLYPH_WIDTH, PANGO_UNKNOWN_GLYPH_HEIGHT, PANGO_UNKNOWN_GLYPH_HEIGHT);
}

typedef struct glyph_info {
  tc_area tex;
  int left, top;
  int generation;
} glyph_info;

static void
free_glyph_info (glyph_info *g)
{
  tc_put (&g->tex);
  g_slice_free (glyph_info, g);
}

static int apple_nvidia_bug_workaround;

static void
apple_nvidia_bug (int enable)
{
  apple_nvidia_bug_workaround = enable;
}

static void
tex_update (int name, int x, int y, int w, int stride, int h, void *bm)
{
  glBindTexture (GL_TEXTURE_2D, name);

  if (!apple_nvidia_bug_workaround)
    {
      glPixelStorei (GL_UNPACK_ROW_LENGTH, stride);
      /*glPixelStorei (GL_UNPACK_ALIGNMENT, 1); expected cfplus default */
      glTexSubImage2D (GL_TEXTURE_2D, 0, x, y, w, h, GL_ALPHA, GL_UNSIGNED_BYTE, bm);
      /*glPixelStorei (GL_UNPACK_ALIGNMENT, 4);*/
      glPixelStorei (GL_UNPACK_ROW_LENGTH, 0);
    }
  else
    {
      /* starting with 10.5.5 (or 10.5.6), pple's nvidia driver corrupts textures */
      /* when glTexSubImage is used, so do it the horribly slow way, */
      /* reading/patching/uploading the full texture one each change */
      int r;

      glGetTexImage (GL_TEXTURE_2D, 0, GL_ALPHA, GL_UNSIGNED_BYTE, tc_temptile);

      for (r = 0; r < h; ++r)
        memcpy (tc_temptile + (y + r) * TC_WIDTH + x, (char *)bm + r * stride, w);

      glTexImage2D (GL_TEXTURE_2D, 0, GL_ALPHA, TC_WIDTH, TC_HEIGHT, 0, GL_ALPHA, GL_UNSIGNED_BYTE, tc_temptile);
    }
}

static void
draw_glyph (PangoRenderer *renderer_, PangoFont *font, PangoGlyph glyph, double x, double y)
{
  PangoOpenGLRenderer *renderer = PANGO_OPENGL_RENDERER (renderer_);
  glyph_info *g;

  if (glyph & PANGO_GLYPH_UNKNOWN_FLAG)
    {
      glyph = pango_opengl_get_unknown_glyph (font);

      if (glyph == PANGO_GLYPH_EMPTY)
	glyph = PANGO_GLYPH_UNKNOWN_FLAG;
    }

  g = _pango_opengl_font_get_cache_glyph_data (font, glyph);

  if (!g || g->generation != tc_generation)
    {
      Glyph bm;
      font_render_glyph (&bm, font, glyph);

      if (!g)
        {
          g = g_slice_new (glyph_info);

          _pango_opengl_font_set_glyph_cache_destroy (font, (GDestroyNotify)free_glyph_info);
          _pango_opengl_font_set_cache_glyph_data (font, glyph, g);
        }

      g->generation = tc_generation;

      g->left = bm.left;
      g->top  = bm.top;

      tc_get (&g->tex, bm.width, bm.height);

      if (bm.width && bm.height)
        tex_update (g->tex.name, g->tex.x, g->tex.y, bm.width, bm.stride, bm.height, bm.bitmap);
    }

  x += g->left;
  y -= g->top;

  if (g->tex.name != renderer->key.texname)
    {
      renderer->key.texname = g->tex.name;
      renderer->arr = rc_array (renderer->rc, &renderer->key);
    }

  rc_glyph (renderer->arr, g->tex.x, g->tex.y, g->tex.w, g->tex.h, x, y);
}

static void
draw_trapezoid (PangoRenderer   *renderer_,
		PangoRenderPart  part,
		double           y1,
		double           x11,
		double           x21,
		double           y2,
		double           x12,
		double           x22)
{
  PangoOpenGLRenderer *renderer = (PangoOpenGLRenderer *)renderer_;
  rc_key_t key = renderer->key;
  rc_array_t *arr;

  key.mode    = GL_QUADS;
  key.format  = GL_V2F;
  key.texname = 0;

  arr = rc_array (renderer->rc, &key);

  rc_v2f (arr, x11, y1);
  rc_v2f (arr, x21, y1);
  rc_v2f (arr, x22, y2);
  rc_v2f (arr, x12, y2);
}

void 
pango_opengl_render_layout_subpixel (PangoLayout *layout,
                                     rc_t *rc,
                                     int x, int y,
                                     float r, float g, float b, float a,
                                     int flags)
{
  PangoContext *context;
  PangoFontMap *fontmap;
  PangoRenderer *renderer;
  PangoOpenGLRenderer *gl;

  context = pango_layout_get_context (layout);
  fontmap = pango_context_get_font_map (context);
  renderer = _pango_opengl_font_map_get_renderer (PANGO_OPENGL_FONT_MAP (fontmap));
  gl = PANGO_OPENGL_RENDERER (renderer);

  gl->rc = rc;
  gl->r = r;
  gl->g = g;
  gl->b = b;
  gl->a = a;
  gl->flags = flags;
  
  pango_renderer_draw_layout (renderer, layout, x, y);
}

void 
pango_opengl_render_layout (PangoLayout *layout,
                            rc_t *rc,
			    int x, int y,
                            float r, float g, float b, float a,
                            int flags)
{
  pango_opengl_render_layout_subpixel (
    layout, rc, x * PANGO_SCALE, y * PANGO_SCALE, r, g, b, a, flags
  );
}

static void
pango_opengl_renderer_init (PangoOpenGLRenderer *renderer)
{
  memset (&renderer->key, 0, sizeof (rc_key_t));

  renderer->r = 1.;
  renderer->g = 1.;
  renderer->b = 1.;
  renderer->a = 1.;
}

static void
prepare_run (PangoRenderer *renderer, PangoLayoutRun *run)
{
  PangoOpenGLRenderer *gl = (PangoOpenGLRenderer *)renderer;
  PangoColor *fg = 0;
  GSList *l;
  unsigned char r, g, b, a;

  renderer->underline = PANGO_UNDERLINE_NONE;
  renderer->strikethrough = FALSE;

  gl->key.mode    = GL_QUADS;
  gl->key.format  = 0; // glyphs
  gl->key.texname = 0;

  for (l = run->item->analysis.extra_attrs; l; l = l->next)
    {
      PangoAttribute *attr = l->data;
      
      switch (attr->klass->type)
	{
	case PANGO_ATTR_UNDERLINE:
	  renderer->underline = ((PangoAttrInt *)attr)->value;
	  break;
	  
	case PANGO_ATTR_STRIKETHROUGH:
	  renderer->strikethrough = ((PangoAttrInt *)attr)->value;
	  break;
	  
	case PANGO_ATTR_FOREGROUND:
          fg = &((PangoAttrColor *)attr)->color;
	  break;
	  
	default:
	  break;
	}
    }

  if (fg)
    {
      r = fg->red   * (255.f / 65535.f);
      g = fg->green * (255.f / 65535.f);
      b = fg->blue  * (255.f / 65535.f);
    }
  else 
    {
      r = gl->r * 255.f;
      g = gl->g * 255.f;
      b = gl->b * 255.f;
    }

  a = gl->a * 255.f;

  if (gl->flags & FLAG_INVERSE)
    {
      r ^= 0xffU;
      g ^= 0xffU;
      b ^= 0xffU;
    } 

  gl->key.r = r;
  gl->key.g = g;
  gl->key.b = b;
  gl->key.a = a;
}

static void
draw_begin (PangoRenderer *renderer_)
{
  PangoOpenGLRenderer *renderer = (PangoOpenGLRenderer *)renderer_;
}

static void
draw_end (PangoRenderer *renderer_)
{
  PangoOpenGLRenderer *renderer = (PangoOpenGLRenderer *)renderer_;
}

static void
pango_opengl_renderer_class_init (PangoOpenGLRendererClass *klass)
{
  PangoRendererClass *renderer_class = PANGO_RENDERER_CLASS (klass);

  renderer_class->draw_glyph     = draw_glyph;
  renderer_class->draw_trapezoid = draw_trapezoid;
  renderer_class->prepare_run    = prepare_run;
  renderer_class->begin          = draw_begin;
  renderer_class->end            = draw_end;
}

