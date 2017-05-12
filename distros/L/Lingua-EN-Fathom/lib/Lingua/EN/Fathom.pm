=head1 NAME

Lingua::EN::Fathom - Measure readability of English text

=head1 SYNOPSIS

    use Lingua::EN::Fathom;

    my $text = Lingua::EN::Fathom->new();

    $text->analyse_file("sample.txt");

    $accumulate = 1;
    $text->analyse_block($text_string,$accumulate);

    $num_chars             = $text->num_chars;
    $num_words             = $text->num_words;
    $percent_complex_words = $text->percent_complex_words;
    $num_sentences         = $text->num_sentences;
    $num_text_lines        = $text->num_text_lines;
    $num_blank_lines       = $text->num_blank_lines;
    $num_paragraphs        = $text->num_paragraphs;
    $syllables_per_word    = $text->syllables_per_word;
    $words_per_sentence    = $text->words_per_sentence;


    %words = $text->unique_words;
    foreach $word ( sort keys %words )
    {
      print("$words{$word} :$word\n");
    }

    $fog     = $text->fog;
    $flesch  = $text->flesch;
    $kincaid = $text->kincaid;

    print($text->report);


=head1 REQUIRES

Perl, version 5.001 or higher, Lingua::EN::Syllable


=head1 DESCRIPTION

This module analyses English text in either a string or file. Totals are
then calculated for the number of characters, words, sentences, blank
and non blank (text) lines and paragraphs.

Three common readability statistics are also derived, the Fog, Flesch and
Kincaid indices.

All of these properties can be accessed through individual methods, or by
generating a text report.

A hash of all unique words and the number of times they occur is generated.


=head1 METHODS

=head2 new

The C<new> method creates an instance of an text object This must be called
before any of the following methods are invoked. Note that the object only
needs to be created once, and can be reused with new input data.

   my $text = Lingua::EN::Fathom->new();

=head2 analyse_file

The C<analyse_file> method takes as input the name of a text file. Various
text based statistics are calculated for the file. This method and
C<analyse_block> are prerequisites for all the following methods. An optional
argument may be supplied to control accumulation of statistics. If set to
a non zero value, all statistics are accumulated with each successive call.

    $text->analyse_file("sample.txt");


=head2 analyse_block

The C<analyse_block> method takes as input the name of a text file. Various
text based statistics are calculated for the file. This method and
C<analyse_file> are prerequisites for all the following methods. An optional
argument may be supplied to control accumulation of statistics. If set to
a non zero value, all statistics are accumulated with each successive call.

    $text->analyse_block("sample.txt");

=head2 num_chars

Returns the number of characters in the analysed text file or block. This
includes characters such as spaces, and punctuation marks.

=head2 num_words

Returns the number of words in the analysed text file or block. A word must
consist of letters a-z with at least one vowel sound, and optionally an
apostrophe or hyphen. Items such as "&, K108, NW" are not counted as words.

=head2 percent_complex_words

Returns the percentage of complex words in the analysed text file or block. A 
complex word must consist of three or more syllables. This statistic is used to
calculate the fog index.

=head2 num_sentences

Returns the number of sentences in the analysed text file or block. A sentence
is any group of words and non words terminated with a single full stop. Spaces
may occur before and after the full stop.


=head2 num_text_lines

Returns the number of lines containing some text in the analysed
text file or block.

=head2 num_blank_lines

Returns the number of lines NOT containing any text in the analysed
text file or block.

=head2 num_paragraphs

Returns the number of paragraphs in the analysed text file or block.

=head2 syllables_per_word

Returns the average number of syllables per word in the analysed 
text file or block.

=head2 words_per_sentence

Returns the average number of words per sentence in the analysed 
text file or block.



=head2 READABILITY

Three indices of text readability are calculated. They all measure complexity as
a function of syllables per word and words per sentence. They assume the text is
well formed and logical. You could analyse a passage of nonsensical English and
find the readability is quite good, provided the words are not too complex and
the sentences not too long.

For more information see: L<http://www.plainlanguage.com/Resources/readability.html>


=head2 fog

Returns the Fog index for the analysed text file or block.

  ( words_per_sentence + percent_complex_words ) * 0.4

