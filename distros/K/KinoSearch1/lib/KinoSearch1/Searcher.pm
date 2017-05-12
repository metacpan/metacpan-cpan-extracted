package KinoSearch1::Searcher;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Searchable );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # params/members
        invindex => undef,
        analyzer => undef,
        # members
        reader       => undef,
        close_reader => 0,       # not implemented yet
    );
    __PACKAGE__->ready_get(qw( reader ));
}

use KinoSearch1::Store::FSInvIndex;
use KinoSearch1::Index::IndexReader;
use KinoSearch1::Search::Hits;
use KinoSearch1::Search::HitCollector;
use KinoSearch1::Search::Similarity;
use KinoSearch1::QueryParser::QueryParser;
use KinoSearch1::Search::BooleanQuery;
use KinoSearch1::Analysis::Analyzer;

sub init_instance {
    my $self = shift;

    $self->{analyzer} ||= KinoSearch1::Analysis::Analyzer->new;
    $self->{similarity} = KinoSearch1::Search::Similarity->new;
    $self->{field_sims} = {};

    if ( !defined $self->{reader} ) {
        # confirm or create an InvIndex object
        my $invindex;
        if ( blessed( $self->{invindex} )
            and $self->{invindex}->isa('KinoSearch1::Store::InvIndex') )
        {
            $invindex = $self->{invindex};
        }
        elsif ( defined $self->{invindex} ) {
            $invindex = $self->{invindex}
                = KinoSearch1::Store::FSInvIndex->new(
                create => $self->{create},
                path   => $self->{invindex},
                );
        }
        else {
            croak("valid 'reader' or 'invindex' must be supplied");
        }

        # now that we have an invindex, get a reader for it
        $self->{reader} = KinoSearch1::Index::IndexReader->new(
            invindex => $self->{invindex} );
    }
}

my %search_args = (
    query    => undef,
    filter   => undef,
    num_docs => undef,
);

sub search {
    my $self = shift;
    my %args
        = @_ == 1
        ? ( %search_args, query => $_[0] )
        : ( %search_args, @_ );
    confess kerror() unless verify_args( \%search_args, %args );

    # turn a query string into a query against all fields
    if ( !a_isa_b( $args{query}, 'KinoSearch1::Search::Query' ) ) {
        $args{query} = $self->_prepare_simple_search( $args{query} );
    }

    return KinoSearch1::Search::Hits->new( searcher => $self, %args );
}

sub get_field_names {
    my $self = shift;
    return $self->{reader}->get_field_names(@_);
}

# Search for the query string against all indexed fields
sub _prepare_simple_search {
    my ( $self, $query_string ) = @_;

    my $indexed_field_names = $self->get_field_names( indexed => 1 );
    my $query_parser = KinoSearch1::QueryParser::QueryParser->new(
        fields   => $indexed_field_names,
        analyzer => $self->{analyzer},
    );
    return $query_parser->parse($query_string);
}

my %search_hit_collector_args = (
    hit_collector => undef,
    weight        => undef,
    filter        => undef,
    sort_spec     => undef,
);

sub search_hit_collector {
    my $self = shift;
    confess kerror() unless verify_args( \%search_hit_collector_args, @_ );
    my %args = ( %search_hit_collector_args, @_ );

    # wrap the collector if there's a filter
    my $collector = $args{hit_collector};
    if ( defined $args{filter} ) {
        $collector = KinoSearch1::Search::FilteredCollector->new(
            filter_bits   => $args{filter}->bits($self),
            hit_collector => $args{hit_collector},
        );
    }

    # accumulate hits into the HitCollector if the query is valid
    my $scorer = $args{weight}->scorer( $self->{reader} );
    if ( defined $scorer ) {
        $scorer->score_batch(
            hit_collector => $collector,
            end           => $self->{reader}->max_doc,
        );
    }
}

sub fetch_doc { $_[0]->{reader}->fetch_doc( $_[1] ) }
sub max_doc   { shift->{reader}->max_doc }

sub doc_freq {
    my ( $self, $term ) = @_;
    return $self->{reader}->doc_freq($term);
}

sub create_weight {
    my ( $self, $query ) = @_;
    return $query->to_weight($self);
}

sub rewrite {
    my ( $self, $query ) = @_;
    my $reader = $self->{reader};
    while (1) {
        my $rewritten = $query->rewrite($reader);
        last if ( 0 + $rewritten == 0 + $query );
        $query = $rewritten;
    }
    return $query;
}

sub close {
    my $self = shift;
    $self->{reader}->close if $self->{close_reader};
}

1;

__END__

=head1 NAME

KinoSearch1::Searcher - execute searches

=head1 SYNOPSIS

    my $analyzer = KinoSearch1::Analysis::PolyAnalyzer->new( 
        language => 'en',
    );

    my $searcher = KinoSearch1::Searcher->new(
        invindex => $invindex,
        analyzer => $analyzer,
    );
    my $hits = $searcher->search( query => 'foo bar' );


=head1 DESCRIPTION

Use the Searcher class to perform queries against an invindex.  

=head1 METHODS

=head2 new

    my $searcher = KinoSearch1::Searcher->new(
        invindex => $invindex,
        analyzer => $analyzer,
    );

Constructor.  Takes two labeled parameters, both of which are required.

=over

=item *

B<invindex> - can be either a path to an invindex, or a
L<KinoSearch1::Store::InvIndex|KinoSearch1::Store::InvIndex> object.

=item *

B<analyzer> - An object which subclasses
L<KinoSearch1::Analysis::Analyer|KinoSearch1::Analysis::Analyzer>, such as a
L<PolyAnalyzer|KinoSearch1::Analysis::PolyAnalyzer>.  This B<must> be identical
to the Analyzer used at index-time, or the results won't match up.

=back

=head2 search

    my $hits = $searcher->search( 
        query  => $query,  # required
        filter => $filter, # default: undef (no filtering)
    );

Process a search and return a L<Hits|KinoSearch1::Search::Hits> object.
search() expects labeled hash-style parameters.

=over

=item *

B<query> - Can be either an object which subclasses
L<KinoSearch1::Search::Query|KinoSearch1::Search::Query>, or a query string.  If
it's a query string, it will be parsed using a QueryParser and a search will
be performed against all indexed fields in the invindex.  For more sophisticated
searching, supply Query objects, such as TermQuery and BooleanQuery.

=item *

B<filter> - Must be a
L<KinoSearch1::Search::QueryFilter|KinoSearch1::Search::QueryFilter>.  Search
results will be limited to only those documents which pass through the filter.

=back

=head1 Caching a Searcher

When a Searcher is created, a small portion of the invindex is loaded into
memory.  For large document collections, this startup time may become
noticeable, in which case reusing the searcher is likely to speed up your
search application.  Caching a Searcher is especially helpful when running a
high-activity app under mod_perl.

Searcher objects always represent a snapshot of an invindex as it existed when
the Searcher was created.  If you want the search results to reflect
modifications to an invindex, you must create a new Searcher after the update
process completes.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.
