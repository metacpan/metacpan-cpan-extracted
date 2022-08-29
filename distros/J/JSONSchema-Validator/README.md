# NAME

JSONSchema::Validator - Validator for JSON Schema Draft4/Draft6/Draft7 and OpenAPI Specification 3.0

# VERSION

version 0.011

# SYNOPSIS

    # to get OpenAPI validator in YAML format
    $validator = JSONSchema::Validator->new(resource => 'file:///some/path/to/oas30.yml');
    my ($result, $errors, $warnings) = $validator->validate_request(
        method => 'GET',
        openapi_path => '/user/{id}/profile',
        parameters => {
            path => {
                id => 1234
            },
            query => {
                details => 'short'
            },
            header => {
                header => 'header value'
            },
            cookie => {
                name => 'value'
            },
            body => [$is_exists, $content_type, $data]
        }
    );
    my ($result, $errors, $warnings) = $validator->validate_response(
        method => 'GET',
        openapi_path => '/user/{id}/profile',
        status => '200',
        parameters => {
            header => {
                header => 'header value'
            },
            body => [$is_exists, $content_type, $data]
        }
    )

    # to get JSON Schema Draft4/Draft6/Draft7 validator in JSON format
    $validator = JSONSchema::Validator->new(resource => 'http://example.com/draft4/schema.json')
    my ($result, $errors) = $validator->validate_schema($object_to_validate)

# DESCRIPTION

OpenAPI specification and JSON Schema Draft4/Draft6/Draft7 validators with minimum dependencies.

# METHODS

## new

Creates one of the following validators: JSONSchema::Validator::Draft4, JSONSchema::Validator::Draft6, JSONSchema::Validator::Draft7, JSONSchema::Validator::OAS30.

    my $validator = JSONSchema::Validator->new(resource => 'file:///some/path/to/oas30.yml');
    my $validator = JSONSchema::Validator->new(resource => 'http://example.com/draft4/schema.json');
    my $validator = JSONSchema::Validator->new(schema => {'$schema' => 'path/to/schema', ...});
    my $validator = JSONSchema::Validator->new(schema => {...}, specification => 'Draft4');

if parameter `specification` is not specified then type of validator will be determined by `$schema` key
for JSON Schema Draft4/Draft6/Draft7 and by `openapi` key for OpenAPI Specification 3.0 in `schema` parameter.

Parameters:

- resources

    To get schema by uri

- schema

    To get explicitly specified schema

- specification

    To specify specification of schema

- validate\_schema

    Do not validate specified schema

- base\_uri

    To specify base uri of schema.
    This parameter used to build absolute path by relative reference in schema.
    By default `base_uri` is equal to the resource path if the resource parameter is specified otherwise the `$id` key in the schema.

Additional parameters need to be looked at in a specific validator class.
Currently there are validators: JSONSchema::Validator::Draft4, JSONSchema::Validator::Draft6, JSONSchema::Validator::Draft7, JSONSchema::Validator::OAS30.

## validate\_paths

Validates all files specified by path globs.

    my $result = JSONSchema::Validator->validate_paths(['/some/path/to/openapi.*.yaml', '/some/path/to/jsonschema.*.json']);
    for my $file (keys %$result) {
        my ($res, $errors) = @{$result->{$file}};
    }

## validate\_resource

## validate\_resource\_schema

# CAVEATS

## YAML & booleans

When reading schema definitions from YAML, please note that the standard
behaviour of [YAML::PP](https://metacpan.org/pod/YAML%3A%3APP) and [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS) is to read values which evaluate
to `true` or `false` in a perl context. These values have no recognizable
'boolean type'. This is insufficient for JSON schema validation.

To make the YAML readers and booleans work with `JSONSchema::Validator`,
you need to use the `JSON::PP` (included in Perl's standard library) module
as follows:

    # for YAML::PP
    use YAML::PP;

    my $reader = YAML::PP->new( boolean => 'JSON::PP' );
    # from here, you can freely use the reader to
    # read & write booleans as 'true' and 'false'


    # for YAML::XS
    use YAML::XS;

    my $reader = YAML::XS->new;

    # and whenever you read YAML with this reader, do:
    my $yaml = do {
      local $YAML::XS::Boolean = 'JSON::PP';
      $reader->Load($string); # or $reader->LoadFile('filename');
    };

This isn't a problem when you use the `resource` argument to the
`JSONSchema::Validator::new` constructor, but if you read your own
schema and use the `schema` argument, this is something to be aware of.

## allow\_bignum => 1

The `allow_bignum =` 1> setting (available on [JSON::XS](https://metacpan.org/pod/JSON%3A%3AXS) and
[Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel%3A%3AJSON%3A%3AXS)) on deserializers is not supported.

When deserializing a request body with a JSON parser configured with
`allow_bignum =` 1>, floats - even ones which fit into the regular
float ranges - will be deserialized as `Math::BigFloat`. Similarly,
integers outside of the internal integer range are deserialized as
`Math::BigInt`. Numbers represented as `Math::Big*` objects are not
recognized as actual numbers and will fail validation.

# AUTHORS

- Alexey Stavrov <logioniz@ya.ru>
- Ivan Putintsev <uid@rydlab.ru>
- Anton Fedotov <tosha.fedotov.2000@gmail.com>
- Denis Ibaev <dionys@gmail.com>
- Andrey Khozov <andrey@rydlab.ru>

# CONTRIBUTORS

- Erik Huelsmann <ehuels@gmail.com>
- James Waters <james@jcwaters.co.uk>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

    The MIT (X11) License
