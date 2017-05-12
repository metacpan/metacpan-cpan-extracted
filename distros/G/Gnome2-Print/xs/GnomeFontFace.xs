#include "gnomeprintperl.h"

MODULE = Gnome2::Print::FontFace PACKAGE = Gnome2::Print::FontFace PREFIX = gnome_font_face_


GnomeFontFace_noinc *
gnome_font_face_find (class, name)
	const guchar * name
    C_ARGS:
     	name

GnomeFontFace_noinc *
gnome_font_face_find_closest (class, name)
	const guchar * name
    C_ARGS:
    	name

GnomeFontFace_noinc *
gnome_font_face_find_closest_from_weight_slant (class, family, weight, italic)
	const guchar *family
	gint weight
	gboolean italic
    C_ARGS:
    	family, weight, italic

GnomeFontFace_noinc *
gnome_font_face_find_closest_from_pango_font (class, pfont)
	PangoFont * pfont
    C_ARGS:
    	pfont

GnomeFontFace_noinc *
gnome_font_face_find_closest_from_pango_description (class, desc)
	PangoFontDescription * desc
    C_ARGS:
    	desc
	
GnomeFontFace_noinc *
gnome_font_face_find_from_family_and_style (class, family, style)
	const guchar * family
	const guchar * style
    C_ARGS:
    	family, style


GnomeFont_noinc *
gnome_font_face_get_font (face, size, xres, yres)
	GnomeFontFace * face
	gdouble size
	gdouble xres
	gdouble yres

GnomeFont_noinc *
gnome_font_face_get_font_default (face, size)
	GnomeFontFace * face
	gdouble size

##const guchar * gnome_font_face_get_name         (const GnomeFontFace *face);
const guchar *
gnome_font_face_get_name (GnomeFontFace * face)

##const guchar * gnome_font_face_get_ps_name      (const GnomeFontFace *face);
const guchar *
gnome_font_face_get_ps_name (GnomeFontFace * face)

##const guchar * gnome_font_face_get_family_name  (const GnomeFontFace *face);
const guchar *
gnome_font_face_get_family_name (GnomeFontFace * face)

##const guchar * gnome_font_face_get_species_name (const GnomeFontFace *face);
const guchar *
gnome_font_face_get_species_name (GnomeFontFace * face)

##const ArtDRect *gnome_font_face_get_stdbbox (GnomeFontFace *face);
=for apidoc
=signature ($x0, $y0, $x1, $y1) = $face->get_stdbbox
=cut
void
gnome_font_face_get_stdbbox (face)
	GnomeFontFace * face
    PREINIT:
    	const ArtDRect * rect;
    PPCODE:
    	rect = gnome_font_face_get_stdbbox (face);
	if (! rect)
		XSRETURN_UNDEF;
	
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVnv (rect->x0)));
	PUSHs (sv_2mortal (newSVnv (rect->y0)));
	PUSHs (sv_2mortal (newSVnv (rect->x1)));
	PUSHs (sv_2mortal (newSVnv (rect->y1)));

##ArtDRect *gnome_font_face_get_glyph_stdbbox (GnomeFontFace *face, gint glyph, ArtDRect * bbox);
=for apidoc
=signature ($x0, $y0, $x1, $y1) = $face->get_glyph_stdbbox ($glyph)
=cut
void
gnome_font_face_get_glyph_stdbbox (face, glyph)
	GnomeFontFace * face
	gint glyph
    PREINIT:
    	ArtDRect bbox;
    PPCODE:
    	gnome_font_face_get_glyph_stdbbox (face, glyph, &bbox);
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVnv (bbox.x0)));
	PUSHs (sv_2mortal (newSVnv (bbox.y0)));
	PUSHs (sv_2mortal (newSVnv (bbox.x1)));
	PUSHs (sv_2mortal (newSVnv (bbox.y1)));

##ArtPoint *gnome_font_face_get_glyph_stdadvance (GnomeFontFace *face, gint glyph, ArtPoint * advance);
=for apidoc
=signature ($x, $y) = $face->get_glyph_stdadvance ($glyph)
=cut
void
gnome_font_face_get_glyph_stdadvance (face, glyph)
	GnomeFontFace * face
	gint glyph
    PREINIT:
    	ArtPoint advance;
    PPCODE:
    	gnome_font_face_get_glyph_stdadvance (face, glyph, &advance);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVnv (advance.x)));
	PUSHs (sv_2mortal (newSVnv (advance.y)));

##const ArtBpath *gnome_font_face_get_glyph_stdoutline (GnomeFontFace *face, gint glyph);
##ArtPoint *gnome_font_face_get_glyph_stdkerning (GnomeFontFace *face, gint glyph0, gint glyph1, ArtPoint *kerning);
=for apidoc
=signature ($x, $y) = $face->get_glyph_stdkerning ($glyph0, $glyph1)
=cut
void
gnome_font_face_get_glyph_stdkerning (face, glyph0, glyph1)
	GnomeFontFace * face
	gint glyph0
	gint glyph1
    PREINIT:
    	ArtPoint kerning;
    PPCODE:
    	gnome_font_face_get_glyph_stdkerning (face, glyph0, glyph1, &kerning);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVnv (kerning.x)));
	PUSHs (sv_2mortal (newSVnv (kerning.y)));

##GnomeFontWeight gnome_font_face_get_weight_code (GnomeFontFace *face);

gboolean
gnome_font_face_is_italic (face)
	GnomeFontFace * face

gboolean
gnome_font_face_is_fixed_width (face)
	GnomeFontFace * face

gdouble
gnome_font_face_get_ascender (face)
	GnomeFontFace * face
	
gdouble
gnome_font_face_get_descender (face)
	GnomeFontFace * face
	
gdouble
gnome_font_face_get_underline_position  (face)
	GnomeFontFace * face
	
gdouble
gnome_font_face_get_underline_thickness (face)
	GnomeFontFace * face

gint
gnome_font_face_get_num_glyphs (face)
	GnomeFontFace * face

gdouble
gnome_font_face_get_glyph_width (face, glyph)
	GnomeFontFace * face
	gint glyph

# doesn't seem to be defined in the libs i have, even thought it's in 
# the header files.
#gdouble
#gnome_font_face_get_glyph_kerning (face, glyph1, glyph2)
#	GnomeFontFace * face
#	gint glyph1
#	gint glyph2

##const guchar   *gnome_font_face_get_glyph_ps_name (GnomeFontFace *face, gint glyph);
const guchar *
gnome_font_face_get_glyph_ps_name (GnomeFontFace *face, gint glyph)
	
