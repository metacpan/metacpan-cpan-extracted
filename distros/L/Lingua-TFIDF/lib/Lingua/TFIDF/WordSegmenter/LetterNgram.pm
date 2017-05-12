package Lingua::TFIDF::WordSegmenter::LetterNgram;

# ABSTRACT: Letter N-gram segmenter

use strict;
use warnings;
use Carp qw//;
use Smart::Args;

sub new {
  args
    my $class => 'ClassName',
    my $n => 'Int';

  Carp::croak('Word length must be 1+.') if $n <= 0;

  bless +{ n => $n } => $class;
}

sub n { $_[0]->{n} }

sub segment {
  args_pos
    my $self,
    my $document => 'Ref | Str';

  $document = \"$document" unless ref $document;

  my $length = length $$document;
  my $index = -1;
  my $n = $self->n;
  sub {
  GET_NEXT_NGRAM:
    {
      ++$index;
      return if $index + $n > $length;

      my $ngram = substr $$document, $index, $n;
      redo GET_NEXT_NGRAM if $ngram =~ /\s/;
      return $ngram;
    }
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TFIDF::WordSegmenter::LetterNgram - Letter N-gram segmenter

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Lingua::TFIDF::WordSegmenter::LetterNgram;
  
  my $segmenter = Lingua::TFIDF::WordSegmenter::LetterNgram->new(n => 2);
  my $iter = $segmenter->segment('ロンドン橋落ちた　落ちた　落ちた...');
  while (defined(my $word = $iter->())) { ... }

=head1 DESCRIPTION

This class provides a N-gram word segmenter.

=head1 METHODS

=head2 new(n => $n)

Constructor.

=head2 segment($document | \$document)

Executes word segmentation on given C<$document> and returns an word iterator.

=head1 AUTHOR

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut
