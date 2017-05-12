package Lingua::TFIDF;

# ABSTRACT: Language-independent TF-IDF calculator.

use strict;
use warnings;
use Lingua::TFIDF::Types;
use List::MoreUtils qw/uniq/;
use List::Util qw/sum/;
use Smart::Args;

our $VERSION = 0.01;

sub new {
  args
    my $class => 'ClassName',
    my $word_counter => +{ isa => 'Lingua::TFIDF::WordCounter', optional => 1 },
    my $word_segmenter => 'Lingua::TFIDF::WordSegmenter';

  unless (defined $word_counter) {
    require Lingua::TFIDF::WordCounter::Simple;
    $word_counter = Lingua::TFIDF::WordCounter::Simple->new;
  }

  bless +{
    word_counter => $word_counter,
    word_segmenter => $word_segmenter,
  } => $class;
}

sub idf {
  args
    my $self,
    my $documents => 'ArrayRef[Lingua::TFIDF::TermFrequency] | ArrayRef[Str]';

  return +{} if @$documents == 0;

  my @tfs = ref $documents->[0]
    ? @$documents : map { $self->tf(document => \$_) } @$documents;
  my %idf;
  for my $word (uniq map { keys %$_ } @tfs) {
    my $num_documents_including_word = grep { exists $_->{$word} } @tfs;
    $idf{$word} = log(@tfs / $num_documents_including_word);
  }
  return \%idf;
}

sub tf {
  args
    my $self,
    my $document => 'Ref | Str',
    my $normalize => +{ isa => 'Bool', default => 0 };

  $self->word_counter->clear;

  my $iter = $self->word_segmenter->segment($document);
  my $counter = $self->word_counter;
  while (defined (my $word = $iter->())) { $counter->add_count($word) }

  my $tf = $counter->frequencies;
  return $tf unless $normalize;

  my $total_words = sum values %$tf;
  +{ map { ($_ => $tf->{$_} / $total_words) } keys %$tf };
}

sub tf_idf {
  args
    my $self,
    my $documents => 'ArrayRef[Str]',
    my $normalize => +{ isa => 'Bool', default => 0 };

  return +{} if @$documents == 0;

  my @tfs =
    map { $self->tf(document => \$_, normalize => $normalize) } @$documents;
  my $idf = $self->idf(documents => \@tfs);
  my @tf_idf;
  for my $tf (@tfs) {
    push @tf_idf, +{ map { ($_ => $tf->{$_} * $idf->{$_}) } keys %$tf };
  }
  return \@tf_idf;
}

sub word_counter { $_[0]->{word_counter} }

sub word_segmenter { $_[0]->{word_segmenter} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TFIDF - Language-independent TF-IDF calculator.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Lingua::TFIDF;
  use Lingua::TFIDF::WordSegmenter::SplitBySpace;
  
  my $tf_idf_calc = Lingua::TFIDF->new(
    # Use a word segmenter for japanese text.
    word_segmenter => Lingua::TFIDF::WordSegmenter::SplitBySpace->new,
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

  tf–idf, short for term frequency–inverse document frequency, is a numerical statistic that is intended to reflect how important a word is to a document in a collection or corpus. It is often used as a weighting factor in information retrieval and text mining.

This module provides feature for calculating TF, IDF and TF-IDF.

=head2 MOTIVATION

There are several TF-IDF calculator modules in CPAN already, for example L<Text::TFIDF> and L<Lingua::JA::TFIDF>. So why I reinvent the wheel? The reason is language dependency: C<Text::TFIDF> assumes that words in sentence are separated by spaces. This assumption is not true in most east asian languages. And C<Lingua::JA::TFIDF> works only on japanese text.

C<Lingua::TFIDF> solves this problem by separating word segmentation process from word frequency counting. You can process documents written in any languages, by providing appropriate word segmenter (see L</CUSTOM WORD SEGMENTER> below.)

=head1 METHODS

=head2 new(word_segmenter => $segmenter)

Constructor. Takes 1 mandatory parameter C<word_segmenter>.

=head3 CUSTOM WORD SEGMENTER

Although this distribution bundles some language-independent word segmenter, like L<Lingua::TFIDF::WordSegmenter::SplitBySpace>, sometimes language-specifiec word segmenters are more appropriate. You can pass a custom word segmenter object to the calculator.

The word segmenter is a plain Perl object that implements C<segment> method. The method takes 1 positional argument C<$document>, which is a string or a B<reference> to string. It is expected to return an word iterator as CodeRef.

Roughly speaking, given custom word segmenter will be used like:

  my $document = 'foo bar baz';
  
  # Can be called with a reference, like |->segment(\$document)|.
  # Detecting data type is callee's responsibility.
  my $iter = $word_segmenter->segment($document);
  
  while (defined(my $word = $iter->())) {
     ...
  }

=head2 idf(documents => \@documents)

Calculates IDFs. Result is returned as HashRef, which the keys and values are words and corresponding IDFs respectively.

=head2 tf(document => $document | \$document [, normalize => 0])

Calculates TFs. Result is returned as HashRef, which the keys and values are words and corresponding TFs respectively.

If optional parameter <normalize> is set true, the TFs are devided by the number of words in the C<$document>. It is useful when comparing TFs with other documents.

=head2 tf_idf(documents => \@documents [, normalize => 0])

Calculates TF-IDFs. Result is returned as ArrayRef of HashRef. Each HashRef contains TF-IDF values for corresponding document.

=head1 SEE ALSO

=over 2

=item L<Lingua::TFIDF::WordSegmenter::LetterNgram>

=item L<Lingua::TFIDF::WordSegmenter::SplitBySpace>

=item L<Lingua::TFIDF::WordSegmenter::JA::MeCab>

=back

=head1 AUTHOR

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut
