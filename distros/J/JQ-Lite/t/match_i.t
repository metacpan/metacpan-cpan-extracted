use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    { "name": "Alice" },
    { "name": "BOB" },
    { "name": "Carol" }
  ]
});

my $jq = JQ::Lite->new;

my @case_sensitive = $jq->run_query($json, '.users[] | select(.name match "bob")');
my @case_insensitive = $jq->run_query($json, '.users[] | select(.name match "bob"i)');

is(scalar(@case_sensitive), 0, 'case-sensitive match fails for "bob"');
is($case_insensitive[0]{name}, 'BOB', 'case-insensitive match succeeds');

done_testing;
