#include "gnomeprintperl.h"

MODULE = Gnome2::Print::Font	PACKAGE = Gnome2::Print::Font

### GnomeFontWeight it's not a GEnum type, so we need this hack...
### mmh... I'm wondering if I should file this as a bug in gnome-print.
gint
constants (class)
    ALIAS:
	Gnome2::Print::Font::lightest    = 1
	Gnome2::Print::Font::extra_light = 2
	Gnome2::Print::Font::thin        = 3
	Gnome2::Print::Font::ligh        = 4
	Gnome2::Print::Font::book        = 5
	Gnome2::Print::Font::regular     = 6
	Gnome2::Print::Font::medium      = 7
	Gnome2::Print::Font::semi        = 8
	Gnome2::Print::Font::demi        = 9
	Gnome2::Print::Font::bold        = 10
	Gnome2::Print::Font::heavy       = 11
	Gnome2::Print::Font::extrabold   = 12
	Gnome2::Print::Font::black       = 13
	Gnome2::Print::Font::extrablack  = 14
	Gnome2::Print::Font::heaviest    = 15
    CODE:
    	switch (ix) {
		case  1: RETVAL = GNOME_FONT_LIGHTEST; break; 
		case  2: RETVAL = GNOME_FONT_EXTRA_LIGHT; break;
		case  3: RETVAL = GNOME_FONT_THIN; break;
		case  4: RETVAL = GNOME_FONT_LIGHT; break;
		case  5: RETVAL = GNOME_FONT_BOOK; break;
		case  6: RETVAL = GNOME_FONT_REGULAR; break;
		case  7: RETVAL = GNOME_FONT_MEDIUM; break;
		case  8: RETVAL = GNOME_FONT_SEMI; break;
		case  9: RETVAL = GNOME_FONT_DEMI; break;
		case 10: RETVAL = GNOME_FONT_BOLD; break;
		case 11: RETVAL = GNOME_FONT_HEAVY; break;
		case 12: RETVAL = GNOME_FONT_EXTRABOLD; break;
		case 13: RETVAL = GNOME_FONT_BLACK; break;
		case 14: RETVAL = GNOME_FONT_EXTRABLACK; break; 
		case 15: RETVAL = GNOME_FONT_HEAVIEST; break;

		default: RETVAL = 0; /* you wouldn't want this, and in normal
		                      * operation, we shouldn't trigger it.
				      * it shuts up the compiler in -Wall. */
	}
    OUTPUT:
	RETVAL


MODULE = Gnome2::Print::Font	PACKAGE = Gnome2::Print::Font	PREFIX = gnome_font_

	
const guchar *
gnome_font_get_name (font)
	GnomeFont	* font

const guchar *
gnome_font_get_family_name (font)
	GnomeFont 	* font
	
const guchar *
gnome_font_get_species_name (font)
	GnomeFont 	* font
	
const guchar *
gnome_font_get_ps_name (font)
	GnomeFont 	* font

gdouble 
gnome_font_get_size (font)
	GnomeFont 	* font

GnomeFontFace_noinc  *
gnome_font_get_face (font)
	GnomeFont 	* font

##ArtPoint *gnome_font_get_glyph_stdadvance (GnomeFont *font, gint glyph, ArtPoint *advance);
=for apidoc
=signature ($x, $y) = $font->get_glyph_stdadvance ($glyph)
=cut
void
gnome_font_get_glyph_stadvance (font, glyph)
	GnomeFont	* font
	gint		glyph
    PREINIT:
    	ArtPoint advance;
    PPCODE:
	gnome_font_get_glyph_stdadvance (font, glyph, &advance);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVnv (advance.x)));
	PUSHs (sv_2mortal (newSVnv (advance.y)));

##ArtDRect *gnome_font_get_glyph_stdbbox (GnomeFont *font, gint glyph, ArtDRect *bbox);
=for apidoc
=signature ($x0, $y0, $x1, $y1) = $font->get_glyph_stdbbox ($glyph)
=cut
void
gnome_font_get_glyph_stdbbox (font, glyph)
	GnomeFont	* font
	gint		glyph
    PREINIT:
    	ArtDRect bbox;
    PPCODE:
	gnome_font_get_glyph_stdbbox (font, glyph, &bbox);
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVnv (bbox.x0)));
	PUSHs (sv_2mortal (newSVnv (bbox.y0)));
	PUSHs (sv_2mortal (newSVnv (bbox.x1)));
	PUSHs (sv_2mortal (newSVnv (bbox.y1)));

### ArtBpath is a matrix (2x3) of double, representing a bezier path element.
### Unfortunately, it has also an element taken from an enum that declares the
### state of the bezier path; the enum is not a registered type.
##const ArtBpath *gnome_font_get_glyph_stdoutline (GnomeFont *font, gint glyph);

