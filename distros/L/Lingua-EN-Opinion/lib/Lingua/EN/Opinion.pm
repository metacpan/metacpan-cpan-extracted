package Lingua::EN::Opinion;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Measure the emotional sentiment of text

our $VERSION = '0.1300';

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
    is       => 'rw',
    init_arg => undef,
    lazy     => 1,
    builder  => 1,
);

sub _build_positive {
    return Lingua::EN::Opinion::Positive->new;
}


has negative => (
    is       => 'rw',
    init_arg => undef,
    lazy     => 1,
    builder  => 1,
);

sub _build_negative {
    return Lingua::EN::Opinion::Negative->new;
}


has emotion => (
    is       => 'rw',
    init_arg => undef,
    lazy     => 1,
    builder  => 1,
);

sub _build_emotion {
    return Lingua::EN::Opinion::Emotion->new;
}


sub analyze {
    my ($self) = @_;

    my @sentences = $self->_get_sentences();

    my @scores;

    for my $sentence ( @sentences ) {
        my @words = _tokenize($sentence);

        my $score = 0;

        for my $word ( @words ) {
            $word = $self->_stemword($word);

            $score += exists $self->positive->wordlist->{$word} ? 1
                    : exists $self->negative->wordlist->{$word} ? -1 : 0;
        }

        push @scores, $score;
    }

    $self->scores( \@scores );
}


sub averaged_score {
    my ( $self, $bins ) = @_;

    $bins ||= 10;

    my @scores = map { $_ } @{ $self->scores };

    my @averaged;

    while ( my @n = splice @scores, 0, $bins ) {
        push @averaged, mean(@n);
    }

    return \@averaged;
}


sub nrc_sentiment {
    my ($self) = @_;

    my $null_state = { anger=>0, anticipation=>0, disgust=>0, fear=>0, joy=>0, negative=>0, positive=>0, sadness=>0, surprise=>0, trust=>0 };

    my @sentences = $self->_get_sentences();

    my @scores;

    for my $sentence ( @sentences ) {
        my @words = _tokenize($sentence);

        my $score;

        for my $word ( @words ) {
            $word = $self->_stemword($word);

            if ( exists $self->emotion->wordlist->{$word} ) {
                for my $key ( keys %{ $self->emotion->wordlist->{$word} } ) {
                    $score->{$key} += $self->emotion->wordlist->{$word}{$key};
                }
            }
        }

        $score = $null_state
            unless $score;

        push @scores, $score;
    }

    $self->nrc_scores( \@scores );
}


sub get_word {
    my ( $self, $word ) = @_;

    $word = $self->_stemword($word);

    return exists $self->positive->wordlist->{$word} || exists $self->negative->wordlist->{$word}
        ? {
            positive => exists $self->positive->wordlist->{$word} ? 1 : 0,
            negative => exists $self->negative->wordlist->{$word} ? 1 : 0,
        }
        : undef;
}


sub nrc_get_word {
    my ( $self, $word ) = @_;

    $word = $self->_stemword($word);

    return exists $self->emotion->wordlist->{$word}
        ? $self->emotion->wordlist->{$word}
        : undef;
}


sub get_sentence {
    my ( $self, $sentence ) = @_;

    my @words = _tokenize($sentence);

    my %score;

    for my $word ( @words ) {
        $score{$word} = $self->get_word($word);
    }

    return \%score;
}


sub nrc_get_sentence {
    my ( $self, $sentence ) = @_;

    my @words = _tokenize($sentence);

    my %score;

    for my $word ( @words ) {
        $score{$word} = $self->nrc_get_word($word);
    }

    return \%score;
}

sub _tokenize {
    my ($sentence) = @_;
    $sentence =~ s/[[:punct:]]//g;  # Drop punctuation
    $sentence =~ s/\d//g;           # Drop digits
    my @words = grep { $_ } map { lc $_ } split /\s+/, $sentence;
    return @words;
}

