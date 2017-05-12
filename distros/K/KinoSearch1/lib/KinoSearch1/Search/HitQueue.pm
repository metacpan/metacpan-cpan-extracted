package KinoSearch1::Search::HitQueue;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::PriorityQueue );

BEGIN { __PACKAGE__->init_instance_vars() }

use KinoSearch1::Search::Hit;

sub new {
    my $either = shift;
    my $self   = $either->SUPER::new(@_);

    $self->define_less_than;

    return $self;
}

# Create an array of "empty" Hit objects -- they have scores and ids,
# but the stored fields have yet to be retrieved.
sub hits {
    my ( $self, $start_offset, $num_wanted, $searcher ) = @_;
    my @hits = @{ $self->pop_all };

    if ( defined $start_offset and defined $num_wanted ) {
        @hits = splice( @hits, $start_offset, $num_wanted );
    }

    @hits = map {
        KinoSearch1::Search::Hit->new(
            id       => unpack( 'N', "$_" ),
            score    => 0 + $_,
            searcher => $searcher
            )
    } @hits;

    return \@hits;
}

1;

__END__
__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Search::HitQueue

void
define_less_than(hitq)
    PriorityQueue *hitq;
PPCODE:
    hitq->less_than = &Kino1_HitQ_less_than;

__H__

#ifndef H_KINOSEARCH_SEARCH_HIT_QUEUE
#define H_KINOSEARCH_SEARCH_HIT_QUEUE 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

bool Kino1_HitQ_less_than(SV*, SV*);

#endif /* include guard */

__C__

#include "KinoSearch1SearchHitQueue.h"

/* Compare the NV then the PV for two scalars. 
 */
bool
Kino1_HitQ_less_than(SV* a, SV* b) {
    char *ptr_a, *ptr_b; 

    if (SvNV(a) == SvNV(b)) {
        ptr_a = SvPVX(a);
        ptr_b = SvPVX(b);
        /* sort by doc_num second */
        return (bool) (memcmp(ptr_b, ptr_a, 4) < 0);
    }
    /* sort by score first */
    return SvNV(a) < SvNV(b);
}


__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Search::HitQueue - track highest scoring docs

==head1 DESCRIPTION 

HitQueue, a subclass of KinoSearch1::Util::PriorityQueue, keeps track of
score/doc_num pairs.  Each pair is stored in a single scalar, with the
document number in the PV and the score in the NV.
The encoding algorithm is functionally equivalent to this:

    my $encoded_doc_num = pack('N', $doc_num);
    my $doc_num_slash_score = dualvar( $score, $encoded_doc_num );

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
