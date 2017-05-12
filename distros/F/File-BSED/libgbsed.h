/*
*
*    Copyright (C) 2007 Ask Solem <ask@0x61736b.net>
*
*    This file is part of gbsed
*
*    gbsed is free software; you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation; either version 3 of the License, or
*    (at your option) any later version.
*
*    gbsed is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
* $Id: libgbsed.h,v 1.1 2007/07/14 14:39:49 ask Exp $
* $Source: /opt/CVS/File-gbsed/libgbsed.h,v $
* $Author: ask $
* $HeadURL$
* $Revision: 1.1 $
* $Date: 2007/07/14 14:39:49 $
*/

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif /* HAVE_CONFIG_H */

#ifndef _LIBGBSED_H_
#define _LIBGBSED_H_        1

#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef _cplusplus
#   define __BEGIN_DECLS    extern "C" {
#   define __END_DECLS      }
#else  /* not _cplusplus */
#   define __BEGIN_DECLS /* empty */
#   define __END_DECLS   /* empty */
#endif /* _cplusplus */

/* __P is a macro used to wrap function prototypes, so that compilers
    that don't understand ANSI C prototypes still work, and ANSI C
    compilers can issue warnigns about type mismatches. 
*/
#undef __P
#if defined (__STDC__)   || defined (_AIX) \
    || (defined (__mips) && defined (_SYSTYPE_SVR4)) \
    || defined(WIN32)    || defined (__cplusplus)
#       define __P(protos) protos
# else /* not __STDC__ */
#   define __P(protos) ()
# endif




/*           Constants             */

#define GBSED_ERROR                 -1
#define GBSED_NO_MATCH             0x0

#define GBSED_ENULL_SEARCH         0x1
#define GBSED_ENULL_REPLACE        0x2
#define GBSED_EMISSING_INPUT       0x3
#define GBSED_EMISSING_OUTPUT      0x4
#define GBSED_EINVALID_CHAR        0x5 
#define GBSED_ENIBBLE_NOT_BYTE     0x6 
#define GBSED_EOPEN_INFILE         0x7
#define GBSED_EOPEN_OUTFILE        0x8
#define GBSED_ENOMEM               0x9
#define GBSED_EMINMAX_BALANCE      0xa
#define GBSED_ENOSTAT_FDES         0xb

#define GBSED_WBALANCE             0x1

#define GBSED_MMAX_NO_LIMIT         -1

/*           Types                 */

typedef unsigned char UCHAR;

struct gbsed_arguments {
    char *search;
    char *replace;
    char *infilename;
    char *outfilename;
    int  minmatch;
    int  maxmatch;
};
typedef struct gbsed_arguments  GBSEDargs;

struct fgbsed_arguments {
    char *search;
    char *replace;
    FILE *infile;
    FILE *outfile;
    int   minmatch;
    int   maxmatch;
};
typedef struct fgbsed_arguments fGBSEDargs;

/*           Public functions.      */

__BEGIN_DECLS

extern int  gbsed_errno;
extern int  gbsed_warnings[];
extern int  gbsed_warn_index;

const char*
gbsed_version                __P((void));

int
gbsed_binary_search_replace  __P((struct gbsed_arguments *));

int
gbsed_fbinary_search_replace __P((struct fgbsed_arguments *));

char *
gbsed_string2hexstring       __P((char *orig));

const char*
gbsed_errtostr               __P((int));

char*
gbsed_warntostr              __P((int));

void *
_gbsed_alloczero             __P((size_t,  size_t));

__END_DECLS


#ifdef PERL_MALLOC
#  include <EXTERN.h>
#  include <perl.h>
#  define _gbsed_alloc(pointer, add, type)   \
    (type *)Newxz(pointer, add, type)
#  define  _gbsed_realloc(pointer, add, type) \
    (type *)Renew(pointer, add, type)
#  define _gbsed_safefree(pointer)           \
    Safefree(pointer)
#else /* not PERL_MALLOC */
#define _gbsed_alloc(pointer, add, type)    \
    _gbsed_alloczero(add, sizeof(type))
#define _gbsed_realloc(pointer, add, type)  \
    realloc(pointer, add*sizeof(type))
#define _gbsed_safefree(pointer)            \
    free(pointer)
#endif /* PERL_MALLOC */

/*           Private functions       */

#ifdef LIBGBSED_PRIVATE

__BEGIN_DECLS

UCHAR *
_gbsed_hexstr2bin         __P((char *, size_t *));

mode_t
_gbsed_preserve_execbit   __P((FILE *file));

__END_DECLS

#else  /* not lIBGBSED_PRIVATE */
#  define LIBGBSED_PRIVATE 0
#endif /*     LIBGBSED_PRIVATE */

#endif /* !_LIBGBSED_H_ */


/*
# Local Variables:
#   indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
*/
