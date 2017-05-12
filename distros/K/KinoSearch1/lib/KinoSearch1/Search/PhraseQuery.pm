package KinoSearch1::Search::PhraseQuery;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Query );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor args / members
        slop => 0,
        # members
        field     => undef,
        terms     => undef,
        positions => undef,
    );
    __PACKAGE__->ready_get_set(qw( slop ));
    __PACKAGE__->ready_get(qw( terms ));
}

use KinoSearch1::Search::TermQuery;
use KinoSearch1::Document::Field;
use KinoSearch1::Util::ToStringUtils qw( boost_to_string );

sub init_instance {
    my $self = shift;
    $self->{terms}     = [];
    $self->{positions} = [];
}

# Add a term/position combo to the query.  The position is specified
# explicitly in order to allow for phrases with gaps, two terms at the same
# position, etc.
sub add_term {
    my ( $self, $term, $position ) = @_;
    my $field = $term->get_field;
    $self->{field} = $field unless defined $self->{field};
    croak("Mismatched fields in phrase query: '$self->{field}' '$field'")
        unless ( $field eq $self->{field} );
    if ( !defined $position ) {
        $position
            = @{ $self->{positions} }
            ? $self->{positions}[-1] + 1
            : 0;
    }
    push @{ $self->{terms} },     $term;
    push @{ $self->{positions} }, $position;
}

sub create_weight {
    my ( $self, $searcher ) = @_;

    # optimize for one-term phrases
    if ( @{ $self->{terms} } == 1 ) {
        my $term_query
            = KinoSearch1::Search::TermQuery->new( term => $self->{terms}[0],
            );
        return $term_query->create_weight($searcher);
    }
    else {
        return KinoSearch1::Search::PhraseWeight->new(
            parent   => $self,
            searcher => $searcher,
        );
    }
}

sub extract_terms { shift->{terms} }

sub to_string {
    my ( $self, $proposed_field ) = @_;
    my $string
        = $proposed_field eq $self->{field}
        ? qq(")
        : qq($proposed_field:");
    $string .= ( $_->get_text . ' ' ) for @{ $self->{terms} };
    $string .= qq(");
    $string .= qq(~$self->{slop}) if $self->{slop};
    $string .= boost_to_string( $self->get_boost );
    return $string;
}

package KinoSearch1::Search::PhraseWeight;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Search::Weight );

BEGIN { __PACKAGE__->init_instance_vars(); }

use KinoSearch1::Search::PhraseScorer;

sub init_instance {
    my $self = shift;
    $self->{similarity}
        = $self->{parent}->get_similarity( $self->{searcher} );
    $self->{idf} = $self->{similarity}
        ->idf( $self->{parent}->get_terms, $self->{searcher} );

    undef $self->{searcher};    # don't want the baggage
}

sub scorer {
    my ( $self, $reader ) = @_;
    my $query = $self->{parent};

    # look up each term
    my @term_docs;
    for my $term ( @{ $query->{terms} } ) {

        # bail if any one of the terms isn't in the index
        return unless $reader->doc_freq($term);

        my $td = $reader->term_docs($term);
        push @term_docs, $td;

        # turn on positions
        $td->set_read_positions(1);
    }

    # bail if there are no terms
    return unless @term_docs;

    my $norms_reader = $reader->norms_reader( $query->{field} );
    return KinoSearch1::Search::PhraseScorer->new(
        weight         => $self,
        slop           => $query->{slop},
        similarity     => $self->{similarity},
        norms_reader   => $norms_reader,
        term_docs      => \@term_docs,
        phrase_offsets => $query->{positions},
    );
}

1;

__END__

=head1 NAME

KinoSearch1::Search::PhraseQuery - match ordered list of Terms

=head1 SYNOPSIS

    my $phrase_query = KinoSearch1::Search::PhraseQuery->new;
    for ( qw( the who ) ) {
        my $term = KinoSearch1::Index::Term( 'bodytext', $_ );
        $phrase_query->add_term($term);
    }
    my $hits = $searcher->search( query => $phrase_query );

=head1 DESCRIPTION 

PhraseQuery is a subclass of
L<KinoSearch1::Search::Query|KinoSearch1::Search::Query> for matching against
ordered collections of terms.  

=head1 METHODS

=head2 new

    my $phrase_query = KinoSearch1::Search::PhraseQuery->new;

Constructor.  Takes no arguments.

=head2 add_term

    $phrase_query->add_term($term);

Append a term to the phrase to be matched.  Takes one argument, a
L<KinoSearch1::Index::Term|KinoSearch1::Index::Term> object.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
