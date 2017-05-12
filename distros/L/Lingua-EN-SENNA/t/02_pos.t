use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Test::More tests => 4;
use Lingua::EN::SENNA;

# Test 1:
my $tagger = Lingua::EN::SENNA->new();
my $sentence = ["Time flies like an arrow"];
my $pos = $tagger->pos_tag($sentence);
my $pos_analyzed = $tagger->analyze($sentence,{POS=>1});
my $expected_pos =  [
  [
    {
      'POS' => 'NN',
      'word' => 'Time'
    },
    {
      'word' => 'flies',
      'POS' => 'VBZ'
    },
    {
      'POS' => 'IN',
      'word' => 'like'
    },
    {
      'word' => 'an',
      'POS' => 'DT'
    },
    {
      'POS' => 'NN',
      'word' => 'arrow'
    }
  ]
];
is_deeply($pos,$expected_pos,"POS tagging on 1 sentence");
is_deeply($pos_analyzed,$expected_pos,"POS analysis on 1 sentence");

# Test 2:
my $sentences = ["The fox swallowed the cheese",
                 "John loves Mary",
                 "He likes to code and sing but not to dance"];
my $pos_array = $tagger->pos_tag($sentences);
my $pos_analyzed_array = $tagger->analyze($sentences,{POS=>1});
my $expected_pos_array = [
  [
    {
      'word' => 'The',
      'POS' => 'DT'
    },
    {
      'word' => 'fox',
      'POS' => 'NN'
    },
    {
      'POS' => 'VBD',
      'word' => 'swallowed'
    },
    {
      'word' => 'the',
      'POS' => 'DT'
    },
    {
      'word' => 'cheese',
      'POS' => 'NN'
    }
  ],
  [
    {
      'POS' => 'NNP',
      'word' => 'John'
    },
    {
      'POS' => 'VBZ',
      'word' => 'loves'
    },
    {
      'word' => 'Mary',
      'POS' => 'NNP'
    }
  ],
  [
    {
      'word' => 'He',
      'POS' => 'PRP'
    },
    {
      'POS' => 'VBZ',
      'word' => 'likes'
    },
    {
      'POS' => 'TO',
      'word' => 'to'
    },
    {
      'POS' => 'NN',
      'word' => 'code'
    },
    {
      'POS' => 'CC',
      'word' => 'and'
    },
    {
      'POS' => 'VB',
      'word' => 'sing'
    },
    {
      'POS' => 'CC',
      'word' => 'but'
    },
    {
      'POS' => 'RB',
      'word' => 'not'
    },
    {
      'word' => 'to',
      'POS' => 'TO'
    },
    {
      'word' => 'dance',
      'POS' => 'VB'
    }
  ]
];

is_deeply($pos_array,$expected_pos_array,"POS tagging on 3 sentences");
is_deeply($pos_analyzed_array,$expected_pos_array,"POS analysis on 3 sentences");