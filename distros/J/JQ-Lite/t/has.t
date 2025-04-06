use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "meta": {
    "version": "1.0",
    "author": "you"
  }
});

my $jq = JQ::Lite->new;

my @result1 = $jq->run_query($json, 'select(.meta has "version")');
my @result2 = $jq->run_query($json, 'select(.meta has "missing")');

ok(@result1, 'meta has version');
ok(!@result2, 'meta does not have missing key');

done_testing;
