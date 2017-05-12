/*
 * Daisuke Maki <dmaki@cpan.org>
 * All rights reserved.
 *
 * This is a complete port of the apache module mod_mime_magic.
 * This is based on httpd-2.0.52's mod_mime_magic.c -- portions of this
 * code was shamelessly borrowed from there. 
 *
 * fmm_mime_magic(file)
 *    -> fsmagic(file)
 *    -> read HOWMANY bytes
 *       -> apply softmagic(buf)
 *       -> apply ascmagic(buf)
 *
 * fmm_append_buf -> appends raw string to a buffer
 * fmm_append_mime -> appends mime string
 *
 */

/* Copyright 1999-2004 The Apache Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * mod_mime_magic: MIME type lookup via file magic numbers
 * Copyright (c) 1996-1997 Cisco Systems, Inc.
 *
 * This software was submitted by Cisco Systems to the Apache Software Foundation in July
 * 1997.  Future revisions and derivatives of this source code must
 * acknowledge Cisco Systems as the original contributor of this module.
 * All other licensing and usage conditions are those of the Apache Software Foundation.
 *
 * Some of this code is derived from the free version of the file command
 * originally posted to comp.sources.unix.  Copyright info for that program
 * is included below as required.
 * ---------------------------------------------------------------------------
 * - Copyright (c) Ian F. Darwin, 1987. Written by Ian F. Darwin.
 *
 * This software is not subject to any license of the American Telephone and
 * Telegraph Company or of the Regents of the University of California.
 *
 * Permission is granted to anyone to use this software for any purpose on any
 * computer system, and to alter it and redistribute it freely, subject to
 * the following restrictions:
 *
 * 1. The author is not responsible for the consequences of use of this
 * software, no matter how awful, even if they arise from flaws in it.
 *
 * 2.  origin of this software must not be misrepresented, either by
 * explicit claim or by omission.  Since few users ever read sources, credits
 * must appear in the documentation.
 *
 * 3. Altered versions must be plainly marked as such, and must not be
 * misrepresented as being the original software.  Since few users ever read
 * sources, credits must appear in the documentation.
 *
 * 4. This notice may not be removed or altered.
 * -------------------------------------------------------------------------
 *
 * For compliance with Mr Darwin's terms: this has been very significantly
 * modified from the free "file" command.
 * - all-in-one file for compilation convenience when moving from one
 *   version of Apache to the next.
 * - Memory allocation is done through the Apache API's apr_pool_t structure.
 * - All functions have had necessary Apache API request or server
 *   structures passed to them where necessary to call other Apache API
 *   routines.  (i.e. usually for logging, files, or memory allocation in
 *   itself or a called function.)
 * - struct magic has been converted from an array to a single-ended linked
 *   list because it only grows one record at a time, it's only accessed
 *   sequentially, and the Apache API has no equivalent of realloc().
 * - Functions have been changed to get their parameters from the server
 *   configuration instead of globals.  (It should be reentrant now but has
 *   not been tested in a threaded environment.)
 * - Places where it used to print results to stdout now saves them in a
 *   list where they're used to set the MIME type in the Apache request
 *   record.
 * - Command-line flags have been removed since they will never be used here.
 *
 * Ian Kluft <ikluft@cisco.com>
 * Engineering Information Framework
 * Central Engineering
 * Cisco Systems, Inc.
 * San Jose, CA, USA
 *
 * Initial installation          July/August 1996
 * Misc bug fixes                May 1997
 * Submission to Apache Software Foundation    July 1997
 *
 */

#ifndef __PERL_MMAGIC_XS_C__
#define __PERL_MMAGIC_XS_C__
#include "perl-mmagic-xs.h"

/*
 * data structures for tar file recognition
 * --------------------------------------------------------------------------
 * Header file for public domain tar (tape archive) program.
 *
 * @(#)tar.h 1.20 86/10/29    Public Domain. Created 25 August 1985 by John
 * Gilmore, ihnp4!hoptoad!gnu.
 *
 * Header block on tape.
 *
 * I'm going to use traditional DP naming conventions here. A "block" is a big
 * chunk of stuff that we do I/O on. A "record" is a piece of info that we
 * care about. Typically many "record"s fit into a "block".
 */
#define RECORDSIZE    512
#define NAMSIZ    100
#define TUNMLEN    32
#define TGNMLEN    32

union record {
    char charptr[RECORDSIZE];
    struct header {
    char name[NAMSIZ];
    char mode[8];
    char uid[8];
    char gid[8];
    char size[12];
    char mtime[12];
    char chksum[8];
    char linkflag;
    char linkname[NAMSIZ];
    char magic[8];
    char uname[TUNMLEN];
    char gname[TGNMLEN];
    char devmajor[8];
    char devminor[8];
    } header;
};

/* The magic field is filled with this if uname and gname are valid. */
#define    TMAGIC        "ustar  "  /* 7 chars and a null */

/*
 * includes for ASCII substring recognition formerly "names.h" in file
 * command
 *
 * Original notes: names and types used by ascmagic in file(1). These tokens are
 * here because they can appear anywhere in the first HOWMANY bytes, while
 * tokens in /etc/magic must appear at fixed offsets into the file. Don't
 * make HOWMANY too high unless you have a very fast CPU.
 */

/* these types are used to index the apr_table_t 'types': keep em in sync! */
/* HTML inserted in first because this is a web server module now */
#define L_HTML    0		/* HTML */
#define L_C       1		/* first and foremost on UNIX */
#define L_FORT    2		/* the oldest one */
#define L_MAKE    3		/* Makefiles */
#define L_PLI     4		/* PL/1 */
#define L_MACH    5		/* some kinda assembler */
#define L_ENG     6		/* English */
#define L_PAS     7		/* Pascal */
#define L_MAIL    8		/* Electronic mail */
#define L_NEWS    9		/* Usenet Netnews */

