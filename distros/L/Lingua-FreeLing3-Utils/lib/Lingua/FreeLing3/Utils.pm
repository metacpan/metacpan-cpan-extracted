package Lingua::FreeLing3::Utils;

use 5.010;
use strict;
use warnings;
use Scalar::Util 'blessed';

no if $] >= 5.018, 'warnings', "experimental::smartmatch";

require Exporter;
our @ISA = qw(Exporter);

use FL3;
use Lingua::FreeLing3::Sentence;
use Lingua::FreeLing3::Word;
use Data::Dumper;

=head1 NAME

Lingua::FreeLing3::Utils - text processing utilities using FreeLing3 Perl inferface

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

Calculate n-grams for a given text.

    use Lingua::FreeLing3::Utils qw/ngrams ngrams_pp/;

    # calculate bigrams
    my $ngrams = ngrams({ n => 2 }, $text);

    # pretty print bigrams
    ngrams_pp($ngrams);

Calculate word analysis (all possible for each word)

    use Lingua::FreeLing3::Utils qw/word_analysis/;

    # calculate analysis
    my $analysis = word_analysis($word);

    # in fact, you can get for a list of words
    my @analysis = word_analysis(@words);

    # or for a text, and we'll calculate the list for you
    my @analysis = word_analysis($text);


=head1 EXPORT

The following functions can be exported:

=over 4

=item ngrams

=item ngrams_pp

=item word_analysis

=back

=cut

our @EXPORT_OK = qw(ngrams ngrams_pp word_analysis);

=head1 FUNCTIONS

=head2 word_analysis

Compute all possible analysis for a specific word, list of words, or
words from a text. You can pass an optional first argument (hash
reference) with extra configuration.

   @analysis = word_analysis( { l=>'pt' }, @words );

=cut

sub word_analysis {
    state $inited = {};

    my %opts;
    %opts = ( %{ shift @_ } ) if ref $_[0] eq "HASH";
    my $l = $opts{l} || 'en';

    my @words;
    if (scalar(@_) == 1) {
        my $text = shift;
        my $words = tokenizer($l)->tokenize($text);
        @words = @$words;
    } else {
        @words = map {
            if (blessed $_) {
                if ($_->isa('Lingua::FreeLing3::Word')) {
                    $_
                } else {
                    die "blessed argument to word_analysis is not a FL3 word."
                }
            } else {
                word($_);
            }
        } @_;
    }

    if (!$inited->{$l}) {
        morph($l,
              ProbabilityAssignment  => 'no',
              QuantitiesDetection    => 'no',
              MultiwordsDetection    => 'no',
              NumbersDetection       => 'no',
              DatesDetection         => 'no',
              OrthographicCorrection => 'no',
              NERecognition          => 'no');
        $inited->{$l}++;
    }

    my $analysis = morph($l)->analyze([Lingua::FreeLing3::Sentence->new(@words)]);

    if (wantarray) {
        return map { $_->analysis(FeatureStructure => 1) } $analysis->[0]->words
    } else {
        return $analysis->[0]->word(0)->analysis(FeatureStructure => 1);
    }
}

=head2 ngrams

Compute n-grams for a given input. The argument to this function is
the text to process. You can optionally add a hash reference of
options.

  ngrams({n => 2, l => 'en'}, $text);

The following options are available:

=over 4

=item C<-n>

Set n (default: bigrams, n = 2).

=item C<-l>

Select language (default: en).

=item C<-i 1|0>

Case insensitive (default: off).

=item C<-t 1|0>

Use C<<s>> and C<</s>> around sentences (default: on).

=item C<-a 1|0>

Compute all i-grams with i from 1 to the specified n value (default:
off).

=back

=cut

sub ngrams {
    my %opts;
    %opts = ( %{ shift @_ } ) if ref $_[0] eq "HASH";

    my ($text) = @_;

    # handle options and defaults
    my $n = $opts{n} // 2;
    my $l = $opts{l} // 'en';
    my $i = $opts{i} // 0;
    my $t = $opts{t} // 1;
    my $a = $opts{a} // 0;

    # transform text into list of tokens
    my $tokens;
    if ($t) {
        my $words = tokenizer($l)->tokenize($text);
        my $sentences = splitter($l)->split($words, buffered => 0);
        foreach (@$sentences) {
            my @ts = map { $_->form } $_->words;
            unshift @ts, '<s>';
            push @ts, '</s>';
            push @$tokens, @ts;
        }
    } else {
        $tokens = tokenizer($l)->tokenize($text, to_text=>1 );
    }

    # compute ngrams
    my $ngrams;
    my $c = 0;

    if ($a) {
        my @window;
        while ($c < @$tokens) {
            push @window, $i ? lc $tokens->[$c] : $tokens->[$c];
            for (1 .. $n) {
                if (@window >= $_) {
                    my $tuple = __tuple(@window[scalar(@window)-$_ .. scalar(@window)-1]);
                    $ngrams->[$_-1]{$tuple}{count}++ if $tuple;
                }
            }
            shift @window if @window > $n - 1;
            $c++;
        }
    } else {
        while ($c < @$tokens - $n + 1) {
            my @s = @$tokens[$c .. $c+$n-1];
            @s = map { lc $_ } @s if $i;
            my $tuple = __tuple(@s);
            $ngrams->[0]->{$tuple}->{count}++ if $tuple;
            $c++;
        }
    }

    # compute percentages
    my $nn = $a ? 1 : $n;
    for my $ngram (@$ngrams) {
        my $total = @$tokens;
        foreach (keys %$ngram) {
            my ($numerator, $denominator);

            $numerator = $ngram->{$_}->{count};
            if ($nn > 1) {
                my $count = 0;
                my @search = __untuple($_);
                pop @search;
                my $c = 0;
                while ($c < @$tokens - $nn + 1) {
                    my @s = @$tokens[$c .. $c+$nn-2];

                    $count++ if @s ~~ @search;
                    $c++;
                }
                $denominator = $count;
            } else {
                $denominator = $total;
            }
            if ($numerator and $denominator and $denominator != 0) {
                $ngram->{$_}->{p} = $numerator / $denominator
            }
        }
        ++$nn;
    }

    return $a ? $ngrams : $ngrams->[0];
}

sub __tuple {
    my $t = join ' ', @_;
    return undef if $t =~ m{</s>.};
    return undef if $t =~ m{.<s>};
    return $t;
}

sub __untuple {
    split /\s/, $_[0];
}

=head2 ngrams_pp

Pretty print n-grams data in plain text.

=cut

sub ngrams_pp {
    my ($ngrams) = @_;

    printf "%-25s %-10s %-10s\n", '# n-gram', 'count', 'p';
    my $format = "%-25s %-10s %-.8f\n";
    foreach (keys %$ngrams) {
        printf $format, $_, $ngrams->{$_}->{count}, $ngrams->{$_}->{p};
    }
}

=head1 AUTHOR

Nuno Carvalho, C<< <smash at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-freeling3-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-FreeLing3-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::FreeLing3::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-FreeLing3-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-FreeLing3-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-FreeLing3-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-FreeLing3-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nuno Carvalho.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lingua::FreeLing3::Utils
