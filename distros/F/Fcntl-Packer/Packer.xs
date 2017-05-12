#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <unistd.h>
#include <fcntl.h>

#if(IVSIZE < 8)
#include "perl_math_int64.h"
#else
#define SvI64 SvIV
#define newSVi64 newSViv
#endif

SV *get(pTHX_ HV *hv, char *name, STRLEN len) {
  SV **svp = hv_fetch(hv, name, len, 0);
  if (svp && *svp && SvOK(*svp)) return *svp;
  return NULL;
}

#define GET(name, accesor, def)  ((tmp = get(aTHX_ hv, (name), strlen(name))) ? accesor(tmp) : def)

#define INIT_STRUCT(ptr) {                         \
    RETVAL = newSV(sizeof(*(ptr)));                \
    SvPOK_only(RETVAL);                            \
    SvCUR_set(RETVAL, sizeof(*(ptr)));             \
    Zero(SvPVX(RETVAL), sizeof(*(ptr)) + 1, char); \
    ptr = (void *)SvPVX(RETVAL);                   \
  }


#define GET_STRUCT(str, type) {                                         \
    STRLEN len;                                                         \
    char *pv = SvPV(sv, len);                                           \
    if (len != sizeof(str)) Perl_croak(aTHX_ "invalid size for packed '" #type "'"); \
    Copy(pv, (void *)&(str), len, char);                                \
  }

MODULE = Fcntl::Packer		PACKAGE = Fcntl::Packer		

BOOT:
#if (IVSIZE < 8)
  PERL_MATH_INT64_LOAD_OR_CROAK;
#else
  ;
#endif

SV *
pack_fcntl_flock(HV *hv)
PREINIT:
  struct flock *f;
  SV *tmp;
CODE:
  INIT_STRUCT(f);
  f->l_type   = GET("type",   SvIV,  0);
  f->l_whence = GET("whence", SvIV,  0);
  f->l_start  = GET("start",  SvI64, 0);
  f->l_len    = GET("len",    SvI64, 0);
  f->l_pid    = (sizeof(f->l_pid) > 4
                 ? GET("pid", SvI64, 0)
                 : GET("pid", SvIV,  0));
OUTPUT:
  RETVAL

SV *
unpack_fcntl_flock(SV *sv)
PREINIT:
  struct flock f;
  HV *hv;
CODE:
  GET_STRUCT(f, struct flock);
  hv = (HV *)sv_2mortal((SV*)newHV());
  hv_stores(hv, "type",   newSViv (f.l_type));
  hv_stores(hv, "whence", newSViv (f.l_whence));
  hv_stores(hv, "start",  newSVi64(f.l_start));
  hv_stores(hv, "len",    newSVi64(f.l_len));
  hv_stores(hv, "pid",    (sizeof(f.l_pid) > 4
                           ? newSVi64(f.l_pid)
                           : newSViv(f.l_pid)));
RETVAL = newRV_inc((SV*)hv);
OUTPUT:
  RETVAL


#ifdef F_SETOWN_EX 

SV *
pack_fcntl_f_owner_ex(HV *hv)
PREINIT:
  struct f_owner_ex *f;
  SV *tmp;
CODE:
  INIT_STRUCT(f);
  f->type = GET("type", SvIV, 0);
  f->pid = (sizeof(f->pid) > 4 
            ? GET("pid", SvI64, 0)
            : GET("pid", SvIV, 0));
OUTPUT:
  RETVAL

SV *
unpack_fcntl_f_owner_ex(SV *sv)
PREINIT:
  struct f_owner_ex f;
  HV *hv;
CODE:
  GET_STRUCT(f, struct f_owner_ex);
  hv = (HV *)sv_2mortal((SV*)newHV());
  hv_stores(hv, "type", newSViv (f.type));
  hv_stores(hv, "pid",    (sizeof(f.pid) > 4
                           ? newSVi64(f.pid)
                           : newSViv(f.pid)));
RETVAL = newRV_inc((SV*)hv);
OUTPUT:
  RETVAL

#endif /* F_SETOWN_EX */