static char *types[] =
{
    "text/html",		/* HTML */
    "text/plain",		/* "c program text", */
    "text/plain",		/* "fortran program text", */
    "text/plain",		/* "make commands text", */
    "text/plain",		/* "pl/1 program text", */
    "text/plain",		/* "assembler program text", */
    "text/plain",		/* "English text", */
    "text/plain",		/* "pascal program text", */
    "message/rfc822",		/* "mail text", */
    "message/news",		    /* "news text", */
    "application/binary",	/* "can't happen error on names.h/types", */
    0
};

static struct names {
    char *name;
    short type;
} names[] = {

    /* These must be sorted by eye for optimal hit rate */
    /* Add to this list only after substantial meditation */
    {
	"<html>", L_HTML
    },
    {
	"<HTML>", L_HTML
    },
    {
	"<head>", L_HTML
    },
    {
	"<HEAD>", L_HTML
    },
    {
	"<title>", L_HTML
    },
    {
	"<TITLE>", L_HTML
    },
    {
	"<h1>", L_HTML
    },
    {
	"<H1>", L_HTML
    },
    {
	"<!--", L_HTML
    },
    {
	"<!DOCTYPE HTML", L_HTML
    },
    {
    "</html>", L_HTML
    },
    {
	"/*", L_C
    },				/* must precede "The", "the", etc. */
    {
	"#include", L_C
    },
    {
	"char", L_C
    },
    {
	"The", L_ENG
    },
    {
	"the", L_ENG
    },
    {
	"double", L_C
    },
    {
	"extern", L_C
    },
    {
	"float", L_C
    },
    {
	"real", L_C
    },
    {
	"struct", L_C
    },
    {
	"union", L_C
    },
    {
	"CFLAGS", L_MAKE
    },
    {
	"LDFLAGS", L_MAKE
    },
    {
	"all:", L_MAKE
    },
    {
	".PRECIOUS", L_MAKE
    },
    /*
     * Too many files of text have these words in them.  Find another way to
     * recognize Fortrash.
     */
#ifdef    NOTDEF
    {
	"subroutine", L_FORT
    },
    {
	"function", L_FORT
    },
    {
	"block", L_FORT
    },
    {
	"common", L_FORT
    },
    {
	"dimension", L_FORT
    },
    {
	"integer", L_FORT
    },
    {
	"data", L_FORT
    },
#endif /* NOTDEF */
    {
	".ascii", L_MACH
    },
    {
	".asciiz", L_MACH
    },
    {
	".byte", L_MACH
    },
    {
	".even", L_MACH
    },
    {
	".globl", L_MACH
    },
    {
	"clr", L_MACH
    },
    {
	"(input,", L_PAS
    },
    {
	"dcl", L_PLI
    },
    {
	"Received:", L_MAIL
    },
    {
	">From", L_MAIL
    },
    {
	"Return-Path:", L_MAIL
    },
    {
	"Cc:", L_MAIL
    },
    {
	"Newsgroups:", L_NEWS
    },
    {
	"Path:", L_NEWS
    },
    {
	"Organization:", L_NEWS
    },
    {
	NULL, 0
    }
};

#define NNAMES ((sizeof(names)/sizeof(struct names)) - 1)

/* append string to an existing buffer, using printf fashion */
/* Will refuse to append anything after MAXMIMESTRING into dst*/
static void
fmm_append_buf(PerlFMM *state, char **dst, char *str, ...)
{
    va_list ap;
    char buf[MAXMIMESTRING];
    SV *err;

    strcpy( buf, str );
    
    va_start(ap, str);
    vsnprintf(buf, sizeof(buf), str, ap);
    va_end(ap);

    if (strlen(buf) + 1 > MAXMIMESTRING - strlen(*dst)) {
        err = newSVpv("detected truncation in fmm_append_buf. refusing to append", 0);
        FMM_SET_ERROR(state, err);
        return;
    }
#ifdef FMM_DEBUG
    PerlIO_printf(PerlIO_stderr(), "dst = %s, buf = %s\n", *dst, buf);
#endif
    strncat(*dst, buf, strlen(buf));
}

/* APR_CTIME_LEN is defined in apr_time.h */
#define CTIME_LEN 25
#define CTIME_FMT "%a %b %d %H:%M:%S %Y"

/*
 * Convert the byte order of the data we are looking at
 */
static int 
fmm_mconvert(PerlFMM *state, union VALUETYPE *p, fmmagic *m)
{
    char *rt;
    SV *err;

    switch (m->type) {
        case BYTE:
        case SHORT:
        case LONG:
        case DATE:
            return 1;
        case STRING:
            /* Null terminate and eat the return */
            p->s[sizeof(p->s) - 1] = '\0';
            if ((rt = strchr(p->s, '\n')) != NULL)
                *rt = '\0';
            return 1;
        case BESHORT:
            p->h = (short) ((p->hs[0] << 8) | (p->hs[1]));
            return 1;
        case BELONG:
        case BEDATE:
            p->l = (long)
                ((p->hl[0] << 24) | (p->hl[1] << 16) | (p->hl[2] << 8) | (p->hl[3]));
            return 1;
        case LESHORT:
            p->h = (short) ((p->hs[1] << 8) | (p->hs[0]));
            return 1;
        case LELONG:
        case LEDATE:
            p->l = (long)
                ((p->hl[3] << 24) | (p->hl[2] << 16) | (p->hl[1] << 8) | (p->hl[0]));
            return 1;
        default:
            err = newSVpvf(
                "fmm_mconvert : invalid type %d in mconvert().",
                m->type
            );
            FMM_SET_ERROR(state, err);
            return 0;
    }
}

