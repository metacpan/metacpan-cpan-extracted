# NAME

HTTP::StructuredFieldValues - Encode and decode HTTP Structured Field Values (RFC 9651) in Perl

# SYNOPSIS

    use HTTP::StructuredFieldValues qw(:all);

    # Encode a Perl data structure into a Structured Field string
    my $dict = {
        foo => { _type => 'integer', value => 42 },
        bar => { _type => 'boolean', value => 1 }
    };
    my $encoded = encode($dict);
    print $encoded;   # foo=42, bar

    # Decode a Structured Field string into a Perl data structure
    my $decoded = decode_dictionary('foo=42, bar');
    print $decoded->{foo}->{value};  # 42

    # Encode a list
    my $list = [
        { _type => 'string', value => 'hello' },
        { _type => 'decimal', value => 3.14 }
    ];
    my $encoded_list = encode($list);

    # Decode a list
    my $decoded_list = decode_list('"hello", 3.14');

    # Decode a single item
    my $item = decode_item('?1');   # boolean true

# DESCRIPTION

This module provides support for encoding and decoding
**Structured Field Values for HTTP** as defined in RFC 9651.

Structured Field Values define well-typed, constrained data structures
for use in HTTP fields, improving interoperability, consistency,
and correctness.

This implementation allows you to round-trip Perl data structures into
well-formed Structured Field Value strings and back again.

This is an alpha release. The API may be subject to change.

# FUNCTIONS

The following functions can be imported individually or via the `:all` tag.

## encode($data)

Encodes a Perl data structure into a valid Structured Field string.
Supported data structures include:

- Dictionary (Perl hash)
- List (Perl array)
- Item (hash with `_type` and `value`)

## decode\_dictionary($string)

Decodes a Structured Field dictionary string into a Perl hash
(tied to `Tie::IxHash` to preserve order).

## decode\_list($string)

Decodes a Structured Field list string into a Perl array reference.

## decode\_item($string)

Decodes a single Structured Field item string into its corresponding
Perl representation.

# DATA MODEL

Each Structured Field Item is represented as a Perl hashref
with the following form:

    {
      _type => 'string' | 'integer' | 'decimal' | 'boolean' |
               'token' | 'binary' | 'date' | 'inner_list' | 'displaystring',
      value => ...,
      params => { optional parameters hash }
    }

Lists are represented as array references, possibly containing such items
or "inner lists". Dictionaries are hash references mapping keys to items.

# ERROR HANDLING

Invalid or malformed Structured Field strings will cause the decoding
functions to `die` with an error message. Similarly, attempts to encode
invalid data (such as invalid tokens, strings with forbidden characters,
or out-of-range numbers) will result in exceptions.

# SEE ALSO

`Tie::IxHash`

# AUTHOR

SHIRAKATA Kentaro <argrath@ub32.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
