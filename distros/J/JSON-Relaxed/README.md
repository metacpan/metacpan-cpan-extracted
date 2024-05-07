# NAME

![Version](https://img.shields.io/github/v/release/sciurius/perl-JSON-Relaxed)
![GitHub issues](https://img.shields.io/github/issues/sciurius/perl-JSON-Relaxed)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![Language Perl](https://img.shields.io/badge/Language-Perl-blue)

 *Note: This is a fork of the abandoned CPAN version by Miko
O'Sullivan. I forked it for my own purposes. If it is useful for you,
enjoy and participate!*

# Relaxed JSON?

There's been increasing support for the idea of expanding JSON to improve
human-readability.
"Relaxed" JSON (RJSON) is a term that has been used to describe a
JSON-ish format that has some human-friendly features that JSON doesn't.
Most notably, RJSON allows the use of JavaScript-like comments and
eliminates the need to quote all keys and values.
An (official) specification can be found on
[RelaxedJSON.org](https://www.relaxedjson.org).

_Note that by definition every JSON document is also a valid RJSON document._

# SYNOPSIS

    use JSON::Relaxed;

    # Some raw RJSON data.
    my $rjson = <<'RAW_DATA';
    /* Javascript-like comments. */
    {
        // Keys do not require quotes.
        // Single, double and backtick quotes.
        a : 'Larry',
        b : "Curly",
        c : `Phoey`,
        // Simple values do not require quotes.
        d:  unquoted

        // Nested structures.
        e: [
          { a:1, b:2 },
        ],

        // Like Perl, trailing commas are allowed.
        f: "more stuff",
    }
    RAW_DATA

    # Functional parsing.
    my $hash = decode_rjson($rjson);

    # Object-oriented parsing.
    my $parser = JSON::Relaxed->new();
    $hash = $parser->decode($rjson);

# DESCRIPTION

JSON::Relaxed is a lightweight parser and serializer for RJSON.
It is fully compliant to the [RelaxedJSON.org](https://www.relaxedjson.org/specification) specification.

# EXTENSIONS

Extensions can be disabled with the `strict` option.

- Hash keys without values

    JSON::Relaxed supports object keys without a specified value.
    In that case the hash element is simply assigned the undefined value.

    In the following example, a is assigned 1, and b is assigned undef:

        { a:1, b }

- String continuation

    Long strings can be split over multiple lines by putting a backslash
    at the end of the line:

        "this is a " \
        "long string"

    Note that this is different from

        "this is a \
        long string"

    which **embeds** the newline into the string.

- Extended Unicode escapes

    Unicode escapes in strings may contain an arbitrary number of hexadecimal
    digits enclosed in braces:

        \u{1d10e}

    This eliminates the need to use [surrogates](https://unicode.org/faq/utf_bom.html#utf16-2) to obtain the same character:

        \uD834\uDD0E

# SUBROUTINES

## decode\_rjson

    $structure = decode_rjson($data)

`decode_rjson()` is the simple way to parse an RJSON string.
It is exported by default.
`decode_rjson` takes a single parameter, the string to be parsed.

Optionally an additional hash with options can be passed
to change the behaviour of the parser.
See [Object-oriented parsing](https://metacpan.org/pod/JSON::Relaxed#OBJECT-ORIENTED-PARSING)
in JSON::Relaxed::Parser.

    $structure = decode_rjson( $rjson, %options );

# METHODS

## new

To parse using an object, create a `JSON::Relaxed` object:

    $parser = JSON::Relaxed->new();

Then call the parser's `decode` method, passing in the RJSON string:

    $structure = $parser->decode($rjson);

For more details, see [Object-oriented parsing](https://metacpan.org/pod/JSON::Relaxed#OBJECT-ORIENTED-PARSING) in JSON::Relaxed::Parser.

# ERROR HANDLING

If the document cannot be parsed, JSON::Relaxed returns an undefined
value and sets error indicators in $JSON::Relaxed::Parser::err\_id and
$JSON::Relaxed::Parser::err\_msg. For a full list of error codes, see
[JSON::Relaxed::ErrorCodes](https://metacpan.org/pod/JSON::Relaxed::ErrorCodes).

# COMPATIBILITY WITH PRE-0.05 VERSION

The old static method `from_rjson` has been renamed to `decode_rjson`,
to conform to many other modules of this kind.
`from_rjson` is kept as a synonym for `decode_rjson`.

For the same reason, the old parser method `parse` has been renamed to `decode`.
`parse` is kept as a synonym for `decode`.

# AUTHOR

Johan Vromans `jv@cpan.org`

Miko O'Sullivan `miko@idocs.com`, original version.

# SUPPORT

Development of this module takes place on GitHub:
[https://github.com/sciurius/perl-JSON-Relaxed](https://github.com/sciurius/perl-JSON-Relaxed).

You can find documentation for this module with the perldoc command.

    perldoc JSON::Relaxed

Please report any bugs or feature requests using the issue tracker on
GitHub.

# LICENSE

Copyright (c) 2024 by Johan Vromans. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. This software comes with **NO
WARRANTY** of any kind.

Original copyright 2014 by Miko O'Sullivan. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. This software comes with **NO
WARRANTY** of any kind.