static int
fmm_mget(PerlFMM *state, union VALUETYPE *p, unsigned char *s, fmmagic *m, size_t nbytes)
{
    long offset = m->offset;

    if (offset + sizeof(union VALUETYPE) > nbytes) {
        return 0;
    }

    memcpy(p, s + offset, sizeof(union VALUETYPE));

    if (!fmm_mconvert(state, p, m)) {
        return 0;
    }

    if (m->flag & INDIR) {
        switch (m->in.type) {
            case BYTE:
                offset = p->b + m->in.offset;
                break;
            case SHORT:
                offset = p->h + m->in.offset;
                break;
            case LONG: 
                offset = p->l + m->in.offset;
                break;
        }
    
        if (offset + sizeof(union VALUETYPE) > nbytes)
              return 0;
    
        memcpy(p, s + offset, sizeof(union VALUETYPE));
    
        if (!fmm_mconvert(state, p, m)) {
            return 0;
        }
    }

    return 1;
}

#define isODIGIT(c) (((unsigned char)(c) >= '0') && ((unsigned char)(c) <= '7'))

/*
 * Quick and dirty octal conversion.
 *
 * Result is -1 if the field is invalid (all blank, or nonoctal).
 */
static long
from_oct(int digs, char *where)
{
    register long value;

    while (isSPACE(*where)) {   /* Skip spaces */
        where++;
        if (--digs <= 0)
            return -1;      /* All blank field */
    }
    value = 0;
    while (digs > 0 && isODIGIT(*where)) {  /* Scan til nonoctal */
        value = (value << 3) | (*where++ - '0');
        --digs;
    }

    if (digs > 0 && *where && !isSPACE(*where))
        return -1;      /* Ended on non-space/nul */

    return value;
}

/*
 * is_tar() -- figure out whether file is a tar archive.
 *
 * Stolen (by author of file utility) from the public domain tar program: Public
 * Domain version written 26 Aug 1985 John Gilmore (ihnp4!hoptoad!gnu).
 *
 * @(#)list.c 1.18 9/23/86 Public Domain - gnu $Id: mod_mime_magic.c,v 1.7
 * 1997/06/24 00:41:02 ikluft Exp ikluft $
 *
 * Comments changed and some code/comments reformatted for file command by Ian
 * Darwin.
 */


/*
 * Return 0 if the checksum is bad (i.e., probably not a tar archive), 1 for
 * old UNIX tar file, 2 for Unix Std (POSIX) tar file.
 */

static int
is_tar(unsigned char *buf, size_t nbytes)
{
    register union record *header = (union record *) buf;
    register int i;
    register long sum, recsum;
    register char *p;

    if (nbytes < sizeof(union record))
       return 0;

    recsum = from_oct(8, header->header.chksum);
    sum = 0;
    p = header->charptr;
    for (i = sizeof(union record); --i >= 0;) {
        /*
         * We can't use unsigned char here because of old compilers, e.g. V7.
         */
        sum += 0xFF & *p++;
    }

    /* Adjust checksum to count the "chksum" field as blanks. */
    for (i = sizeof(header->header.chksum); --i >= 0;)
        sum -= 0xFF & header->header.chksum[i];
    sum += ' ' * sizeof header->header.chksum;

    if (sum != recsum)
        return 0;       /* Not a tar archive */

    if (0 == strcmp(header->header.magic, TMAGIC))
        return 2;       /* Unix Standard tar archive */

    return 1;           /* Old fashioned tar archive */
}

/*
 * extend the sign bit if the comparison is to be signed
 */
static unsigned long 
fmm_signextend(PerlFMM *state, fmmagic *m, unsigned long v)
{
    SV *err;

    if (!(m->flag & UNSIGNED))
    switch (m->type) {
        /*
         * Do not remove the casts below.  They are vital. When later
         * compared with the data, the sign extension must have happened.
         */
    case BYTE:
        v = (char) v;
        break;
    case SHORT:
    case BESHORT:
    case LESHORT:
        v = (short) v;
        break;
    case DATE:
    case BEDATE:
    case LEDATE:
    case LONG:
    case BELONG:
    case LELONG:
        v = (long) v;
        break;
    case STRING:
        break;
    default:
        err = newSVpvf(
            "fmm_signextend: can't happen: m->type=%d\n", m->type);
        FMM_SET_ERROR(state, err);
        return -1;
    }
    return v;
}

static void
fmm_append_mime(PerlFMM *state, char **buf, union VALUETYPE *p, fmmagic *m)
{
    char *pp;
    unsigned long v;
    char *time_str;
    SV *err;

#ifdef FMM_DEBUG
    PerlIO_printf(PerlIO_stderr(), "fmm_append_mime: buf = %s\n", buf);
#endif 
    switch (m->type) {
        case BYTE:
            v = p->b;
            break;
        case SHORT:
        case BESHORT:
        case LESHORT:
            v = p->h;
            break;
        case STRING:
            if (m->reln == '=') {
                fmm_append_buf(state, buf, m->desc, m->value.s );
            } else {
                fmm_append_buf(state, buf, m->desc, p->s);
            }
            return;
        case DATE:
        case BEDATE:
        case LEDATE:
            Newz(1234, time_str, CTIME_LEN, char);
            strftime(time_str, CTIME_LEN, CTIME_FMT,
                localtime((const time_t *) &p->l));
            pp = time_str;
            fmm_append_buf(state, buf, m->desc, pp);
            Safefree(time_str);
            return;
        default:
            err = newSVpvf(
                "fmm_append_mime: invalud m->type (%d) in fmm_append_mime().\n", m->type);
            FMM_SET_ERROR(state, err);
            return;
    }

    v = fmm_signextend(state, m, v) & m->mask;
    fmm_append_buf(state, buf, m->desc, (unsigned long) v);
}

