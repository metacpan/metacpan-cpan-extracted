package KinoSearch1::Search::TermQuery;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Query );

use KinoSearch1::Util::ToStringUtils qw( boost_to_string );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        term => undef,
    );
    __PACKAGE__->ready_get(qw( term ));
}

sub init_instance {
    my $self = shift;
    confess("parameter 'term' is not a KinoSearch1::Index::Term")
        unless a_isa_b( $self->{term}, 'KinoSearch1::Index::Term' );
}

sub create_weight {
    my ( $self, $searcher ) = @_;
    my $weight = KinoSearch1::Search::TermWeight->new(
        parent   => $self,
        searcher => $searcher,
    );
}

sub extract_terms { shift->{term} }

sub to_string {
    my ( $self, $proposed_field ) = @_;
    my $field = $self->{term}->get_field;
    my $string = $proposed_field eq $field ? '' : "$field:";
    $string .= $self->{term}->get_text . boost_to_string( $self->{boost} );
    return $string;

}

sub get_similarity {
    my ( $self, $searcher ) = @_;
    my $field_name = $self->{term}->get_field;
    return $searcher->get_similarity($field_name);
}

sub equals { shift->todo_death }

package KinoSearch1::Search::TermWeight;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Weight );

use KinoSearch1::Search::TermScorer;

our %instance_vars = __PACKAGE__->init_instance_vars();

sub init_instance {
    my $self = shift;

    $self->{similarity}
        = $self->{parent}->get_similarity( $self->{searcher} );

    $self->{idf} = $self->{similarity}
        ->idf( $self->{parent}->get_term, $self->{searcher} );

    # kill this because we don't want its baggage.
    undef $self->{searcher};
}

sub scorer {
    my ( $self, $reader ) = @_;
    my $term      = $self->{parent}{term};
    my $term_docs = $reader->term_docs($term);
    return unless defined $term_docs;
    return unless $term_docs->get_doc_freq;

    my $norms_reader = $reader->norms_reader( $term->get_field );
    return KinoSearch1::Search::TermScorer->new(
        weight       => $self,
        term_docs    => $term_docs,
        similarity   => $self->{similarity},
        norms_reader => $norms_reader,
    );
}

sub to_string {
    my $self = shift;
    return "weight(" . $self->{parent}->to_string . ")";
}

1;

__END__

=head1 NAME

KinoSearch1::Search::TermQuery - match individual Terms

=head1 SYNOPSIS

    my $term = KinoSearch1::Index::Term->new( $field, $term_text );
    my $term_query = KinoSearch1::Search::TermQuery->new(
        term => $term,
    );
    my $hits = $searcher->search( query => $term_query );

=head1 DESCRIPTION 

TermQuery is a subclass of
L<KinoSearch1::Search::Query|KinoSearch1::Search::Query> for matching individual
L<Terms|KinoSearch1::Index::Term>.  Note that since Term objects are associated
with one and only one field, so are TermQueries.

=head1 METHODS

=head2 new

    my $term_query = KinoSearch1::Search::TermQuery->new(
        term => $term,
    );

Constructor.  Takes hash-style parameters:

=over

=item *

B<term> - a L<KinoSearch1::Index::Term>.

=back

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut

