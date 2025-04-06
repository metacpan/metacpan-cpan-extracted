use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "nums": [5, 3, 5, 1, 3],
  "words": ["banana", "apple", "banana", "pear"]
});

my $jq = JQ::Lite->new;

my @sorted = $jq->run_query($json, '.nums | sort');
my @unique = $jq->run_query($json, '.words | unique');

is_deeply($sorted[0], [1, 3, 3, 5, 5], 'nums sorted correctly');
is_deeply($unique[0], ['banana', 'apple', 'pear'], 'words unique');

done_testing;
