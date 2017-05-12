#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include<sys/param.h>
#include<sys/ucred.h>
#include<sys/mount.h>

/* TODO: Figure out whether this can be detected intelligently */
#define FS_MAX 256

MODULE = FreeBSD::FsStat	PACKAGE = FreeBSD::FsStat
PROTOTYPES: ENABLE

SV *
getfsstat()
	INIT:
		AV * results;
		results = (AV *) sv_2mortal ((SV *) newAV ());
	CODE:
        	struct statfs buf[FS_MAX];
        	long bufsize = sizeof(buf);
        	int c = getfsstat( buf, bufsize, MNT_WAIT );
		if( c < 0 ) {
			croak("getfsstat returned error");
		}
		for( int i=0 ; i < c ; i++ ){
			HV * h;
			h = (HV *) sv_2mortal ((SV *) newHV ());
			hv_store(h, "f_type", 6, newSVnv(buf[i].f_type), 0);
			hv_store(h, "f_flags", 7, newSVnv(buf[i].f_flags), 0);
			hv_store(h, "f_bsize", 7, newSVnv(buf[i].f_bsize), 0);
			hv_store(h, "f_iosize", 8, newSVnv(buf[i].f_iosize), 0);
			hv_store(h, "f_blocks", 8, newSVnv(buf[i].f_blocks), 0);
			hv_store(h, "f_bfree", 7, newSVnv(buf[i].f_bfree), 0);
			hv_store(h, "f_bavail", 8, newSVnv(buf[i].f_bavail), 0);
			hv_store(h, "f_files", 7, newSVnv(buf[i].f_files), 0);
			hv_store(h, "f_ffree", 7, newSVnv(buf[i].f_ffree), 0);
			hv_store(h, "f_syncwrites", 12, newSVnv(buf[i].f_syncwrites), 0);
			hv_store(h, "f_asyncwrites", 12, newSVnv(buf[i].f_asyncwrites), 0);
			hv_store(h, "f_syncreads", 11, newSVnv(buf[i].f_syncreads), 0);
			hv_store(h, "f_asyncreads", 12, newSVnv(buf[i].f_asyncreads), 0);
			hv_store(h, "f_namemax", 9, newSVnv(buf[i].f_namemax), 0);
			hv_store(h, "f_owner", 7, newSVnv(buf[i].f_owner), 0);
			hv_store(h, "f_fstypename", 12, newSVpvn(buf[i].f_fstypename, MFSNAMELEN), 0);
			hv_store(h, "f_mntfromname", 13, newSVpv(buf[i].f_mntfromname, MNAMELEN ), 0);
			hv_store(h, "f_mntonname", 11, newSVpv(buf[i]. f_mntonname, MNAMELEN), 0);
			/* typedef struct fsid { int32_t val[2]; } fsid_t;   */
			/* hv_store(h, "f_fsid1", 7, newSVnv(buf[i].f_fsid.val[0]), 0);
			hv_store(h, "f_fsid2", 7, newSVnv(buf[i].f_fsid.val[1]), 0); */
			av_push( results , newRV((SV *)h));
		}
		RETVAL = newRV((SV *)results);
	OUTPUT:
		RETVAL