##ArtPoint *gnome_font_get_glyph_stdkerning (GnomeFont *font, gint glyph0, gint glyph1, ArtPoint *kerning);
=for apidoc
=signature ($x, $y) = $font->get_glyph_stdkerning ($glyph0, $glyph1)
=cut
void
gnome_font_get_glyph_stdkerning (font, glyph0, glyph1)
	GnomeFont	* font
	gint		glyph0
	gint		glyph1
    PREINIT:
    	ArtPoint kerning;
    PPCODE:
    	gnome_font_get_glyph_stdkerning (font, glyph0, glyph1, &kerning);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVnv (kerning.x)));
	PUSHs (sv_2mortal (newSVnv (kerning.y)));

gdouble 
gnome_font_get_glyph_width (font, glyph)
	GnomeFont 	* font
	gint 		glyph

### This is defined inside gnome-font.h, but it's not an exported symbol.
##gdouble 
##gnome_font_get_glyph_kerning (font, glyph1, glyph2)
##	GnomeFont 	* font
##	gint 		glyph1
##	gint		glyph2

gint
gnome_font_lookup_default (font, unicode)
	GnomeFont 	* font
	gint 		unicode

##guchar *gnome_font_get_full_name (GnomeFont *font);

gdouble gnome_font_get_ascender (GnomeFont *font)

gdouble gnome_font_get_descender (GnomeFont *font)

gdouble gnome_font_get_underline_position  (GnomeFont *font)

gdouble gnome_font_get_underline_thickness (GnomeFont *font)

 ## Find the closest face matching the family name, weight, and italic
 ## This is not very intelligent, so use with caution (Lauris)
GnomeFont_noinc *
gnome_font_find (class, name, size)
	const guchar *name
	gdouble size
    C_ARGS:
    	name, size

GnomeFont_noinc *
gnome_font_find_closest (class, name, size)
	const guchar *name
	gdouble size
    C_ARGS:
    	name, size

GnomeFont_noinc *
gnome_font_find_from_full_name (class, string)
	const guchar *string
    C_ARGS:
    	string
	

GnomeFont_noinc *
gnome_font_find_closest_from_full_name (class, string)
	const guchar *string
    C_ARGS:
    	string

### weight should be GnomeFontWeight, but since it's an enum, we use a gint
### instead.
GnomeFont *
gnome_font_find_closest_from_weight_slant (family, weight, italic, size)
	const guchar *family
	gint weight
	gboolean italic
	gdouble size

### These lists are lists of strings.
##GList  *gnome_font_list (void);
=for apidoc
This method returns a list of strings, each one containing a font name present
on this system.
=cut
void
gnome_font_list (class)
    PREINIT:
    	GList *list, *i;
    PPCODE:
    	list = gnome_font_list ();
	if (! list)
		XSRETURN_EMPTY;
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGChar (i->data)));
	/* according to docs, it's up to us to free this. */	
	gnome_font_list_free(list);

##void    gnome_font_list_free (GList *fontlist);

##GList  *gnome_font_family_list (void);
=for apidoc
This method returns a list of strings, each one containing a font family
present on this system.
=cut
void
gnome_font_family_list (class)
    PREINIT:
    	GList *list, *i;
    PPCODE:
    	list = gnome_font_family_list ();
	if (! list)
		XSRETURN_EMPTY;
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGChar (i->data)));
	/* according to docs, it's up to us to free this. */	
	gnome_font_family_list_free(list);

##void    gnome_font_family_list_free (GList *fontlist);

##GList  *gnome_font_style_list (const guchar *family);
=for apidoc
This method returns a list of strings, each one containing a style for the
given font family.
=cut
void
gnome_font_style_list (class, family)
	const guchar * family
    PREINIT:
    	GList *list, *i;
    PPCODE:
    	list = gnome_font_style_list (family);
	if (! list)
		XSRETURN_EMPTY;
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGChar (i->data)));
	/* according to docs, it's up to us to free this. */	
	gnome_font_style_list_free (list);

##void    gnome_font_style_list_free (GList *styles);

### From gnome-font.h:
## We keep these at moment, but in future better go with Pango/glyphlists
##
## Normal utf8 functions
## These are still crap, as you cannot expect ANYTHING about layouting rules
##double gnome_font_get_width_utf8       (GnomeFont *font, const char *s);
##double gnome_font_get_width_utf8_sized (GnomeFont *font, const char *s, int n);
double
gnome_font_get_width_utf8 (font, s)
	GnomeFont * font
	const char * s

double
gnome_font_get_width_utf8_sized (font, s, n)
	GnomeFont * font
	const char * s
	int n

### From gnome-font.h
## These are somewhat tricky, as you cannot do arbitrarily transformed
## fonts with Pango. So be cautious and try to figure out the best
## solution.
##PangoFont            *gnome_font_get_closest_pango_font (const GnomeFont *font, PangoFontMap *map, gdouble dpi);
##PangoFontDescription *gnome_font_get_pango_description (const GnomeFont *font, gdouble dpi);
