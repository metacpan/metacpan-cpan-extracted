/*
 Copyright 2005 Laurent Wacrenier

 This file is part of Maildir-Quota

 Maildir-Quota is free software; you can redistribute it and/or modify it
 under the terms of the GNU Lesser General Public License as
 published by the Free Software Foundation; either version 2 of the
 License, or (at your option) any later version.

 Maildir-Quota is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with Maildir-Quota; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 USA
*/

/*
   $Id: Quota.xs,v 1.4 2005/02/01 17:38:50 lwa Exp $
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <mdq.h>

typedef MDQ * Maildir_Quota;

#ifndef INT2PTR
#define INT2PTR(any,d) (any)(d)
#define PTR2IV(p) (IV)(p)
#endif

static void error(const char *fmt, va_list ap) {
    CV *cv = perl_get_cv("Maildir::Quota::error", 0);

    if (cv) {
      bool maybe_tainted = 0;
      SV *sv;

      dSP;
      ENTER;
      SAVETMPS;
  
      sv = sv_newmortal();
      sv_vsetpvfn(sv, fmt, strlen(fmt), &ap, NULL, 0, &maybe_tainted);

      PUSHMARK(SP);
      XPUSHs(sv);
      PUTBACK;      
      perl_call_sv((SV*)cv, G_VOID);
      FREETMPS;
      LEAVE;
    }
}
    

MODULE = Maildir::Quota		PACKAGE = Maildir::Quota		

Maildir_Quota
new(class, dir, string = NULL )
    char *class
    char *dir
    char *string 
  PROTOTYPE: $$;$
  CODE:
    RETVAL = mdq_open(dir, string);
  OUTPUT:
    RETVAL

int
test(q, bytes = 0, files = 0)
    Maildir_Quota q
    long bytes
    long files
  CODE:
    RETVAL = mdq_test(q, bytes, files) == 0;
  OUTPUT:
    RETVAL

void
DESTROY(q)
   Maildir_Quota q
 CODE:
   mdq_close(q);

void
add(q, bytes = 0, files = 0)
   Maildir_Quota q
   long bytes
   long files
 CODE:
   mdq_add(q, bytes, files);

long
bytes(q)
    Maildir_Quota q
  CODE:
    RETVAL = mdq_get(q, MDQ_BYTES_CURRENT);
    if (RETVAL < 0) XSRETURN_UNDEF ;
  OUTPUT:
    RETVAL

long
max_bytes(q)
    Maildir_Quota q
  CODE:
    RETVAL = mdq_get(q, MDQ_BYTES_MAX);
    if (RETVAL < 0) XSRETURN_UNDEF ;
  OUTPUT:
    RETVAL

    
long
files(q)
    Maildir_Quota q
  CODE:
    RETVAL = mdq_get(q, MDQ_FILES_CURRENT);
    if (RETVAL < 0) XSRETURN_UNDEF ;
  OUTPUT:
    RETVAL

long
max_files(q)
    Maildir_Quota q
  CODE:
    RETVAL = mdq_get(q, MDQ_FILES_MAX);
    if (RETVAL < 0) XSRETURN_UNDEF ;
  OUTPUT:
    RETVAL

BOOT:
  mdq_error = error;
