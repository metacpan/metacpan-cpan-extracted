/*
$Id: Door.xs 37 2005-06-07 05:50:05Z asari $
*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <stdlib.h>
#include <stropts.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <door.h>
#include <sys/ddi.h>
#include <sched.h>
#include <thread.h>
#include <limits.h>

#include "const-c.inc"

#define FILE_MODE (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
#define MAX_STRING 12000

#ifdef DEBUGGING
#define WARN(x) do {                                     \
        if ( (getenv("TEST_VERBOSE") != NULL) && (atoi(getenv("TEST_VERBOSE"))) ) \
            { PerlIO_stdoutf x; PerlIO_stdoutf ("\n"); } \
} while (0)
#else
#define WARN(x)
#endif

/* typedefs */
typedef struct {
    char ipc_door_data_pv[MAX_STRING];
    int  cur;
    int  len;
} ipc_door_data_t;

/* The server process */
static void servproc(void *cookie, char *dataptr, size_t datasize,
    door_desc_t *descptr, size_t ndesc)
{
    dSP;

    ipc_door_data_t arg, retval;
    SV          *result;
#ifdef _UCRED_H_
    ucred_t     **info;
#else
    door_cred_t info;
#endif
    SV          *sv_callback; /* serverprocess code reference */
    register SV *sv;          /* convenience variable */
    void        *tmp;
    char        *str;
    int         count;
            /* number of elements returned from sv_callback in Perl */

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    memmove(&arg, dataptr, min(datasize,sizeof(arg)));
    if ((str = calloc(1, MAX_STRING)) == NULL)
    {
        WARN(("memory allocation error: %s", strerror(errno)));
        return;
    }
    arg.ipc_door_data_pv[MAX_STRING-1]='\0';
    memmove((void*)str, arg.ipc_door_data_pv, MAX_STRING);

    sv=sv_newmortal();
    sv_callback=sv_newmortal();
    sv_callback = (SV *) cookie;
    sv = newSVpv( "", 0 );
    SvGROW(sv,MAX_STRING);
    memmove((void*)SvPVX(sv), str, MAX_STRING);
    SvCUR(sv)=arg.cur;
    SvLEN(sv)=arg.len;

    free(str);

    if (SvOK(sv))
        XPUSHs(sv);
    else {
        /* fall through; we shouldn't be here, but you never know. */
        WARN(("Something went horribly wrong in servproc"));
        return;
    }

    PUTBACK;

    /* grab the client's credentials before calling &main::serv */
#ifdef _UCRED_H_
/* the new way to get the client process credentials */
    if ( (*info = calloc(1, ucred_size())) == NULL )
    {
        WARN(("memory allocation error: %s\n", strerror(errno)));
        return;
    }
    if (door_ucred(info) < 0)
        WARN(("door_ucred() failed: %s\n", strerror(errno)));

    sv_setiv( get_sv("IPC::Door::CLIENT_EUID",TRUE), ucred_geteuid( *info));
    sv_setiv( get_sv("IPC::Door::CLIENT_EGID",TRUE), ucred_getegid( *info));
    sv_setiv( get_sv("IPC::Door::CLIENT_RUID",TRUE), ucred_getruid( *info));
    sv_setiv( get_sv("IPC::Door::CLIENT_RGID",TRUE), ucred_getrgid( *info));
    sv_setiv( get_sv("IPC::Door::CLIENT_PID", TRUE), ucred_getpid(  *info));

    ucred_free( *info );

#else
    if (door_cred(&info) < 0)
        WARN(("door_cred() failed: %s\n", strerror(errno)));

    sv_setiv( get_sv("IPC::Door::CLIENT_EUID",TRUE), info.dc_euid );
    sv_setiv( get_sv("IPC::Door::CLIENT_EGID",TRUE), info.dc_egid );
    sv_setiv( get_sv("IPC::Door::CLIENT_RUID",TRUE), info.dc_ruid );
    sv_setiv( get_sv("IPC::Door::CLIENT_RGID",TRUE), info.dc_rgid );
    sv_setiv( get_sv("IPC::Door::CLIENT_PID", TRUE), info.dc_pid  );

#endif

    count = call_sv(sv_callback, G_SCALAR);

    SPAGAIN;

    if (count != 1)
        WARN(("servproc: Expected 1 value from server process, but got %d values", count));
    result = POPs;

    str = SvPV( result, PL_na );
    memmove(retval.ipc_door_data_pv, str, MAX_STRING);
    retval.cur=SvCUR(result);
    retval.len=SvLEN(result);

    if (door_return((char *) &retval, sizeof(retval),NULL,0) < 0)
        WARN(("door_return() failed in servproc: %s\n", strerror(errno)));

    PUTBACK;

    FREETMPS;
    LEAVE;

}

