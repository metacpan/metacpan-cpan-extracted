# NAME

JSON::Schema::ToJSON - Generate example JSON structures from JSON Schema definitions

# VERSION

0.13

# SYNOPSIS

    use JSON::Schema::ToJSON;

    my $to_json  = JSON::Schema::ToJSON->new(
        example_key => undef, # set to a key to take example from
        max_depth   => 10,    # increase if you have very deep data structures
    );

    my $perl_string_hash_or_arrayref = $to_json->json_schema_to_json(
        schema     => $already_parsed_json_schema,  # either this
        schema_str => '{ "type" : "boolean" }',     # or this
    );

# DESCRIPTION

[JSON::Schema::ToJSON](https://metacpan.org/pod/JSON::Schema::ToJSON) is a class for generating "fake" or "example" JSON data
structures from JSON Schema structures.

# CONSTRUCTOR ARGUMENTS

## example\_key

The key that will be used to find example data for use in the returned structure. In
the case of the following schema:

    {
        "type" : "object",
        "properties" : {
            "id" : {
                "type" : "string",
                "description" : "ID of the payment.",
                "x-example" : "123ABC"
            }
        }
    }

Setting example\_key to `x-example` will make the generator return the content of
the `"x-example"` (123ABC) rather than a random string/int/etc. This is more so
for things like OpenAPI specifications.

You can set this to any key you like, although be careful as you could end up with
invalid data being used (for example an integer field and then using the description
key as the content would not be sensible or valid).

## max\_depth

To prevent deep recursion due to circular references in JSON schemas the module has
a default max depth set to a very conservative level of 10. If you need to go deeper
than this then pass a larger value at object construction.

# METHODS

## json\_schema\_to\_json

    my $perl_string_hash_or_arrayref = $to_json->json_schema_to_json(
        schema     => $already_parsed_json_schema,  # either this
        schema_str => '{ "type" : "boolean" }',     # or this
    );

Returns a randomly generated representative data structure that corresponds to the
passed JSON schema. Can take either an already parsed JSON Schema or the raw JSON
Schema string.

# CAVEATS

Caveats? The implementation is incomplete as using some of the more edge case JSON
schema validation options may not generate representative JSON so they will not
validate against the schema on a round trip. These include:

- additionalItems

    This is ignored

- additionalProperties and patternProperties

    These are also ignored

- dependencies

    This is \*also\* ignored, possible result of invalid JSON if used

- oneOf

    Only the \*first\* schema from the oneOf list will be used (which means
    that the data returned may be invalid against others in the list)

- not

    Currently any not restrictions are ignored as these can be very hand wavy
    but we will try a "best guess" in the case of "not" : { "type" : ... }

In the case of oneOf and not the module will raise a warning to let you know that
potentially invalid JSON has been generated. If you're using this module then you
probably want to avoid oneOf and not in your schemas.

It is also entirely possible to pass a schema that could never be validated, but
will result in a generated structure anyway, example: an integer that has a "minimum"
value of 2, "maximum" value of 4, and must be a "multipleOf" 5 - a nonsensical
combination.

Note that the data generated is completely random, don't expect it to be the same
across runs or calls. The data is also meaningless in terms of what it represents
such that an object property of "name" that is a string will be generated as, for
example, "kj02@#fjs01je#$42wfjs" - The JSON generated is so you have a representative
**structure**, not representative **data**. Set example keys in your schema and then
set the `example_key` in the constructor if you want this to be repeatable and/or
more representative.

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/json-schema-tojson

# AUTHOR

Lee Johnson - `leejo@cpan.org`
