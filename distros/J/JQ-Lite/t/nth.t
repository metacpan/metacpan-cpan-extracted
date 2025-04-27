use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "users": ["Alice", "Bob", "Carol"]
}
JSON

my $jq = JQ::Lite->new;

is_deeply([$jq->run_query($json, '.users | nth(0)')], ['Alice'], 'nth(0) is Alice');
is_deeply([$jq->run_query($json, '.users | nth(1)')], ['Bob'], 'nth(1) is Bob');
is_deeply([$jq->run_query($json, '.users | nth(2)')], ['Carol'], 'nth(2) is Carol');
is_deeply([$jq->run_query($json, '.users | nth(5)')], [undef], 'nth(5) is undef (out of bounds)');

done_testing();

