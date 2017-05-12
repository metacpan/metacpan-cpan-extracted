/* This file is part of the Linux::SysInfo Perl module.
 * See http://search.cpan.org/dist/Linux-SysInfo/
 * Vincent Pit - 2007 */

#include <linux/version.h> /* LINUX_VERSION_CODE, KERNEL_VERSION() */
#include <sys/sysinfo.h>   /* <struct sysinfo>, sysinfo(), SI_LOAD_SHIFT */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define __PACKAGE__     "Linux::SysInfo"
#define __PACKAGE_LEN__ (sizeof(__PACKAGE__)-1)

/* --- Extended fields ----------------------------------------------------- */

#if ((defined(__i386__) || defined(__x86_64__)) && (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 3, 23))) || (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 3, 48))
# define LS_HAS_EXTENDED 1
#else
# define LS_HAS_EXTENDED 0
#endif

/* --- Keys ---------------------------------------------------------------- */

#define LS_KEY(K)            (ls_key_##K##_sv)
#if PERL_REVISION <= 4 || (PERL_REVISION == 5 && PERL_VERSION <= 6)
/* newSVpvn_share doesn't exist in perl-5.6.x */
# define LS_HASH(K)          (ls_key_##K##_hash)
# define LS_KEY_DECLARE(K)   STATIC const char LS_KEY(K)[] = #K; \
                             STATIC U32 LS_HASH(K) = 0
# define LS_KEY_DEFINE(K)    PERL_HASH(LS_HASH(K), LS_KEY(K), sizeof(#K)-1)
# define LS_KEY_STORE(H,K,V) hv_store((H), LS_KEY(K), sizeof(#K)-1, \
                                      (V), LS_HASH(K))
#else
# if PERL_REVISION > 5 || (PERL_REVISION == 5 && (PERL_VERSION > 9 || (PERL_VERSION == 9 && PERL_SUBVERSION >= 3)))
/* From perl-5.9.3 (#24802), the key is only a SVt_PV and one can get the hash
 * value with the SvSHARED_HASH() macro. */
#  define LS_HASH(K)         SvSHARED_HASH(LS_KEY(K))
# else
/* Before, the key was a SVt_PVIV and the hash was stored in the UV field. */
#  define LS_HASH(K)         SvUVX(LS_KEY(K))
# endif
# define LS_KEY_DECLARE(K)   STATIC SV *LS_KEY(K) = NULL
# define LS_KEY_DEFINE(K)    LS_KEY(K) = newSVpvn_share(#K, sizeof(#K)-1, 0)
# define LS_KEY_STORE(H,K,V) hv_store_ent((H), LS_KEY(K), (V), LS_HASH(K))
#endif

LS_KEY_DECLARE(uptime);
LS_KEY_DECLARE(load1);
LS_KEY_DECLARE(load5);
LS_KEY_DECLARE(load15);
LS_KEY_DECLARE(totalram);
LS_KEY_DECLARE(freeram);
LS_KEY_DECLARE(sharedram);
LS_KEY_DECLARE(bufferram);
LS_KEY_DECLARE(totalswap);
LS_KEY_DECLARE(freeswap);
LS_KEY_DECLARE(procs);
#if LS_HAS_EXTENDED
LS_KEY_DECLARE(totalhigh);
LS_KEY_DECLARE(freehigh);
LS_KEY_DECLARE(mem_unit);
#endif /* LS_HAS_EXTENDED */

/* --- XS ------------------------------------------------------------------ */

MODULE = Linux::SysInfo              PACKAGE = Linux::SysInfo

PROTOTYPES: ENABLE

BOOT:
{
 HV *stash;
 stash = gv_stashpvn(__PACKAGE__, __PACKAGE_LEN__, TRUE);
 newCONSTSUB(stash, "LS_HAS_EXTENDED", newSViv(LS_HAS_EXTENDED));

 LS_KEY_DEFINE(uptime);
 LS_KEY_DEFINE(load1);
 LS_KEY_DEFINE(load5);
 LS_KEY_DEFINE(load15);
 LS_KEY_DEFINE(totalram);
 LS_KEY_DEFINE(freeram);
 LS_KEY_DEFINE(sharedram);
 LS_KEY_DEFINE(bufferram);
 LS_KEY_DEFINE(totalswap);
 LS_KEY_DEFINE(freeswap);
 LS_KEY_DEFINE(procs);
#if LS_HAS_EXTENDED
 LS_KEY_DEFINE(totalhigh);
 LS_KEY_DEFINE(freehigh);
 LS_KEY_DEFINE(mem_unit);
#endif /* LS_HAS_EXTENDED */
}

SV *sysinfo()
PROTOTYPE:
PREINIT:
 struct sysinfo si;
 NV l;
 HV *hv;
CODE:
 if (sysinfo(&si) == -1) XSRETURN_UNDEF;

 hv = newHV();

 LS_KEY_STORE(hv, uptime,    newSViv(si.uptime));

 l = ((NV) si.loads[0]) / ((NV) (((U32) 1) << ((U32) SI_LOAD_SHIFT)));
 LS_KEY_STORE(hv, load1,     newSVnv(l));
 l = ((NV) si.loads[1]) / ((NV) (((U32) 1) << ((U32) SI_LOAD_SHIFT)));
 LS_KEY_STORE(hv, load5,     newSVnv(l));
 l = ((NV) si.loads[2]) / ((NV) (((U32) 1) << ((U32) SI_LOAD_SHIFT)));
 LS_KEY_STORE(hv, load15,    newSVnv(l));

 LS_KEY_STORE(hv, totalram,  newSVuv(si.totalram));
 LS_KEY_STORE(hv, freeram,   newSVuv(si.freeram));
 LS_KEY_STORE(hv, sharedram, newSVuv(si.sharedram));
 LS_KEY_STORE(hv, bufferram, newSVuv(si.bufferram));
 LS_KEY_STORE(hv, totalswap, newSVuv(si.totalswap));
 LS_KEY_STORE(hv, freeswap,  newSVuv(si.freeswap));
 LS_KEY_STORE(hv, procs,     newSVuv(si.procs));
#if LS_HAS_EXTENDED
 LS_KEY_STORE(hv, totalhigh, newSVuv(si.totalhigh));
 LS_KEY_STORE(hv, freehigh,  newSVuv(si.freehigh));
 LS_KEY_STORE(hv, mem_unit,  newSVuv(si.mem_unit));
#endif /* LS_HAS_EXTENDED */

 RETVAL = newRV_noinc((SV *) hv);
OUTPUT:
 RETVAL

