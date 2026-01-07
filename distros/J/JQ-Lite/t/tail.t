use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    { "name": "Alice" },
    { "name": "Bob" },
    { "name": "Carol" },
    { "name": "Dave" }
  ],
  "status": "ok"
});

my $jq = JQ::Lite->new;

my @tail_2 = $jq->run_query($json, '.users | tail(2)');
my @tail_0 = $jq->run_query($json, '.users | tail(0)');
my @tail_10 = $jq->run_query($json, '.users | tail(10)');
my @tail_scalar = $jq->run_query($json, '.status | tail(3)');

my $negative_ok = eval { $jq->run_query($json, '.users | tail(-1)') };
ok(!$negative_ok && $@ =~ /tail\(\): count must be a non-negative integer/,
   'tail() rejects negative counts');

my $non_numeric_ok = eval { $jq->run_query($json, '.users | tail(foo)') };
ok(!$non_numeric_ok && $@ =~ /tail\(\): count must be a non-negative integer/,
   'tail() rejects non-numeric counts');

is_deeply($tail_2[0], [ { name => 'Carol' }, { name => 'Dave' } ], 'tail(2) returns final 2 elements');
is_deeply($tail_0[0], [], 'tail(0) returns empty array');
is_deeply([ map { $_->{name} } @{ $tail_10[0] } ],
          [ 'Alice', 'Bob', 'Carol', 'Dave' ],
          'tail(10) returns all elements when count exceeds length');

is($tail_scalar[0], 'ok', 'tail on scalar passes value through unchanged');

done_testing;
