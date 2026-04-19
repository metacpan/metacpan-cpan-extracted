# SPDX-FileCopyrightText: 2014 Koichi SATOH <r.sekia@gmail.com>
# SPDX-FileCopyrightText: 2026 Wesley Schwengle <waterkip@cpan.org>
#
# SPDX-License-Identifier: MIT

package Lingua::TermWeight::WordSegmenter::LetterNgram;
our $VERSION = '0.01';
# ABSTRACT: Word segmenter

use v5.20;
use utf8;
use warnings;
use Object::Pad;
use Carp qw(croak);

class Lingua::TermWeight::WordSegmenter::LetterNgram {

  field $n : param;

  ADJUST {
    croak "Word length must be 1+" if !defined($n) || $n <= 0;
  }

  method n { $n }

  method segment ($document) {
    $document = \"$document" unless ref $document;

    my $length = length $$document;
    my $index  = -1;
    my $n      = $self->n;

    return sub {
      GET_NEXT_NGRAM: {
        ++$index;
        return if $index + $n > $length;

        my $ngram = substr $$document, $index, $n;
        redo GET_NEXT_NGRAM if $ngram =~ /\s/;
        return $ngram;
      }
    };
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TermWeight::WordSegmenter::LetterNgram - Word segmenter

=head1 VERSION

version 0.01

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Wesley Schwengle.

This is free software, licensed under:

  The MIT (X11) License

=cut
