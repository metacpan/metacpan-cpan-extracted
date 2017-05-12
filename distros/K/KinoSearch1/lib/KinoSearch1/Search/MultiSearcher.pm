package KinoSearch1::Search::MultiSearcher;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Searcher );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # members / constructor args
        searchables => undef,
        # members
        starts  => undef,
        max_doc => undef,
    );
}

use KinoSearch1::Search::Similarity;

sub init_instance {
    my $self = shift;
    $self->{field_sims} = {};

    # derive max_doc, relative start offsets
    my $max_doc = 0;
    my @starts;
    for my $searchable ( @{ $self->{searchables} } ) {
        push @starts, $max_doc;
        $max_doc += $searchable->max_doc;
    }
    $self->{max_doc} = $max_doc;
    $self->{starts}  = \@starts;

    # default similarity
    $self->{similarity} = KinoSearch1::Search::Similarity->new
        unless defined $self->{similarity};
}

sub get_field_names {
    my $self = shift;
    my %field_names;
    for my $searchable ( @{ $self->{searchables} } ) {
        my $sub_field_names = $searchable->get_field_names;
        @field_names{@$sub_field_names} = (1) x scalar @$sub_field_names;
    }
    return [ keys %field_names ];
}

sub max_doc { shift->{max_doc} }

sub close { }

sub subsearcher {
    my ( $self, $doc_num ) = @_;
    my $i = -1;
    for ( @{ $self->{starts} } ) {
        last if $_ > $doc_num;
        $i++;
    }
    return $i;
}

sub doc_freq {
    my ( $self, $term ) = @_;
    my $doc_freq = 0;
    $doc_freq += $_->doc_freq($term) for @{ $self->{searchables} };
    return $doc_freq;
}

sub fetch_doc {
    my ( $self, $doc_num ) = @_;
    my $i          = $self->subsearcher($doc_num);
    my $searchable = $self->{searchables}[$i];
    $doc_num -= $self->{starts}[$i];
    return $searchable->fetch_doc($doc_num);
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
    my ( $searchables, $starts ) = @{$self}{qw( searchables starts )};

    for my $i ( 0 .. $#$searchables ) {
        my $searchable = $searchables->[$i];
        my $start      = $starts->[$i];
        my $collector  = KinoSearch1::Search::OffsetCollector->new(
            hit_collector => $args{hit_collector},
            offset        => $start
        );
        $searchable->search_hit_collector( %args,
            hit_collector => $collector );
    }
}

sub rewrite {
    my ( $self, $orig_query ) = @_;

    # not necessary to rewrite until we add query types that need it
    return $orig_query;

    #my @queries = map { $_->rewrite($orig_query) } @{ $self->{searchables} };
    #my $combined = $queries->[0]->combine(\@queries);
    #return $combined;
}

sub create_weight {
    my ( $self, $query ) = @_;
    my $searchables = $self->{searchables};

    my $rewritten_query = $self->rewrite($query);

    # generate an array of unique terms
    my @terms = $rewritten_query->extract_terms;
    my %unique_terms;
    for my $term (@terms) {
        if ( a_isa_b( $term, "KinoSearch1::Index::Term" ) ) {
            $unique_terms{ $term->to_string } = $term;
        }
        else {
            # PhraseQuery returns an array of terms
            $unique_terms{ $_->to_string } = $_ for @$term;
        }
    }
    @terms = values %unique_terms;
    my @stringified = keys %unique_terms;

    # get an aggregated doc_freq for each term
    my @aggregated_doc_freqs = (0) x scalar @terms;
    for my $i ( 0 .. $#$searchables ) {
        my $doc_freqs = $searchables->[$i]->doc_freqs( \@terms );
        for my $j ( 0 .. $#terms ) {
            $aggregated_doc_freqs[$j] += $doc_freqs->[$j];
        }
    }

    # prepare a hashmap of stringified_term => doc_freq pairs.
    my %doc_freq_map;
    @doc_freq_map{@stringified} = @aggregated_doc_freqs;

    my $cache_df_source = KinoSearch1::Search::CacheDFSource->new(
        doc_freq_map => \%doc_freq_map,
        max_doc      => $self->max_doc,
        similarity   => $self->get_similarity,
    );

    return $rewritten_query->to_weight($cache_df_source);
}

package KinoSearch1::Search::CacheDFSource;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Searchable );

BEGIN {
    __PACKAGE__->init_instance_vars(
        doc_freq_map => {},
        max_doc      => undef,
    );
    __PACKAGE__->ready_get(qw( max_doc ));
}

sub init_instance { }

sub doc_freq {
    my ( $self, $term ) = @_;
    my $df = $self->{doc_freq_map}{ $term->to_string };
    confess( "df for " . $term->to_string . " not available" )
        unless defined $df;
}

sub doc_freqs {
    my $self = shift;
    my @doc_freqs = map { $self->doc_freq($_) } @_;
    return \@doc_freqs;
}

sub max_doc { shift->{max_doc} }

sub rewrite {
    return $_[1];
}

=for comment

Dummy class, only here to support initialization of Weights from Queries.

=cut

1;

__END__


=head1 NAME

KinoSearch1::Search::MultiSearcher - Aggregate results from multiple searchers.

=head1 SYNOPSIS

    for my $server_name (@server_names) {
        push @searchers, KinoSearch1::Search::SearchClient->new(
            peer_address => "$server_name:$port",
            analyzer     => $analyzer,
            password     => $pass,
        );
    }
    my $multi_searcher = KinoSearch1::Search::MultiSearcher->new(
        searchables => \@searchers,
        analyzer    => $analyzer,
    );
    my $hits = $multi_searcher->search( query => $query );

=head1 DESCRIPTION

Aside from the arguments to its constructor, MultiSearcher looks and acts just
like a L<KinoSearch1::Searcher> object.

The primary use for MultiSearcher is to aggregate results from several remote
searchers via L<SearchClient|KinoSearch1::Search::SearchClient>, diffusing the
cost of searching a large corpus over multiple machines.

=head1 METHODS

=head2 new

Constructor.  Takes two hash-style parameters, both of which are required.

=over

=item *

B<analyzer> - an item which subclasses L<KinoSearch1::Analysis::Analyzer>.

=item *

B<searchables> - a reference to an array of searchers.

=back

=head1 COPYRIGHT

Copyright 2006-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
