# NAME

GraphQL::Plugin::Convert::OpenAPI - convert OpenAPI schema to GraphQL schema

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-OpenAPI.svg?branch=master)](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-OpenAPI) |

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-OpenAPI.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::OpenAPI)

# SYNOPSIS

    use GraphQL::Plugin::Convert::OpenAPI;
    use Schema;
    my $converted = GraphQL::Plugin::Convert::OpenAPI->to_graphql(
      sub { Schema->connect }
    );
    print $converted->{schema}->to_doc;

# DESCRIPTION

This module implements the [GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert) API to convert
a [JSON::Validator::OpenAPI](https://metacpan.org/pod/JSON::Validator::OpenAPI) to [GraphQL::Schema](https://metacpan.org/pod/GraphQL::Schema) etc.

## Example

Consider this minimal data model:

    blog:
      id # primary key
      articles # has_many
      title # non null
      language # nullable
    article:
      id # primary key
      blog # foreign key to Blog
      title # non null
      content # nullable

## Generated Output Types

These [GraphQL::Type::Object](https://metacpan.org/pod/GraphQL::Type::Object) types will be generated:

    type Blog {
      id: Int!
      articles: [Article]
      title: String!
      language: String
    }

    type Article {
      id: Int!
      blog: Blog
      title: String!
      content: String
    }

    type Query {
      blog(id: [Int!]!): [Blog]
      article(id: [Int!]!): [Blog]
    }

Note that while the queries take a list, the return order is
undefined. This also applies to the mutations. If this matters, request
the primary key fields and use those to sort.

## Generated Input Types

Different input types are needed for each of CRUD (Create, Read, Update,
Delete).

The create one needs to have non-null fields be non-null, for idiomatic
GraphQL-level error-catching. The read one needs all fields nullable,
since this will be how searches are implemented, allowing fields to be
left un-searched-for. Both need to omit primary key fields. The read
one also needs to omit foreign key fields, since the idiomatic GraphQL
way for this is to request the other object, with this as a field on it,
then request any required fields of this.

Meanwhile, the update and delete ones need to include the primary key
fields, to indicate what to mutate, and also all non-primary key fields
as nullable, which for update will mean leaving them unchanged, and for
delete is to be ignored.

Therefore, for the above, these input types (and an updated Query,
and Mutation) are created:

    input BlogCreateInput {
      title: String!
      language: String
    }

    input BlogSearchInput {
      title: String
      language: String
    }

    input BlogMutateInput {
      id: Int!
      title: String
      language: String
    }

    input ArticleCreateInput {
      blog_id: Int!
      title: String!
      content: String
    }

    input ArticleSearchInput {
      title: String
      content: String
    }

    input ArticleMutateInput {
      id: Int!
      title: String!
      language: String
    }

    type Mutation {
      createBlog(input: [BlogCreateInput!]!): [Blog]
      createArticle(input: [ArticleCreateInput!]!): [Article]
      deleteBlog(input: [BlogMutateInput!]!): [Boolean]
      deleteArticle(input: [ArticleMutateInput!]!): [Boolean]
      updateBlog(input: [BlogMutateInput!]!): [Blog]
      updateArticle(input: [ArticleMutateInput!]!): [Article]
    }

    extends type Query {
      searchBlog(input: BlogSearchInput!): [Blog]
      searchArticle(input: ArticleSearchInput!): [Article]
    }

# ARGUMENTS

To the `to_graphql` method: a code-ref returning a [DBIx::Class::Schema](https://metacpan.org/pod/DBIx::Class::Schema)
object. This is so it can be called during the conversion process,
but also during execution of a long-running process to e.g. execute
database queries, when the database handle passed to this method as a
simple value might have expired.

# PACKAGE FUNCTIONS

## field\_resolver

This is available as `\&GraphQL::Plugin::Convert::OpenAPI::field_resolver`
in case it is wanted for use outside of the "bundle" of the `to_graphql`
method.

# DEBUGGING

To debug, set environment variable `GRAPHQL_DEBUG` to a true value.

# AUTHOR

Ed J, `<etj at cpan.org>`

Parts based on [https://github.com/yarax/swagger-to-graphql](https://github.com/yarax/swagger-to-graphql)

# LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
