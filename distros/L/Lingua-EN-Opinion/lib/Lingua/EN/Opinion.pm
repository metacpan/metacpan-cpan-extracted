package Lingua::EN::Opinion;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Measure the emotional sentiment of text

our $VERSION = '0.1701';

use Moo;
use strictures 2;
use namespace::clean;

use Lingua::EN::Opinion::Positive;
use Lingua::EN::Opinion::Negative;
use Lingua::EN::Opinion::Emotion;

use Carp;
use File::Slurper qw( read_text );
use Lingua::EN::Sentence qw( get_sentences );
use Statistics::Lite qw( mean );
use Try::Tiny;


has file => (
    is  => 'ro',
    isa => sub { die "File $_[0] does not exist" unless -e $_[0] },
);


has text => (
    is => 'ro',
);


has stem => (
    is      => 'ro',
    default => sub { 0 },
);


has stemmer => (
    is       => 'ro',
    lazy     => 1,
    builder  => 1,
    init_arg => undef,
);

sub _build_stemmer {
    try {
        require WordNet::QueryData;
        require WordNet::stem;

        my $wn      = WordNet::QueryData->new();
        my $stemmer = WordNet::stem->new($wn);

        return $stemmer;
    }
    catch {
        croak 'The WordNet::QueryData and WordNet::stem modules must be installed and working to enable stemming support';
    };
}


has sentences => (
    is       => 'rw',
    init_arg => undef,
    default  => sub { [] },
);


has scores => (
    is       => 'rw',
    init_arg => undef,
    default  => sub { [] },
);


has nrc_scores => (
    is       => 'rw',
    init_arg => undef,
    default  => sub { [] },
);


has positive => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { Lingua::EN::Opinion::Positive->new },
);


has negative => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { Lingua::EN::Opinion::Negative->new },
);


has emotion => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { Lingua::EN::Opinion::Emotion->new },
);


has familiarity => (
    is       => 'rw',
    init_arg => undef,
    default  => sub { { known => 0, unknown => 0 } },
);


sub analyze {
    my ($self) = @_;

    my @scores;
    my ( $known, $unknown ) = ( 0, 0 );

    for my $sentence ( $self->_get_sentences ) {
        my $score = 0;
        ( $score, $known, $unknown ) = $self->get_sentence( $sentence, $known, $unknown );
        push @scores, $score;
    }

    $self->familiarity( { known => $known, unknown => $unknown } );

    $self->scores( \@scores );
}


sub averaged_score { shift->averaged_scores(@_) }

sub averaged_scores {
    my ( $self, $bins ) = @_;

    $bins ||= 10;

    my @scores = map { $_ } @{ $self->scores };

    my @averaged;

    while ( my @n = splice @scores, 0, $bins ) {
        push @averaged, mean(@n);
    }

    return \@averaged;
}


sub nrc_sentiment { shift->nrc_analyze(@_) };

sub nrc_analyze {
    my ($self) = @_;

    my $null_state = { map { $_ => 0 } qw/ anger anticipation disgust fear joy negative positive sadness surprise trust / };

    my @scores;
    my ( $known, $unknown ) = ( 0, 0 );

    for my $sentence ( $self->_get_sentences ) {
        my $score = {};

        ( $score, $known, $unknown ) = $self->nrc_get_sentence( $sentence, $known, $unknown );

        $score = $null_state
            unless $score;

        push @scores, $score;
    }

    $self->familiarity( { known => $known, unknown => $unknown } );

    $self->nrc_scores( \@scores );
}


sub get_word {
    my ( $self, $word ) = @_;

    $word = $self->_stemword($word)
        if $self->stem;

    return exists $self->positive->wordlist->{$word} ? 1
        : exists $self->negative->wordlist->{$word} ? -1
        : undef;
}


sub set_word {
    my ( $self, $word, $value ) = @_;

    if ($value > 0) {
        $self->positive->wordlist->{$word} = $value;
    }
    else {
        $self->negative->wordlist->{$word} = $value;
    }
}


sub nrc_get_word {
    my ( $self, $word ) = @_;

    $word = $self->_stemword($word)
        if $self->stem;

    return exists $self->emotion->wordlist->{$word}
        ? $self->emotion->wordlist->{$word}
        : undef;
}


sub nrc_set_word {
    my ( $self, $word, $value ) = @_;

    my %emotion;

    for my $emotion (qw(
        anger
        anticipation
        disgust
        fear
        joy
        negative
        positive
        sadness
        surprise
        trust
    )) {
        if (exists $value->{$emotion}) {
            $emotion{$emotion} = $value->{$emotion};
        }
        else {
            $emotion{$emotion} = 0;
        }
    }

    $self->emotion->wordlist->{$word} = \%emotion;
}


