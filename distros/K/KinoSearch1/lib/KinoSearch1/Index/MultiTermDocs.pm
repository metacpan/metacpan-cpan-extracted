package KinoSearch1::Index::MultiTermDocs;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Index::TermDocs );

BEGIN {
    __PACKAGE__->init_instance_vars(
        sub_readers => undef,
        starts      => undef,
    );
}
our %instance_vars;

sub new {
    my $self = shift->SUPER::new;
    confess kerror() unless verify_args( \%instance_vars, @_ );
    my %args = ( %instance_vars, @_ );

    # get a SegTermDocs for each segment
    my $sub_readers = $args{sub_readers} || [];
    my $starts      = $args{starts}      || [];
    my @sub_term_docs = map { $_->term_docs } @$sub_readers;
    _init_child( $self, \@sub_term_docs, $starts );

    return $self;
}

sub seek {
    my ( $self, $term ) = @_;
    $_->seek($term) for @{ $self->_get_sub_term_docs };
    $self->_reset_pointer;
}

sub set_read_positions {
    my ( $self, $val ) = @_;
    $_->set_read_positions($val) for @{ $self->_get_sub_term_docs };
}

sub close {
    my $self = shift;
    $_->close for @{ $self->_get_sub_term_docs };
}

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Index::MultiTermDocs

void
_init_child(term_docs, sub_term_docs_avref, starts_av)
    TermDocs *term_docs;
    SV       *sub_term_docs_avref;
    AV       *starts_av;
PPCODE:
    Kino1_MultiTermDocs_init_child(term_docs, sub_term_docs_avref, starts_av);


=for comment
Helper for seek().

=cut

void
_reset_pointer(term_docs)
    TermDocs *term_docs;
PREINIT:
    MultiTermDocsChild *child;
PPCODE:
    child = (MultiTermDocsChild*)term_docs->child;
    child->base    = 0;
    child->pointer = 0;
    child->current = NULL;
    

SV*
_set_or_get(term_docs, ...)
    TermDocs *term_docs;
ALIAS:
    _set_sub_term_docs = 1
    _get_sub_term_docs = 2
