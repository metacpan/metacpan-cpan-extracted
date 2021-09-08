# NAME

GraphQL::Plugin::Convert::DBIC - convert DBIx::Class schema to GraphQL schema

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-DBIC.svg?branch=master)](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-DBIC) |

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-DBIC.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::DBIC)

# SYNOPSIS

    use GraphQL::Plugin::Convert::DBIC;
    use My::Local::Schema;
    my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(My::Local::Schema->connect);
    print $converted->{schema}->to_doc;

# DESCRIPTION

This module implements the [GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL%3A%3APlugin%3A%3AConvert) API to convert
a [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) to [GraphQL::Schema](https://metacpan.org/pod/GraphQL%3A%3ASchema) etc.

Its `Query` type represents a guess at what fields are suitable, based
on providing a lookup for each type (a [DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSource)).

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

These [GraphQL::Type::Object](https://metacpan.org/pod/GraphQL%3A%3AType%3A%3AObject) types will be generated:

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
delete is to be ignored. These input types are split into one input
for the primary keys, which is a full input type to allow for multiple
primary keys, then a wrapper input for updates, that takes one ID input,
and a payload that due to the same requirements, is just the search input.

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

    input BlogIDInput {
      id: Int!
    }

    input BlogUpdateInput {
      id: BlogIDInput!
      payload: BlogSearchInput!
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

    input ArticleIDInput {
      id: Int!
    }

    input ArticleUpdateInput {
      id: ArticleIDInput!
      payload: ArticleSearchInput!
    }

    type Mutation {
      createBlog(input: [BlogCreateInput!]!): [Blog]
      createArticle(input: [ArticleCreateInput!]!): [Article]
      deleteBlog(input: [BlogIDInput!]!): [Boolean]
      deleteArticle(input: [ArticleIDInput!]!): [Boolean]
      updateBlog(input: [BlogUpdateInput!]!): [Blog]
      updateArticle(input: [ArticleUpdateInput!]!): [Article]
    }

    extends type Query {
      searchBlog(input: BlogSearchInput!): [Blog]
      searchArticle(input: ArticleSearchInput!): [Article]
    }

# ARGUMENTS

To the `to_graphql` method: a  [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) object.

# PACKAGE FUNCTIONS

## field\_resolver

This is available as `\&GraphQL::Plugin::Convert::DBIC::field_resolver`
in case it is wanted for use outside of the "bundle" of the `to_graphql`
method.

# DEBUGGING

To debug, set environment variable `GRAPHQL_DEBUG` to a true value.

# AUTHOR

Ed J, `<etj at cpan.org>`

# LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
