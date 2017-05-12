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


void
hello()
	CODE:
		printf("Hello, world!\n");

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
                name = strdup(namebuf);
                if (name == NULL)
                        strerror_r(errno, jail_errmsg, 255);
        }
        return name;
}

int get_jails(int argc,char **argv) { 
	struct iovec iov[4];
	u_int niov;
	int ret;
	int flags = 0;
	int jid = 0;
	char empty[] = "";
	int jail_id;

	printf("Searching for jails...\n");

	while( 1 ) { 

		*(const void **)&iov[0].iov_base = "lastjid";
		iov[0].iov_len = strlen("lastjid") + 1;
		iov[1].iov_base = &jid;
		iov[1].iov_len = sizeof(jid);

		if( ( jail_id = jail_get(iov, 2, flags) ) == -1 ) { 
			if( errno == ENOENT ) { 
				printf("probably finished\n");
				exit(0);
			}
			else { 
				perror("jail_get returned error");
				exit(1);
			}
		}
		printf("jailid = %d\n",jail_id);

		printf("jailname = %s\n", jail_getname( jail_id ) );
	
		jid = jail_id;
	}
}


