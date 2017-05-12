
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::GlyphList		PACKAGE = Gnome::GlyphList		PREFIX = gnome_glyph_list_

#ifdef GNOME_GLYPH_LIST

Gnome::GlyphList
gnome_glyphlist_from_text_dumb (Class, font, color, kerning, letterspace, text)
	SV *	Class
	Gnome::Font	font
	guint32	color
	gdouble	kerning
	gdouble	letterspace
	char *	text
	CODE:
	RETVAL = gnome_glyphlist_from_text_dumb (font, color, kerning, letterspace, text);
	OUTPUT:
	RETVAL

void
gnome_glyphlist_glyph (gl, glyph)
	Gnome::GlyphList	gl
	int	glyph

void
gnome_glyphlist_glyphs (gl, glyph, ...)
	Gnome::GlyphList	gl
	int	glyph
	CODE:
	{
		int *glyphs;
		int i;

		glyphs = malloc(sizeof(int)*(items-1));
		for (i=1; i < items; ++i)
			glyphs[i-1] = SvIV(ST(i));
		gnome_glyphlist_glyphs (gl, glyphs, items-1);
		free(glyphs);
	}

void
gnome_glyphlist_advance (gl, advance)
	Gnome::GlyphList	gl
	bool	advance

void
gnome_glyphlist_moveto (gl, x, y)
	Gnome::GlyphList	gl
	gdouble	x
	gdouble	y

void
gnome_glyphlist_rmoveto (gl, x, y)
	Gnome::GlyphList	gl
	gdouble	x
	gdouble	y

void
gnome_glyphlist_font (gl, font)
	Gnome::GlyphList	gl
	Gnome::Font	font

void
gnome_glyphlist_color (gl, color)
	Gnome::GlyphList	gl
	guint32	color

void
gnome_glyphlist_kerning (gl, kerning)
	Gnome::GlyphList	gl
	gdouble	kerning

void
gnome_glyphlist_letterspace (gl, letterspace)
	Gnome::GlyphList	gl
	gdouble	letterspace

void
gnome_glyphlist_text_dumb (gl, text)
	Gnome::GlyphList	gl
	char *	text

#endif

