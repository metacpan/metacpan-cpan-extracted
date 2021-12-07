# NAME

JSONSchema::Validator - Validator for JSON Schema Draft4/Draft6/Draft7 and OpenAPI Specification 3.0

# VERSION

version 0.010

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

### Parameters

#### resources

To get schema by uri

#### schema

To get explicitly specified schema

#### specification

To specify specification of schema

#### validate\_schema

Do not validate specified schema

#### base\_uri

To specify base uri of schema.
This parameter used to build absolute path by relative reference in schema.
By default `base_uri` is equal to the resource path if the resource parameter is specified otherwise the `$id` key in the schema.

### Additional parameters

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

# AUTHORS

- Alexey Stavrov <logioniz@ya.ru>
- Ivan Putintsev <uid@rydlab.ru>
- Anton Fedotov <tosha.fedotov.2000@gmail.com>
- Denis Ibaev <dionys@gmail.com>
- Andrey Khozov <andrey@rydlab.ru>

# CONTRIBUTORS

- Erik Huelsmann <ehuels@gmail.com>
- James Waters <james@jcwaters.co.uk>
- uid66 <19481514+uid66@users.noreply.github.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

    The MIT (X11) License
