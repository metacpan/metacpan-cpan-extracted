# NAME

GraphQL::Plugin::Convert::MojoPubSub - convert a Mojo PubSub server to GraphQL schema

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub.svg?branch=master)](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub) |

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-MojoPubSub.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::MojoPubSub) [![Coverage Status](https://coveralls.io/repos/github/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub/badge.svg?branch=master)](https://coveralls.io/github/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub?branch=master)

# SYNOPSIS

    use GraphQL::Plugin::Convert::MojoPubSub;
    use GraphQL::Type::Scalar qw($String);
    my $pg = Mojo::Pg->new('postgresql://postgres@/test');
    my $converted = GraphQL::Plugin::Convert::MojoPubSub->to_graphql(
      {
        username => $String->non_null,
        message => $String->non_null,
      },
      $pg->pubsub,
    );
    print $converted->{schema}->to_doc;

# DESCRIPTION

This module implements the [GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert) API to convert
a Mojo pub-sub server (currently either [Mojo::Pg::PubSub](https://metacpan.org/pod/Mojo::Pg::PubSub) or
[Mojo::Redis::PubSub](https://metacpan.org/pod/Mojo::Redis::PubSub)) to [GraphQL::Schema](https://metacpan.org/pod/GraphQL::Schema) with publish/subscribe
functionality.

# ARGUMENTS

To the `to_graphql` method:

- a hash-ref of field-names to [GraphQL::Type](https://metacpan.org/pod/GraphQL::Type) objects. These must be
both input and output types, so only scalars or enums. This allows you
to pass in programmatically-created scalars or enums.

    This will be used to construct the `fields` arguments for the
    [GraphQL::Type::InputObject](https://metacpan.org/pod/GraphQL::Type::InputObject) and [GraphQL::Type::Object](https://metacpan.org/pod/GraphQL::Type::Object) which are
    the input and output of the mutation and subscription respectively.

- an object compatible with [Mojo::Redis](https://metacpan.org/pod/Mojo::Redis), with a `pubsub` attribute.

Note the output type will have a `dateTime` field added to it with type
non-null `DateTime`. Both input and output types will have a non-null
`channel` `String` added.

E.g. for this input (implementing a trivial chat system):

    {
      username => $String->non_null,
      message => $String->non_null,
    }

The schema will look like:

    scalar DateTime

    input MessageInput {
      channel: String!
      username: String!
      message: String!
    }

    type Message {
      channel: String!
      username: String!
      message: String!
      dateTime: DateTime!
    }

    type Query {
      status: Boolean!
    }

    type Mutation {
      publish(input: [MessageInput!]!): DateTime!
    }

    type Subscription {
      subscribe(channels: [String!]): Message!
    }

The `subscribe` field takes a list of channels to subscribe to. If the
list is null or empty, all channels will be subscribed to - a "firehose",
implemented as an actual channel named `_firehose`.

# DEBUGGING

To debug, set environment variable `GRAPHQL_DEBUG` to a true value.

# AUTHOR

Ed J, `<etj at cpan.org>`

# LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
