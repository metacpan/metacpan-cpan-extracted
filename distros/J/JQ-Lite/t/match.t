use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    { "name": "Alice", "email": "alice@example.com" },
    { "name": "Bob",   "email": "bob@admin.com" },
    { "name": "Carol", "email": "carol@example.org" }
  ]
});

my $jq = JQ::Lite->new;

my @matched_bob   = $jq->run_query($json, '.users[] | select(.name match "Bob")');
my @matched_admin = $jq->run_query($json, '.users[] | select(.email match "^bob@")');
my @matched_fail  = $jq->run_query($json, '.users[] | select(.name match "David")');

is($matched_bob[0]{name}, 'Bob', 'matched user name = Bob');
is($matched_admin[0]{email}, 'bob@admin.com', 'matched email start with bob@');
ok(!@matched_fail, 'no match for David');

done_testing;
