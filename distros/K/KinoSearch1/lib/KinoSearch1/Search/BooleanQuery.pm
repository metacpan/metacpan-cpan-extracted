package KinoSearch1::Search::BooleanQuery;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Query );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor args / members
        disable_coord => 0,
        # members
        clauses          => undef,
        max_clause_count => 1024,
    );
    __PACKAGE__->ready_get(qw( clauses ));
}

use KinoSearch1::Search::BooleanClause;

sub init_instance {
    my $self = shift;
    $self->{clauses} = [];
}

# Add an subquery tagged with boolean characteristics.
sub add_clause {
    my $self = shift;
    my $clause
        = @_ == 1
        ? shift
        : KinoSearch1::Search::BooleanClause->new(@_);
    push @{ $self->{clauses} }, $clause;
    confess("not a BooleanClause")
        unless a_isa_b( $clause, 'KinoSearch1::Search::BooleanClause' );
    confess("Too many clauses")
        if @{ $self->{clauses} } > $self->{max_clause_count};
}

sub get_similarity {
    my ( $self, $searcher ) = @_;
    if ( $self->{disable_coord} ) {
        confess "disable_coord not implemented yet";
    }
    return $searcher->get_similarity;
}

sub extract_terms {
    my $self = shift;
    my @terms;
    for my $clause ( @{ $self->{clauses} } ) {
        push @terms, $clause->get_query()->extract_terms;
    }
    return @terms;
}

sub create_weight {
    my ( $self, $searcher ) = @_;
    return KinoSearch1::Search::BooleanWeight->new(
        parent   => $self,
        searcher => $searcher,
    );

}

sub clone { shift->todo_death }

package KinoSearch1::Search::BooleanWeight;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Weight );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # members
        weights => undef,
    );
}

use KinoSearch1::Search::BooleanScorer;

sub init_instance {
    my $self = shift;
    $self->{weights} = [];
    my ( $weights, $searcher ) = @{$self}{ 'weights', 'searcher' };

    $self->{similarity} = $self->{parent}->get_similarity($searcher);

    for my $clause ( @{ $self->{parent}{clauses} } ) {
        my $query = $clause->get_query;
        push @$weights, $query->create_weight($searcher);
    }

    undef $self->{searcher};    # don't want the baggage
}

sub get_value { shift->{parent}->get_boost }

sub sum_of_squared_weights {
    my $self = shift;

    my $sum = 0;
    $sum += $_->sum_of_squared_weights for @{ $self->{weights} };

    # compound the weight of each sub-Weight
    $sum *= $self->{parent}->get_boost**2;

    return $sum;
}

sub normalize {
    my ( $self, $query_norm ) = @_;
    $_->normalize($query_norm) for @{ $self->{weights} };
}

sub scorer {
    my ( $self, $reader ) = @_;

    my $scorer = KinoSearch1::Search::BooleanScorer->new(
        similarity => $self->{similarity}, );

    # add all the subscorers one by one
    my $clauses = $self->{parent}{clauses};
    my $i       = 0;
    for my $weight ( @{ $self->{weights} } ) {
        my $clause    = $clauses->[ $i++ ];
        my $subscorer = $weight->scorer($reader);
        if ( defined $subscorer ) {
            $scorer->add_subscorer( $subscorer, $clause->get_occur );
        }
        elsif ( $clause->is_required ) {
            # if any required clause fails, the whole thing fails
            return undef;
        }
    }
    return $scorer;
}

1;

__END__

=head1 NAME

KinoSearch1::Search::BooleanQuery - match boolean combinations of Queries

=head1 SYNOPSIS

    my $bool_query = KinoSearch1::Search::BooleanQuery->new;
    $bool_query->add_clause( query => $term_query, occur => 'MUST' );
    my $hits = $searcher->search( query => $bool_query );

=head1 DESCRIPTION 

BooleanQueries are super-Query objects which match boolean combinations of
other Queries.

One way of producing a BooleanQuery is to feed a query string along the lines
of C<this AND NOT that> to a
L<QueryParser|KinoSearch1::QueryParser::QueryParser> object:
    
    my $bool_query = $query_parser->parse( 'this AND NOT that' );

It's also possible to achieve the same end by manually constructing the query
piece by piece:

    my $bool_query = KinoSearch1::Search::BooleanQuery->new;
    
    my $this_query = KinoSearch1::Search::TermQuery->new(
        term => KinoSearch1::Index::Term->new( 'bodytext', 'this' ),
    );
    $bool_query->add_clause( query => $this_query, occur => 'MUST' );

    my $that_query = KinoSearch1::Search::TermQuery->new(
        term => KinoSearch1::Index::Term->new( 'bodytext', 'that' ),
    );
    $bool_query->add_clause( query => $that_query, occur => 'MUST_NOT' );

QueryParser objects and hand-rolled Queries can work together:

    my $general_query = $query_parser->parse($q);
    my $news_only     = KinoSearch1::Search::TermQuery->new(
        term => KinoSearch1::Index::Term->new( 'category', 'news' );
    );
    $bool_query->add_clause( query => $general_query, occur => 'MUST' );
    $bool_query->add_clause( query => $news_only,     occur => 'MUST' );

=head1 METHODS

=head2 new

    my $bool_query = KinoSearch1::Search::BooleanQuery->new;

Constructor. Takes no arguments.

=head2 add_clause

    $bool_query->add_clause(
        query => $query, # required
        occur => 'MUST', # default: 'SHOULD'
    );

Add a clause to the BooleanQuery.  Takes hash-style parameters:

=over

=item *

B<query> - an object which belongs to a subclass of
L<KinoSearch1::Search::Query|KinoSearch1::Search::Query>.

=item *

B<occur> - must be one of three possible values: 'SHOULD', 'MUST', or
'MUST_NOT'.

=back

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
