package KinoSearch1::Search::Hits;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # params/members
        searcher  => undef,
        query     => undef,
        filter    => undef,
        sort_spec => undef,
        num_docs  => undef,

        # members
        weight      => undef,
        highlighter => undef,

        hit_docs   => undef,
        total_hits => undef,
    );

    __PACKAGE__->ready_get(qw( hit_docs ));
}

use KinoSearch1::Highlight::Highlighter;
use KinoSearch1::Search::HitCollector;

sub init_instance {
    my $self = shift;

    croak("required parameter 'query' not supplied")
        unless $self->{query};
    croak("required parameter 'searcher' not supplied")
        unless $self->{searcher};

    # turn the Query into a Weight (so the Query won't get mussed)
    $self->{weight} = $self->{searcher}->create_weight( $self->{query} );
}

sub seek {
    my ( $self, $start_offset, $num_wanted ) = @_;
    croak('Usage: $hits->seek( START, NUM_TO_RETRIEVE );')
        unless @_ = 3;

    # collect enough to satisfy both the offset and the num wanted
    my $collector = KinoSearch1::Search::HitQueueCollector->new(
        size => $num_wanted + $start_offset, );

    # execute the search!
    $self->{searcher}->search_hit_collector(
        hit_collector => $collector,
        weight        => $self->{weight},
        filter        => $self->{filter},
        sort_spec     => $self->{sort_spec},
    );
    $self->{total_hits} = $collector->get_total_hits;
    my $hit_queue = $collector->get_hit_queue;

    # turn the HitQueue into an array of Hit objects
    $self->{hit_docs}
        = $hit_queue->hits( $start_offset, $num_wanted, $self->{searcher} );

}

sub total_hits {
    my $self = shift;
    $self->seek( 0, 100 )
        unless defined $self->{total_hits};
    return $self->{total_hits};
}

sub fetch_hit {
    my $self = shift;
    $self->seek( 0, 100 )
        unless defined $self->{total_hits};

    my $hit = shift @{ $self->{hit_docs} };
    return unless defined $hit;
    return $hit;
}

sub fetch_hit_hashref {
    my $self = shift;
    $self->seek( 0, 100 )
        unless defined $self->{total_hits};

    # bail if there aren't any more *captured* hits
    my $hit = shift @{ $self->{hit_docs} };
    return unless defined $hit;

    # lazily fetch stored fields
    my $hashref = $hit->get_field_values;

    if ( !exists $hashref->{score} ) {
        $hashref->{score} = $hit->get_score;
    }
    if ( defined $self->{highlighter} and !exists $hashref->{excerpt} ) {
        $hashref->{excerpt}
            = $self->{highlighter}->generate_excerpt( $hit->get_doc );
    }

    return $hashref;
}

my %create_excerpts_defaults = ( highlighter => undef, );

sub create_excerpts {
    my $self = shift;
    confess kerror() unless verify_args( \%create_excerpts_defaults, @_ );
    my %args = ( %create_excerpts_defaults, @_ );

    $self->{highlighter} = $args{highlighter};
    $self->{highlighter}->set_terms( [ $self->{query}->extract_terms ] );
}

1;

=head1 NAME

KinoSearch1::Search::Hits - access search results

=head1 SYNOPSIS

    my $hits = $searcher->search( query => $query );
    $hits->seek( 0, 10 );
    while ( my $hashref = $hits->fetch_hit_hashref ) {
        print "<p>$hashref->{title} <em>$hashref->{score}</em></p>\n";
    }

=head1 DESCRIPTION

Hits objects are used to access the results of a search.  By default, a hits
object provides access to the top 100 matches; the seek() method provides
finer-grained control.

A classic application would be paging through hits.  The first time, seek to a
START of 0, and retrieve 10 documents.  If the user wants to see more -- and
there are more than 10 total hits -- seek to a START of 10, and retrieve 10
more documents.  And so on.

=head1 METHODS

=head2 seek 

    $hits->seek( START, NUM_TO_RETRIEVE );

Position the Hits iterator at START, and capture NUM_TO_RETRIEVE docs.

=head2 total_hits

    my $num_that_matched = $hits->total_hits;

Return the total number of documents which matched the query used to produce
the Hits object.  (This number is unlikely to match NUM_TO_RETRIEVE.)

=head2 fetch_hit

    while ( my $hit = $hits->fetch_hit ) {
        # ...
    }

Return the next hit as a KinoSearch1::Search::Hit object.

=head2 fetch_hit_hashref

    while ( my $hashref = $hits->fetch_hit_hashref ) {
        # ...
    }

Return the next hit as a hashref, with the field names as keys and the field
values as values.  An entry for C<score> will also be present, as will an
entry for C<excerpt> if create_excerpts() was called earlier.  However, if the
document contains stored fields named "score" or "excerpt", they will not be
clobbered.

=head2 create_excerpts

    my $highlighter = KinoSearch1::Highlight::Highlighter->new(
        excerpt_field => 'bodytext',    
    );
    $hits->create_excerpts( highlighter => $highlighter );

Use the supplied highlighter to generate excerpts.  See
L<KinoSearch1::Highlight::Highlighter|KinoSearch1::Highlight::Highlighter>.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut

