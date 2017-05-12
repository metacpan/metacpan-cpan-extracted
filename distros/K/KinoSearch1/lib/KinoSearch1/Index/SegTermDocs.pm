package KinoSearch1::Index::SegTermDocs;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Index::TermDocs );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params
        reader => undef,
    );
}
our %instance_vars;

sub new {
    my $self = shift->SUPER::new;
    confess kerror() unless verify_args( \%instance_vars, @_ );
    my %args = ( %instance_vars, @_ );
    my $reader = $args{reader};

    _init_child($self);

    # dupe some stuff from the parent reader.
    $self->_set_reader($reader);
    $self->_set_skip_interval( $reader->get_skip_interval );
    $self->_set_freq_stream( $reader->get_freq_stream()->clone_stream );
    $self->_set_skip_stream( $reader->get_freq_stream()->clone_stream );
    $self->_set_prox_stream( $reader->get_prox_stream()->clone_stream );
    $self->_set_deldocs( $reader->get_deldocs );

    return $self;
}

sub seek {
    my ( $self, $term ) = @_;
    my $tinfo
        = defined $term
        ? $self->_get_reader()->fetch_term_info($term)
        : undef;
    $self->seek_tinfo($tinfo);
}

sub close {
    my $self = shift;
    $self->_get_freq_stream()->close;
    $self->_get_prox_stream()->close;
    $self->_get_skip_stream()->close;
}

1;

__END__
__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Index::SegTermDocs

void
_init_child(term_docs)
    TermDocs *term_docs;
PPCODE:
    Kino1_SegTermDocs_init_child(term_docs);

SV*
_set_or_get(term_docs, ...)
    TermDocs *term_docs;
ALIAS:
    _set_count         = 1
    _get_count         = 2
    _set_freq_stream   = 3
    _get_freq_stream   = 4
    _set_prox_stream   = 5
    _get_prox_stream   = 6
    _set_skip_stream   = 7
    _get_skip_stream   = 8
    _set_deldocs       = 9
    _get_deldocs       = 10
    _set_reader        = 11
    _get_reader        = 12
    set_read_positions = 13
    get_read_positions = 14
    _set_skip_interval = 15
    _get_skip_interval = 16
CODE:
{
    SegTermDocsChild *child = (SegTermDocsChild*)term_docs->child;

    KINO_START_SET_OR_GET_SWITCH

    case 1:  child->count = SvUV(ST(1));
             /* fall through */
    case 2:  RETVAL = newSVuv(child->count);
             break;

    case 3:  SvREFCNT_dec(child->freq_stream_sv);
             child->freq_stream_sv = newSVsv( ST(1) );
             Kino1_extract_struct( child->freq_stream_sv, child->freq_stream, 
                InStream*, "KinoSearch1::Store::InStream");
             /* fall through */
    case 4:  RETVAL = newSVsv(child->freq_stream_sv);
             break;

    case 5:  SvREFCNT_dec(child->prox_stream_sv);
             child->prox_stream_sv = newSVsv( ST(1) );
             Kino1_extract_struct( child->prox_stream_sv, child->prox_stream, 
                InStream*, "KinoSearch1::Store::InStream");
             /* fall through */
    case 6:  RETVAL = newSVsv(child->prox_stream_sv);
             break;

    case 7:  SvREFCNT_dec(child->skip_stream_sv);
             child->skip_stream_sv = newSVsv( ST(1) );
             Kino1_extract_struct( child->skip_stream_sv, child->skip_stream, 
                InStream*, "KinoSearch1::Store::InStream");
             /* fall through */
    case 8:  RETVAL = newSVsv(child->skip_stream_sv);
             break;

    case 9:  SvREFCNT_dec(child->deldocs_sv);
             child->deldocs_sv = newSVsv( ST(1) );
             Kino1_extract_struct( child->deldocs_sv, child->deldocs, 
                BitVector*, "KinoSearch1::Index::DelDocs" );
             /* fall through */
    case 10: RETVAL = newSVsv(child->deldocs_sv);
             break;

    case 11: SvREFCNT_dec(child->reader_sv);
             if (!sv_derived_from( ST(1), "KinoSearch1::Index::IndexReader") )
                Kino1_confess("not a KinoSearch1::Index::IndexReader");
             child->reader_sv = newSVsv( ST(1) );
             /* fall through */
    case 12: RETVAL = newSVsv(child->reader_sv);
             break;

    case 13: child->read_positions = SvTRUE( ST(1) ) ? 1 : 0;
             /* fall through */
    case 14: RETVAL = newSViv(child->read_positions);
             break;

    case 15: child->skip_interval = SvUV(ST(1));
             /* fall through */
    case 16: RETVAL = newSVuv(child->skip_interval);
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL

__H__

#ifndef H_KINO_SEG_TERM_DOCS
#define H_KINO_SEG_TERM_DOCS 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilBitVector.h"
#include "KinoSearch1IndexTermDocs.h"
#include "KinoSearch1IndexTermInfo.h"
#include "KinoSearch1StoreInStream.h"
#include "KinoSearch1UtilMemManager.h"

typedef struct segtermdocschild {
    U32        count;
    U32        doc_freq;
    U32        doc;
    U32        freq;
    U32        skip_doc;
    U32        skip_count;
    U32        num_skips;
    SV        *positions;
    U32        read_positions;
    U32        skip_interval;
    InStream  *freq_stream;
    InStream  *prox_stream;
    InStream  *skip_stream;
    bool       have_skipped;
    double     frq_fileptr;
    double     prx_fileptr;
    double     skip_fileptr;
    BitVector *deldocs;
    SV        *freq_stream_sv;
    SV        *prox_stream_sv;
    SV        *skip_stream_sv;
    SV        *deldocs_sv;
    SV        *reader_sv;
} SegTermDocsChild;

void Kino1_SegTermDocs_init_child(TermDocs*);
void Kino1_SegTermDocs_set_doc_freq(TermDocs*, U32);
U32  Kino1_SegTermDocs_get_doc_freq(TermDocs*);
U32  Kino1_SegTermDocs_get_doc(TermDocs*);
U32  Kino1_SegTermDocs_get_freq(TermDocs*);
SV*  Kino1_SegTermDocs_get_positions(TermDocs*);
U32  Kino1_SegTermDocs_bulk_read(TermDocs*, SV*, SV*, U32);
void Kino1_SegTermDocs_seek_tinfo(TermDocs*, TermInfo*);
bool Kino1_SegTermDocs_next(TermDocs*);
bool Kino1_SegTermDocs_skip_to(TermDocs*, U32 target);
bool Kino1_SegTermDocs_skip_to_with_positions(TermDocs*);
void Kino1_SegTermDocs_destroy(TermDocs*);

#endif /* include guard */

__C__

#include "KinoSearch1IndexSegTermDocs.h"

static void
load_positions(TermDocs *term_docs);

void
Kino1_SegTermDocs_init_child(TermDocs *term_docs) {
    SegTermDocsChild *child;

    Kino1_New(1, child, 1, SegTermDocsChild);
    term_docs->child = child;

    child->doc_freq = KINO_TERM_DOCS_SENTINEL;
    child->doc      = KINO_TERM_DOCS_SENTINEL;
    child->freq     = KINO_TERM_DOCS_SENTINEL;

    /* child->positions starts life as an empty string */
    child->positions = newSV(1);
    SvCUR_set(child->positions, 0);
    SvPOK_on(child->positions);

    term_docs->set_doc_freq  = Kino1_SegTermDocs_set_doc_freq;
    term_docs->get_doc_freq  = Kino1_SegTermDocs_get_doc_freq;
    term_docs->get_doc       = Kino1_SegTermDocs_get_doc;
    term_docs->get_freq      = Kino1_SegTermDocs_get_freq;
    term_docs->get_positions = Kino1_SegTermDocs_get_positions;
    term_docs->bulk_read     = Kino1_SegTermDocs_bulk_read;
    term_docs->seek_tinfo    = Kino1_SegTermDocs_seek_tinfo;
    term_docs->next          = Kino1_SegTermDocs_next;
    term_docs->skip_to       = Kino1_SegTermDocs_skip_to;
    term_docs->destroy       = Kino1_SegTermDocs_destroy;

    child->freq_stream_sv   = &PL_sv_undef;
    child->prox_stream_sv   = &PL_sv_undef;
    child->skip_stream_sv   = &PL_sv_undef;
    child->deldocs_sv       = &PL_sv_undef;
    child->reader_sv        = &PL_sv_undef;
    child->count            = 0;

    child->read_positions = 0; /* off by default */
}

void
Kino1_SegTermDocs_set_doc_freq(TermDocs *term_docs, U32 doc_freq) {
    SegTermDocsChild *child;
    child = (SegTermDocsChild*)term_docs->child;
    child->doc_freq = doc_freq;
}

U32
Kino1_SegTermDocs_get_doc_freq(TermDocs *term_docs) {
    SegTermDocsChild *child;
    child = (SegTermDocsChild*)term_docs->child;
    return child->doc_freq;
}

U32
Kino1_SegTermDocs_get_doc(TermDocs *term_docs) {
    SegTermDocsChild *child;
    child = (SegTermDocsChild*)term_docs->child;
    return child->doc;
}


U32
Kino1_SegTermDocs_get_freq(TermDocs *term_docs) {
    SegTermDocsChild *child;
    child = (SegTermDocsChild*)term_docs->child;
    return child->freq;
}

SV*
Kino1_SegTermDocs_get_positions(TermDocs *term_docs) {
    SegTermDocsChild *child;
    child = (SegTermDocsChild*)term_docs->child;
    return child->positions;
}

U32 
Kino1_SegTermDocs_bulk_read(TermDocs *term_docs, SV* doc_nums_sv, 
                           SV* freqs_sv, U32 num_wanted) {
    SegTermDocsChild *child;
    InStream         *freq_stream;
    U32               doc_code;
    U32              *doc_nums;
    U32              *freqs;
    STRLEN            len;
    U32               num_got = 0;

    /* local copies */
    child       = (SegTermDocsChild*)term_docs->child;
    freq_stream = child->freq_stream;

    /* allocate space in supplied SVs and make them POK, if necessary */ 
    len = num_wanted * sizeof(U32);
    SvUPGRADE(doc_nums_sv, SVt_PV);
    SvUPGRADE(freqs_sv,    SVt_PV);
    SvPOK_on(doc_nums_sv);
    SvPOK_on(freqs_sv);
    doc_nums = (U32*)SvGROW(doc_nums_sv, len + 1);
    freqs    = (U32*)SvGROW(freqs_sv,    len + 1);

    while (child->count < child->doc_freq && num_got < num_wanted) {
        /* manually inlined call to term_docs->next */ 
        child->count++;
        doc_code = freq_stream->read_vint(freq_stream);;
        child->doc  += doc_code >> 1;
        if (doc_code & 1)
            child->freq = 1;
        else
            child->freq = freq_stream->read_vint(freq_stream);

        /* if the doc isn't deleted... */
        if ( !Kino1_BitVec_get(child->deldocs, child->doc) ) {
            /* ... append to results */
            *doc_nums++ = child->doc;
            *freqs++    = child->freq;
            num_got++;
        }
    }

    /* set the string end to the end of the U32 array */
    SvCUR_set(doc_nums_sv, (num_got * sizeof(U32)));
    SvCUR_set(freqs_sv,    (num_got * sizeof(U32)));

    return num_got;
}

bool
Kino1_SegTermDocs_next(TermDocs *term_docs) {
    SegTermDocsChild *child = (SegTermDocsChild*)term_docs->child;
    InStream         *freq_stream = child->freq_stream;
    U32               doc_code;
    
    while (1) {
        /* bail if we're out of docs */
        if (child->count == child->doc_freq) {
            return 0;
        }

        /* decode delta doc */
        doc_code = freq_stream->read_vint(freq_stream);
        child->doc  += doc_code >> 1;

        /* if the stored num was odd, the freq is 1 */ 
        if (doc_code & 1) {
            child->freq = 1;
        }
        /* otherwise, freq was stored as a VInt. */
        else {
            child->freq = freq_stream->read_vint(freq_stream);
        } 

        child->count++;
        
        /* read positions if desired */
        if (child->read_positions)
            load_positions(term_docs);
        
        /* if the doc isn't deleted... success! */
        if (!Kino1_BitVec_get(child->deldocs, child->doc))
            break;
    }
    return 1;
}

static void
load_positions(TermDocs *term_docs) {
    SegTermDocsChild *child = (SegTermDocsChild*)term_docs->child;
    InStream *prox_stream = child->prox_stream;
    STRLEN len = child->freq * sizeof(U32);
    U32 *positions, *positions_end;
    U32 position = 0;

    SvGROW( child->positions, len );
    SvCUR_set(child->positions, len);
    positions = (U32*)SvPVX(child->positions);
    positions_end = (U32*)SvEND(child->positions);
    while (positions < positions_end) {
        position += prox_stream->read_vint(prox_stream);
        *positions++ = position;
    }
}

void
Kino1_SegTermDocs_seek_tinfo(TermDocs *term_docs, TermInfo *tinfo) {
    SegTermDocsChild *child;
    child = (SegTermDocsChild*)term_docs->child;

    child->count = 0;

    if (tinfo == NULL) {
        child->doc_freq = 0;
    }
    else {
        child->doc          = 0;
        child->freq         = 0;
        child->skip_doc     = 0;
        child->skip_count   = 0;
        child->have_skipped = FALSE;
        child->num_skips    = tinfo->doc_freq / child->skip_interval;
        child->doc_freq     = tinfo->doc_freq;
        child->frq_fileptr  = tinfo->frq_fileptr;
        child->prx_fileptr  = tinfo->prx_fileptr;
        child->skip_fileptr = tinfo->frq_fileptr + tinfo->skip_offset;
        child->freq_stream->seek( child->freq_stream, tinfo->frq_fileptr );
        child->prox_stream->seek( child->prox_stream, tinfo->prx_fileptr );
    }
}

bool
Kino1_SegTermDocs_skip_to(TermDocs *term_docs, U32 target) {
    SegTermDocsChild *child = (SegTermDocsChild*)term_docs->child;
    
    if (child->doc_freq >= child->skip_interval) {
        InStream *freq_stream   = child->freq_stream;
        InStream *prox_stream   = child->prox_stream;
        InStream *skip_stream   = child->skip_stream;
        U32 last_skip_doc       = child->skip_doc;
        double last_frq_fileptr = freq_stream->tell(freq_stream);
        double last_prx_fileptr = -1;
        I32 num_skipped         = -1 - (child->count % child->skip_interval);

        if (!child->have_skipped) {
            child->skip_stream->seek(child->skip_stream, child->skip_fileptr);
            child->have_skipped = TRUE;
        }
        
        while (target > child->skip_doc) {
            last_skip_doc    = child->skip_doc;
            last_frq_fileptr = child->frq_fileptr;
            last_prx_fileptr = child->prx_fileptr;

            if (child->skip_doc != 0 && child->skip_doc >= child->doc) {
                num_skipped += child->skip_interval;
            }

            if (child->skip_count >= child->num_skips) {
                break;
            }

            child->skip_doc += skip_stream->read_vint(skip_stream);
            child->frq_fileptr += skip_stream->read_vint(skip_stream);
            child->prx_fileptr += skip_stream->read_vint(skip_stream);

            child->skip_count++;
        }

        /* if there's something to skip, skip it */
        if (last_frq_fileptr > freq_stream->tell(freq_stream)) {
            freq_stream->seek(freq_stream, last_frq_fileptr);
            if (child->read_positions) {
                prox_stream->seek(prox_stream, last_prx_fileptr);
            }
            child->doc = last_skip_doc;
            child->count += num_skipped;
        }
    }

    /* done skipping, so scan */
    do {
        if (!term_docs->next(term_docs)) {
            return FALSE;
        }
    } while (target > child->doc);
    return TRUE;
}

void 
Kino1_SegTermDocs_destroy(TermDocs *term_docs){
    SegTermDocsChild *child;
    child = (SegTermDocsChild*)term_docs->child;

    SvREFCNT_dec(child->positions);
    SvREFCNT_dec(child->freq_stream_sv);
    SvREFCNT_dec(child->prox_stream_sv);
    SvREFCNT_dec(child->skip_stream_sv);
    SvREFCNT_dec(child->deldocs_sv);
    SvREFCNT_dec(child->reader_sv);

    Kino1_Safefree(child);

    Kino1_TermDocs_destroy(term_docs);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::SegTermDocs - single-segment TermDocs

==head1 DESCRIPTION

Single-segment implemetation of KinoSearch1::Index::TermDocs.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
