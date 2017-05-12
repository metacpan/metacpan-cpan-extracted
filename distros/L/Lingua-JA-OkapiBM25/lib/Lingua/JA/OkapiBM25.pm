package Lingua::JA::OkapiBM25;

use strict;
use warnings;
use Lingua::JA::OkapiBM25::Result;
use base qw( Lingua::JA::TFIDF);
use 5.008_001;

our $VERSION = '0.00001';

__PACKAGE__->mk_accessors($_) for qw( param_k1 param_b avg_doc_length );

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = $class->SUPER::new(%args);
}

sub bm25 {
    my $self = shift;
    my $text = shift;

    my $length = length($text);

    my $data = $self->_calc_tf( \$text );
    $self->_calc_idf($data);

    my $k1             = $self->param_k1       || 2.0;
    my $b              = $self->param_b        || 0.75;
    my $avg_doc_length = $self->avg_doc_length || 2000;
    my $N              = 25000000000;

    while ( my ( $key, $ref ) = each %{$data} ) {
        my $tf  = $ref->{tf};
        my $idf = log( $N / $ref->{df} );
        my $bm25 =
          $idf *
          ( $tf *
              ( $k1 + 1 ) /
              ( $tf + $k1 * ( 1 - $b + $b * ( $length / $avg_doc_length ) ) ) );
        $data->{$key}->{bm25} = $bm25;
    }

    return Lingua::JA::OkapiBM25::Result->new($data);
}

1;
__END__

=head1 NAME

Lingua::JA::OkapiBM25 - Okapi-BM25 algorithm module which derived from Lingua::JA::TFIDF

=head1 SYNOPSIS

  use Lingua::JA::OkapiBM25;
  use Data::Dumper; 

  my $calc   = Lingua::JA::OkapiBM25->new(%config);
  my $result = $calc->bm25($text);
  print Dumper $result->list;

=head1 DESCRIPTION

* This software is still in alpha release * 

Okapi-BM25 algorithm module which derived from Lingua::JA::TFIDF

Sorry, this module for Japanese only.


OkapiBM25 is ...

    In information retrieval, Okapi BM25 is a ranking function used by search engines to rank matching documents according to their relevance to a given search query. It is based on the probabilistic retrieval framework developed in the 1970s and 1980s by Stephen E. Robertson, Karen Spärck Jones, and others.
    
    The name of the actual ranking function is BM25. To set the right context, however, it usually referred to as "Okapi BM25", since the Okapi information retrieval system, implemented at London's City University in the 1980s and 1990s, was the first system to implement this function.
    
    BM25, and its newer variants, e.g. BM25F (a version of BM25 that can take document structure and anchor text into account), represent state-of-the-art retrieval functions used in document retrieval, such as Web search.

--from wikipedia ( http://en.wikipedia.org/wiki/Okapi_BM25 )

=head1 METHODS

=head2 new

=head2 bm25

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
