use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

sub run_query {
    my ($json, $query) = @_;
    return [$jq->run_query($json, $query)];
}

sub encode_json {
    my ($data) = @_;
    require JSON::PP;
    return JSON::PP::encode_json($data);
}

my $json = <<'JSON';
{
  "name": "widget",
  "details": {
    "dimensions": {
      "width": 10,
      "height": 20
    }
  }
}
JSON

my $res = run_query($json, 'setpath(["details", "dimensions", "depth"]; 5)');

is_deeply($res->[0], {
    name    => 'widget',
    details => {
        dimensions => {
            width  => 10,
            height => 20,
            depth  => 5,
        },
    },
}, 'setpath() adds missing nested key');

$res = run_query($json, 'setpath(["details", "dimensions", "width"]; 42)');

is_deeply($res->[0], {
    name    => 'widget',
    details => {
        dimensions => {
            width  => 42,
            height => 20,
        },
    },
}, 'setpath() replaces existing value');

my $array_json = <<'JSON';
{
  "items": [
    { "name": "alpha" }
  ]
}
JSON

$res = run_query($array_json, 'setpath(["items", 1, "name"]; "beta")');

is_deeply($res->[0], {
    items => [
        { name => 'alpha' },
        { name => 'beta' },
    ],
}, 'setpath() autovivifies array entries');

$res = run_query($json, 'setpath(["copy_of_name"]; .name)');

is_deeply($res->[0], {
    name         => 'widget',
    details      => {
        dimensions => {
            width  => 10,
            height => 20,
        },
    },
    copy_of_name => 'widget',
}, 'setpath() evaluates value expression as filter');

$res = run_query($json, 'setpath(paths; 99)');

is_deeply($res->[0], {
    name    => 99,
    details => {
        dimensions => {
            width  => 99,
            height => 99,
        },
    },
}, 'setpath() accepts path arrays from filter results');

$res = run_query($json, 'setpath(["details", "dimensions"]; { "area": 200 })');

is_deeply($res->[0], {
    name    => 'widget',
    details => {
        dimensions => {
            area => 200,
        },
    },
}, 'setpath() clones complex replacement values');

subtest 'original inputs untouched' => sub {
    my $original = { foo => { bar => 1 } };
    my $encoded  = encode_json($original);
    my ($output) = $jq->run_query($encoded, 'setpath(["foo", "baz"]; 7)');

    is($original->{foo}{bar}, 1, 'source structure not mutated');
    is($output->{foo}{baz}, 7, 'new path applied to result');
};

done_testing;
