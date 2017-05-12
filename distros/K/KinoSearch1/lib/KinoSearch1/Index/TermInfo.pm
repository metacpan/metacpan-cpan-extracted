package KinoSearch1::Index::TermInfo;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

1;

__END__
__XS__

MODULE = KinoSearch1   PACKAGE = KinoSearch1::Index::TermInfo

TermInfo*
new( class_sv, doc_freq, frq_fileptr, prx_fileptr, skip_offset, index_fileptr )
    SV        *class_sv;
    I32        doc_freq;
    double     frq_fileptr;
    double     prx_fileptr;
    I32        skip_offset;
    double     index_fileptr;
PREINIT:
    TermInfo *tinfo;
CODE:
    class_sv = NULL; /* suppress "unused variable" warning */
    Kino1_New(0, tinfo, 1, TermInfo);
    tinfo->doc_freq      = doc_freq;
    tinfo->frq_fileptr   = frq_fileptr;
    tinfo->prx_fileptr   = prx_fileptr;
    tinfo->skip_offset   = skip_offset;
    tinfo->index_fileptr = index_fileptr;
    RETVAL = tinfo;
OUTPUT: RETVAL


=begin comment

Duplicate a TermInfo object.

=end comment
=cut

TermInfo*
clone(tinfo)
    TermInfo *tinfo;
CODE:
    RETVAL = Kino1_TInfo_dupe(tinfo);
OUTPUT: RETVAL

=for comment
Zero out the TermInfo object.

=cut

void
reset(tinfo)
    TermInfo *tinfo;
PPCODE:
    Kino1_TInfo_reset(tinfo);


=begin comment

Setters and getters.

=end comment
=cut

SV*
_set_or_get(tinfo, ...)
    TermInfo *tinfo;
ALIAS:
    set_doc_freq      = 1
    get_doc_freq      = 2
    set_frq_fileptr   = 3
    get_frq_fileptr   = 4
    set_prx_fileptr   = 5
    get_prx_fileptr   = 6
    set_skip_offset   = 7
    get_skip_offset   = 8
    set_index_fileptr = 9
    get_index_fileptr = 10
CODE:
{
    KINO_START_SET_OR_GET_SWITCH

    case 1:  tinfo->doc_freq = SvIV(ST(1));
             /* fall through */
    case 2:  RETVAL = newSViv(tinfo->doc_freq);
             break;

    case 3:  tinfo->frq_fileptr = SvNV(ST(1));
             /* fall through */
    case 4:  RETVAL = newSVnv(tinfo->frq_fileptr);
             break;

    case 5:  tinfo->prx_fileptr = SvNV(ST(1));
             /* fall through */
    case 6:  RETVAL = newSVnv(tinfo->prx_fileptr);
             break;

    case 7:  tinfo->skip_offset = SvIV(ST(1));
             /* fall through */
    case 8:  RETVAL = newSViv(tinfo->skip_offset);
             break;

    case 9:  tinfo->index_fileptr = SvNV(ST(1));
             /* fall through */
    case 10: RETVAL = newSVnv(tinfo->index_fileptr);
             break;
        
    KINO_END_SET_OR_GET_SWITCH
}
    OUTPUT: RETVAL

void
DESTROY(tinfo)
    TermInfo* tinfo;
CODE: 
    Kino1_Safefree(tinfo);

__H__

#ifndef H_KINOSEARCH_INDEX_TERM_INFO
#define H_KINOSEARCH_INDEX_TERM_INFO 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilMemManager.h"

typedef struct terminfo {
    I32      doc_freq;
    double   frq_fileptr;
    double   prx_fileptr;
    I32      skip_offset;
    double   index_fileptr;
} TermInfo;

TermInfo* Kino1_TInfo_new();
TermInfo* Kino1_TInfo_dupe(TermInfo*);
void      Kino1_TInfo_reset(TermInfo*);
void      Kino1_TInfo_destroy(TermInfo*);

#endif /* include guard */


__C__

#include "KinoSearch1IndexTermInfo.h"

TermInfo*
Kino1_TInfo_new() {
    TermInfo* tinfo;
    Kino1_New(0, tinfo, 1, TermInfo);
    Kino1_TInfo_reset(tinfo);
    return tinfo;
}

/* Allocate and return a copy of the supplied TermInfo.  */
TermInfo*
Kino1_TInfo_dupe(TermInfo *tinfo) {
    TermInfo* new_tinfo;
    
    Kino1_New(0, new_tinfo, 1, TermInfo);
    new_tinfo->doc_freq      = tinfo->doc_freq;
    new_tinfo->frq_fileptr   = tinfo->frq_fileptr;
    new_tinfo->prx_fileptr   = tinfo->prx_fileptr;
    new_tinfo->skip_offset   = tinfo->skip_offset;
    new_tinfo->index_fileptr = tinfo->index_fileptr;

    return new_tinfo;
}

void
Kino1_TInfo_reset(TermInfo *tinfo) {
    tinfo->doc_freq      = 0;
    tinfo->frq_fileptr   = 0.0;
    tinfo->prx_fileptr   = 0.0;
    tinfo->skip_offset   = 0;
    tinfo->index_fileptr = 0.0;
}

void 
Kino1_TInfo_destroy(TermInfo *tinfo) {
    Kino1_Safefree(tinfo);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::TermInfo - filepointer/statistical data for a Term

==head1 SYNOPSIS

    my $tinfo = KinoSearch1::Index::TermInfo->new(
        $doc_freq,
        $frq_fileptr,
        $prx_fileptr,
        $skip_offset,
        $index_fileptr
    );

==head1 DESCRIPTION

The TermInfo contains pointer data indicating where a term can be found in
various files, plus the document frequency of the term.

The index_fileptr member variable is only used if the TermInfo is part of the
.tii stream; it is a filepointer to a locations in the main .tis file.

==head1 METHODS

==head2 new

Constructor.  All 5 arguments are required.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut



