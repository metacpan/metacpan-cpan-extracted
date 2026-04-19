# SPDX-FileCopyrightText: 2014 Koichi SATOH <r.sekia@gmail.com>
# SPDX-FileCopyrightText: 2026 Wesley Schwengle <waterkip@cpan.org>
#
# SPDX-License-Identifier: MIT

package Lingua::TermWeight::WordSegmenter::SplitBySpace;
our $VERSION = '0.01';
# ABSTRACT: Simple word segmenter suitable for most european languages

use v5.20;
use warnings;
use Object::Pad;

class Lingua::TermWeight::WordSegmenter::SplitBySpace {

    field $lower_case :accessor :param = 0;
    field $remove_punctuations :accessor :param = 0;
    field $stop_words :accessor :param = [];

    method segment ($document) {
        my @words = split /\s+/, ref $document ? $$document : $document;

        @words = map lc, @words if $self->lower_case;

        if ($self->remove_punctuations) {
            s/^\W+|\W+$//g for @words;
        }

        if (@{ $self->stop_words } != 0) {
            my %stop_words = map { ($_ => 1) } @{ $self->stop_words };
            @words = grep { not exists $stop_words{$_} } @words;
        }

        return sub { shift @words };
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TermWeight::WordSegmenter::SplitBySpace - Simple word segmenter suitable for most european languages

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Lingua::TermWeight::WordSegmenter::SplitBySpace;
  
  my $segmenter = Lingua::TermWeight::WordSegmenter::SplitBySpace->new(
    lower_case => 1,
    remove_punctuations => 1,
    stop_words => [qw/i you he she it they a the am are is was were/],
  );
  my $iter = $segmenter->segment('Humpty Dumpty sat on wall, ...');
  while (defined(my $word = $iter->())) { ... }

=head1 DESCRIPTION

This class is a simple word segmenter. Like L<Text::TF::IDF>, this class segments a sentence into words by spliting by spaces.

=head1 METHODS

=head2 new([ lower_case => 0 ] [, remove_punctuations => 0 ] [, stop_words => [] ])

Constructor. Takes some optional parameters:

=over 2

=item lower_case

Set off by default. Convert all the words into lower cases.

=item remove_punctuations

Set off by default. Removes punctuation characters (e.g., commas, periods, quotes, question marks and exclamation marks) from head and tail of segmented words. Note that punctuations at inside of a word (e.g., "King's") will be remain unchanged.

=item stop_words

Specifies words you want to exclude from segmented words. This is useful for removing functional words.

Note that stop word filtering will be performed B<after> C<lower_case> and C<remove_punctuations> options are processed. So, for example, if you enable C<lower_case> option and want to exclude "I" from result, you should supply the stop word list as C<['i']>.

=back

=head2 segment($document | \$document)

Executes word segmentation on given C<$document> and returns an word iterator.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Wesley Schwengle.

This is free software, licensed under:

  The MIT (X11) License

=cut
