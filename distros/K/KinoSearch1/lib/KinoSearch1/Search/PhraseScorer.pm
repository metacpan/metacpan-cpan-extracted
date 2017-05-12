package KinoSearch1::Search::PhraseScorer;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Scorer );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params
        weight         => undef,
        term_docs      => undef,
        phrase_offsets => undef,
        norms_reader   => undef,
        slop           => 0,
    );
}
our %instance_vars;

sub new {
    my $either = shift;
    confess kerror() unless verify_args( \%instance_vars, @_ );
    my %args = ( %instance_vars, @_ );
    my $self = $either->SUPER::new;
    $self->_init_child;

    # set/derive some member vars
    $self->_set_norms( $args{norms_reader}->get_bytes );
    $self->set_similarity( $args{similarity} );
    $self->_set_weight_value( $args{weight}->get_value );
    confess("Sloppy phrase matching not yet implemented")
        unless $args{slop} == 0;    # TODO -- enable slop.
    $self->_set_slop( $args{slop} );

    # sort terms by ascending frequency
    confess("positions count doesn't match term count")
        unless $#{ $args{term_docs} } == $#{ $args{phrase_offsets} };
    my @by_size = sort { $a->[0]->get_doc_freq <=> $b->[0]->get_doc_freq }
        map { [ $args{term_docs}[$_], $args{phrase_offsets}[$_] ] }
        0 .. $#{ $args{term_docs} };
    my @term_docs      = map { $_->[0] } @by_size;
    my @phrase_offsets = map { $_->[1] } @by_size;
    $self->_init_elements( \@term_docs, \@phrase_offsets );

    return $self;
}

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Search::PhraseScorer

void
_init_child(scorer)
    Scorer *scorer;
PPCODE:
    Kino1_PhraseScorer_init_child(scorer);

void
_init_elements(scorer, term_docs_av, phrase_offsets_av) 
    Scorer *scorer;
    AV     *term_docs_av;
    AV     *phrase_offsets_av;
PREINIT:
    PhraseScorerChild *child;
    I32                i;
    SV               **sv_ptr;
    IV                 tmp;
PPCODE:
{
    child = (PhraseScorerChild*)scorer->child;

    SvREFCNT_inc(term_docs_av);
    SvREFCNT_dec(child->term_docs_av);
    child->term_docs_av = term_docs_av;

    child->num_elements = av_len(term_docs_av) + 1;
    Kino1_New(0, child->term_docs, child->num_elements, TermDocs*);
    Kino1_New(0, child->phrase_offsets, child->num_elements, U32);
    
    /* create an array of TermDocs* */
    for(i = 0; i < child->num_elements; i++) {
        sv_ptr = av_fetch(term_docs_av, i, 0);
        tmp                 = SvIV((SV*)SvRV( *sv_ptr ));
        child->term_docs[i] = INT2PTR(TermDocs*, tmp);
        sv_ptr = av_fetch(phrase_offsets_av, i, 0);
        child->phrase_offsets[i] = SvIV( *sv_ptr );
    }
}

SV*
_phrase_scorer_set_or_get(scorer, ...)
    Scorer *scorer;
ALIAS:
    _set_slop = 1
    _get_slop = 2
    _set_weight_value = 3
    _get_weight_value = 4
    _set_norms        = 5
    _get_norms        = 6
