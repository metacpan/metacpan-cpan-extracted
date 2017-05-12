package Lingua::TFIDF::WordSegmenter::SplitBySpace;

# ABSTRACT: Simple word segmenter suitable for most european languages

use strict;
use warnings;
use Smart::Args;

sub new {
  args
    my $class => 'ClassName',
    my $lower_case => +{ isa => 'Bool', default => 0 },
    my $remove_punctuations => +{ isa => 'Bool', default => 0 },
    my $stop_words => +{ isa => 'ArrayRef[Str]', default => [] };

  bless +{
    lower_case => $lower_case,
    remove_punctuations => $remove_punctuations,
    stop_words => $stop_words,
  } => $class;
}

sub lower_case { $_[0]->{lower_case} }

sub remove_punctuations { $_[0]->{remove_punctuations} }

sub segment {
  args_pos
    my $self,
    my $document => 'Ref | Str';

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

sub stop_words { $_[0]->{stop_words} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TFIDF::WordSegmenter::SplitBySpace - Simple word segmenter suitable for most european languages

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Lingua::TFIDF::WordSegmenter::SplitBySpace;
  
  my $segmenter = Lingua::TFIDF::WordSegmenter::SplitBySpace->new(
    lower_case => 1,
    remove_punctuations => 1,
    stop_words => [qw/i you he she it they a the am are is was were/],
  );
  my $iter = $segmenter->segment('Humpty Dumpty sat on wall, ...');
  while (defined(my $word = $iter->())) { ... }

=head1 DESCRIPTION

This class is a simple word segmenter. Like L<Text::TFIDF>, this class segments a sentence into words by spliting by spaces.

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

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut
