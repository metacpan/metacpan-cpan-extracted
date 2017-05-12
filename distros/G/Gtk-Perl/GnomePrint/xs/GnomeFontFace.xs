
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GtkDefs.h"
#include "GnomePrintDefs.h"

MODULE = Gnome::FontFace		PACKAGE = Gnome::FontFace		PREFIX = gnome_font_face_

#ifdef GNOME_FONT_FACE


Gnome::FontFace
gnome_font_face_new (Class, name)
	SV *	Class
	char *	name
	CODE:
	RETVAL = gnome_font_face_new (name);
	OUTPUT:
	RETVAL

char *
gnome_font_face_get_name (face)
	Gnome::FontFace	face

char *
gnome_font_face_get_family_name (face)
	Gnome::FontFace	face

char *
gnome_font_face_get_species_name (face)
	Gnome::FontFace	face

char *
gnome_font_face_get_ps_name (face)
	Gnome::FontFace	face

int
gnome_font_face_lookup_default (face, unicode)
	Gnome::FontFace	face
	int	unicode

#ArtPoint *
#gnome_font_face_get_glyph_stdadvance (face, glyph, advance)
#	Gnome::FontFace	face
#	int	glyph
#	ArtPoint *	advance;
#
#ArtDRect *
#gnome_font_face_get_glyph_stdbbox (face, glyph, bbox)
#	Gnome::FontFace	face
#	int	glyph
#	ArtDRect *	bbox
#
#ArtBpath *
#gnome_font_face_get_glyph_stdoutline (face, glyph)
#	Gnome::FontFace	face
#	int	glyph

Gnome::Font
gnome_font_face_get_font (face, size, xres, yres)
	Gnome::FontFace	face
	gdouble	size
	gdouble	xres
	gdouble	yres

Gnome::Font
gnome_font_face_get_font_default (face, size)
	Gnome::FontFace	face
	gdouble	size

gdouble
gnome_font_face_get_ascender (face)
	Gnome::FontFace	face

gdouble
gnome_font_face_get_descender (face)
	Gnome::FontFace	face

gdouble
gnome_font_face_get_underline_position (face)
	Gnome::FontFace	face

gdouble
gnome_font_face_get_underline_thickness (face)
	Gnome::FontFace	face

gdouble
gnome_font_face_get_glyph_width (face, glyph)
	Gnome::FontFace	face
	int	glyph

gdouble
gnome_font_face_get_glyph_kerning (face, glyph1, glyph2)
	Gnome::FontFace	face
	int	glyph1
	int	glyph2

char *
gnome_font_face_get_glyph_ps_name (face, glyph)
	Gnome::FontFace	face
	int	glyph

Gnome::FontWeight
gnome_font_face_get_weight_code (face)
	Gnome::FontFace	face

bool
gnome_font_face_is_italic (face)
	Gnome::FontFace	face

bool
gnome_font_face_is_fixed_width (face)
	Gnome::FontFace	face

char *
gnome_font_face_get_pfa (face)
	Gnome::FontFace	face

char *
gnome_font_face_get_sample (face)
	Gnome::FontFace	face

Gnome::FontFace
gnome_font_unsized_closest (family_name, weight, italic)
	char *	family_name
	Gnome::FontWeight	weight
	bool	italic

#endif
