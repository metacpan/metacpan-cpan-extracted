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
#include <harfbuzz/hb.h>
#include <harfbuzz/hb-ot.h>

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

void *
hb_buffer_create()
  CODE:
    RETVAL = hb_buffer_create();
  OUTPUT:
    RETVAL

void
hb_buffer_clear_contents( void* buf )
CODE:
  hb_buffer_clear_contents(buf);

void
hb_buffer_add_utf8(void* buf, SV* sv)
PREINIT:
  STRLEN len;
  char* s;
CODE:
  s = SvPVutf8(sv, len);
  hb_buffer_add_utf8( buf, s, len, 0, len);

void *
hb_blob_create_from_file(SV* sv)
PREINIT:
  STRLEN len;
  char* s;
CODE:
  s = SvPVutf8(sv, len);
  RETVAL = hb_blob_create_from_file(s);
OUTPUT:
  RETVAL

void
hb_blob_destroy(void* blob)
CODE:
  hb_blob_destroy(blob);

void *
hb_face_create(void* buf, int index)
CODE:
  RETVAL = hb_face_create( buf, index);
OUTPUT:
  RETVAL

void *
hb_font_create(void* face)
CODE:
  RETVAL = hb_font_create(face);
OUTPUT:
  RETVAL

void
hb_ot_font_set_funcs(void* font)
CODE:
  hb_ot_font_set_funcs(font);

void
hb_font_set_scale( void* font, int xscale, int yscale)
CODE:
  hb_font_set_scale(font, xscale, yscale);

void
hb_font_set_ptem( void* font, float pt )
CODE:
  hb_font_set_ptem(font, pt);

void
hb_buffer_guess_segment_properties( void* buf )
CODE:
  hb_buffer_guess_segment_properties(buf);

int
hb_buffer_get_length( void* buf )
CODE:
  RETVAL = hb_buffer_get_length(buf);
OUTPUT:
  RETVAL

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
    RETVAL = newSVpv(NULL, 0);
OUTPUT:
  RETVAL

void
hb_shape( void *font, void* buf )
CODE:
  hb_shape( font, buf, NULL, 0 );

SV *
_hb_shaper( void* font, void* buf, SV* feat )
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
    features = (hb_feature_t*) calloc( sizeof(hb_feature_t), n );
    for ( i = 0; i < n; i++ ) {
      hb_feature_t* f;
      f = (hb_feature_t*) SvPV_nolen (*av_fetch ((AV*) SvRV(feat), i, 0));
      features[i] = *f;
    }
    for ( i = 0; i < n; i++ ) {
      hb_feature_to_string( &features[i], glyphname, 32 );
      /* fprintf( stderr, "feature[%d] = '%s'\n", i, glyphname ); */
    }
  }
  else {
    /* fprintf( stderr, "No features\n"); */
    features = NULL;
    n = 0;
  }

  hb_shape( font, buf, features, n );
  if ( features ) free(features);

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
