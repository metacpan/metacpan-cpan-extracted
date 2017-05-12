[![Build Status](https://travis-ci.org/karupanerura/p5-JSON5.svg?branch=master)](https://travis-ci.org/karupanerura/p5-JSON5) [![Coverage Status](http://codecov.io/github/karupanerura/p5-JSON5/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/p5-JSON5?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/JSON5.svg)](https://metacpan.org/release/JSON5)
# NAME

JSON5 - The JSON5 implementation for Perl 5

# SYNOPSIS

```perl
use JSON5;

my $object = decode_json5('{$ref:"#"}');
# { '$ref' => "#" }
```

# DESCRIPTION

JSON5 is the JSON5 implementation for Perl 5

# FUNCTIONAL INTERFACE

Some documents are copied and modified from ["FUNCTIONAL INTERFACE" in JSON::PP](https://metacpan.org/pod/JSON::PP#FUNCTIONAL-INTERFACE).

## decode\_json5

```
$perl_scalar = decode_json5 $json_text
```

expects an UTF-8 (binary) string and tries to parse that as
an UTF-8 encoded JSON5 text, returning the resulting reference.

This function call is functionally identical to:

```
$perl_scalar = JSON5->new->utf8->decode($json_text)
```

# METHODS

Some documents are copied and modified from ["METHODS" in JSON5::PP](https://metacpan.org/pod/JSON5::PP#METHODS).

## new

```
$json5 = JSON5->new
```

Returns a new JSON5 object that can be used to decode JSON5
strings.

All boolean flags described below are by default _disabled_.

The mutators for flags all return the JSON5 object again and thus calls can
be chained:

```perl
my $object = JSON5->new->utf8->allow_nonref->decode("true")
=> JSON::PP::true
```

## utf8

```
$json5 = $json5->utf8([$enable])

$enabled = $json5->get_utf8
```

If $enable is true (or missing), then the decode method expects to be handled
an UTF-8-encoded string. Please note that UTF-8-encoded strings do not contain any
characters outside the range 0..255, they are thus useful for bytewise/binary I/O.

(In Perl 5.005, any character outside the range 0..255 does not exist.
See to ["UNICODE HANDLING ON PERLS"](#unicode-handling-on-perls).)

In future versions, enabling this option might enable auto-detection of the UTF-16 and UTF-32
encoding families, as described in RFC4627.

If $enable is false, then the decode expects thus a Unicode string. Any decoding
(e.g. to UTF-8 or UTF-16) needs to be done yourself, e.g. using the Encode module.

Example, decode UTF-32LE-encoded JSON5:

```perl
use Encode;
$object = JSON5->new->decode (decode "UTF-32LE", $json5text);
```

## allow\_nonref

```
$json5 = $json5->allow_nonref([$enable])

$enabled = $json5->get_allow_nonref
```

If `$enable` is true (or missing), then the `decode` method will accept a
non-reference into its corresponding string, number or null JSON5 value,
which is an extension to RFC4627.

If `$enable` is false, then the `decode` method will croak if
given something that is not a JSON5 object or array.

## max\_size

```
$json5 = $json5->max_size([$maximum_string_size])

$max_size = $json5->get_max_size
```

Set the maximum length a JSON5 text may have (in bytes) where decoding is
being attempted. The default is `0`, meaning no limit. When `decode`
is called on a string that is longer then this many bytes, it will not
attempt to decode the string but throw an exception.

If no argument is given, the limit check will be deactivated (same as when
`0` is specified).

## decode

```
$perl_scalar = $json5->decode($json5_text)
```

JSON5 numbers and strings become simple Perl scalars. JSON5 arrays become
Perl arrayrefs and JSON5 objects become Perl hashrefs. `true` becomes
`1` (`JSON::PP::true`), `false` becomes `0` (`JSON::PP::false`),
`NaN` becomes `'NaN'`, `Infinity` becomes `'Inf'`, and
`null` becomes `undef`.

# SEE ALSO

[JSON::PP](https://metacpan.org/pod/JSON::PP)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
