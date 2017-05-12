package Lingua::ES::PhT;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.


our %EXPORT_TAGS = ( 'test' => [ qw(
    transcribe
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'test'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.9';
use Lingua::ES::Syllabify;
use String::Multibyte;

sub _setStressOnSyllabe;
sub _setStressOnSyllabedWord;



=item transcribe

    Phonetically transcribe the given piece of text.

    If text has several words, the returned list of phonemes has no idications
      of word boundaries.

=cut
sub transcribe($) {
    my $text = shift;

    my @phonemes = ();

    my @words = split(/\s+/, $text);

    foreach my $word (@words) {
        # Some replacement for phonemes depending on suprasyllabical information
        $word =~ s/^r/R/;
        $word =~ s/([bcdfghjklmnpqstvwxyz])r/$1R/g;
        $word =~ s/^ps/s/;
        $word =~ s/^gn/n/;

		$word =~ s/^x/s/g;

        my @syllabes =
            _setStressOnSyllabedWord(
                Lingua::ES::Syllabify::getSyllables($word));

        push(@phonemes, _transcribeSyllabe($_)) foreach @syllabes;
    }

    return @phonemes;
}

sub _transcribeSyllabe($) {
    my $syllabe = shift;

    my @phonemesToReturn;

    my %symbolsWithDirectMappings = (
        "a" => "a",
        "á" => "a'",
        "b" => "b",
        "C" => "tS", # ch
        "d" => "d",
        "e" => "e",
        "é" => "e'",
        "f" => "f",
        "G" => "g", # gu
        "í" => "i'",
        "j" => "x",
        "k" => "k",
        "l" => "l",
        "L" => "L",
        "m" => "m",
        "n" => "n",
        "ñ" => "J",
        "o" => "o",
        "ó" => "o'",
        "p" => "p",
        "q" => "k",
        "Q" => "k", # qu
        "r" => "r",
        "R" => "rr", # rr
        "s" => "s",
        "t" => "t",
        "ü" => "w",
        "ú" => "u'",
        "v" => "b",
        "z" => "T"
    );

    my $vowels_re = "i|í|u|ú|ü|a|á|e|é|o|ó";
    my $consonants_re = "[bcdfghjklmnpqrstvwxyz]";

    # Some replacement for phonemes expanding several letters
    $syllabe =~ s/rr/R/;
    $syllabe =~ s/ll/L/;
    $syllabe =~ s/ch/C/;
    $syllabe =~ s/tx/C/;
    $syllabe =~ s/qu(e|é|i|í)/Q$1/;
    $syllabe =~ s/gu(e|é|i|í)/G$1/;

    # Some replacements
    $syllabe =~ s/x/cs/;

    my $utf8 = new String::Multibyte('UTF8');
    my @chars = $utf8->strsplit('', $syllabe);
    my $cInd = 0;
    while ($cInd < @chars) {
        my $char = $chars[$cInd];
        if ($symbolsWithDirectMappings{$char}) {
            push(@phonemesToReturn, $symbolsWithDirectMappings{$char});
        } else {
            if ($char eq 'c') {
                if ($cInd < $#chars && $chars[$cInd+1] =~ /e|é|i|í/) {
                    push(@phonemesToReturn, 'T');
                } else {
                    push(@phonemesToReturn, 'k');
                }
            } elsif ($char eq 'g') {
                if ($cInd < $#chars && $chars[$cInd+1] =~ /a|á|o|ó|ü/) {
                    push(@phonemesToReturn, 'g');
                } else {
                    push(@phonemesToReturn, 'x');
                }
            } elsif ($char eq 'h') {
                # 'h' has no sound in spanish
            } elsif ($char eq 'i') {
                if (($cInd == 0 || ($cInd == 1 && $chars[0] eq 'h')) && 
                    ($cInd < $#chars && $chars[$cInd+1] =~ /$vowels_re/)) {
                    push(@phonemesToReturn, 'L');
                } elsif (($cInd > 0 && $chars[$cInd-1] =~ /$vowels_re/) ||
                         ($cInd < $#chars && $chars[$cInd+1] =~ /$vowels_re/)) {
                    push(@phonemesToReturn, 'j');
                } else {
                    push(@phonemesToReturn, 'i');
                }
            } elsif ($char eq 'u') {
                if (($cInd < $#chars && $chars[$cInd+1] =~ /$vowels_re/)) {
                    push(@phonemesToReturn, 'w');
                } else {
                    push(@phonemesToReturn, 'u');
                }
            } elsif ($char eq 'w') {
                push(@phonemesToReturn, 'g', 'u');
            } elsif ($char eq 'y') {
                if ($cInd == $#chars) {
                    push(@phonemesToReturn, 'i');
                } else {
                    push(@phonemesToReturn, 'L');
                }
            } else {
                warn "'$char' can not be translated. Ignoring it\n";
            }
        }
        $cInd++;
    }
    return @phonemesToReturn;
}

sub _setStressOnSyllabedWord($) {
    my @syllabes = @_;
    my $word = join("", @syllabes);
    if ($word !~ /á|é|í|ó|ú/) {
        if ($word =~ /.mente$/ && @syllabes > 2) {
            my $maxIndex = $#syllabes - 2;
            @syllabes[0..$maxIndex] = _setStressOnSyllabedWord(
	      @syllabes[0..$maxIndex]);
        } elsif ($syllabes[-1] =~ /[aeiouns]$/ ) { # word is 'llana' or monosyllabic
            if (@syllabes == 1) {
                $syllabes[0] = _setStressOnSyllabe($syllabes[0]);
            } else {
                $syllabes[-2] = _setStressOnSyllabe($syllabes[-2]);
            }
        } else { # word is 'aguda'
            $syllabes[-1] = _setStressOnSyllabe($syllabes[-1]);
        }
    }
    return @syllabes;
}

sub _setStressOnSyllabe($) {
    my $syllabe = shift;

    my $strongVowels_re = "a|á|e|é|o|ó";
    my $softVowels_re = "i|í|u|ú|ü";

    my $utf8 = new String::Multibyte('UTF8');
    my @chars = $utf8->strsplit('', $syllabe);

    my @vowelsPositions;

    for (my $index = 0; $index < @chars; $index++) {
        push(@vowelsPositions, $index) if ($chars[$index] =~ /[aeiou]/);
    }

    return $syllabe unless @vowelsPositions;

    my $stressPosition;

    if (@vowelsPositions == 1) {
        $stressPosition = $vowelsPositions[0];
    } elsif (@vowelsPositions == 2) { #diphthong
        if ($chars[$vowelsPositions[0]] =~ /$strongVowels_re/ &&
            $chars[$vowelsPositions[1]] =~ /$softVowels_re/) {
            $stressPosition = $vowelsPositions[0];
        } elsif ($chars[$vowelsPositions[0]] =~ /$softVowels_re/) {
            $stressPosition = $vowelsPositions[1];
        } elsif ($chars[$vowelsPositions[0]] =~ /$strongVowels_re/ &&
                 $chars[$vowelsPositions[1]] =~ /$strongVowels_re/) {
            $stressPosition = $vowelsPositions[1];
        } else {
            warn "Can not determine stressed vowel for '$syllabe'\n";
        }
    } else {
        foreach (@vowelsPositions) {
            if ($chars[$_] =~ /$strongVowels_re/) {
                $stressPosition = $_;
                last;
            }
        }
    }

    $chars[$stressPosition] =~ s/a/á/;
    $chars[$stressPosition] =~ s/e/é/;
    $chars[$stressPosition] =~ s/i/í/;
    $chars[$stressPosition] =~ s/o/ó/;
    $chars[$stressPosition] =~ s/u/ú/;

    return join("", @chars);
}

# Preloaded methods go here.
1;
__END__


=head1 NAME

Lingua::ES::PhT - Perl extension for phonetic/phonologic transcriptions in
  Spanish.

=head1 SYNOPSIS

  use Lingua::ES::PhT;

  @phonemes = Lingua::ES::PhT::transcribe($text);

=head1 DESCRIPTION

Perl extension for phonetic/phonologic transcriptions in Spanish. Phonemes are
  represented with SAMPA symbols for Spanish, as defined at
  http://es.wikipedia.org/wiki/SAMPA_para_español .


=head2 EXPORT


=head1 SEE ALSO

Internally uses TeX::Hyphen.

=head1 AUTHOR

Alberto Montero, E<lt>alberto@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alberto Montero

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

sub _hasHiatus($) {
    my $text = shift;

    my $strongVowels_re = "a|á|e|é|o|ó";
    my $softVowels_re = "i|í|u|ú|ü";
    my $stressedSoftVowels_re = "í|ú";

    return $text =~ /(($strongVowels_re)h?($strongVowels_re))/ ||
           $text =~ /(($softVowels_re)h?($softVowels_re))/ ||
           $text =~ /(($stressedSoftVowels_re)h?($strongVowels_re))/ ||
           $text =~ /(($strongVowels_re)h?($stressedSoftVowels_re))/
}



1;