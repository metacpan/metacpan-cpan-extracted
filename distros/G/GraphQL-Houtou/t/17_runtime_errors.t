use strict;
use warnings;

use Test::More 0.98;

use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $Node;

# interfaces is lazy so User can implement the Node declared below it;
# without the declaration `... on User` inside a Node selection would be
# rejected by request validation before resolve_type ever runs.
my $User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  interfaces => sub { [ $Node ] },
  fields => {
    id => { type => $String->non_null },
    brokenName => {
      type => $String,
      resolve => sub { die "broken field\n" },
    },
  },
);

$Node = GraphQL::Houtou::Type::Interface->new(
  name => 'Node',
  fields => {
    id => { type => $String->non_null },
  },
  resolve_type => sub { die "resolve_type exploded\n" },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      viewer => {
        type => $User,
        resolve => sub { +{ id => 'u1' } },
      },
      node => {
        type => $Node,
        resolve => sub { +{ id => 'u1' } },
      },
    },
  ),
  types => [ $User, $Node ],
);

subtest 'resolver errors are materialized lazily with path' => sub {
  my $result = $schema->execute('{ viewer { id brokenName } }');

  is_deeply $result, {
    data => {
      viewer => {
        id => 'u1',
        brokenName => undef,
      },
    },
    errors => [
      {
        message => 'broken field',
        path => [ 'viewer', 'brokenName' ],
      },
    ],
  }, 'field resolver exception is reported with nested path';
};

subtest 'abstract resolution errors are materialized lazily with path' => sub {
  my $result = $schema->execute('{ node { ... on User { id } } }');

  is_deeply $result, {
    data => {
      node => undef,
    },
    errors => [
      {
        message => 'resolve_type exploded',
        path => [ 'node' ],
      },
    ],
  }, 'abstract resolve_type exception is reported with field path';
};

done_testing;
