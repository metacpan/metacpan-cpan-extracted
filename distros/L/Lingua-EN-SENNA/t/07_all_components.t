use strict;
use warnings;

use Test::More tests => 2;
use Lingua::EN::SENNA;

my $all_components = {POS=>1, CHK=>1, NER=>1, SRL=>1, PSG=>1};

# Test 1:
my $tagger = Lingua::EN::SENNA->new();
my $sentence = ["The New York Times flies like an arrow"];
my $result = $tagger->analyze($sentence,$all_components);
my $expected_result = [[
{
  'CHK' => 'B-NP',
  'NER' => 'B-ORG',
  'POS' => 'DT',
  'PSG' => '(S1(S(NP*',
  'SRL' => [
             '-',
             'B-A1'
           ],
  'word' => 'The'
},
{
  'CHK' => 'I-NP',
  'NER' => 'I-ORG',
  'POS' => 'NNP',
  'PSG' => '*',
  'SRL' => [
             '-',
             'I-A1'
           ],
  'word' => 'New'
},
{
  'CHK' => 'I-NP',
  'NER' => 'I-ORG',
  'POS' => 'NNP',
  'PSG' => '*',
  'SRL' => [
             '-',
             'I-A1'
           ],
  'word' => 'York'
},
{
  'CHK' => 'E-NP',
  'NER' => 'E-ORG',
  'POS' => 'NNP',
  'PSG' => '*)',
  'SRL' => [
             '-',
             'E-A1'
           ],
  'word' => 'Times'
},
{
  'CHK' => 'S-VP',
  'NER' => 'O',
  'POS' => 'VBZ',
  'PSG' => '(VP*',
  'SRL' => [
             'flies',
             'S-V'
           ],
  'word' => 'flies'
},
{
  'CHK' => 'S-PP',
  'NER' => 'O',
  'POS' => 'IN',
  'PSG' => '(PP*',
  'SRL' => [
             '-',
             'B-AM-MNR'
           ],
  'word' => 'like'
},
{
  'CHK' => 'B-NP',
  'NER' => 'O',
  'POS' => 'DT',
  'PSG' => '(NP*',
  'SRL' => [
             '-',
             'I-AM-MNR'
           ],
  'word' => 'an'
},
{
  'CHK' => 'E-NP',
  'NER' => 'O',
  'POS' => 'NN',
  'PSG' => '*)))))',
  'SRL' => [
             '-',
             'E-AM-MNR'
           ],
  'word' => 'arrow'
}
]];
is_deeply($result,$expected_result,"Full analysis on 1 sentence");

# Test 2:
my $sentences = ["The fox swallowed the cheese",
                 "John loves Mary",
                 "He likes to code and sing but not to dance"];
my $result_array = $tagger->analyze($sentences,$all_components);
my $expected_result_array = [
[
  {
    'CHK' => 'B-NP',
    'NER' => 'O',
    'POS' => 'DT',
    'PSG' => '(S1(S(NP*',
    'SRL' => [
               '-',
               'B-A0'
             ],
    'word' => 'The'
  },
  {
    'CHK' => 'E-NP',
    'NER' => 'O',
    'POS' => 'NN',
    'PSG' => '*)',
    'SRL' => [
               '-',
               'E-A0'
             ],
    'word' => 'fox'
  },
  {
    'CHK' => 'S-VP',
    'NER' => 'O',
    'POS' => 'VBD',
    'PSG' => '(VP*',
    'SRL' => [
               'swallowed',
               'S-V'
             ],
    'word' => 'swallowed'
  },
  {
    'CHK' => 'B-NP',
    'NER' => 'O',
    'POS' => 'DT',
    'PSG' => '(NP*',
    'SRL' => [
               '-',
               'B-A1'
             ],
    'word' => 'the'
  },
  {
    'CHK' => 'E-NP',
    'NER' => 'O',
    'POS' => 'NN',
    'PSG' => '*))))',
    'SRL' => [
               '-',
               'E-A1'
             ],
    'word' => 'cheese'
  }
],
[
  {
    'CHK' => 'S-NP',
    'NER' => 'S-PER',
    'POS' => 'NNP',
    'PSG' => '(S1(S(NP*)',
    'SRL' => [
               '-',
               'S-A0'
             ],
    'word' => 'John'
  },
  {
    'CHK' => 'S-VP',
    'NER' => 'O',
    'POS' => 'VBZ',
    'PSG' => '(VP*)',
    'SRL' => [
               'loves',
               'S-V'
             ],
    'word' => 'loves'
  },
  {
    'CHK' => 'S-NP',
    'NER' => 'S-PER',
    'POS' => 'NNP',
    'PSG' => '(NP*)))',
    'SRL' => [
               '-',
               'S-A1'
             ],
    'word' => 'Mary'
  }
],
[
  {
    'CHK' => 'S-NP',
    'NER' => 'O',
    'POS' => 'PRP',
    'PSG' => '(S1(S(S(NP*)',
    'SRL' => [
               '-',
               'S-A0',
               'S-A0',
               'S-A0'
             ],
    'word' => 'He'
  },
  {
    'CHK' => 'S-VP',
    'NER' => 'O',
    'POS' => 'VBZ',
    'PSG' => '(VP*',
    'SRL' => [
               'likes',
               'S-V',
               'O',
               'O'
             ],
    'word' => 'likes'
  },
  {
    'CHK' => 'S-PP',
    'NER' => 'O',
    'POS' => 'TO',
    'PSG' => '(PP*',
    'SRL' => [
               '-',
               'B-A1',
               'O',
               'O'
             ],
    'word' => 'to'
  },
  {
    'CHK' => 'S-NP',
    'NER' => 'O',
    'POS' => 'NN',
    'PSG' => '(NP*',
    'SRL' => [
               '-',
               'E-A1',
               'O',
               'O'
             ],
    'word' => 'code'
  },
  {
    'CHK' => 'O',
    'NER' => 'O',
    'POS' => 'CC',
    'PSG' => '*',
    'SRL' => [
               '-',
               'O',
               'O',
               'O'
             ],
    'word' => 'and'
  },
  {
    'CHK' => 'B-VP',
    'NER' => 'O',
    'POS' => 'VB',
    'PSG' => '*))))',
    'SRL' => [
               'sing',
               'O',
               'S-V',
               'O'
             ],
    'word' => 'sing'
  },
  {
    'CHK' => 'I-VP',
    'NER' => 'O',
    'POS' => 'CC',
    'PSG' => '*',
    'SRL' => [
               '-',
               'O',
               'O',
               'O'
             ],
    'word' => 'but'
  },
  {
    'CHK' => 'I-VP',
    'NER' => 'O',
    'POS' => 'RB',
    'PSG' => '(S*',
    'SRL' => [
               '-',
               'O',
               'S-AM-NEG',
               'S-AM-NEG'
             ],
    'word' => 'not'
  },
  {
    'CHK' => 'I-VP',
    'NER' => 'O',
    'POS' => 'TO',
    'PSG' => '(VP*',
    'SRL' => [
               '-',
               'O',
               'O',
               'O'
             ],
    'word' => 'to'
  },
  {
    'CHK' => 'E-VP',
    'NER' => 'O',
    'POS' => 'VB',
    'PSG' => '(VP*)))))',
    'SRL' => [
               'dance',
               'O',
               'O',
               'O'
             ],
    'word' => 'dance'
  }
]];

is_deeply($result_array,$expected_result_array,"Full analysis on 3 sentences");