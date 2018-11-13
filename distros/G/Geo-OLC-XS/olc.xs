#define PERL_NO_GET_CONTEXT      /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "olc.h"

/*
 * This is our internal data structure.
 * We don't really need an object, because the API doesn't actually carry
 * any context from one call to another, so maybe we should get rid of this.
 */
typedef struct OLC {
    int unused;
} OLC;

static OLC* olc_create(void)
{
    OLC* olc = (OLC*) malloc(sizeof(OLC));
    memset(olc, 0, sizeof(OLC));
    return olc;
}

static void olc_destroy(OLC* olc)
{
    free((void*) olc);
}

static void add_int_data(pTHX_ HV* hash, const char* label, int value)
{
    SV* val = sv_2mortal(newSViv(value));
    if (hv_store(hash, label, strlen(label), val, 0)) {
        SvREFCNT_inc(val);
    }
}

static void add_pos_data(pTHX_ HV* hash, const char* label, const OLC_LatLon* pos)
{
    int cnt = 0;
    SV* val = 0;
    SV* ref = 0;

    AV* av = (AV*) sv_2mortal((SV*) newAV());

    val = sv_2mortal(newSVnv(pos->lat));
    if (av_store(av, cnt, val)) {
        SvREFCNT_inc(val);
        ++cnt;
    }
    val = sv_2mortal(newSVnv(pos->lon));
    if (av_store(av, cnt, val)) {
        SvREFCNT_inc(val);
        ++cnt;
    }
    ref = newRV((SV*) av);
    if (hv_store(hash, label, strlen(label), ref, 0)) {
        SvREFCNT_inc((SV*) av);
    }
}

static int session_dtor(pTHX_ SV* sv, MAGIC* mg)
{
    (void) sv;
    OLC* olc = (OLC*) mg->mg_ptr;
    olc_destroy(olc);
    return 0;
}

static MGVTBL session_magic_vtbl = { .svt_free = session_dtor };

MODULE = Geo::OLC::XS        PACKAGE = Geo::OLC::XS
PROTOTYPES: DISABLE

#################################################################

OLC*
new(char* CLASS, HV* opt = NULL)
  CODE:
    RETVAL = olc_create();
  OUTPUT: RETVAL

int
is_valid(OLC* olc, const char* code)
  CODE:
    RETVAL = OLC_IsValid(code, 0);
  OUTPUT: RETVAL

int
is_short(OLC* olc, const char* code)
  CODE:
    RETVAL = OLC_IsShort(code, 0);
  OUTPUT: RETVAL

int
is_full(OLC* olc, const char* code)
  CODE:
    RETVAL = OLC_IsFull(code, 0);
  OUTPUT: RETVAL

const char*
encode(OLC* olc, double lat, double lon, int len = -1)
  CODE:
    OLC_LatLon pos;
    char code[64];
    pos.lat = lat;
    pos.lon = lon;
    if (len < 0) {
        OLC_EncodeDefault(&pos, code, 64);
    } else {
        OLC_Encode(&pos, len, code, 64);
    }

    RETVAL = code;

  OUTPUT: RETVAL

HV*
decode(OLC* olc, const char* code)
  CODE:
    OLC_CodeArea decoded;
    OLC_LatLon center;
    int len = OLC_CodeLength(code, 0);
    OLC_Decode(code, 0, &decoded);
    OLC_GetCenter(&decoded, &center);

    HV* hv = newHV();
    add_int_data(aTHX_ hv, "length", len);
    add_pos_data(aTHX_ hv, "lower", &decoded.lo);
    add_pos_data(aTHX_ hv, "upper", &decoded.hi);
    add_pos_data(aTHX_ hv, "center", &center);

    RETVAL = hv;

  OUTPUT: RETVAL

const char*
shorten(OLC* olc, const char* longer, double lat, double lon)
  CODE:
    OLC_LatLon ref;
    char shorter[64];
    ref.lat = lat;
    ref.lon = lon;
    OLC_Shorten(longer, 0, &ref, shorter, 64);

    RETVAL = shorter;

  OUTPUT: RETVAL

const char*
recover_nearest(OLC* olc, const char* shorter, double lat, double lon)
  CODE:
    OLC_LatLon ref;
    char longer[64];
    ref.lat = lat;
    ref.lon = lon;
    OLC_RecoverNearest(shorter, 0, &ref, longer, 64);

    RETVAL = longer;

  OUTPUT: RETVAL
