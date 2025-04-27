use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "data": [1, null, 2, null, 3]
}
JSON

my $jq = JQ::Lite->new;

my @result = $jq->run_query($json, '.data | compact()');

is_deeply(
    $result[0],
    [1, 2, 3],
    'compact() removes nulls'
);

done_testing();

