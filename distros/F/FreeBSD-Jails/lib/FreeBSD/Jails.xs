#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

// works like jls, but aims to be self-contained in order to
// be included in a Perl module someday
//
#include <sys/param.h>
#include <sys/jail.h>

#include <sys/param.h>
#include <sys/types.h>
#include <sys/uio.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>



// I copy-pasted this function from /usr/src/lib/libjail/jail_getid.c
// no need to reinvent the wheel
//
char * jail_getname(int jid)
{
        struct iovec jiov[6];
        char *name;
        char namebuf[255];

	char jail_errmsg[255];

        *(const void **)&jiov[0].iov_base = "jid";
        jiov[0].iov_len = sizeof("jid");
        jiov[1].iov_base = &jid;
        jiov[1].iov_len = sizeof(jid);
        *(const void **)&jiov[2].iov_base = "name";
        jiov[2].iov_len = sizeof("name");
        jiov[3].iov_base = namebuf;
        jiov[3].iov_len = sizeof(namebuf);
        *(const void **)&jiov[4].iov_base = "errmsg";
        jiov[4].iov_len = sizeof("errmsg");
        jiov[5].iov_base = jail_errmsg;
        jiov[5].iov_len = 255;
        jail_errmsg[0] = 0;
        jid = jail_get(jiov, 6, 0);
        if (jid < 0) {
                if (!jail_errmsg[0])
                        snprintf(jail_errmsg, 255, "jail_get: %s",
                            strerror(errno));
                return NULL;
        } else {
                name = strndup(namebuf,255);
                if (name == NULL)
                        strerror_r(errno, jail_errmsg, 255);
        }
        return name;
}

HV * enum_jails() { 
	struct iovec iov[4];
	u_int niov;
	int ret;
	int flags = 0;
	int jid = 0;
	char empty[] = "";
	int jail_id;

	HV *hash;

	hash = newHV();

	//printf("Searching for jails...\n");

	while( 1 ) { 

		*(const void **)&iov[0].iov_base = "lastjid";
		iov[0].iov_len = strnlen("lastjid",255) + 1;
		iov[1].iov_base = &jid;
		iov[1].iov_len = sizeof(jid);

		if( ( jail_id = jail_get(iov, 2, flags) ) == -1 ) { 
			if( errno == ENOENT ) { 
				//printf("probably finished\n");
				return hash;	
			}
			else { 
				perror("jail_get returned error");
				exit(1);
			}
		}
		//printf("jailid = %d\n",jail_id);

		//printf("jailname = %s\n", jail_getname( jail_id ) );

		char buf[255];	
		int n;
		n = snprintf( buf, 255, "%d" , jail_id); 

		hv_store( hash , buf , n, newSVpv( jail_getname( jail_id ) , strnlen(jail_getname( jail_id ),255) ) , 0 );
	
		jid = jail_id;
	}
}

MODULE = FreeBSD::Jails	PACKAGE = FreeBSD::Jails 
PROTOTYPES: ENABLE

SV * 
get_jails()
	CODE:
		HV *hash;
		hash = enum_jails();
		// @@TODO Figure out how this mortal stuff works exactly, I have 
		// only a few hours experience with XS
		// RETVAL = sv_2mortal( (SV*)newRV_noinc( (SV *)hash ) );
		SV* sv ;
		sv = (SV*)newRV_noinc( (SV *)hash ) ;
		// hash already has a reference count 1
		// we called newRV_noinc because we don't want the reference count to increase to 2.
		//RETVAL = (SV*)newRV_noinc( (SV *)hash ) ;
		RETVAL = sv;
		// printf("reference count is %d \n",SvREFCNT(sv));
	OUTPUT:
		RETVAL
