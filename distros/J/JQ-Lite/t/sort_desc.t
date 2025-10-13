use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "nums": [1, 9, 3, 2],
  "words": ["apple", "pear", "banana"],
  "mixed": ["10", "2", "30"]
});

my $jq = JQ::Lite->new;

my @desc_nums   = $jq->run_query($json, '.nums | sort_desc');
my @desc_words  = $jq->run_query($json, '.words | sort_desc');
my @desc_mixed  = $jq->run_query($json, '.mixed | sort_desc');

is_deeply($desc_nums[0],  [9, 3, 2, 1], 'numeric sort descending');
is_deeply($desc_words[0], ['pear', 'banana', 'apple'], 'string sort descending');
is_deeply($desc_mixed[0], ['30', '10', '2'], 'smart comparison honors numeric values');

done_testing;
