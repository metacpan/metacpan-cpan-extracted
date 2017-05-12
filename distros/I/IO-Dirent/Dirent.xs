#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <dirent.h>

MODULE = IO::Dirent          PACKAGE = IO::Dirent

#ifdef  DT_DIR
#define USE_D_NAME
#endif

SV *
readdirent(dirp)
        DIR             *dirp;
  PROTOTYPE: *
  PPCODE:
        Direntry_t      *dent;
	while ((dent = (Direntry_t *)readdir(dirp))) {
            HV *hdent;
	    hdent = (HV *)sv_2mortal((SV *)newHV());
#ifdef DIRNAMLEN /* from perl's config.h */
	    hv_store(hdent, "name",    4, newSVpv(dent->d_name, dent->d_namlen), 0);
#else
	    hv_store(hdent, "name",    4, newSVpv(dent->d_name, 0),              0);
#endif /* DIRNAMLEN */
#ifdef USE_D_NAME
            hv_store(hdent, "inode",   5, newSViv(dent->d_fileno),               0);
            hv_store(hdent, "type",    4, newSVnv(dent->d_type),                 0);
#endif
            XPUSHs(sv_2mortal(newRV((SV *) hdent)));
        }

SV *
nextdirent(dirp)
        DIR             *dirp;
  PROTOTYPE: *
  CODE:
        Direntry_t      *dent;
        HV              *hdent;
        if( dent = (Direntry_t *)readdir(dirp) ) {
            hdent = (HV *)sv_2mortal((SV *)newHV());
#ifdef DIRNAMLEN /* from perl's config.h */
	    hv_store(hdent, "name",    4, newSVpv(dent->d_name, dent->d_namlen), 0);
#else
	    hv_store(hdent, "name",    4, newSVpv(dent->d_name, 0),              0);
#endif /* DIRNAMLEN */
#ifdef USE_D_NAME
            hv_store(hdent, "inode",   5, newSViv(dent->d_fileno),               0);
            hv_store(hdent, "type",    4, newSVnv(dent->d_type),                 0);
#endif
        }

        else {
            XSRETURN_UNDEF;
        }

        RETVAL = newRV((SV *)hdent);

  OUTPUT:
        RETVAL
