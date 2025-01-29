// XS glue for harfbuzz library.
//
// As conventional this is not documented :) .

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stdint.h"
#include <string.h>
#include <math.h>
#include <hb.h>
#include <hb-ot.h>

typedef const char * bytestring_t;
typedef const char * bytestring_nolen_t;

MODULE = HarfBuzz::Shaper		PACKAGE = HarfBuzz::Shaper		
PROTOTYPES: ENABLE

SV *
hb_version_string()
INIT:
  const char *p;
CODE:
  p = hb_version_string();
  RETVAL = newSVpv(p, strlen(p));
OUTPUT:
    RETVAL

hb_buffer_t *
hb_buffer_create()

void
hb_buffer_clear_contents( hb_buffer_t *buf )

void
hb_buffer_reset( hb_buffer_t *buf )

void
hb_buffer_add_utf8(hb_buffer_t *buf, bytestring_t s, size_t length(s), unsigned int offset=0, size_t len=-1)

hb_blob_t *
hb_blob_create_from_file( bytestring_nolen_t s )

void
hb_blob_destroy(hb_blob_t *blob)

hb_face_t *
hb_face_create(hb_blob_t *blob, int index)

hb_font_t *
hb_font_create(hb_face_t *face)

void
hb_ot_font_set_funcs(hb_font_t *font)

void
hb_font_set_scale( hb_font_t *font, int xscale, int yscale)

void
hb_font_set_ptem( hb_font_t *font, float pt )

int
hb_buffer_set_language( hb_buffer_t *buf, bytestring_t s, size_t length(s) )
PREINIT:
  hb_language_t lang;
CODE:
  lang = hb_language_from_string(s, XSauto_length_of_s);
  if ( lang ) {
    hb_buffer_set_language( buf, lang );
    RETVAL = 1;
  }
  else
    XSRETURN_UNDEF;
OUTPUT:
  RETVAL

SV *
hb_buffer_get_language( hb_buffer_t *buf )
PREINIT:
  hb_language_t lang;
  const char *s;
CODE:
  lang = hb_buffer_get_language(buf);
  s = hb_language_to_string(lang);
  RETVAL = newSVpvn(s, strlen(s));
OUTPUT:
  RETVAL

int
hb_buffer_set_script( hb_buffer_t *buf, bytestring_t s, size_t length(s) )
PREINIT:
  hb_script_t script;
CODE:
  script = hb_script_from_string(s, XSauto_length_of_s);
  if ( script ) {
    hb_buffer_set_script( buf, script );
    RETVAL = 1;
  }
  else
    XSRETURN_UNDEF;
OUTPUT:
  RETVAL

SV *
hb_buffer_get_script( hb_buffer_t *buf )
PREINIT:
  hb_script_t script;
  hb_tag_t tag;
  char s[5];
CODE:
  script = hb_buffer_get_script(buf);
  tag = hb_script_to_iso15924_tag(script);
  hb_tag_to_string(tag, s);
  RETVAL = newSVpvn(s, 4);
OUTPUT:
  RETVAL

int
hb_buffer_set_direction( hb_buffer_t *buf, bytestring_t s, size_t length(s) )
PREINIT:
  hb_direction_t dir;
CODE:
  dir = hb_direction_from_string(s, XSauto_length_of_s);
  if ( dir ) {
    hb_buffer_set_direction( buf, dir );
    RETVAL = 1;
  }
  else
    XSRETURN_UNDEF;
OUTPUT:
  RETVAL

SV *
hb_buffer_get_direction( hb_buffer_t *buf )
PREINIT:
  hb_direction_t dir;
  const char *s;
CODE:
  dir = hb_buffer_get_direction(buf);
  s = hb_direction_to_string(dir);
  RETVAL = newSVpvn(s, strlen(s));
OUTPUT:
  RETVAL

void
hb_buffer_guess_segment_properties( hb_buffer_t *buf )

int
hb_buffer_get_length( hb_buffer_t *buf )

SV *
hb_feature_from_string( SV *sv )
PREINIT:
  STRLEN len;
  char* s;
  hb_feature_t f;
CODE:
  s = SvPVutf8(sv, len);
  if ( hb_feature_from_string(s, len, &f) )
    RETVAL = newSVpv((char*)&f,sizeof(f));
  else
    XSRETURN_UNDEF;
OUTPUT:
  RETVAL

void
hb_shape( hb_font_t *font, hb_buffer_t *buf )
CODE:
  hb_shape( font, buf, NULL, 0 );

