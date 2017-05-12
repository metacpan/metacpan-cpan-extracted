#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* Solaris doesn't have u_int64_t type */
#ifndef u_int64_t
#define u_int64_t unsigned long long int
#endif

#include <glib.h>
#include <glibtop.h>
#include <glibtop/open.h>
#include <glibtop/close.h>

#ifndef GTOP_2_5_PLUS
#include <glibtop/xmalloc.h>
#endif

#include <glibtop/parameter.h>
#include <glibtop/union.h>
#include <glibtop/sysdeps.h>

#ifdef GTOP_2_5_PLUS
#define glibtop_free g_free
#endif

#ifdef GTOP_DEBUG
#define GTOP_TRACE(a) a
#else
#define GTOP_TRACE(a)
#endif

#ifdef USE_ITHREADS
#define cop_file PL_curcop->cop_file
#else
#define cop_file SvPVX(GvSV(PL_curcop->cop_filegv))
#endif

#define trace_malloc(self)                                  \
    GTOP_TRACE(fprintf(stderr, "malloc 0x%lx %d %ld:%s\n",  \
                       (unsigned long)self,                 \
                       __LINE__, (long)PL_curcop->cop_line, \
                       cop_file))

#define trace_free(self)                                    \
    GTOP_TRACE(fprintf(stderr, "free 0x%lx %d %ld:%s\n",    \
                       (unsigned long)self,                 \
                       __LINE__, (long)PL_curcop->cop_line, \
                       cop_file))


#define my_free(a) \
    trace_free(a); \
    safefree(a)

#define my_malloc safemalloc

typedef struct {
    unsigned old_method;
    int do_close;
    char *host;
    char *port;
} PerlGTop;

typedef PerlGTop * GTop;

#define OffsetOf(structure, field) \
(guint32)(&((structure *)NULL)->field)

#define any_ptr_deref(structure) \
((char *)structure + (int)(long)CvXSUBANY(cv).any_ptr)