static int
fmm_mcheck(PerlFMM *state, union VALUETYPE *p, fmmagic *m)
{
    register unsigned long l = m->value.l;
    register unsigned long v;
    register unsigned char *a;
    register unsigned char *b;
    register int len;
    int matched;
    SV *err;

    if ((m->value.s[0] == 'x') && (m->value.s[1] == '\0')) {
        /* XXX - WTF does this mean?? */
        PerlIO_printf(PerlIO_stderr(), "fmm_mcheck: BOINK\n");
        return 1;
    }

    switch (m->type) {
        case BYTE:
            v = p->b;
            break;
        case SHORT:
        case BESHORT:
        case LESHORT:
            v = p->h;
            break;
        case LONG:
        case BELONG:
        case LELONG:
        case DATE:
        case BEDATE:
        case LEDATE:
            v = p->l;
            break;
        case STRING:
            l = 0;
            /* What we want here is: v = strncmp(m->value.s, p->s, m->vallen)
             * but ignoring any nulls. bcmp doesn't give -/+/0 and isn't
             * universally available anyway
             */
            v = 0;
            {
                a = (unsigned char *) m->value.s;
                b = (unsigned char *) p->s;
                len = m->vallen;

                while (--len >= 0) {
                    if ((v = *b++ - *a++) != 0) {
                        break;
                    }
                }
            }
            break;
        default:
            /* bogosity, pretend that it just wan't a match*/
            err = newSVpvf(
                    "fmm_mcheck: invalid type %d in mcheck().\n", m->type);
            FMM_SET_ERROR(state, err);
            return 0;
    }

    v = fmm_signextend(state, m, v) & m->mask;

    switch (m->reln) {
        case 'x':
            matched = 1;
            break;
        case '!':
            matched = v != l;
            break;
        case '=':
            matched = v == l;
            break;
        case '>':
            if (m->flag & UNSIGNED) {
                matched = v > l;
            } else {
                matched = (long) v > (long) l;
            }
            break;
        case '<':
            if (m->flag & UNSIGNED) {
                matched = v < l;
            } else {
                matched = (long) v < (long) l;
            }
            break;
        case '&':
            matched = (v & l) == l;
            break;
        case '^':
            matched = (v & l) != l;
            break;
        default:
            /* bogosity, pretend it didn't match */
            matched = 0;
            err = newSVpvf(
                "fmm_mcheck: Can't happen: invalid relation %d.\n", m->reln);
            FMM_SET_ERROR(state, err);
    }
    return matched;
}



/* Single hex char to int; -1 if not a hex char. */
static int 
fmm_hextoint(int c)
{
    if (isDIGIT(c))
    return c - '0';
    if ((c >= 'a') && (c <= 'f'))
    return c + 10 - 'a';
    if ((c >= 'A') && (c <= 'F'))
    return c + 10 - 'A';
    return -1;
}

/*
 * Convert a string containing C character escapes.  Stop at an unescaped
 * space or tab. Copy the converted version to "p", returning its length in
 * *slen. Return updated scan pointer as function result.
 */
static char *
fmm_getstr(PerlFMM *state, register char *s, register char *p, int plen, int *slen)
{
    char *origs = s, *origp = p;
    char *pmax = p + plen - 1;
    register int c;
    register int val;
    SV *err;

    while ((c = *s++) != '\0') {
    if (isSPACE(c))
        break;
    if (p >= pmax) {
        err = newSVpvf(
            "fmm_getstr: string too long: %s", origs);
        FMM_SET_ERROR(state, err);
        break;
    }
    if (c == '\\') {
        switch (c = *s++) {

        case '\0':
        goto out;

        default:
        *p++ = (char) c;
        break;

        case 'n':
        *p++ = '\n';
        break;

        case 'r':
        *p++ = '\r';
        break;

        case 'b':
        *p++ = '\b';
        break;

        case 't':
        *p++ = '\t';
        break;

        
        case 'f':
        *p++ = '\f';
        break;
        
        case 'v':
        *p++ = '\v';
        break;
        
        /* \ and up to 3 octal digits */
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7': 
        val = c - '0'; 
        c = *s++;   /* try for 2 */
        if (c >= '0' && c <= '7') { 
            val = (val << 3) | (c - '0');
            c = *s++;   /* try for 3 */
            if (c >= '0' && c <= '7')
            val = (val << 3) | (c - '0');
            else
            --s;
        }
        else
            --s;
        *p++ = (char) val;
        break;
        
        /* \x and up to 3 hex digits */
        case 'x':
        val = 'x';  /* Default if no digits */
        c = fmm_hextoint(*s++); /* Get next char */
        if (c >= 0) {
            val = c;
            c = fmm_hextoint(*s++);
            if (c >= 0) { 
            val = (val << 4) + c;
            c = fmm_hextoint(*s++);
            if (c >= 0) {
                val = (val << 4) + c;
            }
            else
                --s;
            }
            else
            --s;
        }
        else
            --s;
        *p++ = (char) val;
        break;
        }
    }
    else
        *p++ = (char) c;
    }
  out:
    *p = '\0';
    *slen = p - origp;
    return s;
}

/*
 * Read a numeric value from a pointer, into the value union of a magic
 * pointer, according to the magic type.  Update the string pointer to point
 * just after the number read.  Return 0 for success, non-zero for failure.
 */
