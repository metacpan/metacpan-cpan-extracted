# NAME

JSON::XS::Sugar - sugar for using JSON::XS

# VERSION

version 1.01

# SYNOPSIS

    use JSON::XS qw(encode_json);
    use JSON::XS::Sugar qw(
      JSON_TRUE JSON_FALSE json_truth json_number json_string
    );

    print encode_json({
       towel_location_known => JSON_TRUE,
       panic                => JSON_FALSE,
       wants_tea            => json_truth is_arthur_dent(),
       answer               => json_number "42",
       telephone_number     => json_string 2079460347,
    });

# DESCRIPTION

This module allows you to easily control the output that JSON::XS generates when
it creates JSON.  In particular, it makes it easier to have JSON::XS create
`true` and `false` when you want, and if a scalar should be rendered as a
number or a string.

## Functions

Exported on demand or may be used fully qualified.

- JSON\_TRUE

    A constant that will result in JSON::XS printing out `true`. It's an alias for
    `Types::Serialiser::true`.

- JSON\_FALSE

    A constant that will result in JSON::XS printing out `false`. It's an alias for
    `Types::Serialiser::false`.

- json\_truth $something\_true\_or\_false

    A function that will return a value that will cause JSON::XS to render `true`
    or `false` depending on if the argument passed to it was true or false.

- json\_number $scalar

    A function that will return a value which will cause JSON::XS to render the
    argument as a number.  This can more or less be thought of as syntactic sugar
    for `+0` (but we take extra care to ensure proper handing of very large
    integers.) This function is implemented as rewriting the OP tree to a custom OP,
    so there's no run time performance penalty for using this verses the Perl
    solution.

- json\_string $scalar

    A function that will return a value which will cause JSON::XS to render the
    argument as a string. This is syntactic sugar for `""`.  This function is
    implemented as rewriting the OP tree, so there's no run time performance penalty
    for using this verses the Perl solution.

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/JSON-XS-Sugar-perl/issues](https://github.com/maxmind/JSON-XS-Sugar-perl/issues).

We welcome patches as pull requests against our GitHub repository at
[https://github.com/maxmind/JSON-XS-Sugar-perl](https://github.com/maxmind/JSON-XS-Sugar-perl).

# THANKS

Thanks to Andrew Main (Zefram) for his help with the hairy parts of this
module and providing code to cargo-cult XS from.

# BUGS

`json_number` and `json_string` are designed to be just as forgiving as
`+0` and `""`, meaning that they can be used as drop in replacements for
those constructs.  However, this means that if they're used on things that
aren't numeric or strings respectively then they will coerce just as the
corresponding Perl code would (including emitting warnings in a similar
way if warnings are enabled.)

# SEE ALSO

[JSON::XS](https://metacpan.org/pod/JSON::XS)

# AUTHOR

Mark Fowler <mfowler@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
