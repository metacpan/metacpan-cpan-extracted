package KinoSearch1::Search::BooleanScorer;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Scorer );

BEGIN { __PACKAGE__->init_instance_vars() }
our %instance_vars;

sub new {
    my $self = shift->SUPER::new;
    confess kerror() unless verify_args( \%instance_vars, @_ );
    my %args = ( %instance_vars, @_ );
    $self->set_similarity( $args{similarity} );
    $self->_init_child;
    return $self;
}

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Search::BooleanScorer

void
_init_child(scorer)
    Scorer *scorer;
PPCODE:
    Kino1_BoolScorer_init_child(scorer);

=for comment
Add a scorer for a sub-query of the BooleanQuery.

=cut

void 
add_subscorer(scorer, subscorer_sv, occur)
    Scorer *scorer;
    SV     *subscorer_sv;
    char   *occur;
PREINIT:
    BoolScorerChild* child;
    Scorer *subscorer;
    SV     *subscorer_sv_copy;
PPCODE:
    child = (BoolScorerChild*)scorer->child;
    Kino1_extract_struct(subscorer_sv, subscorer, 
        Scorer*, "KinoSearch1::Search::Scorer");
    subscorer_sv_copy = newSVsv(subscorer_sv);
    av_push(child->subscorers_av, subscorer_sv_copy);
    Kino1_BoolScorer_add_subscorer(scorer, subscorer, occur);

SV*
_boolean_scorer_set_or_get(scorer, ...)
    Scorer* scorer;
ALIAS:
    _get_subscorer_storage = 2
CODE:
{
    BoolScorerChild* child = (BoolScorerChild*)scorer->child;

    KINO_START_SET_OR_GET_SWITCH

    case 2:  RETVAL = newRV((SV*)child->subscorers_av);
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL

void
DESTROY(scorer)
    Scorer *scorer;
PPCODE:
    Kino1_BoolScorer_destroy(scorer);

__H__

#ifndef H_KINO_BOOLEAN_SCORER
#define H_KINO_BOOLEAN_SCORER 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1SearchScorer.h"
#include "KinoSearch1UtilMemManager.h"

#define KINO_MATCH_BATCH_SIZE (1 << 11)
#define KINO_MATCH_BATCH_DOC_MASK (KINO_MATCH_BATCH_SIZE - 1)

/* A MatchBatch can hold scoring data for 2048 documents.  */

typedef struct matchbatch {
    U32       count;
    float    *scores;
    U32      *matcher_counts;
    U32      *bool_masks;
    U32      *recent_docs;
} MatchBatch;

typedef struct boolsubscorer {
    Scorer *scorer;
    U32     bool_mask;
    bool    done;
    struct boolsubscorer *next_subscorer;
} BoolSubScorer;

typedef struct boolscorerchild {
    U32            doc;
    U32            end;
    U32            max_coord;
    float         *coord_factors;
    U32            required_mask;
    U32            prohibited_mask;
    U32            next_mask;
    MatchBatch    *mbatch;
    BoolSubScorer *subscorers; /* linked list */
    AV            *subscorers_av;
} BoolScorerChild;

void Kino1_BoolScorer_init_child(Scorer*);
MatchBatch* Kino1_BoolScorer_new_mbatch();
void Kino1_BoolScorer_clear_mbatch(MatchBatch*);
void Kino1_BoolScorer_compute_coord_factors(Scorer*);
void Kino1_BoolScorer_add_subscorer(Scorer*, Scorer*, char*);
bool Kino1_BoolScorer_next(Scorer*);
float Kino1_BoolScorer_score(Scorer*);
U32 Kino1_BoolScorer_doc(Scorer*);
void Kino1_BoolScorer_destroy(Scorer*);

#endif /* include guard */

__C__

#include "KinoSearch1SearchBooleanScorer.h"

void
Kino1_BoolScorer_init_child(Scorer *scorer) {
    BoolScorerChild *child;

    Kino1_New(0, child, 1, BoolScorerChild);
    scorer->child = child;

    /* define Scorer's abstract methods */
    scorer->next  = Kino1_BoolScorer_next;
    scorer->doc   = Kino1_BoolScorer_doc;
    scorer->score = Kino1_BoolScorer_score;

    /* init */
    child->end             = 0;
    child->max_coord       = 1;
    child->coord_factors   = NULL;
    child->required_mask   = 0;
    child->prohibited_mask = 0;
    child->next_mask       = 1;
    child->mbatch          = Kino1_BoolScorer_new_mbatch();
    child->subscorers      = NULL;
    child->subscorers_av   = newAV();
}

MatchBatch*
Kino1_BoolScorer_new_mbatch() {
    MatchBatch* mbatch;

    /* allocate and init */
    Kino1_New(0, mbatch, 1, MatchBatch);
    Kino1_New(0, mbatch->scores, KINO_MATCH_BATCH_SIZE, float);
    Kino1_New(0, mbatch->matcher_counts, KINO_MATCH_BATCH_SIZE, U32);
    Kino1_New(0, mbatch->bool_masks, KINO_MATCH_BATCH_SIZE, U32);
    Kino1_New(0, mbatch->recent_docs, KINO_MATCH_BATCH_SIZE, U32);
    mbatch->count    = 0;

    return mbatch;
}

/* Return a MatchBatch to a "zeroed" state.  Only the matcher_counts and the
 * count are actually cleared; the rest get initialized the next time a doc
 * gets captured. */
void
Kino1_BoolScorer_clear_mbatch(MatchBatch *mbatch) {
    Zero(mbatch->matcher_counts, KINO_MATCH_BATCH_SIZE, U32);
    mbatch->count = 0;
}

/* BooleanScorers award bonus points to documents which match multiple
 * subqueries.  This routine calculates the size of the bonuses. */
void
Kino1_BoolScorer_compute_coord_factors(Scorer *scorer) {
    BoolScorerChild *child;
    float           *coord_factors;
    U32              i;

    child = (BoolScorerChild*)scorer->child;

    Kino1_New(0, child->coord_factors, (child->max_coord + 1), float);
    coord_factors = child->coord_factors;

    for (i = 0; i <= child->max_coord; i++) {
        *coord_factors++ 
            = scorer->sim->coord(scorer->sim, i, child->max_coord);
    }
}

void
Kino1_BoolScorer_add_subscorer(Scorer* main_scorer, Scorer* subscorer, 
                              char *occur) {
    BoolScorerChild *child;
    BoolSubScorer   *bool_subscorer;

    child = (BoolScorerChild*)main_scorer->child;
    
    Kino1_New(0, bool_subscorer, 1, BoolSubScorer);
    bool_subscorer->scorer = subscorer;

    /* if this scorer is required or negated, assign it a unique mask bit. */
    if (strnEQ(occur, "SHOULD", 6)) {
        bool_subscorer->bool_mask = 0;
        child->max_coord++;
    }
    else {
        if (child->next_mask == 0) {
            Kino1_confess("more than 32 required or prohibited clauses");
        }
        bool_subscorer->bool_mask = child->next_mask;
        child->next_mask <<= 1;

        if (strnEQ(occur, "MUST_NOT", 8)) {
            child->prohibited_mask |= bool_subscorer->bool_mask;
        }
        else { /* "MUST" occur */
            child->max_coord++;
            child->required_mask |= bool_subscorer->bool_mask;
        }
    }

    /* prime the pump */
    bool_subscorer->done = !subscorer->next(subscorer);

    /* link up the linked list of subscorers */
    bool_subscorer->next_subscorer = child->subscorers;
    child->subscorers = bool_subscorer;
}

bool
Kino1_BoolScorer_next(Scorer* scorer) {
    BoolScorerChild *child;
    MatchBatch      *mbatch;
    bool             more;
    U32              doc;
    U32              masked_doc;
    U32              bool_mask;
    BoolSubScorer   *sub;

    child = (BoolScorerChild*)scorer->child;
    mbatch = child->mbatch;

    do {
        while (mbatch->count-- > 0) { 

            /* check to see if the doc is prohibited */
            doc        = mbatch->recent_docs[ mbatch->count ];
            masked_doc = doc & KINO_MATCH_BATCH_DOC_MASK;
            bool_mask  = mbatch->bool_masks[masked_doc];
            if (   (bool_mask & child->prohibited_mask) == 0
                && (bool_mask & child->required_mask) == child->required_mask
            ) {
                /* it's not prohibited, so next() was successful */
                child->doc = doc;
                return 1;
            }
        }

        /* refill the queue, processing all docs within the next range */
        Kino1_BoolScorer_clear_mbatch(mbatch);
        more = 0;
        child->end += KINO_MATCH_BATCH_SIZE;
        
        /* iterate through subscorers, caching results to the MatchBatch */
        for (sub = child->subscorers; sub != NULL; sub = sub->next_subscorer) {
            Scorer *scorer = sub->scorer;
            while (!sub->done && scorer->doc(scorer) < child->end) {
                doc        = scorer->doc(scorer);
                masked_doc = doc & KINO_MATCH_BATCH_DOC_MASK;
                if (mbatch->matcher_counts[masked_doc] == 0) {
                    /* first scorer to hit this doc */
                    mbatch->recent_docs[mbatch->count] = doc;
                    mbatch->count++;
                    mbatch->matcher_counts[masked_doc] = 1;
                    mbatch->scores[masked_doc]     = scorer->score(scorer);
                    mbatch->bool_masks[masked_doc] = sub->bool_mask;
                }
                else {
                    mbatch->matcher_counts[masked_doc]++;
                    mbatch->scores[masked_doc] += scorer->score(scorer);
                    mbatch->bool_masks[masked_doc] |= sub->bool_mask;
                }

                /* check whether this scorer is exhausted */
                sub->done = !scorer->next(scorer);
            }
            /* if at least one scorer succeeded, loop back */
            if (!sub->done) {
                more = 1;
            }
        } 
    } while (mbatch->count > 0 || more);

    /* out of docs!  we're done. */
    return 0;
}

float
Kino1_BoolScorer_score(Scorer* scorer){
    BoolScorerChild *child = (BoolScorerChild*)scorer->child;
    MatchBatch      *mbatch = child->mbatch;
    U32              masked_doc;
    float            score;

    if (child->coord_factors == NULL) {
        Kino1_BoolScorer_compute_coord_factors(scorer);
    }

    /* retrieve the docs accumulated score from the MatchBatch */
    masked_doc = child->doc & KINO_MATCH_BATCH_DOC_MASK;
    score = mbatch->scores[masked_doc];

    /* assign bonus for multi-subscorer matches */
    score *= child->coord_factors[ mbatch->matcher_counts[masked_doc] ];
    return score;
}

U32
Kino1_BoolScorer_doc(Scorer* scorer) {
    BoolScorerChild *child = (BoolScorerChild*)scorer->child;
    return child->doc;
}

void
Kino1_BoolScorer_destroy(Scorer * scorer) {
    BoolSubScorer   *sub, *next_sub;
    BoolScorerChild *child;
    child = (BoolScorerChild*)scorer->child;

    if (child->mbatch != NULL) {
        Kino1_Safefree(child->mbatch->scores);
        Kino1_Safefree(child->mbatch->matcher_counts);
        Kino1_Safefree(child->mbatch->bool_masks);
        Kino1_Safefree(child->mbatch->recent_docs);
        Kino1_Safefree(child->mbatch);
    }
    
    sub = child->subscorers;
    while (sub != NULL) {
        next_sub = sub->next_subscorer;
        Kino1_Safefree(sub);
        sub = next_sub;
        /* individual scorers will be GC'd on their own by Perl */
    }

    Kino1_Safefree(child->coord_factors);

    SvREFCNT_dec((SV*)child->subscorers_av);

    Kino1_Safefree(child);
    Kino1_Scorer_destroy(scorer);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Search::BooleanScorer - scorer for BooleanQuery

==head1 DESCRIPTION 

Implementation of Scorer for BooleanQuery.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