SV *
hb_shaper( hb_font_t *font, hb_buffer_t *buf, SV* feat )
INIT:
  int n;
  int i;
  AV* results;
  char glyphname[32];
  hb_feature_t* features = NULL;
  results = (AV *)sv_2mortal((SV *)newAV());
CODE:
  /* Do we have features? */
  if ( (SvROK(feat))
       && (SvTYPE(SvRV(feat)) == SVt_PVAV)
       && ((n = av_len((AV *)SvRV(feat))) >= 0)) {

    n++;	/* top index -> length */
    Newx(features, n, hb_feature_t);
    for ( i = 0; i < n; i++ ) {
      hb_feature_t* f;
      f = (hb_feature_t*) SvPV_nolen (*av_fetch ((AV*) SvRV(feat), i, 0));
      features[i] = *f;
    }
    if (0) for ( i = 0; i < n; i++ ) {
      hb_feature_to_string( &features[i], glyphname, 32 );
      fprintf( stderr, "feature[%d] = '%s'\n", i, glyphname );
    }
  }
  else {
    features = NULL;
    n = 0;
  }

  hb_shape( font, buf, features, n );
  if ( features ) Safefree(features);

  n = hb_buffer_get_length(buf);
  hb_glyph_position_t *pos = hb_buffer_get_glyph_positions(buf, NULL);
  hb_glyph_info_t *info = hb_buffer_get_glyph_infos(buf, NULL);
  for ( i = 0; i < n; i++ ) {
    HV * rh;
    hb_codepoint_t gid   = info[i].codepoint;
    rh = (HV *)sv_2mortal((SV *)newHV());
    hv_store(rh, "ax",   2, newSViv(pos[i].x_advance),   0);
    hv_store(rh, "ay",   2, newSViv(pos[i].y_advance),   0);
    hv_store(rh, "dx",   2, newSViv(pos[i].x_offset),    0);
    hv_store(rh, "dy",   2, newSViv(pos[i].y_offset),    0);
    hv_store(rh, "g",    1, newSViv(gid),                0);
    hb_font_get_glyph_name(font, gid,
			   glyphname, sizeof(glyphname));
    hv_store(rh, "name", 4,
		 newSVpvn(glyphname, strlen(glyphname)),  0);
    av_push(results, newRV_inc((SV *)rh));
  }

  RETVAL = newRV_inc((SV *)results);
OUTPUT:
  RETVAL

SV *
hb_buffer_get_extents( hb_font_t *font, hb_buffer_t *buf )
INIT:
  int n;
  int i;
  AV* results;
  results = (AV *)sv_2mortal((SV *)newAV());
CODE:
  n = hb_buffer_get_length(buf);
  hb_glyph_info_t *info = hb_buffer_get_glyph_infos(buf, NULL);
  for ( i = 0; i < n; i++ ) {
    HV * rh;
    hb_codepoint_t gid   = info[i].codepoint;
    rh = (HV *)sv_2mortal((SV *)newHV());
    hb_glyph_extents_t e;
    hb_font_get_glyph_extents(font, gid, &e);
    hv_store(rh, "g",         1, newSViv(gid),         0);
    hv_store(rh, "x_bearing", 9, newSViv(e.x_bearing), 0);
    hv_store(rh, "y_bearing", 9, newSViv(e.y_bearing), 0);
    hv_store(rh, "width",     5, newSViv(e.width),     0);
    hv_store(rh, "height",    6, newSViv(e.height),    0);
    av_push(results, newRV_inc((SV *)rh));
  }

  RETVAL = newRV_inc((SV *)results);
OUTPUT:
  RETVAL

SV *
hb_buffer_get_font_extents( hb_font_t *font, bytestring_t s, size_t length(s) )
PREINIT:
  hb_direction_t dir;
INIT:
  HV* rh;
  rh = (HV *)sv_2mortal((SV *)newHV());
CODE:
  dir = hb_direction_from_string(s, XSauto_length_of_s);
  if ( !dir )
    XSRETURN_UNDEF;

  hb_font_extents_t e;
  hb_font_get_extents_for_direction( font, dir, &e );
  hv_store(rh, "ascender",  8, newSViv(e.ascender),  0);
  hv_store(rh, "descender", 9, newSViv(e.descender), 0);
  hv_store(rh, "line_gap",  8, newSViv(e.line_gap),  0);

  RETVAL = newRV_inc((SV *)rh);
OUTPUT:
  RETVAL