sub _stemword {
    my ( $self, $word ) = @_;

    if ( $self->stem ) {
        my @stems = $self->stemmer->stemWord($word);
        $word = [ sort @stems ]->[0]
            if @stems;
    }

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

version 0.1300

=head1 SYNOPSIS

  use Lingua::EN::Opinion;
  my $opinion = Lingua::EN::Opinion->new( file => '/some/file.txt', stem => 1 );
  $opinion->analyze();
  my $score = $opinion->averaged_score(5);
  my $sentiment = $opinion->get_word('foo');
  $sentiment = $opinion->get_sentence('Mary had a little lamb.');
  # OR
  $opinion = Lingua::EN::Opinion->new( text => 'Mary had a little lamb...' );
  $opinion->nrc_sentiment();
  # And now do something cool with $opinion->nrc_scores...
  $sentiment = $opinion->nrc_get_word('foo');
  $sentiment = $opinion->nrc_get_sentence('Mary had a little lamb.');

=head1 DESCRIPTION

A C<Lingua::EN::Opinion> object measures the emotional sentiment of text.

Please see the F<eg/> and F<t/> scripts for example usage.

The write-up illustrating results can be found at
L<http://techn.ology.net/book-of-revelation-sentiment-analysis/>

=head1 ATTRIBUTES

=head2 file

The text file to analyze.

=head2 text

A text string to analyze instead of a text file.

=head2 stem

Boolean flag to indicate that word stemming should take place.

For example, "horses" becomes "horse" and "hooves" becomes "hoof."

This is the proper way to use this module.

=head2 stemmer

Require the L<WordNet::QueryData> and L<WordNet::stem> modules to stem each word
of the provided file or text.

* These modules must be installed and working to use this feature.

This is a computed result.  Providing this in the constructor will be ignored.

=head2 sentences

Computed result.

=head2 scores

Computed result.

=head2 nrc_scores

Computed result.

=head2 positive

Computed result.

=head2 negative

Computed result.

=head2 emotion

Computed result.

=head1 METHODS

=head2 new()

  $opinion = Lingua::EN::Opinion->new(%arguments);

Create a new C<Lingua::EN::Opinion> object.

=head2 analyze()

  $opinion->analyze();

Measure the positive/negative emotional sentiment of text.  This method sets the
B<scores> and B<sentences> attributes.

=head2 averaged_score()

  $averaged = $opinion->averaged_score($bins);

Compute the averaged score given a number of (integer) B<bins> (default: 10).

This reduces the amount of "noise" in the original signal.  As such, it loses
information detail.

For example, if there are 400 sentences, B<bins> of 10 will result in 40 data
points.  Each point will be the mean of each successive bin-sized set of points
in the analyzed score.

=head2 nrc_sentiment()

  $opinion->nrc_sentiment();

Compute the NRC sentiment of the given text.

This is given by a 0/1 list of these 10 emotional elements:

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

This method sets the B<nrc_scores> and B<sentences> attributes.

=head2 get_word()

  $sentiment = $opinion->get_word($word);

Get the positive/negative sentiment for a given word.  Return a HashRef of
positive/negative keys.  If the word does not exist, return C<undef>.

=head2 nrc_get_word()

  $sentiment = $opinion->nrc_get_word($word);

Get the NRC emotional sentiment for a given word.  Return a HashRef of the NRC
emotions.  If the word does not exist, return C<undef>.

=head2 get_sentence()

  $values = $opinion->get_sentence($sentence);

Return the positive/negative values for the words of the given sentence.

=head2 nrc_get_sentence()

  $values = $opinion->nrc_get_sentence($sentence);

Return the NRC emotion values for each word of the given sentence.

=head1 SEE ALSO

L<Moo>

L<File::Slurper>

L<Lingua::EN::Sentence>

L<Statistics::Lite>

L<Try::Tiny>

L<https://www.cs.uic.edu/~liub/FBS/sentiment-analysis.html#lexicon>

L<http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm>

L<http://techn.ology.net/book-of-revelation-sentiment-analysis/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