The Fog index, developed by Robert Gunning, is a well known and simple
formula for measuring readability. The index indicates the number of years
of formal education a reader of average intelligence would need to read the
text once and understand that piece of writing with its word sentence workload.

   18 unreadable
   14 difficult
   12 ideal
   10 acceptable
    8 childish


=head2 flesch

Returns the Flesch reading ease score for the analysed text file or block.

   206.835 - (1.015 * words_per_sentence) - (84.6 * syllables_per_word)

This score rates text on a 100 point scale. The higher the score, the easier
it is to understand the text. A score of 60 to 70 is considered to be optimal.


=head2 kincaid

Returns the Flesch-Kincaid grade level score for the analysed text
file or block.

   (11.8 * syllables_per_word) +  (0.39 * words_per_sentence) - 15.59;

This score rates text on U.S. grade school level. So a score of 8.0 means
that the document can be understood by an eighth grader. A score of 7.0 to
8.0 is considered to be optimal.


=head2 unique_words

Returns a hash of unique words. The words (in lower case) are held in
the hash keys while the number of occurrences are held in the hash values.


=head2 report

    print($text->report);

Produces a text based report containing all Fathom statistics for
the currently analysed text block or file. For example: 
    
Number of characters       : 813
Number of words            : 135
Percent of complex words   : 20.00
Average syllables per word : 1.7704
Number of sentences        : 12
Average words per sentence : 11.2500
Number of text lines       : 13
Number of blank lines      : 8
Number of paragraphs       : 4


READABILITY INDICES

Fog                        : 12.5000
Flesch                     : 45.6429
Flesch-Kincaid             : 9.6879

The return value is a string containing the report contents


=head1 SEE ALSO

L<Lingua::EN::Syllable>,L<Lingua::EN::Sentence>,L<B::Fathom>


=head1 POSSIBLE EXTENSIONS

   Count white space and punctuation characters
   Allow user control over what strictly defines a word
   Provide a density measure of white space to characters

=head1 LIMITATIONS

The syllable count provided in Lingua::EN::Syllable is about 90% accurate

Acronyms that contain vowels, like GPO, will be counted as words.

The fog index should exclude proper names


=head1 BUGS

None known

=head1 AUTHOR

Lingua::EN::Fathom was written by Kim Ryan <kimryan at cpan dot org>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016 Kim Ryan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#------------------------------------------------------------------------------

package Lingua::EN::Fathom;

use Lingua::EN::Syllable;
use strict;
use warnings;

our $VERSION = '1.19';

#------------------------------------------------------------------------------
# Create a new instance of a text object.

sub new
{
   my $class = shift;

   my $text = {};
   bless($text,$class);
   return($text);
}
#------------------------------------------------------------------------------
# Analyse text stored in a file, reading from the file one line at a time

sub analyse_file
{
   my $text = shift;
   my ($file_name,$accumulate) = @_;

   unless ( $accumulate )
   {
      $text = &_initialize($text);
   }

   $text->{file_name} = $file_name;

   # Only analyse non-empty text files
   unless ( -T $file_name and -s $file_name )
   {
      return($text);
   }

   open(IN_FH,"<$file_name");

   my $in_paragraph = 0;
   while ( <IN_FH> )
   {
      my $one_line = $_;
      ($in_paragraph,$text) = &_analyse_line($text,$one_line,$in_paragraph);
   }
   close(IN_FH);
   $text->_calculate_readability;

   return($text);
}
#------------------------------------------------------------------------------
# Analyse a block of text, stored as a string. The string may contain line
# terminators.

sub analyse_block
{
   my $text = shift;
   my ($block,$accumulate) = @_;

   unless ( $accumulate )
   {
      $text = &_initialize($text);
   }

   unless ( $block )
   {
      return($text);
   }

   my $in_paragraph = 0;

   # by setting split limit to -1, we prevent split from stripping
   # trailing line terminators
   my @all_lines = split(/\n/,$block,-1);
   my $one_line;
   foreach $one_line ( @all_lines )
   {
      ($in_paragraph,$text) = &_analyse_line($text,$one_line,$in_paragraph);
   }

   $text->_calculate_readability;
   return($text);
}
#------------------------------------------------------------------------------
sub num_chars
{
   my $text = shift;
   return($text->{num_chars});
}
#------------------------------------------------------------------------------
sub num_words
{
   my $text = shift;
   return($text->{num_words});
}
#------------------------------------------------------------------------------
sub percent_complex_words
{
   my $text = shift;
   return($text->{percent_complex_words});
}

