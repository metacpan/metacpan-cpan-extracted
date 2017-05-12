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
Returns the number of sentences in string.
A sentence ends with a dot, exclamation or question mark followed by a space! 
Dots after single letters such as U.S.A or e.g. are ignored,
  as well as common abbreviations such as Dr. Ms. esp. Apr. Calif. and Ave.,
  initials such as 'Mr. A. Smith'.
This string has 4 sentences.
};

my $sentences=get_sentences($par);     
is( @$sentences, 4,'sub sentence_count');

$par .= 'Now add an acronym, such as ret. for retired.';
add_acronyms('Ret');
$sentences=get_sentences($par);
is( @$sentences, 5,'sub add_acronyms');


