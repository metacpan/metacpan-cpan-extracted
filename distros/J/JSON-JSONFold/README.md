# JSON::JSONFold

Readable, compact JSON formatting for Perl.

JSON::JSONFold is a streaming JSON formatter that produces compact,
human-readable output by selectively folding small arrays and objects.


## Installation

```sh
cpanm JSON::JSONFold
```

## Example

```perl
use JSON::JSONFold qw(encode_json);

my $data = {
    ids  => [
        1,
        2,
        3,
        4
    ],
    meta => {
        version => 1,
        ok => 1
    },
};

print encode_json($data);
```

Default output (`default` preset):

```json
{
  "ids": [ 1, 2, 3, 4, 5, 6 ],
  "items": [
    { "id": 1, "name": "alpha" }, { "id": 2, "name": "beta" }
  ],
  "long_array": [
    "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8",
    "a9", "a10",
  ],
  "matrix": [
    [ 1, 2 ], [ 3, 4 ], [ 5, 6 ]
  ],
  "meta": { "name": "jsonfold demo", "ok": true, "version": 1 },
}
```

More compact output (`max` preset):
```perl
use JSON::JSONFold qw(config encode_json);

my $cfg = config(
    compact => "max",
    width   => 120,
);

print encode_json($data, $cfg);
```

Output:

```json
{
  "ids": [ 1, 2, 3, 4, 5, 6 ],
  "items": [ { "id": 1, "name": "alpha" }, { "id": 2, "name": "beta" } ],
  "long_array": [
    "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", 
  ],
  "matrix": [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
  "meta": { "name": "jsonfold demo", "ok": true, "version": 1 }
}
```

## Presets

- `low`
- `default`
- `med`
- `high`
- `max`

## Command Line

```sh
jsonfold.pl < input.json > output.json
```

```sh
jsonfold.pl --compact=max --width=120 < input.json
```

## License

MIT License.

## Links

- CPAN: https://metacpan.org/pod/JSON::JSONFold
- Source: https://github.com/yairlenga/jsonfold

## Documentation

See the module POD or MetaCPAN for full API documentation.