/*
Start XSUB
*/

MODULE=IPC::Door    PACKAGE=IPC::Door

INCLUDE: const-xs.inc

int
is_door(sv)
    SV * sv
PREINIT:
    char*       path;
    HV*         hv;
    SV**        svp;
    struct stat buf;
CODE:
    if (sv_isobject(sv) && sv_derived_from(sv, "IPC::Door")) {
        hv=(HV*)SvRV(sv);
        svp=hv_fetch( hv, "path", 4, FALSE);
        path=SvPV(*svp, PL_na);
    } else {
        path=SvPV(sv, PL_na);
    }
    if (stat(path, &buf) <0)
        XSRETURN_UNDEF;
    RETVAL=S_ISDOOR(buf.st_mode);
OUTPUT:
    RETVAL

void
__info(sv_path, sv_class)
    SV * sv_path
    SV * sv_class
PREINIT:
    char * path = SvPV(sv_path, PL_na);
    char * class = SvPV(sv_class, PL_na);
    int fd;
    struct stat stat;
    door_info_t info;
    SV * sv;
PPCODE:
    if ((fd = open(path, O_RDONLY)) < 0) {
        WARN(("open() failed: %s\n", strerror(errno)));
        XSRETURN_UNDEF;
    }
    if (fstat(fd, &stat) < 0) {
        WARN(("fstat() failed:%s \n", strerror(errno)));
        XSRETURN_UNDEF;
    }
    if (S_ISDOOR(stat.st_mode) == 0) {
        WARN(("%s is not a door\n", path));
        XSRETURN_UNDEF;
    }
    if ( !strcmp( class, "IPC::Door::Server" ) )
        fd = DOOR_QUERY;

    /* path is a door, so gather info */
    if (door_info( fd, &info) < 0) {
        WARN(("door_info() failed: %s", strerror(errno)));
        XSRETURN_UNDEF;
    } else {
        XPUSHs(sv_2mortal(newSViv((long) info.di_target)));
/* I don't know how useful these data will be in Perl.
        XPUSHs(sv_2mortal(newSViv((long) info.di_proc)));
        XPUSHs(sv_2mortal(newSViv((long) info.di_data)));
*/
        XPUSHs(sv_2mortal(newSViv((long) info.di_attributes)));
        XPUSHs(sv_2mortal(newSViv((long) info.di_uniquifier)));
    }

    if (close(fd) < 0) WARN(("close() failed\n"));



MODULE=IPC::Door    PACKAGE=IPC::Door::Server
int
__create(sv_class, sv_path, sv_callback, sv_attr)
    SV *sv_class
    SV *sv_path
    SV *sv_callback
    SV *sv_attr