#define newGTopXS(name, structure, field, type) \
    CvXSUBANY(newXS(name, XS_GTop_field_##type, __FILE__)).any_ptr = \
		    (void *)OffsetOf(structure, field);

#define newGTopXS_u_int64_t(name, structure, field) \
newGTopXS(name, structure, field, u_int64_t)

#define newGTopXS_int(name, structure, field) \
newGTopXS(name, structure, field, int)

#define newGTopXS_char(name, structure, field) \
newGTopXSub(name, structure, field, char)

static GTop my_gtop_new(pTHX_ char *host, char *port) 
{
    GTop RETVAL = (PerlGTop *)safemalloc(sizeof(PerlGTop));
    trace_malloc(RETVAL);
    RETVAL->old_method = glibtop_global_server->method;
    RETVAL->do_close = 0;
    RETVAL->host = NULL;
    RETVAL->port = NULL;

#if 0 && defined(USE_ITHREADS)
    Perl_warn(aTHX_ "perl=0x%lx my_gtop_new() called",
              (unsigned long)my_perl);
#endif
    
    if (host && port) {
	RETVAL->do_close = 1;
	my_setenv("LIBGTOP_HOST", host);
	my_setenv("LIBGTOP_PORT", port);
        New(0, RETVAL->host, strlen(host)+1, char);
        New(0, RETVAL->port, strlen(port)+1, char);
        Copy(host, RETVAL->host, strlen(host)+1, char);
        Copy(port, RETVAL->port, strlen(port)+1, char);
	glibtop_global_server->method = GLIBTOP_METHOD_INET;
	glibtop_init_r(&glibtop_global_server, 0, 0);
    }
    else {
	glibtop_init();
    }

    return RETVAL;
}

XS(XS_GTop_field_u_int64_t) 
{ 
    dXSARGS; 

    void *s = (void *)SvIV((SV*)SvRV(ST(0)));
    u_int64_t **ptr = (u_int64_t **)any_ptr_deref(s);

    ST(0) = sv_2mortal(newSVnv((unsigned long)*ptr));

    XSRETURN(1); 
}

XS(XS_GTop_field_int) 
{ 
    dXSARGS; 

    void *s = (void *)SvIV((SV*)SvRV(ST(0)));
    int **ptr = (int **)any_ptr_deref(s);

    ST(0) = sv_2mortal(newSViv((int)*ptr));

    XSRETURN(1); 
}

XS(XS_GTop_field_char) 
{ 
    dXSARGS; 

    void *s = (void *)SvIV((SV*)SvRV(ST(0)));
    char **ptr = (char **)any_ptr_deref(s);

    ST(0) = sv_2mortal(newSVpv((char *)*ptr, 0));

    XSRETURN(1); 
}

XS(XS_GTop_destroy)
{
    dXSARGS; 

    void *s = (void *)SvIV((SV*)SvRV(ST(0)));
    my_free(s);

    XSRETURN_EMPTY;
}

static void boot_GTop_constants(pTHX)
{
    HV *stash = gv_stashpv("GTop", TRUE);
    (void)newCONSTSUB(stash, "MAP_PERM_READ", 
		      newSViv(GLIBTOP_MAP_PERM_READ));
    (void)newCONSTSUB(stash, "MAP_PERM_WRITE", 
		      newSViv(GLIBTOP_MAP_PERM_WRITE));
    (void)newCONSTSUB(stash, "MAP_PERM_EXECUTE", 
		      newSViv(GLIBTOP_MAP_PERM_EXECUTE));
    (void)newCONSTSUB(stash, "MAP_PERM_SHARED", 
		      newSViv(GLIBTOP_MAP_PERM_SHARED));
    (void)newCONSTSUB(stash, "MAP_PERM_PRIVATE", 
		      newSViv(GLIBTOP_MAP_PERM_PRIVATE));
}

static char *netload_address_string(glibtop_netload *nl)
{
    struct in_addr addr;
    addr.s_addr = nl->address;
    return inet_ntoa(addr);
}
 
static SV *size_string(pTHX_ size_t size)
{
    SV *sv = newSVpv("    -", 5);
    if (size == (size_t)-1) {
	/**/
    }
    else if (!size) {
	sv_setpv(sv, "   0k");
    }
    else if (size < 1024) {
	sv_setpv(sv, "   1k");
    }
    else if (size < 1048576) {
	sv_setpvf(sv, "%4dk", (size + 512) / 1024);
    }
    else if (size < 103809024) {
	sv_setpvf(sv, "%4.1fM", size / 1048576.0);
    }
    else {
	sv_setpvf(sv, "%4dM", (size + 524288) / 1048576);
    }

    return sv;
}


#include "gtop.boot"
#include "gtopxs.boot"

MODULE = GTop   PACKAGE = GTop

PROTOTYPES: disable

BOOT:
    boot_GTop_interface(aTHX);
    boot_GTop_constants(aTHX);

INCLUDE: xs.gtop

void
END()

    CODE:
    glibtop_close();


GTop
_new(CLASS, host=NULL, port="42800")
    SV *CLASS
    char *host
    char *port

    CODE:
    RETVAL = my_gtop_new(aTHX_ host, port);

    OUTPUT:
    RETVAL
    
void
_possess(ref)
    SV *ref

    PREINIT:
    GTop self = (GTop)SvIV((SV*)SvRV(ref));

    CODE:
#ifdef EXAMPLE_CLONE_DEBUG
    Perl_warn(aTHX_ "(self=0x%lx)->possess was : 0x%lx\n", ST(0),
              (unsigned long)self);
#endif
    /* possess the guts of the original refect without changing its shell */
    sv_setiv((SV*)SvRV(ref), (IV)my_gtop_new(aTHX_ self->host, self->port));
#ifdef EXAMPLE_CLONE_DEBUG
    Perl_warn(aTHX_ "(self=0x%lx)->possess got : 0x%lx\n", ST(0),
              (GTop)SvIV((SV*)SvRV(ref)));
#endif

void
_destroy(self)
    GTop self

    CODE:
#if 0 && defined(USE_ITHREADS)
    Perl_warn(aTHX_ "perl=0x%lx: (self=0x%lx)->DESTROY\n",
              (unsigned long)my_perl, (unsigned long)self);
#endif
    if (self->do_close) {
	glibtop_close();
	glibtop_global_server->flags &= ~_GLIBTOP_INIT_STATE_OPEN;
    }
    glibtop_global_server->method = self->old_method;

    if (self->host) {
        my_free(self->host);
        my_free(self->port);
    }
    my_free(self);

SV *
size_string(size)
    size_t size

    CODE:
    RETVAL = size_string(aTHX_ size);

    OUTPUT:
    RETVAL
    
void
mountlist(gtop, all_fs)
    GTop gtop
    int all_fs

    PREINIT:
    GTop__Mountlist	RETVAL;
    GTop__Mountentry	entry;
    SV *svl, *sve;

    PPCODE:
    RETVAL = (glibtop_mountlist *)safemalloc(sizeof(*RETVAL));
    trace_malloc(RETVAL);
    entry = glibtop_get_mountlist(RETVAL, all_fs);

    svl = sv_newmortal();
    sv_setref_pv(svl, "GTop::Mountlist", (void*)RETVAL);
    XPUSHs(svl);

    if (GIMME_V == G_ARRAY) {
	sve = sv_newmortal();
	sv_setref_pv(sve, "GTop::Mountentry", (void*)entry);
	XPUSHs(sve);
    }
    else {
	glibtop_free(entry);
    }

void
proclist(gtop, which=0, arg=0)
    GTop gtop
    int which
    int arg

    PREINIT:
    GTop__Proclist	RETVAL;
    unsigned *ptr;
    SV *svl;
    AV *av;

    PPCODE:
    RETVAL = (glibtop_proclist *)safemalloc(sizeof(*RETVAL));
    trace_malloc(RETVAL);
    ptr = glibtop_get_proclist(RETVAL, which, arg);

    svl = sv_newmortal();
    sv_setref_pv(svl, "GTop::Proclist", (void*)RETVAL);
    XPUSHs(svl);

    if (GIMME_V == G_ARRAY) {
	int i;
	av = newAV();
	av_extend(av, RETVAL->number);
	for (i=0; i < RETVAL->number; i++) {
	    av_push(av, newSViv(ptr[i]));
	}
	XPUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    }
    glibtop_free(ptr);

void
proc_args(gtop, pid, arg=0)
    GTop gtop
    pid_t pid
    int arg

    PREINIT:
    GTop__ProcArgs	RETVAL;
    char *pargs;
    SV *svl;

    PPCODE:
    RETVAL = (glibtop_proc_args *)safemalloc(sizeof(*RETVAL));
    trace_malloc(RETVAL);
    pargs = glibtop_get_proc_args(RETVAL, pid, arg);

    svl = sv_newmortal();
    sv_setref_pv(svl, "GTop::ProcArgs", (void*)RETVAL);
    XPUSHs(svl);

    if (GIMME_V == G_ARRAY) {
	int len, total=0;
	char *ptr = pargs;
	AV *av = newAV();

	while (ptr && (len = strlen(ptr))) {
	    av_push(av, newSVpv(ptr,len));
	    total += (len+1);
	    if (total >= RETVAL->size) {
		break;
	    }
	    ptr += (len+1);
	}

	XPUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    }

    glibtop_free(pargs);

void
proc_map(gtop, pid)
    GTop gtop
    pid_t pid

    PREINIT:
    GTop__ProcMap	RETVAL;
    GTop__MapEntry	entry;
    SV *svl, *sve;

    PPCODE:
    RETVAL = (glibtop_proc_map *)safemalloc(sizeof(*RETVAL));
    trace_malloc(RETVAL);
    entry = glibtop_get_proc_map(RETVAL, pid);

    svl = sv_newmortal();
    sv_setref_pv(svl, "GTop::ProcMap", (void*)RETVAL);
    XPUSHs(svl);

    if (GIMME_V == G_ARRAY) {
	sve = sv_newmortal();
	sv_setref_pv(sve, "GTop::MapEntry", (void*)entry);
	XPUSHs(sve);
    }
    else {
	glibtop_free(entry);
    }

MODULE = GTop   PACKAGE = GTop::Mountentry   PREFIX = Mountlist_

void
DESTROY(entries)
    GTop::Mountentry entries

    CODE:
    glibtop_free(entries);

#define Mountlist_devname(entries, idx) entries[idx].devname
#define Mountlist_type(entries, idx) entries[idx].type
#define Mountlist_mountdir(entries, idx) entries[idx].mountdir
#define Mountlist_dev(entries, idx) entries[idx].dev

char *
Mountlist_devname(entries, idx=0)
    GTop::Mountentry entries
    int idx

char *
Mountlist_type(entries, idx=0)
    GTop::Mountentry entries
    int idx

char *
Mountlist_mountdir(entries, idx=0)
    GTop::Mountentry entries
    int idx

u_int64_t
Mountlist_dev(entries, idx=0)
    GTop::Mountentry entries
    int idx

MODULE = GTop   PACKAGE = GTop::MapEntry   PREFIX = MapEntry_

void
DESTROY(entries)
    GTop::MapEntry entries

    CODE:
    glibtop_free(entries);

char *
perm_string(entries, idx)
    GTop::MapEntry entries
    int idx

    PREINIT:
    char perm[6];

    CODE:
    perm[0] = (entries[idx].perm & GLIBTOP_MAP_PERM_READ) ? 'r' : '-';
    perm[1] = (entries[idx].perm & GLIBTOP_MAP_PERM_WRITE) ? 'w' : '-';
    perm[2] = (entries[idx].perm & GLIBTOP_MAP_PERM_EXECUTE) ? 'x' : '-';
    perm[3] = (entries[idx].perm & GLIBTOP_MAP_PERM_SHARED) ? 's' : '-';
    perm[4] = (entries[idx].perm & GLIBTOP_MAP_PERM_PRIVATE) ? 'p' : '-';
    perm[5] = '\0';
    RETVAL = perm;

    OUTPUT:
    RETVAL

#define MapEntry_flags(entries, idx) entries[idx].flags
#define MapEntry_start(entries, idx) entries[idx].start
#define MapEntry_end(entries, idx) entries[idx].end
#define MapEntry_offset(entries, idx) entries[idx].offset
#define MapEntry_perm(entries, idx) entries[idx].perm
#define MapEntry_inode(entries, idx) entries[idx].inode
#define MapEntry_device(entries, idx) entries[idx].device
#define MapEntry_filename(entries, idx) entries[idx].filename
#define MapEntry_has_filename(entries, idx) (entries[idx].flags & (1L << GLIBTOP_MAP_ENTRY_FILENAME))

u_int64_t
MapEntry_flags(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_start(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_end(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_offset(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_perm(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_inode(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_device(entries, idx=0)
    GTop::MapEntry entries
    int idx

char *
MapEntry_filename(entries, idx=0)
    GTop::MapEntry entries
    int idx

    CODE:
    if (MapEntry_has_filename(entries, idx)) {
	RETVAL = MapEntry_filename(entries, idx);
    }
    else {
	XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

MODULE = GTop   PACKAGE = GTop::Netload   PREFIX = netload_

char *
netload_address_string(self)
    GTop::Netload self

#define Uptime_uptime(self) self->uptime
#define Uptime_idletime(self) self->idletime

MODULE = GTop   PACKAGE = GTop::Uptime   PREFIX = Uptime_

double
Uptime_uptime(self)
    GTop::Uptime self

double
Uptime_idletime(self)
    GTop::Uptime self

MODULE = GTop   PACKAGE = GTop::Loadavg

AV *
loadavg(self)
    GTop::Loadavg self

    PREINIT:
    int i;
    
    CODE:
    RETVAL = newAV();
    for (i=0; i < 3; i++) {
	av_push(RETVAL, newSVnv(self->loadavg[i]));
    }

    OUTPUT:
    RETVAL

MODULE = GTop   PACKAGE = GTop::ProcState   PREFIX = proc_state_

#define proc_state_cmd(state) state->cmd
#define proc_state_state(state) state->state
#define proc_state_uid(state) state->uid
#define proc_state_gid(state) state->gid

char *
proc_state_cmd(state)
    GTop::ProcState state

char
proc_state_state(state)
    GTop::ProcState state

int
proc_state_uid(state)
    GTop::ProcState state

int
proc_state_gid(state)
    GTop::ProcState state
