use strict;
use warnings;

use Test::More tests => 2;
use Lingua::EN::SENNA;

# Test 1:
my $tagger = Lingua::EN::SENNA->new();
my $sentence = ["Time flies like an arrow"];
my $expected_tokens = [["Time","flies","like","an","arrow"]];
my $tokens = $tagger->tokenize($sentence);
is_deeply($tokens,$expected_tokens,"Tokenization on 1 sentence");

# Test 2:
my $sentences = ["The fox swallowed the cheese",
                 "John loves Mary",
                 "He likes to code and sing but not to dance"];
my $tokens_array = $tagger->tokenize($sentences);
my $expected_tokens_array = [
  [
    'The',
    'fox',
    'swallowed',
    'the',
    'cheese'
  ],
  [
    'John',
    'loves',
    'Mary'
  ],
  [
    'He',
    'likes',
    'to',
    'code',
    'and',
    'sing',
    'but',
    'not',
    'to',
    'dance'
  ]
];
is_deeply($tokens_array,$expected_tokens_array,"Tokenization on 3 sentences");