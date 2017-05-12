package KinoSearch1::Index::TermDocs;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

BEGIN { __PACKAGE__->init_instance_vars(); }

=begin comment

    $term_docs->seek($term);

Locate the TermDocs object at a particular term.

=end comment
=cut

sub seek { shift->abstract_death }

sub close { shift->abstract_death }

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Index::TermDocs

void
new(either_sv)
    SV   *either_sv;
PREINIT:
    const char *class;
    TermDocs *term_docs;
PPCODE:
    /* determine the class */
    class = sv_isobject(either_sv) 
        ? sv_reftype(either_sv, 0) 
        : SvPV_nolen(either_sv);

    /* build object */
    term_docs = Kino1_TermDocs_new();
    ST(0)     = sv_newmortal();
    sv_setref_pv(ST(0), class, (void*)term_docs);
    XSRETURN(1);

void
seek_tinfo(term_docs, maybe_tinfo_sv)
    TermDocs *term_docs;
    SV       *maybe_tinfo_sv;
PREINIT: 
    TermInfo *tinfo = NULL;
PPCODE:
    /* if maybe_tinfo_sv is undef, tinfo is NULL */
    if (SvOK(maybe_tinfo_sv)) {
        Kino1_extract_struct(maybe_tinfo_sv, tinfo,
            TermInfo*, "KinoSearch1::Index::TermInfo");
    }
    term_docs->seek_tinfo(term_docs, tinfo);


=begin comment

    while ($term_docs->next) {
        # ...
    }

Advance the TermDocs object to the next document.  Returns false when the
iterator is exhausted, true otherwise.

=end comment
=cut

bool
next(term_docs)
    TermDocs *term_docs;
CODE:
    RETVAL = term_docs->next(term_docs);
OUTPUT: RETVAL

U32
bulk_read(term_docs, doc_nums_sv, freqs_sv, num_wanted)
    TermDocs  *term_docs
    SV        *doc_nums_sv;
    SV        *freqs_sv;
    U32        num_wanted;
CODE:
    RETVAL = term_docs->bulk_read(term_docs, doc_nums_sv, freqs_sv, 
        num_wanted);
OUTPUT: RETVAL

=begin comment

To do.

=end comment
=cut

bool
skip_to(term_docs, target)
    TermDocs *term_docs;
    U32       target;
CODE:
    RETVAL = term_docs->skip_to(term_docs, target);
OUTPUT: RETVAL

SV*
_parent_set_or_get(term_docs, ...)
    TermDocs *term_docs;
ALIAS:
    set_doc       = 1
    get_doc       = 2
    set_freq      = 3
    get_freq      = 4
    set_positions = 5
    get_positions = 6
    set_doc_freq  = 7
    get_doc_freq  = 8
PREINIT:
    U32 num;
