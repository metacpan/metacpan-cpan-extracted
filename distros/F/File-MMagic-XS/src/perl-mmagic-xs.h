#ifndef __PERL_MMAGIC_XS_H__
#define __PERL_MMAGIC_XS_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#include "ppport.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include "MMagicST.h"

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define EATAB(x) \
    {while (isSPACE(*x)) ++x;}
#define MAXDESC   50       /* max leng of text description */
#define MAXstring 64        /* max leng of "string" types */
/* HOWMANY must be at least 4096 to make gzip -dcq work */
#define HOWMANY 4096
/* SMALL_HOWMANY limits how much work we do to figure out text files */
#define SMALL_HOWMANY 1024
#define MAXMIMESTRING 256

typedef struct _fmmagic {
    struct _fmmagic *next;     /* link to next entry */
    int lineno;         /* line number from magic file */

    short flag;
#define INDIR    1      /* if '>(...)' appears,  */
#define UNSIGNED 2       /* comparison is unsigned */
    short cont_level;       /* level of ">" */
    struct {
        char type;      /* byte short long */
        long offset;        /* offset from indirection */
    } in;
    long offset;        /* offset to magic number */
    unsigned char reln;     /* relation (0=eq, '>'=gt, etc) */
    char type;          /* int, short, long or string. */
    char vallen;        /* length of string value, if any */
#define BYTE    1
#define SHORT   2
#define LONG    4
#define STRING  5
#define DATE    6
#define BESHORT 7
#define BELONG  8
#define BEDATE  9
#define LESHORT 10
#define LELONG  11
#define LEDATE  12
    union VALUETYPE {
        unsigned char b;
        unsigned short h;
        unsigned long l;
        char s[MAXstring];
        unsigned char hs[2];    /* 2 bytes of a fixed-endian "short" */
        unsigned char hl[4];    /* 2 bytes of a fixed-endian "long" */
    } value;            /* either number or string */
    unsigned long mask;     /* mask before comparison with value */
    char nospflag;      /* supress space character */

    /* NOTE: this string is suspected of overrunning - find it! */
    char desc[MAXDESC];     /* description */
} fmmagic;

typedef struct _PerlFMM {
    fmmagic *magic;
    fmmagic *last;
    SV    *error;
    st_table *ext;
} PerlFMM;

#define FMM_OK(x) \
    (x != NULL)

#define FMM_SET_ERROR(s, e) \
    if (e && s->error) { \
	Safefree(s->error); \
    } \
    s->error = e;

#define FMM_RESULT(type, rc) \
    (rc == 0 ? \
        newSVpv(type, strlen(type)) : \
        &PL_sv_undef )

PerlFMM* PerlFMM_create(SV *class_sv);
PerlFMM* PerlFMM_clone(PerlFMM *self);
void PerlFMM_destroy(PerlFMM *state);
SV* PerlFMM_parse_magic_file(PerlFMM *self, char *file);
SV* PerlFMM_fhmagic(PerlFMM *self, SV *svio);
SV* PerlFMM_fsmagic(PerlFMM *self, char *filename);
SV* PerlFMM_bufmagic(PerlFMM *self, SV *buf);
SV* PerlFMM_ascmagic(PerlFMM *self, unsigned char *data);
SV* PerlFMM_get_mime(PerlFMM *self, char *filename);
SV* PerlFMM_add_magic(PerlFMM *self, char *magic);
SV* PerlFMM_add_file_ext(PerlFMM *self, char *ext, char *mime);

#endif
