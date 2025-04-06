use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    { "name": "Alice" },
    { "name": "Bob" },
    { "name": "Carol" }
  ],
  "empty": []
});

my $jq = JQ::Lite->new;

my @first = $jq->run_query($json, '.users | first');
my @last  = $jq->run_query($json, '.users | last');
my @first_empty = $jq->run_query($json, '.empty | first');
my @last_empty  = $jq->run_query($json, '.empty | last');

is($first[0]{name}, 'Alice', 'first user is Alice');
is($last[0]{name}, 'Carol', 'last user is Carol');
ok(!defined $first_empty[0], 'first of empty is undef');
ok(!defined $last_empty[0],  'last of empty is undef');

done_testing;
