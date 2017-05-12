use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;

my $wn = Lingua::JA::WordNet->new;
my ($word) = $wn->Word('08259753-n', 'eng');
is($word, 'american federalist party'); # underlines are removed

done_testing;