sub get_sentence {
    my ( $self, $sentence, $known, $unknown ) = @_;

    my @words = $self->tokenize($sentence);

    my $score = 0;

    for my $word ( @words ) {
        my $value = $self->get_word($word);
        if ( $value ) {
            $known++;
        }
        else {
            $unknown++;
        }

        $score += $value
            if defined $value;
    }

    return $score, $known, $unknown;
}


sub nrc_get_sentence {
    my ( $self, $sentence, $known, $unknown ) = @_;

    my @words = $self->tokenize($sentence);

    my $score = {};

    for my $word ( @words ) {
        my $value = $self->nrc_get_word($word);

        if ( $value ) {
            $known++;

            for my $key ( keys %$value ) {
                $score->{$key} += $value->{$key};
            }
        }
        else {
            $unknown++;
        }
    }

    return $score, $known, $unknown;
}


sub ratio {
    my ( $self, $flag ) = @_;

    my $numerator = $flag ? $self->familiarity->{unknown} : $self->familiarity->{known};

    my $ratio = $numerator / ( $self->familiarity->{known} + $self->familiarity->{unknown} );

    return $ratio;
}


sub tokenize {
    my ( $self, $sentence ) = @_;
    $sentence =~ s/[[:punct:]]//g;  # Drop punctuation
    $sentence =~ s/\d//g;           # Drop digits
    my @words = grep { $_ } map { lc $_ } split /\s+/, $sentence;
    return @words;
}

sub _stemword {
    my ( $self, $word ) = @_;

    my @stems = $self->stemmer->stemWord($word);

    $word = [ sort @stems ]->[0]
        if @stems;

    return $word;
}

