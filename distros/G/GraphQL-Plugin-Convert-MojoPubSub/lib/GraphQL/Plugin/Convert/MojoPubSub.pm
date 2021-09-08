package GraphQL::Plugin::Convert::MojoPubSub;
use strict;
use warnings;
use GraphQL::Schema;
use GraphQL::Plugin::Type::DateTime;
use GraphQL::Debug qw(_debug);
use DateTime;
use GraphQL::Type::Scalar qw($Boolean $String);
use GraphQL::Type::Object;
use GraphQL::Type::InputObject;
use GraphQL::AsyncIterator;

our $VERSION = "0.02";
use constant DEBUG => $ENV{GRAPHQL_DEBUG};
use constant FIREHOSE => '_firehose';

my ($DateTime) = grep $_->name eq 'DateTime', GraphQL::Plugin::Type->registered;

sub field_resolver {
  my ($root_value, $args, $context, $info) = @_;
  my $field_name = $info->{field_name};
  my $parent_type = $info->{parent_type}->to_string;
  my $property = ref($root_value) eq 'HASH'
    ? $root_value->{$field_name}
    : $root_value;
  DEBUG and _debug('MojoPubSub.resolver', $field_name, $parent_type, $args, $property, ref($root_value) eq 'HASH' ? $root_value : ());
  my $result = eval {
    return $property->($args, $context, $info) if ref $property eq 'CODE';
    return $property if ref $root_value eq 'HASH';
    if ($parent_type eq 'Query' and $field_name eq 'status') {
      # semi-fake "status" because can't have empty query
      return 1;
    }
    die "Unknown field '$field_name'\n"
      unless $parent_type eq 'Mutation' and $field_name eq 'publish';
    my $now = DateTime->now;
    my @input = @{ $args->{input} || [] };
    DEBUG and _debug('MojoPubSub.resolver(input)', @input);
    for my $msg (@input) {
      # regrettably blocking, until both have a notify_p
      $msg = { dateTime => $now, %$msg };
      $root_value->pubsub->json($_)->notify($_, $msg) for $msg->{channel}, FIREHOSE;
    }
    $now;
  };
  die $@ if $@;
  $result;
}

sub subscribe_resolver {
  my ($root_value, $args, $context, $info) = @_;
  my @channels = @{ $args->{channels} || [] };
  @channels = (FIREHOSE) if !@channels;
  my $ai = GraphQL::AsyncIterator->new(promise_code => $info->{promise_code});
  my $field_name = $info->{field_name};
  DEBUG and _debug('MojoPubSub.s_r', $args, \@channels);
  my $cb;
  my @subscriptions;
  $cb = sub {
    my ($pubsub, $msg) = @_;
    DEBUG and _debug('MojoPubSub.cb', $msg, \@channels);
    eval { $ai->publish({ $field_name => $msg }) };
    DEBUG and _debug('MojoPubSub.cb2', $@);
    return if !$@;
    $root_value->pubsub->unlisten(@$_) for @subscriptions;
  };
  @subscriptions = map [ $_, $root_value->pubsub->listen($_ => $cb) ], @channels;
  $ai;
}

sub to_graphql {
  my ($class, $fieldspec, $root_value) = @_;
  $fieldspec = { map +($_ => { type => $fieldspec->{$_} }), keys %$fieldspec };
  my $input_fields = {
    channel => { type => $String->non_null },
    %$fieldspec,
  };
  DEBUG and _debug('MojoPubSub.input', $input_fields);
  my $output_fields = {
    channel => { type => $String->non_null },
    dateTime => { type => $DateTime->non_null },
    %$fieldspec,
  };
  DEBUG and _debug('MojoPubSub.output', $output_fields);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => { status => { type => $Boolean->non_null } },
    ),
    mutation => GraphQL::Type::Object->new(
      name => 'Mutation',
      fields => { publish => {
        type => $DateTime->non_null,
        args => { input => { type => GraphQL::Type::InputObject->new(
          name => 'MessageInput',
          fields => $input_fields,
        )->non_null->list->non_null } },
      } },
    ),
    subscription => GraphQL::Type::Object->new(
      name => 'Subscription',
      fields => { subscribe => {
        type => GraphQL::Type::Object->new(
          name => 'Message',
          fields => $output_fields,
        )->non_null,
        args => { channels => { type => $String->non_null->list } },
      } },
    ),
  );
  +{
    schema => $schema,
    root_value => $root_value,
    resolver => \&field_resolver,
    subscribe_resolver => \&subscribe_resolver,
  };
}

=encoding utf-8

=head1 NAME

GraphQL::Plugin::Convert::MojoPubSub - convert a Mojo PubSub server to GraphQL schema

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub.svg?branch=master)](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub) |

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-MojoPubSub.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::MojoPubSub) [![Coverage Status](https://coveralls.io/repos/github/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub/badge.svg?branch=master)](https://coveralls.io/github/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub?branch=master)

=end markdown

=head1 SYNOPSIS

  use GraphQL::Plugin::Convert::MojoPubSub;
  use GraphQL::Type::Scalar qw($String);
  my $pg = Mojo::Pg->new('postgresql://postgres@/test');
  my $converted = GraphQL::Plugin::Convert::MojoPubSub->to_graphql(
    {
      username => $String->non_null,
      message => $String->non_null,
    },
    $pg,
  );
  print $converted->{schema}->to_doc;

=head1 DESCRIPTION

This module implements the L<GraphQL::Plugin::Convert> API to convert
a Mojo pub-sub server (currently either L<Mojo::Pg::PubSub> or
L<Mojo::Redis::PubSub>) to L<GraphQL::Schema> with publish/subscribe
functionality.

=head1 ARGUMENTS

To the C<to_graphql> method:

=over

=item *

a hash-ref of field-names to L<GraphQL::Type> objects. These must be
both input and output types, so only scalars or enums. This allows you
to pass in programmatically-created scalars or enums.

This will be used to construct the C<fields> arguments for the
L<GraphQL::Type::InputObject> and L<GraphQL::Type::Object> which are
the input and output of the mutation and subscription respectively.

=item *

an object compatible with L<Mojo::Redis>, with a C<pubsub> attribute.

=back

Note the output type will have a C<dateTime> field added to it with type
non-null C<DateTime>. Both input and output types will have a non-null
C<channel> C<String> added.

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

The C<subscribe> field takes a list of channels to subscribe to. If the
list is null or empty, all channels will be subscribed to - a "firehose",
implemented as an actual channel named C<_firehose>.

=head1 DEBUGGING

To debug, set environment variable C<GRAPHQL_DEBUG> to a true value.

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