static int fmm_getvalue(PerlFMM *state, fmmagic *m, char **p)
{
    int slen;

    if (m->type == STRING) {
        *p = fmm_getstr(state, *p, m->value.s, sizeof(m->value.s), &slen);
        m->vallen = slen;
    }
    else if (m->reln != 'x')
        m->value.l = fmm_signextend(state, m, strtol(*p, p, 0));
    return 0;
}

/* maps to mod_mime_magic::parse */
static int
fmm_parse_magic_line(PerlFMM *state, char *l, int lineno)
{
    char    *t;
    char    *s;
    fmmagic *m;
    SV *err;

    Newz(1234, m, 1, fmmagic);
    m->next       = NULL;
    m->flag       = 0;
    m->cont_level = 0;
    m->lineno     = lineno;

    if (! state->magic || !state->last) {
        state->magic = state->last = m;
    } else {
        state->last->next = m;
        state->last        = m;
    }
        
    while (*l == '>') {
        l++; /* step over */
        m->cont_level++;
    }

    if (m->cont_level  != 0 && *l == '(') {
        l++; /* step over */
        m->flag |= INDIR;
    }

    /* get offset, then skip over it */
    m->offset = (int) strtol(l, &t, 0);
    if (l == t) {
        err = newSVpvf("Invalid offset in mime magic file, line %d: %s", lineno, l);
        goto error;
    }

    l = t;

    if (m->flag & INDIR) {
        m->in.type = LONG;
        m->in.offset = 0;
        /* read [.lbs][+=]nnnnn) */
        if (*l == '.') {
            switch (*++l) {
                case 'l':
                    m->in.type = LONG;
                    break;
                case 's':
                    m->in.type = SHORT;
                    break;
                case 'b':
                    m->in.type = BYTE;
                    break;
                default:
                    err = newSVpvf(
                        "Invalid indirect offset type in mime magic file, line %d: %c", lineno, *l);
                    goto error;
            }
            l++;
        }
        s = l;
        if (*l == '+' || *l == '-') {
            l++;
        }
        if (isdigit((unsigned char) *l)) {
            m->in.offset = strtol(l, &t, 0);
            if (*s == '-') {
                m->in.offset = -(m->in.offset);
            }
        } else {
            t = l;
        }
        if (*t++ != ')') {
            err = newSVpvf(
                "Missing ')' in indirect offset in mime magic file, line %d", lineno);
            goto error;
        }
        l = t;
    } 

    while (isdigit((unsigned char) *l)) {
        ++l;
    }
    EATAB(l);

#define NBYTE           4
#define NSHORT          5
#define NLONG           4
#define NSTRING         6
#define NDATE           4
#define NBESHORT        7
#define NBELONG         6
#define NBEDATE         6
#define NLESHORT        7
#define NLELONG         6
#define NLEDATE         6

    if (*l == 'u') {
    ++l;
    m->flag |= UNSIGNED;
    }

    /* get type, skip it */
    if (strncmp(l, "byte", NBYTE) == 0) {
        m->type = BYTE;
        l += NBYTE;
    }
    else if (strncmp(l, "short", NSHORT) == 0) {
        m->type = SHORT;
        l += NSHORT;
    }
    else if (strncmp(l, "long", NLONG) == 0) {
        m->type = LONG;
        l += NLONG;
    }
    else if (strncmp(l, "string", NSTRING) == 0) {
        m->type = STRING;
        l += NSTRING;
    }
    else if (strncmp(l, "date", NDATE) == 0) {
        m->type = DATE;
        l += NDATE;
    }
    else if (strncmp(l, "beshort", NBESHORT) == 0) {
        m->type = BESHORT;
        l += NBESHORT;
    }
    else if (strncmp(l, "belong", NBELONG) == 0) {
        m->type = BELONG;
        l += NBELONG;
    }
    else if (strncmp(l, "bedate", NBEDATE) == 0) {
        m->type = BEDATE;
        l += NBEDATE;
    }
    else if (strncmp(l, "leshort", NLESHORT) == 0) {
        m->type = LESHORT;
        l += NLESHORT;
    }
    else if (strncmp(l, "lelong", NLELONG) == 0) {
        m->type = LELONG;
        l += NLELONG;
    }
    else if (strncmp(l, "ledate", NLEDATE) == 0) {
        m->type = LEDATE;
        l += NLEDATE;
    }
    else {
        err = newSVpvf("Invalid type in mime magic file, line %d: %s", lineno, l);
        goto error;
    }
    /* New-style anding: "0 byte&0x80 =0x80 dynamically linked" */
    if (*l == '&') {
        ++l;
        m->mask = fmm_signextend(state, m, strtol(l, &l, 0));
    }
    else {
        m->mask = ~0L;
    }
    EATAB(l);

    switch (*l) {
    case '>':
    case '<':
    /* Old-style anding: "0 byte &0x80 dynamically linked" */
    case '&':
    case '^':
    case '=':
        m->reln = *l;
        ++l;
        break;
    case '!':
        if (m->type != STRING) {
            m->reln = *l;
            ++l;
            break;
        }
        /* FALL THROUGH */
    default:
        if (*l == 'x' && isSPACE(l[1])) {
            m->reln = *l;
            ++l;
            goto GetDesc;   /* Bill The Cat */
        }
        m->reln = '=';
        break;
    }
    EATAB(l);
    
    if (fmm_getvalue(state, m, &l))
        return -1;

    /*
     * now get last part - the description
     */
GetDesc:
    EATAB(l);
    if (l[0] == '\b') {
        ++l;
        m->nospflag = 1;
    }
    else if ((l[0] == '\\') && (l[1] == 'b')) {
        ++l;
        ++l;
        m->nospflag = 1;
    }
    else {
        m->nospflag = 0;
    }
    strncpy(m->desc, l, sizeof(m->desc) - 1);
    m->desc[sizeof(m->desc) - 1] = '\0';

    return 0;

 error:
    FMM_SET_ERROR(state, err);
    croak(SvPV_nolen(err));
}

