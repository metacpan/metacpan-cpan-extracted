#------------------------------------------------------------------------------
# Test script for Lingua::EN::::Fathom.pm
#
# Author      : Kim Ryan, Kirk Kimmel
#------------------------------------------------------------------------------

use warnings;
use strict;
use Test::More tests => 7;

BEGIN {

  # does it load properly?
  require_ok('Lingua::EN::Fathom');
}

my $sample = q{
Returns the number of words in the analysed text file or block. A word must
consist of letters a-z with at least one vowel sound, and optionally an
apostrophe or hyphen. Items such as "&, K108, NSW" are not counted as words.
Common abbreviations such a U.S. or numbers like 1.23 will not denote the end of
a sentence.


};

my $text = Lingua::EN::Fathom->new();
$text->analyse_block($sample);

is( $text->num_chars, 313, 'sub num_chars' );
is( $text->num_words, 54,  'sub num_words' );
is( $text->num_sentences,      4,                'sub num_sentences' );
is( $text->num_text_lines,     5,                'sub num_text_lines' );
is( $text->num_blank_lines,    4,                'sub num_blank_lines' );
is( $text->num_paragraphs,     1,                'sub num_paragraphs' );
