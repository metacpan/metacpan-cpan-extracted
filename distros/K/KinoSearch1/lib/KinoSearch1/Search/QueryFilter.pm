package KinoSearch1::Search::QueryFilter;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        query => undef,
        # members
        cached_bits => undef,
    );
}

use KinoSearch1::Search::HitCollector;

sub init_instance {
    my $self = shift;
    confess("required parameter query is not a KinoSearch1::Search::Query")
        unless a_isa_b( $self->{query}, 'KinoSearch1::Search::Query' );
}

sub bits {
    my ( $self, $searcher ) = @_;

    # fill the cache
    if ( !defined $self->{cache} ) {
        my $collector = KinoSearch1::Search::BitCollector->new(
            capacity => $searcher->max_doc, );

        # perform the search
        $searcher->search_hit_collector(
            weight        => $self->{query}->to_weight($searcher),
            hit_collector => $collector,
        );

        # save the bitvector of doc hits
        $self->{cached_bits} = $collector->get_bit_vector;
    }

    return $self->{cached_bits};
}

1;

__END__

=head1 NAME

KinoSearch1::Search::QueryFilter - build a filter based on results of a query

=head1 SYNOPSIS

    my $books_only_query  = KinoSearch1::Search::TermQuery->new(
        term => KinoSearch1::Index::Term->new( 'category', 'books' );
    );
    my $filter = KinoSearch1::Search::QueryFilter->new(
        query => $books_only_query;
    );
    my $hits = $searcher->search(
        query  => $query_string,
        filter => $filter,
    );

=head1 DESCRIPTION 

A QueryFilter spawns a result set that can be used to filter the results of
another query.  The effect is very similar to adding a required clause to a
L<BooleanQuery|KinoSearch1::Search::BooleanQuery> -- however, a QueryFilter
caches its results, so it is more efficient if you use it more than once.

=head1 METHODS

=head2 new

    my $filter = KinoSearch1::Search::QueryFilter->new(
        query => $query;
    );

Constructor.  Takes one hash-style parameter, C<query>, which must be an
object belonging to a subclass of
L<KinoSearch1::Search::Query|KinoSearch1::Search::Query>.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