sub _get_sentences {
    my ($self) = @_;

    unless ( @{ $self->sentences } ) {
        my $contents = $self->file ? read_text( $self->file ) : $self->text;
        $self->sentences( get_sentences($contents) );
    }

    return map { $_ } @{ $self->sentences };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::EN::Opinion - Measure the emotional sentiment of text

=head1 VERSION

version 0.1701

=head1 SYNOPSIS

  use Lingua::EN::Opinion;

  # Positive/Negative:
  my $opinion = Lingua::EN::Opinion->new( file => '/some/file.txt', stem => 1 );
  $opinion->analyze();

  my $scores = $opinion->scores;

  my $ratio = $opinion->ratio(); # Knowns / ( Knowns + Unknowns )
  $ratio = $opinion->ratio(1); # Unknowns / ( Knowns + Unknowns )

  $scores = $opinion->averaged_scores(5);

  my $score = $opinion->get_word('foo');
  my ( $known, $unknown );
  my $sentence = 'Mary had a little lamb.';
  ( $score, $known, $unknown ) = $opinion->get_sentence($sentence);

  # NRC:
  $opinion = Lingua::EN::Opinion->new( text => "$sentence It's fleece was ..." );
  $opinion->nrc_analyze();

  $scores = $opinion->nrc_scores;

  $ratio = $opinion->ratio();
  $ratio = $opinion->ratio(1);

  $score = $opinion->nrc_get_word('happy');
  ( $score, $known, $unknown ) = $opinion->nrc_get_sentence($sentence);
  $score = $opinion->nrc_get_sentence($sentence);

  $opinion->set_word(foo => 1);
  $opinion->nrc_set_word(foo => { anger => 0, etc => '...' });

=head1 DESCRIPTION

A C<Lingua::EN::Opinion> object measures the emotional sentiment of
text and saves the results in the B<scores> and B<nrc_scores>
attributes.

When run against the positive and negative classified training reviews
in the dataset referenced under L</"SEE ALSO">, this module does ...
okay.  Out of 25k reviews, the F<eg/pos-neg> program gets about 70%
correct.

=head1 ATTRIBUTES

=head2 file

  $file = $opinion->file;

The text file to analyze.

=head2 text

  $text = $opinion->text;

A text string to analyze instead of a text file.

=head2 stem

  $stem = $opinion->stem;

Boolean flag to indicate that word stemming should take place.

For example, "horses" becomes "horse" and "hooves" becomes "hoof."

This is the proper way to use this module but takes ... a lot longer.

=head2 stemmer

  $stemmer = $opinion->stemmer;

Require the L<WordNet::QueryData> and L<WordNet::stem> modules to stem
each word of the provided file or text.

* These modules must be installed and working to use this feature.

This is a computed result.  Providing this in the constructor will be
ignored.

=head2 sentences

  $sentences = $opinion->sentences;

Computed result.  An array reference of every sentence!

=head2 scores

  $scores = $opinion->scores;

Computed result.  An array reference of the score of each sentence.

=head2 nrc_scores

  $scores = $opinion->nrc_scores;

Computed result.  An array reference of hash references containing the
NRC scores for each sentence.

=head2 positive

  $positive = $opinion->positive;

Computed result.  A module to use to L</analyze>.

=head2 negative

  $negative = $opinion->negative;

Computed result.  A module to use to L</analyze>.

=head2 emotion

  $emotion = $opinion->emotion;

Computed result.  The module to used to find the L</nrc_sentiment>.

=head2 familiarity

  $familiarity = $opinion->familiarity;

Computed result.  Hash reference of total known and unknown words:

 { known => $x, unknown => $y }

=head1 METHODS

=head2 new

  $opinion = Lingua::EN::Opinion->new(
    file => $file,
    text => $text,
    stem => $stem,
  );

Create a new C<Lingua::EN::Opinion> object.

=head2 analyze

  $scores = $opinion->analyze();

Measure the positive/negative emotional sentiment of text.

This method sets the B<familiarity>, B<scores> and B<sentences>
attributes.

=head2 averaged_score

Synonym for the L</averaged_scores> method.

=head2 averaged_scores

  $scores = $opinion->averaged_scores($bins);

Compute the averaged scores given a number of (integer) B<bins>.

Default: C<10>

This reduces the amount of "noise" in the original signal.  As such,
it loses information detail.

For example, if there are 400 sentences, B<bins> of 10 will result in
40 data points.  Each point will be the mean of each successive
bin-sized set of points in the analyzed scores.

=head2 nrc_sentiment

Synonym for the L</nrc_analyze> method.

=head2 nrc_analyze

  $scores = $opinion->nrc_analyze();

Compute the NRC sentiment of the given text.

This is given by a C<0/1> list of these 10 emotional elements:

  anger
  anticipation
  disgust
  fear
  joy
  negative
  positive
  sadness
  surprise
  trust

This method sets the B<familiarity>, B<nrc_scores> and B<sentences>
attributes.

=head2 get_word

  $sentiment = $opinion->get_word($word);

Get the positive/negative sentiment for a given word.  Return
C<undef>, C<0> or C<1> for "does not exist", "is positive" or "is
negative", respectively.

=head2 set_word

  $opinion->set_word($word => $value);

Set the positive/negative sentiment for a given word as C<1>, C<-1>
or C<undef>.

=head2 nrc_get_word

  $sentiment = $opinion->nrc_get_word($word);

Get the NRC emotional sentiment for a given word.  Return a hash
reference of the NRC emotions as detailed in L</nrc_analyze>.  If the
word does not exist, return C<undef>.

=head2 nrc_set_word

  $opinion->nrc_set_word($word => $value);

Set the NRC emotional sentiment for a given word.

The B<value> must be given as a hash-reference with any of the keys
detailed in the C<nrc_analyze> method.

=head2 get_sentence

  ( $score, $known, $unknown ) = $opinion->get_sentence($sentence);
  ( $score, $known, $unknown ) = $opinion->get_sentence( $sentence, $known, $unknown );

Return the integer value for the sum of the word scores of the given
sentence.  Also return B<known> and B<unknown> values for the number
of familiar words.

The B<known> and B<unknown> arguments refer to the L</familiarity> and
are incremented by this routine.

=head2 nrc_get_sentence

  ( $score, $known, $unknown ) = $opinion->nrc_get_sentence($sentence);
  ( $score, $known, $unknown ) = $opinion->nrc_get_sentence( $sentence, $known, $unknown );

Return the summed NRC emotion values for each word of the given
sentence as a hash reference.  Also return B<known> and B<unknown>
values for the number of familiar words.

=head2 ratio

Return the ratio of either the known or unknown words vs the total
known + unknown words.

Default: C<0>

If the method is given a C<1> as an argument, the unknown words ratio
is returned.  Otherwise the known ratio is returned by default.

=head2 tokenize

  @words = $opinion->tokenize($sentence);

Drop punctuation and digits, then split the sentence by whitespace and
return the resulting lower-cased "word" list.

=head1 SEE ALSO

The F<eg/> and F<t/> scripts

L<Moo>

L<File::Slurper>

L<Lingua::EN::Sentence>

L<Statistics::Lite>

L<Try::Tiny>

L<WordNet::QueryData> and L<WordNet::stem> for stemming

L<https://www.cs.uic.edu/~liub/FBS/sentiment-analysis.html#lexicon>

L<http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm>

L<http://techn.ology.net/book-of-revelation-sentiment-analysis/> is a write-up using this technique.

L<https://ai.stanford.edu/~amaas/data/sentiment/> is the "Large Movie Review Dataset"

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
