use strict;
use Test::More 0.98;
use Test::Snapshot;
use GraphQL::Plugin::Convert::MojoPubSub;
use GraphQL::Type::Scalar qw($String);

my $converted = GraphQL::Plugin::Convert::MojoPubSub->to_graphql(
  {
    username => $String->non_null,
    message => $String->non_null,
  }
);
my $got = $converted->{schema}->to_doc;
is_deeply_snapshot $got, 'schema';

done_testing;