#------------------------------------------------------------------------------
sub num_sentences
{
   my $text = shift;
   return($text->{num_sentences});
}
#------------------------------------------------------------------------------
sub num_text_lines
{
   my $text = shift;
   return($text->{num_text_lines});
}
#------------------------------------------------------------------------------
sub num_blank_lines
{
   my $text = shift;
   return($text->{num_blank_lines});
}
#------------------------------------------------------------------------------
sub num_paragraphs
{
   my $text = shift;
   return($text->{num_paragraphs});
}
#------------------------------------------------------------------------------
sub syllables_per_word
{
   my $text = shift;
   return($text->{syllables_per_word});
}
#------------------------------------------------------------------------------
sub words_per_sentence
{
   my $text = shift;
   return($text->{words_per_sentence});
}
#------------------------------------------------------------------------------
sub fog
{
   my $text = shift;
   return($text->{fog});
}
#------------------------------------------------------------------------------
sub flesch
{
   my $text = shift;
   return($text->{flesch});
}
#------------------------------------------------------------------------------
sub kincaid
{
   my $text = shift;
   return($text->{kincaid});
}
#------------------------------------------------------------------------------
# Return anonymous hash of all the unique words in analysed text. The words
# occurrence count is stored in the hash value.

sub unique_words
{
   my $text = shift;
   if ( $text->{unique_words} )
   {
      return( %{ $text->{unique_words} } );
   }
   else
   {
      return(undef);
   }
}
#------------------------------------------------------------------------------
# Provide a formatted text report of all statistics for a text object.
# Return report as a string.

sub report
{
   my $text = shift;

   my $report = '';

   $text->{file_name} and
   $report .= sprintf("File name                  : %s\n",$text->{file_name} );

   $report .= sprintf("Number of characters       : %d\n",  $text->num_chars);
   $report .= sprintf("Number of words            : %d\n",  $text->num_words);
   $report .= sprintf("Percent of complex words   : %.2f\n",$text->percent_complex_words);
   $report .= sprintf("Average syllables per word : %.4f\n",$text->syllables_per_word);
   $report .= sprintf("Number of sentences        : %d\n",  $text->num_sentences);
   $report .= sprintf("Average words per sentence : %.4f\n",$text->words_per_sentence);
   $report .= sprintf("Number of text lines       : %d\n",  $text->num_text_lines);
   $report .= sprintf("Number of blank lines      : %d\n",  $text->num_blank_lines);
   $report .= sprintf("Number of paragraphs       : %d\n",  $text->num_paragraphs);

   $report .= "\n\nREADABILITY INDICES\n\n";
   $report .= sprintf("Fog                        : %.4f\n",$text->fog);
   $report .= sprintf("Flesch                     : %.4f\n",$text->flesch);
   $report .= sprintf("Flesch-Kincaid             : %.4f\n",$text->kincaid);

   return($report);
}

#------------------------------------------------------------------------------
# PRIVATE METHODS
#------------------------------------------------------------------------------
sub _initialize
{
   my $text = shift;

   $text->{num_chars} = 0;
   $text->{num_syllables} = 0;
   $text->{num_words} = 0;
   $text->{num_complex_words} = 0;
   $text->{num_text_lines} = 0;
   $text->{num_blank_lines} = 0;
   $text->{num_paragraphs} = 0;
   $text->{num_sentences} = 0;
   $text->{unique_words} = ();
   $text->{file_name} = '';


   $text->{fog} = 0;
   $text->{flesch} = 0;
   $text->{kincaid} = 0;


   return($text);
}
#------------------------------------------------------------------------------
# Increment number of text lines, blank lines and paragraphs

sub _analyse_line
{
   my $text = shift;
   my ($one_line,$in_paragraph) = @_;

   if ( $one_line =~ /\w/ )
   {
      chomp($one_line);
      $text = &_analyse_words($text,$one_line);
      $text->{num_text_lines}++;
   
      unless ( $in_paragraph )
      {
         $text->{num_paragraphs}++;
         $in_paragraph = 1;
      }
   }
   else # empty or blank line
   {
      $text->{num_blank_lines}++;
      $in_paragraph = 0;
   }
   return($in_paragraph,$text);
}
#------------------------------------------------------------------------------
# Try to detect real words in line. Increment syllable, word, complex word,
# and sentence counters.

