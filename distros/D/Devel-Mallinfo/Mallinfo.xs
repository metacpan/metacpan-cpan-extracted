/* Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

   This file is part of Devel-Mallinfo.

   Devel-Mallinfo is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 3, or (at your option) any later
   version.

   Devel-Mallinfo is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>. */

#include "config.h"

#include <stdlib.h>
#if HAVE_MALLOC_H
#include <malloc.h>
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* for testing ... */
/* #define tmpfile()   fopen("/tmp/fullfs/tmp/tmpfile","w+b") */


#if HAVE_MALLOC_INFO
static void
slurp_fp_to_sv (FILE *fp, SV *sv)
{
  char buf[256];
  int  got;
  sv_setpvn (sv, "", 0);
  for (;;) {
    got = fread (buf, 1, sizeof(buf), fp);
    if (got == 0)
      return;
    sv_catpvn (sv, buf, got);
  }
}
#endif

MODULE = Devel::Mallinfo   PACKAGE = Devel::Mallinfo

HV *
mallinfo ()
CODE:
  {
#if HAVE_MALLINFO
    struct mallinfo m;

    /* grab the info before building the hash return, so as not to include
       that in "current" usage */
    m = mallinfo();
#endif
    RETVAL = newHV();
    sv_2mortal((SV*)RETVAL);
/**/
#if HAVE_MALLINFO
#define FIELD(field)                            \
  do {                                          \
    SV *val = newSViv (m.field);                \
    if (! hv_stores (RETVAL, #field, val))      \
      goto store_error;                         \
  } while (0)

    STRUCT_MALLINFO_FIELDS;
    goto done;

  store_error:
    croak ("cannot store to hash");
  done:
    ;
#endif
  }
OUTPUT:
    RETVAL


#if HAVE_MALLOC_INFO

int
malloc_info (options, fp)
    int options
    FILE *fp

void
malloc_info_string (options)
    int options
PPCODE:
  {
    FILE *fp;
    SV *ret = &PL_sv_undef;
    int err;

    fp = tmpfile();
    if (fp != NULL) {
      err = malloc_info (options, fp);
      if (err != 0) {
        errno = err;
      } else if (ferror (fp)) {
        /* write error to fp */
      } else {
        SV *sv;
        rewind (fp);
        sv = sv_newmortal();
        slurp_fp_to_sv (fp, sv);
        if (! ferror (fp))
          ret = sv;
      }
      if (fclose (fp) != 0) {
        ret = &PL_sv_undef;
      }
    }
    PUSHs(ret);
  }

#endif

#if HAVE_MALLOC_STATS

void
malloc_stats ()

#endif

#if HAVE_MALLOC_TRIM

int
malloc_trim (leave)
    size_t leave

#endif
