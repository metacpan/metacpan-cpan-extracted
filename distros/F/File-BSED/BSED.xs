/*
v
v
v BSED.xs  - Perl-binding to libgbsed
v
v (c) Copyright 2007 Ask Solem <ask@0x61736b.net>
v
v   
*/

/*
* $Id: BSED.xs,v 1.9 2007/07/17 15:26:35 ask Exp $
* $Source: /opt/CVS/File-BSED/BSED.xs,v $
* $Author: ask $
* $HeadURL$
* $Revision: 1.9 $
* $Date: 2007/07/17 15:26:35 $
*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "libgbsed.h"

extern int gbsed_errno;
extern int gbsed_warnings[];
extern int gbsed_warn_index;

MODULE = File::BSED		PACKAGE = File::BSED
PROTOTYPES: DISABLE



void
_grow (scalar, new_size)
    SV *scalar;
    STRLEN new_size;

    CODE:
        /* allocate more memory for scalar */
        SV *orig = (SV*)SvRV(scalar);
        SvUPGRADE(orig, SVt_PV);
        SvPOK_only(orig);
        SvGROW(orig, new_size);

char *
_string_to_hexstring(orig)
    SV * orig;

    CODE:
        STRLEN  len;
        char   *ptr;
        ptr   = SvPV(orig, len);

        RETVAL = gbsed_string2hexstring(ptr);
    OUTPUT:
        RETVAL

AV *
_warnings()
    CODE:
        AV   *warnings;
        I32   i;
        SV   *element;
        char *tmp;

        /* create the new array to return */
        warnings = newAV();

        /* check if there have been any warnings raises */
        if (gbsed_warn_index > 0) {

            /* if there has, iterate through the list ... */
            for (i = 0; i < gbsed_warn_index; i++) {
                /* ...fetch the warning */
                tmp = gbsed_warntostr(gbsed_warnings[i]);

                if (tmp == NULL)
                    element = &PL_sv_undef;
                else
                    element = newSVpvf("%s", tmp);

                av_store(warnings, i, element);
            }
        }
            

        RETVAL = warnings;
    OUTPUT:
        RETVAL
    

int
_binary_file_matches (search, infile)
    char *search;
    char *infile;

    CODE:
        int matches;
        GBSEDargs *gbsedargs;
        gbsedargs = _gbsed_alloc(gbsedargs, 1, GBSEDargs);
            
        gbsedargs->search       = search;
        gbsedargs->infilename   = infile;
        gbsedargs->outfilename  = NULL;
        gbsedargs->replace      = NULL;

        RETVAL = gbsed_binary_search_replace(gbsedargs);

        _gbsed_safefree(gbsedargs);

    OUTPUT:
    RETVAL

int
_gbsed (search, replace, infile, outfile, min, max)
    char *search;
    char *replace;
    char *infile;
    char *outfile;
    int   min;
    int   max;

    CODE:
        GBSEDargs *gbsedargs;
        gbsedargs = _gbsed_alloc(gbsedargs, 1, GBSEDargs);
        gbsedargs->search      = search;
        gbsedargs->replace     = replace;
        gbsedargs->infilename  = infile;
        gbsedargs->outfilename = outfile;
        gbsedargs->minmatch    = min;
        gbsedargs->maxmatch    = max;

        RETVAL = gbsed_binary_search_replace(gbsedargs);

        _gbsed_safefree(gbsedargs);

    OUTPUT:
    RETVAL

int
_gbsed_errno ()
    CODE:
        RETVAL = gbsed_errno;
    OUTPUT:
    RETVAL

void
_set_gbsed_errno (new_errno)
    int new_errno;

    CODE:
        gbsed_errno = new_errno;


SV *
_errtostr(gbsed_errno_val)
    int gbsed_errno_val;

    CODE:
        const char *gbsed_errstr;

        gbsed_errstr = gbsed_errtostr(gbsed_errno_val);
        if (gbsed_errstr == NULL)
            RETVAL = &PL_sv_undef;
        else 
            RETVAL = newSVpvn(
                (char *)gbsed_errstr,
                (STRLEN)strlen((char *)gbsed_errstr)
            );

    OUTPUT:
    RETVAL

#
# Local Variables:
#   indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
#