/* maps to mod_mime_magic::apprentice */
static int
fmm_parse_magic_file(PerlFMM *state, char *file)
{
    int   ws_offset;
    int   lineno;
    int   errs;
/*    char  line[BUFSIZ + 1];*/
    PerlIO *fhandle;
    SV *err;
    SV *sv = sv_2mortal(newSV(BUFSIZ));
    SV *PL_rs_orig = newSVsv(PL_rs);
    char *line;

    fhandle = PerlIO_open(file, "r");
    if (! fhandle) {
        err = newSVpvf(
            "Failed to open %s: %s", file, strerror(errno));
        FMM_SET_ERROR(state, err);
        PerlIO_close(fhandle);
        return -1;
    }

    /*
     * Parse it line by line
     * $/ (slurp mode) is needed here
     */
    PL_rs = sv_2mortal(newSVpvn("\n", 1));
    for(lineno = 1; sv_gets(sv, fhandle, 0) != NULL; lineno++) {
        line = SvPV_nolen(sv);
        /* delete newline */
        if (line[0]) {
            line[strlen(line) - 1] = '\0';
        }

        /* skip leading whitespace */
        ws_offset = 0;
        while (line[ws_offset] && isSPACE(line[ws_offset])) {
            ws_offset++;
        }

        /* skip blank lines */
        if (line[ws_offset] == 0) {
            continue;
        }

        if (line[ws_offset] == '#') {
            continue;
        }

        if (fmm_parse_magic_line(state, line, lineno) != 0) {
            ++errs;
        }
    }
    PerlIO_close(fhandle);
    PL_rs = PL_rs_orig;

    return 1;
}

/* fmm_fsmagic 
 * 
 * Checks the file's attribute by checking stat() and populates the
 * mime_type variable with a mime type. If no appropriate mime type is
 * found then returns -1 on error, 1 if undetermined because we 
 * saw that it's a regular file which needs further processing to 
 * determine its file type
 */

#define DIR_MAGIC_TYPE    "x-system/x-unix;  directory"
#define FIFO_MAGIC_TYPE   "x-system/x-unix;  named pipe"
#define SOCKET_MAGIC_TYPE "x-system/x-unix;  socket"
#define BLOCK_MAGIC_TYPE  "x-system/x-unix;  block special file"
#define CHAR_MAGIC_TYPE   "x-system/x-unix;  character special file"
#define EMPTY_MAGIC_TYPE  "x-system/x-unix;  empty"
#define BROKEN_SYMLINK_MAGIC_TYPE "x-system/x-unix;  broken symlink"
static int
fmm_fsmagic_stat(PerlFMM *state, struct stat *sb, char **mime_type)
{
    SV *err;

    if (sb->st_mode & S_IFREG) {
        /* Regular file. Need to check for emptiness */
        if (sb->st_size == 0) {
            strcpy(*mime_type, EMPTY_MAGIC_TYPE);
            return 0;
        }
        return 1;
    }

    /* it's not a regular file, so check other possibilities... */
    if (sb->st_mode & S_IFIFO) {
        strcpy(*mime_type, FIFO_MAGIC_TYPE);
    } else if (sb->st_mode & S_IFCHR) {
        strcpy(*mime_type, CHAR_MAGIC_TYPE);
    } else if (sb->st_mode & S_IFDIR) {
        strcpy(*mime_type, DIR_MAGIC_TYPE);
    } else if (sb->st_mode & S_IFBLK) {
        strcpy(*mime_type, BLOCK_MAGIC_TYPE);
    } else if (sb->st_mode & S_IFLNK) {
        /* According to mod_mime_magic.c, the only reason stat() will return
         * a S_IFLNK in st_mode is that the symlink is broken
         */
        strcpy(*mime_type, BROKEN_SYMLINK_MAGIC_TYPE);
    } else if (sb->st_mode & S_IFSOCK) {
        strcpy(*mime_type, SOCKET_MAGIC_TYPE);
    } else {
        /* Unknown type? */
        err = newSVpv("fmm_fsmagic: invalid file type", 0);
        FMM_SET_ERROR(state, err);
        return -1;
    }

    return 0;
}

static int
fmm_fsmagic(PerlFMM *state, char *filename, char **mime_type)
{
    struct stat sb;
    SV *err;

    if (stat(filename, &sb) == -1) {
        err = newSVpvf(
            "Failed to stat file %s: %s", filename, strerror(errno));
        FMM_SET_ERROR(state, err);
        return -1;
    }

    if (fmm_fsmagic_stat(state, &sb, mime_type) == 0) {
        return 0;
    }

    return 1;
}