CODE:
{
    MultiTermDocsChild *child = (MultiTermDocsChild*)term_docs->child;

    KINO_START_SET_OR_GET_SWITCH
        
    case 1:  Kino1_confess("Can't set sub_term_docs");
             /* fall through */
    case 2:  RETVAL = newSVsv( child->sub_term_docs_avref );
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL

__H__

#ifndef H_KINO_MULTI_TERM_DOCS
#define H_KINO_MULTI_TERM_DOCS 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1IndexTermDocs.h"
#include "KinoSearch1UtilCClass.h"
#include "KinoSearch1UtilMemManager.h"

typedef struct multitermdocschild {
    I32        num_subs;
    I32        base;
    I32        pointer;
    SV        *sub_term_docs_avref;
    U32       *starts;
    SV        *term_sv;
    TermDocs **sub_term_docs;
    TermDocs  *current;
} MultiTermDocsChild;

void Kino1_MultiTermDocs_init_child(TermDocs*, SV*, AV*);
void Kino1_MultiTermDocs_set_doc_freq_death(TermDocs*, U32);
U32  Kino1_MultiTermDocs_get_doc_freq(TermDocs*);
U32  Kino1_MultiTermDocs_get_doc(TermDocs*);
U32  Kino1_MultiTermDocs_get_freq(TermDocs*);
SV*  Kino1_MultiTermDocs_get_positions(TermDocs*);
U32  Kino1_MultiTermDocs_bulk_read(TermDocs*, SV*, SV*, U32);
bool Kino1_MultiTermDocs_next(TermDocs*);
bool Kino1_MultiTermDocs_skip_to(TermDocs*, U32);
void Kino1_MultiTermDocs_destroy(TermDocs*);

#endif /* include guard */

__C__

#include "KinoSearch1IndexMultiTermDocs.h"

void 
Kino1_MultiTermDocs_init_child(TermDocs* term_docs, SV *sub_term_docs_avref, 
                              AV *starts_av) {
    MultiTermDocsChild *child;
    I32                 i;
    SV                **sv_ptr;
    AV                 *sub_term_docs_av;

    /* allocate */
    Kino1_New(0, child, 1, MultiTermDocsChild);
    term_docs->child = child;

    /* assign */
    child->current = NULL;
    child->base    = 0;
    child->pointer = 0;

    /* extract AV* and take stock of how many sub-TermDocs we've got */
    child->sub_term_docs_avref = newSVsv(sub_term_docs_avref);;
    sub_term_docs_av = (AV*)SvRV(sub_term_docs_avref);
    child->num_subs = av_len(sub_term_docs_av) + 1;

    /* extract starts from starts array, subTermDocs from the subs array */
    Kino1_New(0, child->starts, child->num_subs, U32);
    Kino1_New(0, child->sub_term_docs, child->num_subs, TermDocs*);
    for (i = 0; i < child->num_subs; i++) {
        sv_ptr = av_fetch(starts_av, i, 0);
        if (sv_ptr == NULL)
            Kino1_confess("starts array doesn't have enough valid members");
        child->starts[i] = (U32)SvUV(*sv_ptr);
        sv_ptr = av_fetch(sub_term_docs_av, i, 0);
        if (sv_ptr == NULL)
            Kino1_confess("TermDocs array doesn't have enough valid members");
        Kino1_extract_struct(*sv_ptr, child->sub_term_docs[i], TermDocs*,
            "KinoSearch1::Index::TermDocs");
    }

    /* assign method pointers */
    term_docs->set_doc_freq  = Kino1_MultiTermDocs_set_doc_freq_death;
    term_docs->get_doc_freq  = Kino1_MultiTermDocs_get_doc_freq;
    term_docs->get_doc       = Kino1_MultiTermDocs_get_doc;
    term_docs->get_freq      = Kino1_MultiTermDocs_get_freq;
    term_docs->get_positions = Kino1_MultiTermDocs_get_positions;
    term_docs->bulk_read     = Kino1_MultiTermDocs_bulk_read;
    term_docs->next          = Kino1_MultiTermDocs_next;
    term_docs->skip_to       = Kino1_MultiTermDocs_skip_to;
    term_docs->destroy       = Kino1_MultiTermDocs_destroy;
}

void
Kino1_MultiTermDocs_set_doc_freq_death(TermDocs *term_docs, U32 doc_freq) {
    Kino1_confess("can't set doc_freq on a MultiTermDocs");
}

U32
Kino1_MultiTermDocs_get_doc_freq(TermDocs *term_docs) {
    MultiTermDocsChild *child;
    TermDocs           *sub_td;
    I32                 i;
    U32                 doc_freq = 0;

    /* sum the doc_freqs of all segments */
    child = (MultiTermDocsChild*)term_docs->child;
    for (i = 0; i < child->num_subs; i++) {
        sub_td = child->sub_term_docs[i];
        doc_freq += sub_td->get_doc_freq(sub_td);
    }
    return doc_freq;
}

U32 
Kino1_MultiTermDocs_get_doc(TermDocs *term_docs) {
    MultiTermDocsChild *child;
    child = (MultiTermDocsChild*)term_docs->child;
    
    if (child->current == NULL) 
        return KINO_TERM_DOCS_SENTINEL;

    return child->current->get_doc(child->current) + child->base;
}

U32
Kino1_MultiTermDocs_get_freq(TermDocs *term_docs) {
    MultiTermDocsChild *child;
    child = (MultiTermDocsChild*)term_docs->child;

    if (child->current == NULL) 
        return KINO_TERM_DOCS_SENTINEL;

    return child->current->get_freq(child->current);
}

SV*
Kino1_MultiTermDocs_get_positions(TermDocs *term_docs) {
    MultiTermDocsChild *child;
    child = (MultiTermDocsChild*)term_docs->child;

    if (child->current == NULL) 
        return &PL_sv_undef;

    return child->current->get_positions(child->current);
}


U32
Kino1_MultiTermDocs_bulk_read(TermDocs *term_docs, SV *doc_nums_sv, 
                             SV *freqs_sv, U32 num_wanted) {
    MultiTermDocsChild *child;
    U32                 i, num_got, base;
    U32                *doc_nums;

    child = (MultiTermDocsChild*)term_docs->child;

    while (1) {
        /* move to the next SegTermDocs */
        while (child->current == NULL) {
            if (child->pointer < child->num_subs) {
                child->base = child->starts[ child->pointer ];
                child->current = child->sub_term_docs[ child->pointer ];
                child->pointer++;
            }
            else {
                return 0;
            }
        }
        
        num_got = child->current->bulk_read(
            child->current, doc_nums_sv, freqs_sv, num_wanted );

        if (num_got == 0) {
            /* no more docs left in this segment */
            child->current = NULL;
        }
        else {
            /* add the start offset for this seg to each doc */
            base = child->base;
            doc_nums = (U32*)SvPVX(doc_nums_sv);
            for (i = 0; i < num_got; i++) {
                *doc_nums++ += base;
            }

            return num_got;
        }
    }
}

bool
Kino1_MultiTermDocs_next(TermDocs* term_docs) {
    MultiTermDocsChild *child;
    child = (MultiTermDocsChild*)term_docs->child;

    if ( child->current != NULL && child->current->next(child->current) ) {
        return 1;
    }
    else if (child->pointer < child->num_subs) {
        /* try next segment */
        child->base    = child->starts[ child->pointer ];
        child->current = child->sub_term_docs[ child->pointer ];
        child->pointer++;
        return term_docs->next(term_docs); /* recurse */
    }
    else {
        /* done with all segments */
        return 0;
    }
}

bool
Kino1_MultiTermDocs_skip_to(TermDocs *term_docs, U32 target) {
    MultiTermDocsChild *child = (MultiTermDocsChild*)term_docs->child;
    
    if (   child->current != NULL 
        && child->current->skip_to(child->current, (target - child->base))
    ) {
        return TRUE;
    }
    else if (child->pointer < child->num_subs) {
        /* try next segment */
        child->base    = child->starts[ child->pointer ];
        child->current = child->sub_term_docs[ child->pointer ];
        child->pointer++;
        return term_docs->skip_to(term_docs, target); /* recurse */
    }
    else {
        return FALSE;
    }
}

void
Kino1_MultiTermDocs_destroy(TermDocs* term_docs) {
    MultiTermDocsChild *child; 
    child = (MultiTermDocsChild*)term_docs->child;

    SvREFCNT_dec(child->sub_term_docs_avref);
    Kino1_Safefree(child->sub_term_docs);
    Kino1_Safefree(child->starts);
    Kino1_Safefree(child);

    Kino1_TermDocs_destroy(term_docs);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::MultiTermDocs - multi-segment TermDocs

==head1 DESCRIPTION 

Multi-segment implementation of KinoSearch1::Index::TermDocs.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
