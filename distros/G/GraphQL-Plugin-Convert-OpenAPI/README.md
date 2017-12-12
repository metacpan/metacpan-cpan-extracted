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

The queries will be run against the spec's server.  If the spec starts
with a `/`, and a [Mojolicious](https://metacpan.org/pod/Mojolicious) app is supplied (see below), that
server will instead be the given app.

# ARGUMENTS

To the `to_graphql` method: a URL to a specification, or a filename
containing a JSON specification, of an OpenAPI v2. Optionally, a
[Mojolicious](https://metacpan.org/pod/Mojolicious) app can be given as the second argument.

# PACKAGE FUNCTIONS

## make\_field\_resolver

This is available as `\&GraphQL::Plugin::Convert::OpenAPI::make_field_resolver`
in case it is wanted for use outside of the "bundle" of the `to_graphql`
method. It takes one argument, a hash-ref mapping from a GraphQL operation
field-name to an `operationId`, and returns a closure that can be used
as a field resolver.

# DEBUGGING

To debug, set environment variable `GRAPHQL_DEBUG` to a true value.

# AUTHOR

Ed J, `<etj at cpan.org>`

Parts based on [https://github.com/yarax/swagger-to-graphql](https://github.com/yarax/swagger-to-graphql)

# LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
