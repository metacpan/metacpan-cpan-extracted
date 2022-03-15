#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <cdb.h>

static struct cdb_make make;

MODULE = Geo::LatLon2Place		PACKAGE = Geo::LatLon2Place

PROTOTYPES: ENABLE

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

int
cdb_init (SV *self, int fd)
	CODE:
        sv_upgrade (self, SVt_PV);
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