static int
fmm_ascmagic(unsigned char *buf, size_t nbytes, char **mime_type)
{
    int has_escapes = 0;
    unsigned char *s;
    char nbuf[HOWMANY + 1]; /* one extra for terminating '\0' */
    char *token;
    register struct names *p;
    int small_nbytes;
    char *strtok_state;
    unsigned char *tp;

    /* these are easy, do them first */

    /*
     * for troff, look for . + letter + letter or .\"; this must be done to
     * disambiguate tar archives' ./file and other trash from real troff
     * input.
     */
    if (*buf == '.') {
        tp = buf + 1;
        while (isSPACE(*tp))
            ++tp;       /* skip leading whitespace */
        if ((isALNUM(*tp) || *tp == '\\') && (isALNUM(*(tp + 1)) || *tp == '"')) {
            strcpy(*mime_type, "application/x-troff");
            return 0;
        }
    }

    if ((*buf == 'c' || *buf == 'C') && isSPACE(*(buf + 1))) {
        /* Fortran */
        strcpy(*mime_type, "text/plain");
        return 0;
    }

    /* look for tokens from names.h - this is expensive!, so we'll limit
     * ourselves to only SMALL_HOWMANY bytes */
    small_nbytes = (nbytes > SMALL_HOWMANY) ? SMALL_HOWMANY : nbytes;

    /* make a copy of the buffer here because strtok() will destroy it */
    s = (unsigned char *) memcpy(nbuf, buf, small_nbytes);
    s[small_nbytes] = '\0';
    has_escapes = (memchr(s, '\033', small_nbytes) != NULL);
    while ((token = strtok_r((char *) s, " \t\n\r\f", &strtok_state)) != NULL) {
        s = NULL;       /* make strtok() keep on tokin' */
        for (p = names; p < names + NNAMES; p++) {
            if (strEQ(p->name, token)) {
                strcpy(*mime_type, types[p->type]);
                if (has_escapes)
                    strcat(*mime_type, " (with escape sequences)");
                return 0;
            }
        }
    }

    int is_tarball = is_tar(buf, nbytes);
    if ( is_tarball == 1 || is_tarball == 2 ) {
        /* 1: V7 tar archive */
        /* 2: POSIX tar archive */
        strcpy(*mime_type, "application/x-tar");
        return 0;
    }

    /* all else fails, but it is ascii... */
    strcpy(*mime_type, "text/plain");
    return 0;
}

static int
fmm_softmagic(PerlFMM *state, unsigned char **buf, int size, char **mime_type)
{
    int cont_level = 0;
    int need_separator = 0;
    union VALUETYPE p;
    fmmagic *m_cont;
    fmmagic *m = state->magic;

    for (; m; m = m->next) {
        /* check if main entry matches */
        if (! fmm_mget(state, &p, *buf, m, size) || !fmm_mcheck(state, &p, m)) {
            /* main entry didn't match, flush its continuations */
            if (! m->next || (m->next->cont_level == 0)) {
                continue;
            }

            m_cont = m->next;
            while (m_cont && (m_cont->cont_level != 0)) {
                /* this trick allows us to keep *m in sync when the continue
                 * advances the pointer
                 */
                m = m_cont;
                m_cont = m_cont->next;
            }
            continue;
        }
        /* if we get here, the main entry rule was a match */
        /* this will be the last run through the loop */

        /* print the match */
        fmm_append_mime(state, mime_type, &p, m);

        /* if we printed something, we'll need to print a blank before
         * we print something else */
        if (m->desc[0]) 
            need_separator = 1;

        /* and any continuations that match */
        cont_level++;

        m = m->next;
        while (m && (m->cont_level != 0)) {
            if (cont_level >= m->cont_level) {
                if (cont_level > m->cont_level) {
                    /* We're at the end of the level "cont_level"
                     * continuations.
                     */
                    cont_level = m->cont_level;
                }

                if (fmm_mget(state, &p, *buf, m, size) && fmm_mcheck(state, &p, m)) {
                    /* This continuation matched. Print its message, with a
                     * blank before it if the previous item printed and this
                     * isn't empty.
                     */
                    /* space if previous printed */
                    if (need_separator && (m->nospflag == 0) && (m->desc[0] != '\0')) {
                        /* putchar  ' ' */
                        fmm_append_buf(state, mime_type, " ");
                        need_separator = 0;
                    }
                    fmm_append_mime(state, mime_type, &p, m);
                    if (m->desc[0]) 
                        need_separator = 1;

                    /* If we see any continuations at a higher level,
                     * process them.
                     */
                    cont_level++;
                }
            }
            /* move to next continuation record */
            m = m->next;
        }
        return 0;
    }
    return 1;
}

/* Perform mime magic on a PerlIO handle */
/* Perform mime magic on a buffer */
static int
fmm_bufmagic(PerlFMM *state, unsigned char **buffer, char **mime_type)
{
    if (fmm_softmagic(state, buffer, HOWMANY, mime_type) == 0) {
#ifdef FMM_DEBUG
    PerlIO_printf(PerlIO_stderr(), "[fmm_bufmagic]: fmm_softmagic returns 0\n");
#endif
        return 0;
    }

    if (fmm_ascmagic(*buffer, HOWMANY, mime_type) == 0) {
#ifdef FMM_DEBUG
    PerlIO_printf(PerlIO_stderr(), "[fmm_bufmagic]: fmm_ascmagic returns 0\n");
#endif
        return 0;
    }

    return 1;
}

static int
fmm_fhmagic(PerlFMM *state, PerlIO *fhandle, char **mime_type)
{
    SV *err;
    unsigned char *data;
    int ret = -1;

    Newz(1234, data, HOWMANY + 1, unsigned char);
    if (! PerlIO_read(fhandle, data, HOWMANY)) {
        err = newSVpvf(
            "Failed to read from handle: %s",
            strerror(errno)
        );
        FMM_SET_ERROR(state, err);
        Safefree(data);
        return -1;
    }

    ret = fmm_bufmagic(state, &data, mime_type);
    Safefree(data);

    return ret;
}

static int
fmm_ext_magic(PerlFMM *state, char *file, char **mime_type)
{
    char ext[BUFSIZ];
    char *temp_mimetype;
    /* Look for the last dot */
    char *dot = rindex(file, '.');
    if (dot == 0x00) {
        return 0;
    }

    strncpy(ext, dot + 1, BUFSIZ);
    if (st_lookup(state->ext, (st_data_t) ext, (st_data_t *) &temp_mimetype) == 0) {
        return 1;
    }
    strncpy(*mime_type, temp_mimetype, MAXMIMESTRING);
    return 0;
}

