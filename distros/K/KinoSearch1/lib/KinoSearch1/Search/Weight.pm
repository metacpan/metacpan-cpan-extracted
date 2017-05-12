package KinoSearch1::Search::Weight;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor args / members
        parent   => undef,
        searcher => undef,
        # members
        similarity   => undef,
        value        => 0,
        idf          => undef,
        query_norm   => undef,
        query_weight => undef,
    );
}

# Return the Query that the Weight was derived from.
sub get_query { shift->{parent} }

# Return the Weight's numerical value, now that it's been calculated.
sub get_value { shift->{value} }

# Return a damping/normalization factor for the Weight/Query.
sub sum_of_squared_weights {
    my $self = shift;
    $self->{query_weight} = $self->{idf} * $self->{parent}->get_boost;
    return ( $self->{query_weight}**2 );
}

# Normalize the Weight/Query, so that it produces more comparable numbers in
# context of other Weights/Queries.

sub normalize {
    my ( $self, $query_norm ) = @_;
    $self->{query_norm} = $query_norm;
    $self->{query_weight} *= $query_norm;
    $self->{value} = $self->{query_weight} * $self->{idf};
}

=begin comment

    my $scorer = $weight->scorer( $index_reader );

Return a subclass of scorer, primed with values and ready to crunch numbers.

=end comment
=cut

sub scorer { shift->abstract_death }

=begin comment

    my $explanation = $weight->explain( $index_reader, $doc_num );

Explain how a document scores.

=end comment
=cut

sub explain { shift->todo_death }

sub to_string {
    my $self = shift;
    return "weight(" . $self->{parent}->to_string . ")";
}

1;

__END__

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Search::Weight - Searcher-dependent transformation of a Query

==head1 SYNOPSIS

    # abstract base class

==head1 DESCRIPTION

In one sense, a Weight is the weight of a Query object.  Conceptually, a
Query's "weight" ought to be a single number: a co-efficient... and indeed,
eventually a Weight object gets turned into a $weight_value.

However, since calculating that multiplier is rather complex, the calculations
are encapsulated within a class.  

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

