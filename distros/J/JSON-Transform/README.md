# NAME

JSON::Transform - arbitrary transformation of JSON-able data

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/json-transform.svg?branch=master)](https://travis-ci.org/mohawk2/json-transform) |

[![CPAN version](https://badge.fury.io/pl/JSON-Transform.svg)](https://metacpan.org/pod/JSON::Transform) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/json-transform/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/json-transform?branch=master)

# SYNOPSIS

    use JSON::Transform qw(parse_transform);
    use JSON::MaybeXS;
    my $transformer = parse_transform(from_file($transformfile));
    to_file($outputfile, encode_json $transformer->(decode_json $json_input));

# DESCRIPTION

Implements a language concisely describing a set of
transformations from an arbitrary JSON-able piece of data, to
another one. The description language uses [JSON Pointer (RFC
6901)](https://tools.ietf.org/html/rfc6901) for addressing. JSON-able
means only strings, booleans, nulls (Perl `undef`), numbers, array-refs,
hash-refs, with no circular references.

A transformation is made up of an output expression, which can be composed
of sub-expressions.

For instance, to transform an array of hashes that each have an `id`
key, to a hash mapping each `id` to its hash:

    # [ { "id": 1, "name": "Alice" }, { "id": 2, "name": "Bob" } ]
    # ->
    "" <@ { "/$K/id":$V#`id` }
    # ->
    # { "1": { "name": "Alice" }, "2": { "name": "Bob" } }

While to do the reverse transformation:

    "" <% [ $V@`id`:$K ]

The identity for an array:

    "" <@ [ $V ]

The identity for an object/hash:

    "" <% { $K:$V }

To get the keys of a hash:

    "" <% [ $K ]

To get how many keys in a hash:

    "" <% $C

To get how many items in an array:

    "" <@ $C

To move from one part of a structure to another:

    "/destination" << "/source"

To copy from one part of a structure to another:

    "/destination" <- "/source"

To do the same with a transformation (assumes `/source` is an array
of hashes):

    "/destination" <- "/source" <@ [ $V@`order`:$K ]

To bind a variable, then replace the whole data structure:

    $defs <- "/definitions"
    "" <- $defs

A slightly complex transformation, using the [jt](https://metacpan.org/pod/jt) script:

    $ cat <<EOF | jt '"" <- "/Time Series (Daily)" <% [ .{ `date`: $K, `close`: $V<"/4. close" } ]'
    {
      "Meta Data": {},
      "Time Series (Daily)": {
        "2018-10-26": { "1. open": "", "4. close": "106.9600" },
        "2018-10-25": { "1. open": "", "4. close": "108.3000" }
      }
    }
    EOF
    # produces:
    [
      {"date":"2018-10-25","close":"108.3000"},
      {"date":"2018-10-26","close":"106.9600"}
    ]

## Expression types

- Object/hash

    These terms are used here interchangeably.

- Array
- String
- Integer
- Float
- Boolean
- Null

## JSON pointers

JSON pointers are surrounded by `""`. JSON pointer syntax gives special
meaning to the `~` character, as well as to `/`. To quote a `~`,
say `~0`. To quote a `/`, say `~1`. Since a `$` has special meaning,
to use a literal one, quote it with a preceding `\`.

The output type of a JSON pointer is whatever the pointed-at value is.

## Transformations

A transformation has a destination, a transformation type operator, and
a source-value expression. The destination can be a variable to bind to,
or a JSON pointer.

If the source-value expression has a JSON-pointer source, then the
destination can be omitted and the JSON-pointer source will be used.

The output type of the source-value expression can be anything.

### Transformation operators

- `<-`

    Copying (including assignment for variable bindings)

- `<<`

    Moving - error if the source-value is other than a bare JSON pointer

## Destination value expressions

These can be either a variable, or a JSON pointer.

### Variables

These are expressed as `$` followed by a lower-case letter, followed
by zero or more letters.

## Source value expressions

These can be either a single value including variables, of any type,
or a mapping expression.

## String value expressions

String value expressions can be surrounded by ``` `` ```. They have the same
quoting rules as in JSON's `"`-surrounded strings, including quoting
of `` ` `` using `\`. Any value inside, including variables, will be
concatenated in the obvious way, and numbers will be coerced into strings
(be careful of locale). Booleans and nulls will be stringified into
`[true]`, `[false]`, `[null]`.

## Literal arrays

These are a single value of type array, expressed as surrounded by `.[]`,
with zero or more comma-separated single values.

## Literal objects/hashes

These are a single value of type object/hash, expressed as surrounded
by `.{}`, with zero or more comma-separated colon pairs (see "Mapping
to an object/hash", below).

## Mapping expressions

A mapping expression has a source-value, a mapping operator, and a
mapping description.

The mapping operator is either `<@`, requiring the source-value
to be of type array, or `<%`, requiring type object/hash. If the
input data pointed at by the source value expression is not the right
type, this is an error.

The mapping description must be surrounded by either `[]` meaning return
type array, or `{}` for object/hash.

The description will be evaluated once for each input value.
Within the brackets, `$K` and `$V` will have special meaning.

For an array input, each input will be each single array value, and `$K`
will be the zero-based array index.

For an object/hash input, each input will be each pair. `$K` will be
the object key being evaluated, of type string.

In either case, `$V` will be the relevant value, of whatever type from
the input. `$C` will be of type integer, being the number of inputs.

### Mapping to an object/hash

The return value will be of type object/hash, composed of a set of pairs,
expressed within `{}` as:

- a expression of type string
- `:`
- an expression of any type

### Mapping to an array

Within `[]`, the value expression will be an arbitrary value expression.

## Single-value modifiers

A single value can have a modifier, followed by arguments.

### `@`

The operand value must be of type object/hash.
The argument must be a pair of string-value, `:`, any-value.
The return value will be the object/hash with that additional key/value pair.

### `#`

The operand value must be of type object/hash.
The argument must be a string-value.
The return value will be the object/hash without that key.

### `<`

The operand value must be of type object/hash or array.
The argument must be a JSON pointer.
The return value will be the value, but having had the JSON pointer applied.

## Available system variables

### `$K`

Available in mapping expressions. For each data pair, set to either the
zero-based index in an array, or the string key of an object/hash.

### `$V`

Available in mapping expressions. For each data pair, set to the value.

### `$C`

Available in mapping expressions. Set to the integer number of values.

## Comments

Any `--` sequence up to the end of that line will be a comment,
and ignored.

# DEBUGGING

To debug, set environment variable `JSON_TRANSFORM_DEBUG` to a true value.

# EXPORT

## parse\_transform

On error, throws an exception. On success, returns a function that can
be called with JSON-able data, that will either throw an exception or
return the transformed data.

Takes arguments:

- $input\_text

    The text describing the transformation.

# SEE ALSO

[Pegex](https://metacpan.org/pod/Pegex)

[RFC 6902 - JSON Patch](https://tools.ietf.org/html/rfc6902) - intended
to change an existing structure, leaving it (largely) the same shape

# AUTHOR

Ed J, `<etj at cpan.org>`

# BUGS

Please report any bugs or feature requests on
[https://github.com/mohawk2/json-transform/issues](https://github.com/mohawk2/json-transform/issues).

Or, if you prefer email and/or RT: to `bug-json-transform
at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-Transform](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-Transform). I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

# LICENSE AND COPYRIGHT

Copyright 2018 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)