static int
fmm_mime_magic(PerlFMM *state, char *file, char **mime_type)
{
    PerlIO *fhandle;
    SV *err;
    int ret;

    if ((ret = fmm_fsmagic(state, file, mime_type)) == 0) {
        return 0;
    }
    if (ret == -1) {
        return -1;
    }

    fhandle = PerlIO_open(file, "r");
    if (!fhandle) {
        err = newSVpvf(
            "Failed to open file %s: %s", file, strerror(errno));
        FMM_SET_ERROR(state, err);
        return -1;
    }

    if ((ret = fmm_fhmagic(state, fhandle, mime_type)) == 0) {
#ifdef FMM_DEBUG
    PerlIO_printf(PerlIO_stderr(), "[fmm_mime_magic]: fmm_fhmagic returns 0\n");
#endif
        PerlIO_close(fhandle);
        return 0;
    }
    PerlIO_close(fhandle);

    return fmm_ext_magic(state, file, mime_type);
}

PerlFMM*
PerlFMM_create(SV *class_sv) {
    PerlFMM *state;

    PERL_UNUSED_VAR(class_sv);
    Newz(1234, state, 1, PerlFMM);
    state->magic = NULL;
    state->error = NULL;
    state->ext   = st_init_strtable();

    return state;
}

PerlFMM *
PerlFMM_clone(PerlFMM *self)
{
    PerlFMM *state;
    fmmagic *d, *s;

    state = PerlFMM_create(NULL);
    st_free_table(state->ext);
    state->ext = st_copy( self->ext );

    s = self->magic;
    Newxz(d, 1, fmmagic);
    memcpy(d, s, sizeof(fmmagic));
    state->magic = d;
    while (s->next != NULL) {
        Newxz(d->next, 1, fmmagic);
        memcpy(d->next, s->next, sizeof(struct _fmmagic));
        d = d->next;
        s = s->next;
    }
    state->last = d;
    state->last->next = NULL;

    return state;
}

SV *
PerlFMM_parse_magic_file(PerlFMM *self, char *file)
{
    FMM_SET_ERROR(self, NULL);
    return fmm_parse_magic_file(self, file) ?
        &PL_sv_yes : &PL_sv_undef;
}

SV *
PerlFMM_add_magic(PerlFMM *self, char *magic)
{
    return fmm_parse_magic_line(self, magic, 0) == 0 ?
        &PL_sv_yes : &PL_sv_undef
    ;
}

SV *
PerlFMM_add_file_ext(PerlFMM *self, char *ext, char *mime)
{
    char *dummy;
    SV *ret;

    if (st_lookup(self->ext, (st_data_t) ext, (st_data_t *) &dummy)) {
        ret = &PL_sv_no;
    } else {
        st_insert(self->ext, (st_data_t) ext, (st_data_t) mime);
        ret = &PL_sv_yes;
    }
    return ret;
}

SV *
PerlFMM_fhmagic(PerlFMM *self, SV *svio)
{
    PerlIO *io;
    char *type;
    int rc;
    SV *ret;

    if (! SvROK(svio))
        croak("Usage: self->fhmagic(*handle))");

    io = IoIFP(sv_2io(SvRV(svio)));
    if (! io)
        croak("Not a handle");

    FMM_SET_ERROR(self, NULL);
    Newz(1234, type, BUFSIZ, char);
    rc = fmm_fhmagic(self, io, &type);
    ret = FMM_RESULT(type, rc);
    Safefree(type);
    return ret;
}

SV *
PerlFMM_fsmagic(PerlFMM *self, char *filename)
{
    char *type;
    int rc;
    SV *ret;

    FMM_SET_ERROR(self, NULL);

    Newz(1234, type, BUFSIZ, char);

    rc = fmm_fsmagic(self, filename, &type);
    ret = FMM_RESULT(type, rc);
    Safefree(type);
    return ret;
}

SV *
PerlFMM_bufmagic(PerlFMM *self, SV *buf)
{
    unsigned char *buffer;
    char *type;
    int rc;
    SV *ret;

    /* rt #28040, allow RV to SVs to be passed here */
    if (SvROK(buf) && SvTYPE(SvRV(buf)) == SVt_PV) {
        buffer = (unsigned char *) SvPV_nolen( SvRV( buf ) );
    } else {
        buffer = (unsigned char *) SvPV_nolen(buf);
    }

    FMM_SET_ERROR(self, NULL);

    Newz(1234, type, BUFSIZ, char);

    rc = fmm_bufmagic(self, &buffer, &type);
    ret = FMM_RESULT(type, rc);
    Safefree(type);
    return ret;
}

SV *
PerlFMM_ascmagic(PerlFMM *self, unsigned char *data)
{
    char *type;
    int rc;
    SV *ret;

    Newz(1234, type, BUFSIZ, char);

    FMM_SET_ERROR(self, NULL);

    rc = fmm_ascmagic(data, strlen(data), &type);
    ret = FMM_RESULT(type, rc);
    Safefree(type);
    return ret;
}

SV *
PerlFMM_get_mime(PerlFMM *self, char *filename)
{
    char *type;
    int rc;
    SV *ret;

    Newz(1234, type, MAXMIMESTRING, char);

    FMM_SET_ERROR(self, NULL);
    rc = fmm_mime_magic(self, filename, &type);
    ret = FMM_RESULT(type, rc);
    Safefree(type);
    return ret;
}

#endif