CODE:
{
    KINO_START_SET_OR_GET_SWITCH

    case 1:  Kino1_confess("Can't set_doc");
             /* fall through */
    case 2:  num = term_docs->get_doc(term_docs);
             RETVAL = num == KINO_TERM_DOCS_SENTINEL 
             ? &PL_sv_undef
             : newSVuv(num);
             break;

    case 3:  Kino1_confess("Can't set_freq");
             /* fall through */
    case 4:  num = term_docs->get_freq(term_docs);
             RETVAL = num == KINO_TERM_DOCS_SENTINEL 
             ? &PL_sv_undef 
             : newSVuv(num);
             break;

    case 5:  Kino1_confess("Can't set_positions");
             /* fall through */
    case 6:  RETVAL = newSVsv(term_docs->get_positions(term_docs));
             break;

    case 7:  term_docs->set_doc_freq(term_docs, (U32)SvUV(ST(1)) );
             /* fall through */
    case 8:  num = term_docs->get_doc_freq(term_docs);
             RETVAL = num == KINO_TERM_DOCS_SENTINEL 
             ? &PL_sv_undef
             : newSVuv(num);
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL

void
DESTROY(term_docs)
    TermDocs *term_docs;
PPCODE:
    term_docs->destroy(term_docs);


__H__

#ifndef H_KINO_TERM_DOCS
#define H_KINO_TERM_DOCS 1

#define KINO_TERM_DOCS_SENTINEL 0xFFFFFFFF

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilMemManager.h"
#include "KinoSearch1IndexTermInfo.h"

typedef struct termdocs {
    void  *child;
    SV    *positions;
    void (*set_doc_freq)(struct termdocs*, U32);
    U32  (*get_doc_freq)(struct termdocs*);
    U32  (*get_doc)(struct termdocs*);
    U32  (*get_freq)(struct termdocs*);
    SV*  (*get_positions)(struct termdocs*);
    void (*seek_tinfo)(struct termdocs*, TermInfo*);
    bool (*next)(struct termdocs*);
    bool (*skip_to)(struct termdocs*, U32);
    U32  (*bulk_read)(struct termdocs*, SV*, SV*, U32);
    void (*destroy)(struct termdocs*);
} TermDocs;

TermDocs* Kino1_TermDocs_new();
void Kino1_TermDocs_set_doc_freq_death(TermDocs*, U32);
U32  Kino1_TermDocs_get_doc_freq_death(TermDocs*);
U32  Kino1_TermDocs_get_doc_death(TermDocs*);
U32  Kino1_TermDocs_get_freq_death(TermDocs*);
SV*  Kino1_TermDocs_get_positions_death(TermDocs*);
void Kino1_TermDocs_seek_tinfo_death(TermDocs*, TermInfo*);
bool Kino1_TermDocs_next_death(TermDocs*);
bool Kino1_TermDocs_skip_to_death(TermDocs*, U32);
U32  Kino1_TermDocs_bulk_read_death(TermDocs*, SV*, SV*, U32);
void Kino1_TermDocs_destroy(TermDocs*);

#endif /* include guard */

__C__

#include "KinoSearch1IndexTermDocs.h"

TermDocs*
Kino1_TermDocs_new() {
    TermDocs* term_docs;
    
    Kino1_New(0, term_docs, 1, TermDocs);
    term_docs->child = NULL;

    /* force the subclass to override functions */
    term_docs->set_doc_freq  = Kino1_TermDocs_set_doc_freq_death;
    term_docs->get_doc_freq  = Kino1_TermDocs_get_doc_freq_death;
    term_docs->get_doc       = Kino1_TermDocs_get_doc_death;
    term_docs->get_freq      = Kino1_TermDocs_get_freq_death;
    term_docs->get_positions = Kino1_TermDocs_get_positions_death;
    term_docs->seek_tinfo    = Kino1_TermDocs_seek_tinfo_death;
    term_docs->next          = Kino1_TermDocs_next_death;
    term_docs->skip_to       = Kino1_TermDocs_skip_to_death;
    term_docs->destroy       = Kino1_TermDocs_destroy;

    return term_docs;
}

void
Kino1_TermDocs_set_doc_freq_death(TermDocs *term_docs, U32 doc_freq) {
    Kino1_confess("term_docs->set_doc_freq must be defined in a subclass");
}

U32
Kino1_TermDocs_get_doc_freq_death(TermDocs *term_docs) {
    Kino1_confess("term_docs->get_doc_freq must be defined in a subclass");
    return 1;
}


U32
Kino1_TermDocs_get_doc_death(TermDocs *term_docs) {
    Kino1_confess("term_docs->get_doc must be defined in a subclass");
    return 1;
}

U32
Kino1_TermDocs_get_freq_death(TermDocs *term_docs) {
    Kino1_confess("term_docs->get_freq must be defined in a subclass");
    return 1;
}

SV*
Kino1_TermDocs_get_positions_death(TermDocs *term_docs) {
    Kino1_confess("term_docs->get_positions must be defined in a subclass");
    return &PL_sv_undef;
}

void
Kino1_TermDocs_seek_tinfo_death(TermDocs *term_docs, TermInfo *tinfo) {
    Kino1_confess("term_docs->seek_tinfo must be defined in a subclass");
}

bool
Kino1_TermDocs_next_death(TermDocs *term_docs) {
    Kino1_confess("term_docs->next must be defined in a subclass");
    return 1;
}

U32  
Kino1_TermDocs_bulk_read_death(TermDocs* term_docs, SV* doc_nums_sv, 
                              SV* freqs_sv, U32 num_wanted) {
    Kino1_confess("term_docs->bulk_read must be defined in a subclass");
    return 1;
}

bool
Kino1_TermDocs_skip_to_death(TermDocs *term_docs, U32 target) {
    Kino1_confess("term_docs->skip_to must be defined in a subclass");
    return 1;
}

void
Kino1_TermDocs_destroy(TermDocs *term_docs) {
    Kino1_Safefree(term_docs);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::TermDocs - retrieve list of docs which contain a Term

==head1 SYNOPSIS

    # abstract base class, but here's how a subclass works:

    $term_docs->seek($term);
    my $num_got  = $term_docs->bulk_read( $docs, $freqs, $num_to_read );
    my @doc_nums = unpack( 'I*', $docs );
    my @tf_ds    = unpack( 'I*', $freqs );    # term frequency in document

    # alternately...
    $term_docs->set_read_positions(1);
    while ($term_docs->next) {
        do_something_with(
            doc       => $term_docs->get_doc,
            freq      => $term_docs->get_freq,
            positions => $term_docs->get_positions,
        );
    }

==head1 DESCRIPTION

Feed a TermDocs object a Term to get docs (and freqs).  If a term is present
in the portion of an index that a TermDocs subclass is responsible for, the
object is used to access the doc_nums for the documents in which it appears,
plus the number of appearances, plus (optionally), the positions at which the
term appears in the document.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

