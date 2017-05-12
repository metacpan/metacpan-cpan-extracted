
/*
 * Simple.xs = part of IPC::Shm::Simple
 *
 * Originally part of IPC::ShareLite by Maurice Aubrey
 *
 * Adapted 2/2004 by Kevin Cody-Little <kcody@cpan.org>
 *
 * This code may be modified or redistributed under the terms
 * of either the Artistic or GNU General Public licenses, at
 * the modifier or redistributor's discretion.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/ipc.h> 
#include "sharelite.h"

/*
 * Some perl version compatibility stuff.
 * Taken from HTML::Parser
 */
#include "patchlevel.h"
#if PATCHLEVEL <= 4 /* perl5.004_XX */

#ifndef PL_sv_undef
   #define PL_sv_undef sv_undef
   #define PL_sv_yes   sv_yes
#endif

#ifndef PL_hexdigit
   #define PL_hexdigit hexdigit
#endif
                                                              
#if (PATCHLEVEL == 4 && SUBVERSION <= 4)
/* The newSVpvn function was introduced in perl5.004_05 */
static SV *
newSVpvn(char *s, STRLEN len)
{
    register SV *sv = newSV(0);
    sv_setpvn(sv,s,len);
    return sv;
}
#endif /* not perl5.004_05 */
#endif /* perl5.004_XX */            

MODULE = IPC::Shm::Simple PACKAGE = IPC::Shm::Simple

Share*
sharelite_shmat(shmid)
	int		shmid

Share*
sharelite_create(key, segsize, flags)
	key_t		key
	int		segsize
	int		flags

Share*
sharelite_attach(key)
	key_t		key

int
sharelite_shmdt(share)
	Share*		share

int
sharelite_remove(share)
	Share*		share

int
sharelite_lock(share, flags)
	Share*		share
	int		flags

int
sharelite_locked(share, flags)
	Share*		share
	int		flags

int
sharelite_store(share, data, length)
	Share*		share
	char*		data
        int             length

char* 
sharelite_fetch(share)
    Share*   share
  PREINIT:
    char*    data; 
    int      length;
  CODE:
    share  = (Share *)SvIV(ST(0));
    length = sharelite_fetch(share, &data);
    ST(0) = sv_newmortal();
    if (length >= 0) {
      sv_usepvn((SV*)ST(0), data, length);
    } else {
      sv_setsv(ST(0), &PL_sv_undef);
    }
 
int
sharelite_key(share)
	Share*		share

int
sharelite_shmid(share)
	Share*		share

int
sharelite_flags(share)
	Share*		share

int
sharelite_is_valid(share)
	Share*		share

int
sharelite_length(share)
	Share*		share

int
sharelite_serial(share)
	Share*		share

int
sharelite_nsegments(share)
	Share*		share

int
sharelite_top_seg_size(share)
	Share*		share

int
sharelite_chunk_seg_size(share,size)
	Share*		share
	int		size

int
sharelite_nconns(share)
	Share*		share

int
sharelite_nrefs(share)
	Share*		share

int
sharelite_incref(share)
	Share*		share

int
sharelite_decref(share)
	Share*		share