sub _analyse_words
{
   my $text = shift;
   my ($one_line) = @_;

    $text->{num_chars} += length($one_line);

   # Word found, such as: twice, BOTH, a, I'd, non-plussed ..
   # Ignore words like K12, &, X.Y.Z ...
   while ( $one_line =~ /\b([a-z][-'a-z]*)\b/ig )
   {
      my $one_word = $1;

      # Try to filter out acronyms and  abbreviations by accepting
      # words with a vowel sound. This won't work for GPO etc.
      next unless $one_word =~ /[aeiouy]/i;

      # Test for valid hyphenated word like be-bop
      if ( $one_word =~ /-/ )
      {
         next unless $one_word =~ /[a-z]{2,}-[a-z]{2,}/i;
      }

      # word frequency count
      $text->{unique_words}{lc($one_word)}++;

      $text->{num_words}++;

      # Use subroutine from Lingua::EN::Syllable
      my $num_syllables_current_word = &syllable($one_word);
      $text->{num_syllables} += $num_syllables_current_word;

      # Required for Fog index, count non hyphenated words of 3 or more
      # syllables. Should add check for proper names in here as well
      if ( $num_syllables_current_word > 2 and $one_word !~ /-/ )
      {
         $text->{num_complex_words}++;
      }
   }
   # Remove full stops to denote common abbreviations. By requiring a following space
   # we know the '.' is not also ending the sentence.
   
   # People's titles
   $one_line =~ s/Mr\. /Mr /ig;
   $one_line =~ s/Mrs\. /Mrs /ig;
   $one_line =~ s/Ms\. /Ms /ig;
   $one_line =~ s/M\/s\. /M\/s /ig;
   $one_line =~ s/Dr\. /Dr /ig;
   $one_line =~ s/Prof\. /Prof /ig;
   $one_line =~ s/Det\. /Det /ig;
   $one_line =~ s/Insp\. /Insp /ig;
   
   # Commercial abbreviations
   $one_line =~ s/Pty\. /Pty /ig;
   $one_line =~ s/PLC\. /PLC /ig;
   $one_line =~ s/Ltd\. /Ltd /ig;
   $one_line =~ s/Inc\. /Inc /ig;

   # Other abbreviations
   $one_line =~ s/etc\. /etc /ig;
   $one_line =~ s/vs\. /vs /ig;
   
   
   # Remove quotation marks as a quote followed by a full stop will not be
   # correctly detected by the following regexps.
   $one_line =~ s/"//g;
   $one_line =~ s/'//g;

   # Search for '.', '?' or '!'  to end a sentence.
   while ( $one_line =~ /\b\s*[.!?]\s*\b/g ) { $text->{num_sentences}++ }
   # Check for final sentence, with no following words.
   $one_line =~ /\b\s*[.!?]\s*$/g and $text->{num_sentences}++;

   return($text);
}
#------------------------------------------------------------------------------
# Determine the three readability indices

sub _calculate_readability
{
   my $text = shift;

   if ( $text->{num_sentences} and $text->{num_words} )
   {

      $text->{words_per_sentence} = $text->{num_words} / $text->{num_sentences};
      $text->{syllables_per_word} = $text->{num_syllables} / $text->{num_words};
      $text->{percent_complex_words} =
         ( $text->{num_complex_words} / $text->{num_words} ) * 100;

      $text->{fog} = ( $text->{words_per_sentence} +  $text->{percent_complex_words} ) * 0.4;

      $text->{flesch} =  206.835 - (1.015 * $text->{words_per_sentence}) -
         (84.6 * $text->{syllables_per_word});

      $text->{kincaid} =  (11.8 * $text->{syllables_per_word}) +
         (0.39 * $text->{words_per_sentence}) - 15.59;
   }
   else
   {
      $text->{words_per_sentence} = 0;
      $text->{syllables_per_word} = 0;
      $text->{fog} = 0;
      $text->{flesch} = 0;
      $text->{kincaid} = 0;
   }
}
#------------------------------------------------------------------------------
return(1);
