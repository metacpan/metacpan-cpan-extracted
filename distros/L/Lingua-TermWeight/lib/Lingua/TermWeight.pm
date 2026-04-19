# SPDX-FileCopyrightText: 2014 Koichi SATOH <r.sekia@gmail.com>
# SPDX-FileCopyrightText: 2026 Wesley Schwengle <waterkip@cpan.org>
#
# SPDX-License-Identifier: MIT

package Lingua::TermWeight;
use utf8;

# ABSTRACT: Language-independent TermWeight calculator.

use v5.26;
use warnings;
use Object::Pad 0.800 ':experimental(init_expr)';
use Carp       qw(croak);
use List::Util qw(sum);

our $VERSION = '0.01';

class Lingua::TermWeight {
  field $word_counter :reader = do {
    require Lingua::TermWeight::WordCounter::Simple;
    Lingua::TermWeight::WordCounter::Simple->new;
  };

  field $word_segmenter : reader : param;

  ADJUST {
    croak "word_segmenter must provide a segment method"
      unless $word_segmenter->can('segment');

    croak "word_counter must provide clear, add_count, and frequencies methods"
      unless $word_counter->can('clear')
      && $word_counter->can('add_count')
      && $word_counter->can('frequencies');
  }

  method tf (%args) {
    croak "tf requires a document argument"
      unless exists $args{document};

    my $document  = $args{document};
    my $normalize = $args{normalize} // 0;

    $word_counter->clear;

    my $iter = $word_segmenter->segment($document);
    croak "word_segmenter->segment must return a coderef iterator"
      unless ref($iter) eq 'CODE';

    while (defined(my $word = $iter->())) {
      $word_counter->add_count($word);
    }

    my $tf = $word_counter->frequencies;
    return $tf unless $normalize;

    return {} unless %$tf;

    my $total_words = sum(values %$tf) // 0;
    return {} unless $total_words;

    return +{ map { ($_ => $tf->{$_} / $total_words) } keys %$tf };
  }

  method idf (%args) {
    croak "idf requires a documents argument"
      unless exists $args{documents};

    my $documents = $args{documents};
    croak "documents must be an arrayref"
      unless ref($documents) eq 'ARRAY';

    return {} if @$documents == 0;

    my @tfs
      = ref($documents->[0])
      ? @$documents
      : map { $self->tf(document => \$_) } @$documents;

    my %seen_word;
    for my $tf (@tfs) {
      croak "each term-frequency entry must be a hashref"
        unless ref($tf) eq 'HASH';
      $seen_word{$_} = 1 for keys %$tf;
    }

    my %idf;
    for my $word (keys %seen_word) {
      my $num_documents_including_word = grep { exists $_->{$word} } @tfs;
      next unless $num_documents_including_word;
      $idf{$word} = log(@tfs / $num_documents_including_word);
    }

    return \%idf;
  }

  method tf_idf (%args) {
    croak "tf_idf requires a documents argument"
      unless exists $args{documents};

    my $documents = $args{documents};
    my $normalize = $args{normalize} // 0;

    croak "documents must be an arrayref"
      unless ref($documents) eq 'ARRAY';

    return [] if @$documents == 0;

    my @tfs = map { $self->tf(document => \$_, normalize => $normalize) }
      @$documents;

    my $idf = $self->idf(documents => \@tfs);

    my @tf_idf;
    for my $tf (@tfs) {
      push @tf_idf, +{ map { ($_ => $tf->{$_} * $idf->{$_}) } keys %$tf };
    }

    return \@tf_idf;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TermWeight - Language-independent TermWeight calculator.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Lingua::TermWeight;
  use Lingua::TermWeight::WordSegmenter::SplitBySpace;

  my $tf_idf_calc = Lingua::TermWeight->new(
    word_segmenter => Lingua::TermWeight::WordSegmenter::SplitBySpace->new,
  );

  my $document1 = 'Humpty Dumpty sat on a wall...';
  my $document2 = 'Remember, remember, the fifth of November...';

  my $tf = $tf_idf_calc->tf(document => $document1);
  # TF of word "Dumpty" in $document1.
  say $tf->{'Dumpty'};  # 2, if you are referring same text as mine.

  my $idf = $tf_idf_calc->idf(documents => [$document1, $document2]);
  say $idf->{'Dumpty'};  # log(2/1) ≒ 0.693147

  my $tf_idfs = $tf_idf_calc->tf_idf(documents => [$document1, $document2]);
  # TF-IDF of word "Dumpty" in $document1.
  say $tf_idfs->[0]{'Dumpty'};  # 2 log(2/1) ≒ 1.386294
  # Ditto. But in $document2.
  say $tf_idfs->[1]{'Dumpty'};  # 0

=head1 DESCRIPTION

Quoting L<Wikipedia|http://en.wikipedia.org/wiki/Tf%E2%80%93idf>:

  tf–idf, short for term frequency–inverse document frequency, is a numerical
  statistic that is intended to reflect how important a word is to a document
  in a collection or corpus. It is often used as a weighting factor in
  information retrieval and text mining.

This module provides feature for calculating TF, IDF and TF-IDF.

=head1 METHODS

=head2 new(word_segmenter => $segmenter)

Constructor. Takes 1 mandatory parameter C<word_segmenter>.

=head3 CUSTOM WORD SEGMENTER

Although this distribution bundles some language-independent word segmenter,
like L<Lingua::TermWeight::WordSegmenter::SplitBySpace>, sometimes
language-specifiec word segmenters are more appropriate. You can pass a custom
word segmenter object to the calculator.

The word segmenter is a plain Perl object that implements C<segment> method.
The method takes 1 positional argument C<$document>, which is a string or a
B<reference> to string. It is expected to return an word iterator as CodeRef.

Roughly speaking, given custom word segmenter will be used like:

  my $document = 'foo bar baz';

  # Can be called with a reference, like |->segment(\$document)|.
  # Detecting data type is callee's responsibility.
  my $iter = $word_segmenter->segment($document);

  while (defined(my $word = $iter->())) {
     ...
  }

=head2 idf(documents => \@documents)

Calculates IDFs. Result is returned as HashRef, which the keys and values are
words and corresponding IDFs respectively.

=head2 tf(document => $document | \$document [, normalize => 0])

Calculates TFs. Result is returned as HashRef, which the keys and values are
words and corresponding TFs respectively.

If optional parameter <normalize> is set true, the TFs are devided by the
number of words in the C<$document>. It is useful when comparing TFs with other
documents.

=head2 tf_idf(documents => \@documents [, normalize => 0])

Calculates TF-IDFs. Result is returned as ArrayRef of HashRef. Each HashRef
contains TF-IDF values for corresponding document.

=head1 SEE ALSO

=over

=item L<Lingua::TermWeight::WordSegmenter::LetterNgram>

=item L<Lingua::TermWeight::WordSegmenter::SplitBySpace>

=back

=head2 Fork of Lingua::TFIDF

This is fork of L<Lingua::TFIDF> which excludes dependencies to the Japanese
language which seem to be breaking installations on both Linux and MacOS. As
the original module has not been updated for over 12 years I've decided to fork
the project and use L<Object::Pad> as the OO base for the new module. The API
will stay the same (for now), the dependency graph will stay lighter.

The original source code is available via L<Lingua::TFIDF>. I thank the author
Koichi Satoh for their original work and will continue to use it in my own
implemention.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Wesley Schwengle.

This is free software, licensed under:

  The MIT (X11) License

=cut