PROTOTYPE: $$$
CODE:
    SV   *sv_server = SvRV(sv_class); /* IPC::Door::Server object */
    int  fd;
    char *path      = SvPV(sv_path, PL_na);
    char *callback  = SvPV(sv_callback, PL_na);

    /* Make sure sv_server is sane */
    if (!sv_isobject(sv_class)) {
        WARN(("Non-object passed in __create()"));
        XSRETURN_UNDEF;
    }

    /* Make sure that sv_callback is sane */
    if (!SvROK(sv_callback) || (SvTYPE(SvRV(sv_callback)) != SVt_PVCV)) {
        WARN(("%s is not a code reference\n", callback));
        XSRETURN_UNDEF;
    }

    /* set sv_callback */
    sv_callback = *(hv_fetch((HV *)sv_server, "callback", 8, FALSE));

    if ((fd = door_create(servproc, sv_callback, SvIV(sv_attr))) < 0) {
        /* Why did it fail? */
        WARN(("door_create() failed: %s\n", strerror(errno)));
        if (close(fd) < 0) WARN(("close() on %s failed: %s\n", path, strerror(errno)));
        XSRETURN_UNDEF;
    } else {
        /* need to trap potential errors here */
        close(open(path, O_CREAT | O_RDWR, FILE_MODE));
        if ( (RETVAL=fattach(fd, path)) < 0) {
            WARN(("fattach() on %s failed: %s\n", path, strerror(errno)));
            XSRETURN_UNDEF;
        }
    }

void
__revoke(sv_class, sv_path)
    SV * sv_class
    SV * sv_path
CODE:
    char *class = SvPV(sv_class, PL_na);
    char *path  = SvPV(sv_path,  PL_na);
    int fd; // file descriptor for the door

    if ( fd = open(path, O_RDWR) < 0 )
        WARN(("open on %s failed during revoke(): %s\n", path, strerror(errno)));
    if ( door_revoke(fd) < 0 ) 
        WARN(("door_revoke() on %s failed: %s\n", path, strerror(errno)));

MODULE=IPC::Door    PACKAGE=IPC::Door::Client
SV *
__call(sv_class, sv_path, sv_input, sv_attr)
    SV * sv_class
    SV * sv_path
    SV * sv_input
    SV * sv_attr
CODE:
    char *class  = SvPV(sv_class, PL_na);
    char *path   = SvPV(sv_path, PL_na);
    int attr     = SvIV(sv_attr);
    int fd;
    ipc_door_data_t servproc_in, servproc_out;
    door_arg_t arg;
    SV   *output;
    char *s;

    ENTER;
    SAVETMPS;

    if ((fd = open(path, attr)) < 0) {
        WARN(("Failed to open %s: %s",path, strerror(errno)));
        XSRETURN_UNDEF;
    };

    if ( memmove((char*)servproc_in.ipc_door_data_pv, SvPV(sv_input, PL_na), MAX_STRING) == NULL )
        XSRETURN_UNDEF;
    else {
        servproc_in.cur=(int)SvCUR(sv_input);
        servproc_in.len=(int)SvLEN(sv_input);
    };

    arg.data_ptr  = (char *) &servproc_in;
    arg.data_size = sizeof(servproc_in);
    arg.desc_ptr  = NULL;
    arg.desc_num  = 0;
    arg.rbuf      = (char *) &servproc_out;
    arg.rsize     = sizeof(servproc_out);

    if (door_call(fd, &arg) < 0) {
        WARN(("door_call() failed: %s\n", strerror(errno)));
        if (close(fd) < 0) WARN(("close() failed: %s\n", strerror(errno)));
        XSRETURN_UNDEF;
    } else {
        if (close(fd) < 0) WARN(("close() failed: %s\n", strerror(errno)));

        /* Coerce output into something we can return to perl */
        /* Newz(0, (void*)s, 1, typeof(servproc_in.ipc_door_data_pv)); */
        if ((s=calloc(MAX_STRING,sizeof(char))) == NULL)
            XSRETURN_UNDEF;
        output = sv_newmortal();
        servproc_out.ipc_door_data_pv[MAX_STRING-1]='\0';
        if ( memmove(s, servproc_out.ipc_door_data_pv, MAX_STRING) == NULL )
            XSRETURN_UNDEF;
        output = newSVpv( "", 0 );
        SvGROW(output,MAX_STRING);
        memmove((void*)SvPVX(output), s, MAX_STRING);
        /* Move(s,SvPVX(output),1,typeof(servproc_in.ipc_door_data_pv)); */
        SvCUR(output) = servproc_out.cur;
        SvLEN(output) = servproc_out.len;
        free(s);

        FREETMPS;
        LEAVE;

        RETVAL = (SV *)output;
    }
OUTPUT:
    RETVAL
