# Time-stamp: <2010-05-14T16:53:47 mxp>
# Copyright © 2000 Michael Piotrowski.  All Rights Reserved.

=head1 NAME

Lingua::Ident - Statistical language identification

=head1 SYNOPSIS

 use Lingua::Ident;
 $classifier = new Lingua::Ident("filename 1", ..., "filename n");
 $lang = $classifier->identify("text to classify");
 $probabilities = $classifier->calculate("text to classify");

=head1 DESCRIPTION

This module implements a statistical language identifier based on the
approach Ted Dunning described in his 1994 report I<Statistical
Identification of Language>.

=head1 METHODS

=cut

###############################################################################

package Lingua::Ident;

$VERSION='1.7';

use Carp;
use bytes;
use strict;

=head2 Lingua::Ident->new($filename, ...)

Construct a new classifier.  The filename arguments to the constructor
must refer to files containing tables of n-gram probabilites for
languages (language models).  These tables can be generated using the
trainlid(1) utility program.

=cut

sub new
{
   my $class = shift;
   my @files = @_;
   my $self  = {};

   my ($filename, $matrix, @matrices, @languages, %bigrams, @bigrams, @n_alph);

   foreach $filename (@files)
   {
      open MATRIX, "<$filename" or croak "$!";

      $matrix  = {};
      my %bigrams = ();

      while (<MATRIX>)
      {
         chomp;

         if (/:/)
         {
            (my $key, my $val) = split(/:/);
            $matrix->{$key} = $val;
         }
         elsif (/;/)
         {
            (my $key, my $val) = split(/;/);
            $bigrams{$key} = $val;
         }
      }

      push @matrices,  $matrix;
      push @languages, $matrix->{'_LANG'};
      push @bigrams,   \%bigrams;
      push @n_alph,    $matrix->{'#ALPH'};

      close MATRIX;
   }

   $self->{MATRICES}  = \@matrices;
   $self->{LANGUAGES} = \@languages;
   $self->{BIGRAMS}   = \@bigrams;

   # Calculate the average alphabet size over all loaded language models
   my $s;
   map { $s += $_ } @n_alph;
   $self->{AVG_ALPH} = $s / @n_alph;

   return bless $self, $class;
}

=head2 $classifier->identify($string)

Identify the language of a text given in $string.  The identify()
method returns the value specified in the B<_LANG> field of the
probabilities table of the language in which the text is most likely
written (see L<"WARNINGS"> below).

Internally, the identify() method calls the calculate() method.

=cut

sub identify
{
   my $self = shift;
   my $text = shift;

   return ${$self->calculate($text)}[0]->[0];
}

=head2 $classifier->calculate($string)

Calculate the probabilities for a text to be in the languages known to
the classifier.  This method returns a reference to an array.  The
array represents a table of languages and the probabiliy for each
language.  Each array element is a reference to an array containing
two elements: The language name and the associated probability.  For
example, you may get something like this:

   [['de.iso-8859-1', -317.980835274509],
    ['en.iso-8859-1', -450.804230119916], ...]

The elements are sorted in descending order by probability.  You can
use this data to assess the reliability of the categorization and make
your own decision using application-specific metrics.

When neither a trigram nor a bigram is found, the calculation deviates
slightly from the formula given by Dunning (1994).  According to
Dunning's formula, one would estimate the probability as:

  p = log(1/#alph)

where #alph is the size of the alphabet of a particular language.
This penalizes different language models with different values because
the alphabet sizes of the languages differ.

However, the size of the alphabet is much larger for Asian languages
than for European languages.  For example, for the sample data in the
Lingua::Ident distribution trainlid(1) reports #alph = 127 for zh.big5
vs. #alph = 31 for de.iso-8859-1.  This means that Asian languages are
penalized much harder than European languages when an estimation must
be made.

To use the I<same> penalty for all languages, calculate() now uses the
average of all alphabet sizes instead.

B<NOTE:> This has only been lightly tested yet--feedback is welcome.

=cut

sub calculate
{
   my $self = shift;
   my $text = shift;

   my @matrices = @{$self->{MATRICES}};
   my @bigrams  = @{$self->{BIGRAMS}};
   my @prob = (0) x @matrices;
   my ($c, $i, @chars, $trigram);

#   for ($i = 0; $i <= $#matrices; $i++) {
#        print "bigram3 size: " . keys(%{$bigrams[$i]}) . "\n";
#   }

   foreach $c (split //, $text)
   {
      push @chars, $c;
      if (@chars == 3)
      {
         $trigram = lc(join("", @chars));
         # $trigram = join("", @chars);
         # $trigram =~ s/[\d\W]/ /og;
         $trigram =~ s/[\x00-\x1f\x21-\x40\x7b-\x7f]/ /og;

         for ($i = 0; $i <= $#matrices; $i++)
         {
            if (exists $matrices[$i]->{$trigram})
            {
               $prob[$i] += log $matrices[$i]->{$trigram};
            }
            else
            {
               # $prob[$i] += log $matrices[$i]->{'_NULL'};
               if (exists $bigrams[$i]->{substr($trigram, 0, 2)})
               {
                  $prob[$i] +=
                      log (1 / $bigrams[$i]->{substr($trigram, 0, 2)});
               }
               else
               {
                  # When neither a trigram nor a bigram is found,
                  # according to Dunning's formula, we would now
                  # calculate:

                  #   $prob[$i] += log (1 / $matrices[$i]->{'#ALPH'});

                  # Thus, we penalize different language models with
                  # different values because of the language's
                  # alphabet size.

                  # However, the size of the alphabet (#ALPH) for
                  # Asian languages is much larger than for European
                  # languages, e.g., with the sample data we get 127
                  # for zh.big5 vs. 31 for de.iso-8859-1.  This means
                  # that these languages are penalized much harder
                  # than European languages.  (This was pointed out by
                  # James Shaw <james.shaw@ask.com>.)

                  # To use the same penalty for all languages, we use
                  # the average of the alphabet sizes instead.

                  # NOTE: This has only been lightly tested yet.

                  $prob[$i] += log (1 / $self->{AVG_ALPH});
               }
            }
         }
         shift @chars;
      }
   }

   # Assemble the results into an array of arrays.  Each array
   # contains two elements: The language name and the associated
   # probability, e.g., @results may look like this:

   #   (['de.iso-8859-1', '-317.980835274509'],
   #    ['en.iso-8859-1', '-450.804230119916'], ...)

   my @results;

   for ($i = 0; $i < @{$self->{'LANGUAGES'}}; $i++)
   {
      push @results, [$self->{'LANGUAGES'}->[$i], $prob[$i]];
   }

   # Sort results in descending order by probability
   my @sorted = sort { $b->[1] <=> $a->[1] } @results;

   return \@sorted;
}

=head1 WARNINGS

Since Lingua::Ident is based on statistics it cannot be 100% accurate.
More precisely, Dunning (see below) reports his implementation to
achieve 92% accuracy with 50 KB of training text for 20-character
strings discriminating between English and Spanish.  This
implementation should be as accurate as Dunning's.  However, not only
the size but also the quality of the training text plays a role.

The current implementation doesn't use a threshold to determine if the
most probable language has a high enough probability; if you're trying
to classify a text in a language for which there is no probability
table, this results in getting an incorrect language.

=head1 AUTHOR

Lingua::Ident was developed by Michael Piotrowski <mxp@dynalabs.de>.

=head1 LICENSE

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Dunning, Ted (1994).  I<Statistical Identification of Language.>
Technical report CRL MCCS-94-273.  Computing Research Lab, New Mexico
State University.

=cut

1;
