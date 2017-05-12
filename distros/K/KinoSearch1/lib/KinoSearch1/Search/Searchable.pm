package KinoSearch1::Search::Searchable;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # members
        similarity => undef,
        field_sims => undef,    # {}
    );
}

use KinoSearch1::Search::Similarity;

=begin comment

    my $hits = $searchable->search($query_string);

    my $hits = $searchable->search(
        query     => $query,
        filter    => $filter,
        sort_spec => $sort_spec,
    );

=end comment
=cut

sub search { shift->abstract_death }

=begin comment

    my $explanation = $searchable->explain( $weight, $doc_num );

Provide an Explanation for how the document represented by $doc_num scored
agains $weight.  Useful for probing the guts of Similarity.

=end comment
=cut

sub explain { shift->todo_death }

=begin comment

    my $doc_num = $searchable->max_doc;

Return one larger than the largest doc_num.

=end comment
=cut

sub max_doc { shift->abstract_death }

=begin comment

    my $doc =  $searchable->fetch_doc($doc_num);

Generate a Doc object, retrieving the stored fields from the invindex.

=end comment
=cut

sub fetch_doc { shift->abstract_death }

=begin comment

    my $doc_freq = $searchable->doc_freq($term);

Return the number of documents which contain this Term.  Used for calculating
Weights.

=end comment
=cut

sub doc_freq { shift->abstract_death }

=begin comment

    $searchable->set_similarity($sim);
    $searchable->set_similarity( $field_name, $alternate_sim );

    my $sim     = $searchable->get_similarity;
    my $alt_sim = $searchable->get_similarity($field_name);

Set or get Similarity.  If a field name is included, set/retrieve the 
Similarity instance for that field only.

=end comment
=cut

sub set_similarity {
    if ( @_ == 3 ) {
        my ( $self, $field_name, $sim ) = @_;
        $self->{field_sims}{$field_name} = $sim;
    }
    else {
        $_[0]->{similarity} = $_[1];
    }
}

sub get_similarity {
    my ( $self, $field_name ) = @_;
    if ( defined $field_name and exists $self->{field_sims}{$field_name} ) {
        return $self->{field_sims}{$field_name};
    }
    else {
        return $self->{similarity};
    }
}

# not sure these are needed (call $query->create_weight($searcher) instead)
sub create_weight { shift->unimplemented_death }
sub rewrite_query { shift->unimplemented_death }

sub doc_freqs {
    my ( $self, $terms ) = @_;
    my @doc_freqs = map { $self->doc_freq($_) } @$terms;
    return \@doc_freqs;
}

sub close { }

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Search::Searchable - base class for searching an invindex

==head1 DESCRIPTION 

Abstract base class for objects which search an invindex.  The most prominent
subclass is KinoSearch1::Searcher.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