CODE:
{
    PhraseScorerChild *child = (PhraseScorerChild*)scorer->child;

    KINO_START_SET_OR_GET_SWITCH

    case 1:  child->slop = SvIV( ST(1) );
             /* fall through */
    case 2:  RETVAL = newSViv(child->slop);
             break;

    case 3:  child->weight_value = SvNV( ST(1) );
             /* fall through */
    case 4:  RETVAL = newSVnv(child->weight_value);
             break;

    case 5:  SvREFCNT_dec(child->norms_sv);
             child->norms_sv = newSVsv( ST(1) );
             {
                 SV* bytes_deref_sv;
                 bytes_deref_sv = SvRV(child->norms_sv);
                 if (SvPOK(bytes_deref_sv)) {
                     child->norms = (unsigned char*)SvPVX(bytes_deref_sv);
                 }
                 else {
                     child->norms = NULL;
                 }
             }
             /* fall through */
    case 6:  RETVAL = newSVsv(child->norms_sv);
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL

void
DESTROY(scorer)
    Scorer *scorer;
PPCODE:
    Kino1_PhraseScorer_destroy(scorer);

__H__

#ifndef H_KINO_PHRASE_SCORER
#define H_KINO_PHRASE_SCORER 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1IndexTermDocs.h"
#include "KinoSearch1SearchScorer.h"
#include "KinoSearch1UtilMemManager.h"

typedef struct phrasescorerchild {
    U32             doc;
    U32             slop;
    U32             num_elements;
    TermDocs      **term_docs;
    U32            *phrase_offsets;
    float           phrase_freq;
    float           weight_value;
    U32             first_time;
    unsigned char  *norms;
    SV             *anchor_set;
    float         (*calc_phrase_freq)(Scorer*);
    SV             *norms_sv;
    AV             *term_docs_av;
} PhraseScorerChild;

void  Kino1_PhraseScorer_init_child(Scorer*);
bool  Kino1_PhraseScorer_next(Scorer*);
float Kino1_PhraseScorer_calc_phrase_freq(Scorer*);
U32   Kino1_PhraseScorer_doc(Scorer*);
float Kino1_PhraseScorer_score(Scorer*);
void  Kino1_PhraseScorer_destroy(Scorer*);

#endif /* include guard */


__C__

#include "KinoSearch1SearchPhraseScorer.h"

void
Kino1_PhraseScorer_init_child(Scorer *scorer) {
    PhraseScorerChild *child;

    /* allocate */
    Kino1_New(0, child, 1, PhraseScorerChild);
    scorer->child = child;
    child->anchor_set      = newSV(0);

    /* init */
    child->doc             = 0xFFFFFFFF;
    child->slop            = 0;
    child->first_time      = 1;
    child->phrase_freq     = 0.0;
    child->norms           = NULL;
    child->phrase_offsets  = NULL;
    child->term_docs_av    = (AV*)&PL_sv_undef;
    child->norms_sv        = &PL_sv_undef;;


    /* define abstract methods */
    scorer->next            = Kino1_PhraseScorer_next;
    scorer->score           = Kino1_PhraseScorer_score;
    scorer->doc             = Kino1_PhraseScorer_doc;
    child->calc_phrase_freq = Kino1_PhraseScorer_calc_phrase_freq;
}

bool
Kino1_PhraseScorer_next(Scorer *scorer) {
    PhraseScorerChild *child;
    TermDocs         **term_docs;
    U32                candidate;
    U32                i;

    child = (PhraseScorerChild*)scorer->child;
    term_docs = child->term_docs;
    
    child->phrase_freq = 0.0;
    child->doc = 0xFFFFFFFF; 

    if (child->first_time) {
        child->first_time = 0;
        /* advance all except the first term_docs */
        for (i = 1; i < child->num_elements; i++) {
            if ( !term_docs[i]->next(term_docs[i]) )
                return 0;
        }
    }
    
    /* seed the search */
    if ( !term_docs[0]->next(term_docs[0]) )
        return 0;
    candidate = term_docs[0]->get_doc(term_docs[0]);

    /* find a doc which contains all the terms */
    FIND_COMMON_DOC:
    while (1) {
        for (i = 0; i < child->num_elements; i++) {
            U32 thisdoc = term_docs[i]->get_doc(term_docs[i]);
            if (thisdoc > candidate)
                candidate = thisdoc;
        }
        for (i = 0; i < child->num_elements; i++) {
            U32 thisdoc = term_docs[i]->get_doc(term_docs[i]);
            if (thisdoc < candidate) {
                if (!term_docs[i]->skip_to(term_docs[i], candidate))
                    return 0;
            }
        }
        for (i = 0; i < child->num_elements; i++) {
            if (term_docs[i]->get_doc(term_docs[i]) != candidate) {
                goto FIND_COMMON_DOC;
            }
        }
        break; /* success! */
    }

    /* if the terms don't actually form a phrase, skip to the next doc */
    child->phrase_freq = child->calc_phrase_freq(scorer);
    if (child->phrase_freq == 0.0)
        return scorer->next(scorer);

    /* success! */
    child->doc  = candidate;
    return 1;
}

float
Kino1_PhraseScorer_calc_phrase_freq(Scorer *scorer) {
    PhraseScorerChild *child;
    TermDocs         **term_docs;
    U32               *anchors;
    U32               *anchors_start;
    U32               *anchors_end;
    U32               *new_anchors;
    U32               *candidates;
    U32               *candidates_end;
    U32                phrase_offset;
    U32                i;
    STRLEN             len;

    child     = (PhraseScorerChild*)scorer->child;
    term_docs = child->term_docs;

    /* create an anchor set */
    sv_setsv( child->anchor_set, term_docs[0]->get_positions(term_docs[0]) );
    anchors_start = (U32*)SvPVX(child->anchor_set);
    anchors       = anchors_start;
    anchors_end   = (U32*)SvEND(child->anchor_set);
    phrase_offset = child->phrase_offsets[0];
    while(anchors < anchors_end) {
        *anchors++ -= phrase_offset;
    }

    /* match the positions of other terms against the anchor set */
    for (i = 1; i < child->num_elements; i++) {
        phrase_offset = child->phrase_offsets[i];

        anchors     = anchors_start;
        new_anchors = anchors_start;
        anchors_end = (U32*)SvEND(child->anchor_set);
        new_anchors = anchors;

        candidates     
            = (U32*)SvPVX( term_docs[i]->get_positions(term_docs[i]) );
        candidates_end 
            = (U32*)SvEND( term_docs[i]->get_positions(term_docs[i]) );

        while (anchors < anchors_end) {
            U32 target;

            /* Discard positions that occur too early in the field to match as
             * a part of the phrase.  For example, if the field begins with
             * "The ants go marching one by one", that initial "the" cannot
             * match as the second term in a phrase search for 
             * "fight the power".
             */
            target = phrase_offset;
            while (candidates < candidates_end && *candidates < target) {
                candidates++;
            }
            if (candidates == candidates_end)
                break;

            /* Discard partial matches which seemed promising earlier but
             * which fail on this go-round.
             */
            target = *candidates - phrase_offset;
            while (anchors < anchors_end && *anchors < target) {
                anchors++;
            }
            if (anchors == anchors_end)
                break;

            /* Blast past any positions for the current term which are too low
             * for the partial phrase matched in earlier iters.
             */
            target = *anchors + phrase_offset;
            while (candidates < candidates_end && *candidates < target) {
                candidates++;
            }
            if (candidates == candidates_end)
                break;

            /* Does the current position fall into the slot? */
            if (*candidates == target) {
                /* The anchor has made it through another elimination round. */
                *new_anchors = *anchors;
                new_anchors++;
            }
            anchors++;
        }

        /* winnow down the size of the anchor set */
        len = (char*)new_anchors - (char*)anchors_start;
        SvCUR_set(child->anchor_set, len);
    }

    /* the number of anchors left is the phrase freq */
    len = SvCUR(child->anchor_set);
    return (float) len / sizeof(U32);
}

U32
Kino1_PhraseScorer_doc(Scorer *scorer) {
    PhraseScorerChild* child = (PhraseScorerChild*)scorer->child;
    return child->doc;
}

float
Kino1_PhraseScorer_score(Scorer *scorer) {
    PhraseScorerChild* child;
    float              score;
    unsigned char      norm;
    
    child = (PhraseScorerChild*)scorer->child;

    /* calculate raw score */
    score =  scorer->sim->tf(scorer->sim, child->phrase_freq) 
             * child->weight_value;

    /* normalize */
    norm   = child->norms[ child->doc ];
    score *= scorer->sim->norm_decoder[norm];

    return score;
}

void
Kino1_PhraseScorer_destroy(Scorer *scorer) {
    PhraseScorerChild *child;
    
    child = (PhraseScorerChild*)scorer->child;

    Kino1_Safefree(child->term_docs);
    Kino1_Safefree(child->phrase_offsets);
    SvREFCNT_dec(child->norms_sv);
    SvREFCNT_dec((SV*)child->term_docs_av);
    SvREFCNT_dec(child->anchor_set);

    Kino1_Safefree(child);
    Kino1_Scorer_destroy(scorer);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Search::PhraseScorer - scorer for PhraseQuery

==head1 DESCRIPTION 

Score phrases.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
