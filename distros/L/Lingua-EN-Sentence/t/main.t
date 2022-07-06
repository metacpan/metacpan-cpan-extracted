#------------------------------------------------------------------------------
# Test script for Lingua::EN::Sentence.pm
#
# Author      : Kim Ryan, 
# Last update : 2015-03-10
#------------------------------------------------------------------------------

use warnings;
use strict;
use Test::More tests => 3;

BEGIN {

  # does it load properly?
  require_ok('Lingua::EN::Sentence');
}
use Lingua::EN::Sentence qw( get_sentences add_acronyms get_acronyms);

my $par = q{
A sentence usually ends with a dot, exclamation or question mark optionally followed by a space!
A string followed by 2 carriage returns denotes a sentence, even though it doesn't end in a dot

Dots after single letters such as U.S.A. or in numbers like -12.34 will not cause a split
as well as common abbreviations such as Dr. I. Smith, Ms. A.B. Jones, Apr. Calif. Esq.
and (some text) ellipsis such as ... or . . are ignored.
Some valid cases canot be deteected, such as the answer is X. It cannot easily be
differentiated from the single letter-dot sequence to abbreviate a person's given name.
Numbered points within a sentence will not cause a split 1. Like this one.
See the code for all the rules that apply.
This string has 7 sentences.
};

my $sentences=get_sentences($par);     
is( @$sentences, 7,'sub sentence_count');

$par .= 'Now add an acronym, such as Ret. for retired.';
add_acronyms('Ret');
$sentences=get_sentences($par);
is( @$sentences, 8,'sub add_acronyms');


