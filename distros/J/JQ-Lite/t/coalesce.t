use strict;
use warnings;
use Test::More tests => 4;
use JQ::Lite;

my $jq = JQ::Lite->new;

# --- 1. Provide fallback string when field is missing
my $json_users = <<'JSON';
{
  "users": [
    { "name": "Alice", "nickname": "Al" },
    { "name": "Bob",   "nickname": null },
    { "name": "Carol" }
  ]
}
JSON

my @names = $jq->run_query($json_users, '.users[] | (.nickname // .name)');
is_deeply(\@names, [ 'Al', 'Bob', 'Carol' ], 'fallback picks existing nickname or name');

# --- 2. Literal fallback when key is absent
my $json_missing = '{"value":42}';
my @fallback = $jq->run_query($json_missing, '.missing // "default"');
is($fallback[0], 'default', 'literal fallback applied for missing key');

# --- 3. Boolean false should not trigger fallback
my $json_false = '{"active":false}';
my @bool = $jq->run_query($json_false, '.active // true');
ok(@bool && !$bool[0], 'false is preserved without using fallback');

# --- 4. Nested alternative operator chains
my $json_nested = '{"foo":null,"bar":null}';
my @nested = $jq->run_query($json_nested, '.foo // .bar // 0');
is($nested[0], 0, 'nested fallbacks evaluate from left to right');

