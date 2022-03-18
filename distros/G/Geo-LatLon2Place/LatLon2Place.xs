#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>

#include "perlmulticore.h"

#if EMBED_CDB
 #include "cdb-embedded.c"
#else
 #include <cdb.h>
#endif

#define TORAD(r) ((r) * (M_PI / 180.))

static struct cdb_make make;

struct res
{
  double mind;
  unsigned int respos, reslen;
  double x, y;
};

static inline int
intmin (int a, int b)
{
  return a > b ? b : a;
}

static inline int
intmax (int a, int b)
{
  return a > b ? a : b;
}

static inline int
get_u16 (const U8 *ptr)
{
  return ptr[0] | (ptr[1] << 8);
}

MODULE = Geo::LatLon2Place		PACKAGE = Geo::LatLon2Place

PROTOTYPES: ENABLE

SV *
lookup_ext_ (SV *cdb, int km, int boxes, NV lat, NV lon, int r0, int r1, int flags)
	CODE:
{
        struct cdb *db = (struct cdb *)SvPVX (cdb);

        if (!r1)
          r1 = km;

        r0 =  r0           / km;
        r1 = (r1 + km - 1) / km;
        double coslat = cos (TORAD (lat));
        int cy = (lat + 90.) * boxes * (1. / 180.);
        int x, y;

        if (r1 < r0 || r0 < 0 || r1 < 0 || r0 >= boxes / 2 || r1 >= boxes / 2)
          XSRETURN_EMPTY;

        if (lat < -90. || lat > 90. || lon < -180 || lon > 180.)
          XSRETURN_EMPTY;

        double mind = 1e99;
        const U8 *resptr;
        int reslen = 0;

        for (y = intmax (0, cy - r1); y <= intmin (boxes - 1, cy + r1); ++y)
          {
            double glat = y * (180. / boxes) - 90.;
            double coslat = cos (TORAD (glat));
            int blat = boxes * coslat; /* can be zero */
            int cx = (lon + 180.) * blat * (1. / 360.);

            for (x = cx - r1; x <= cx + r1; ++x)
              {
                int rx = x;
                rx += rx <     0 ? blat : 0;
                rx -= rx >= blat ? blat : 0;

                unsigned char key[4] = {
                  rx, rx >> 8,
                   y,  y >> 8,
                };

                //printf ("x,y %4d,%4d blat %d %d %g %02x%02x%02x%02x %d\n", rx, y, blat, (int)glat, TORAD(glat), key[0],key[1],key[2],key[3], sizeof(key));

                if (cdb_find (db, key, sizeof (key)) <= 0)
                  continue;

                int len = cdb_datalen (db);
                const U8 *ptr = cdb_get (db, len, cdb_datapos (db));

                while (len > 0)
                  {
                    int datalen = ptr[5];

                    double plat = get_u16 (ptr + 0) * ( 90. / 32767.);
                    double plon = get_u16 (ptr + 2) * (180. / 32767.);
                    int w  = ptr[4];

                    double dx = TORAD (lon - plon) * coslat;
                    double dy = TORAD (lat - plat);
                    double d2 = (dx * dx + dy * dy) * w;
                    //printf ("%g,%g %g %.*s\n", plat,plon,d2, datalen,ptr+6);

                    if (d2 < mind)
                      {
                        mind   = d2;
                        resptr = ptr;
                        reslen = datalen;
                      }

                    len -= datalen + 6;
                    ptr += datalen + 6;
                  }
              }
          }

        if (!reslen)
          XSRETURN_EMPTY;

        RETVAL = newSVpvn (resptr + 6, reslen);
}
	OUTPUT: RETVAL

#############################################################################

int
cdb_init (SV *self, int fd)
	CODE:
        sv_upgrade (self, SVt_PV);
        sv_grow (self, sizeof (struct cdb));
        SvCUR_set (self, sizeof (struct cdb));
        SvPOK_only (self);
        RETVAL = cdb_init ((struct cdb *)SvPVX (self), fd);
        OUTPUT: RETVAL

void
cdb_free (SV *self)
	CODE:
        cdb_free ((struct cdb *)SvPVX (self));

SV *
cdb_get (SV *self, SV *key)
	CODE:
{
	unsigned int p;
        STRLEN l;
        const char *s = SvPVbyte (key, l);
        struct cdb *db = (struct cdb *)SvPVX (self);

        if (cdb_find (db, s, l) <= 0)
	  XSRETURN_UNDEF;

        p = cdb_datapos (db);
        l = cdb_datalen (db);
        RETVAL = newSVpvn (cdb_get (db, l, p), l);
}
        OUTPUT: RETVAL

#############################################################################

int
cdb_make_start (int fd)
	CODE:
        RETVAL = cdb_make_start (&make, fd);
        OUTPUT: RETVAL

int
cdb_make_add (SV *k, SV *v)
	CODE:
{
	STRLEN klen; const char *kp = SvPVbyte (k, klen);
        STRLEN vlen; const char *vp = SvPVbyte (v, vlen);
        RETVAL = cdb_make_add (&make, kp, klen, vp, vlen);
}
        OUTPUT: RETVAL

int
cdb_make_finish ()
	CODE:
        RETVAL = cdb_make_finish (&make);
        OUTPUT: RETVAL

