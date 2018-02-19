# NAME

GraphQL::Plugin::Convert::OpenAPI - convert OpenAPI schema to GraphQL schema

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-OpenAPI.svg?branch=master)](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-OpenAPI) |

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-OpenAPI.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::OpenAPI)

# SYNOPSIS

    use GraphQL::Plugin::Convert::OpenAPI;
    my $converted = GraphQL::Plugin::Convert::OpenAPI->to_graphql(
      'file-containing-spec.json',
    );
    print $converted->{schema}->to_doc;

# DESCRIPTION

This module implements the [GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert) API to convert
a [JSON::Validator::OpenAPI](https://metacpan.org/pod/JSON::Validator::OpenAPI) specification to [GraphQL::Schema](https://metacpan.org/pod/GraphQL::Schema) etc.

It uses, from the given API spec:

- the given "definitions" as output types
- the given "definitions" as input types when required for an
input parameter
- the given operations as fields of either `Query` if a `GET`,
or `Mutation` otherwise

If an output type has `additionalProperties` (effectively a hash whose
values are of a specified type), this poses a problem for GraphQL which
does not have such a concept. It will be treated as being made up of a
list of pairs of objects (i.e. hashes) with two keys: `key` and `value`.

The queries will be run against the spec's server.  If the spec starts
with a `/`, and a [Mojolicious](https://metacpan.org/pod/Mojolicious) app is supplied (see below), that
server will instead be the given app.

# ARGUMENTS

To the `to_graphql` method: a URL to a specification, or a filename
containing a JSON specification, or a data structure, of an OpenAPI v2.

Optionally, a [Mojolicious](https://metacpan.org/pod/Mojolicious) app can be given as the second argument. In
this case, with a [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious::Lite) app, do:

    my $api = plugin OpenAPI => {spec => 'data://main/api.yaml'};
    plugin(GraphQL => {convert => [ 'OpenAPI', $api->validator->bundle, app ]});

with the usual mapping in the case of a full app. For this to work you
need [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI) version 1.25+, which returns itself
on `register`.

# PACKAGE FUNCTIONS

## make\_field\_resolver

This is available as `\&GraphQL::Plugin::Convert::OpenAPI::make_field_resolver`
in case it is wanted for use outside of the "bundle" of the `to_graphql`
method. It takes arguments:

- a hash-ref mapping from a GraphQL type-name to another hash-ref with
information about that type. There are addition pseudo-types with stored
information, named eg `TypeName.fieldName`, for the obvious
purpose. The use of `.` avoids clashing with real types. This will only
have information about input types.

    Valid keys:

    - is\_hashpair

        True value if that type needs transforming from a hash into pairs.

    - field2operationId

        Hash-ref mapping from a GraphQL operation field-name (which will
        only be done on the `Query` or `Mutation` types, for obvious reasons)
        to an `operationId`.

    - field2type

        Hash-ref mapping from a GraphQL type's field-name to hash-ref mapping
        its arguments, if any, to the corresponding GraphQL type-name.

    - field2prop

        Hash-ref mapping from a GraphQL type's field-name to the corresponding
        OpenAPI property-name.

    - is\_enum

        Boolean value indicating whether the type is a [GraphQL::Type::Enum](https://metacpan.org/pod/GraphQL::Type::Enum).

and returns a closure that can be used as a field resolver.

# DEBUGGING

To debug, set environment variable `GRAPHQL_DEBUG` to a true value.

# AUTHOR

Ed J, `<etj at cpan.org>`

Parts based on [https://github.com/yarax/swagger-to-graphql](https://github.com/yarax/swagger-to-graphql)

# LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
