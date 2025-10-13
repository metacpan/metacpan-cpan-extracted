use Test::More;
use JQ::Lite;

my $json = q({
  "arr": [1, 2, 3],
  "obj": {"a": 1, "b": 2},
  "str": "hello",
  "num": 12345,
  "bool": true,
  "null": null
});

my $jq = JQ::Lite->new;

my @arr = $jq->run_query($json, '.arr | length');
my @obj = $jq->run_query($json, '.obj | length');
my @str = $jq->run_query($json, '.str | length');
my @num = $jq->run_query($json, '.num | length');
my @bool = $jq->run_query($json, '.bool | length');
my @null = $jq->run_query($json, '.null | length');

is($arr[0], 3, 'array length counts elements');
is($obj[0], 2, 'object length counts keys');
is($str[0], 5, 'string length counts characters');
is($num[0], 5, 'numeric length counts digits');
is($bool[0], 1, 'boolean length is treated as scalar');
is($null[0], 0, 'null length is zero');

done_testing;
