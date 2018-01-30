use strict;
use Test::More 0.98;
use Test::Snapshot;

use_ok 'GraphQL::Plugin::Convert::OpenAPI';

my $converted = GraphQL::Plugin::Convert::OpenAPI->to_graphql(
  't/03-corpus.json'
);
my $got = $converted->{schema}->to_doc;
is_deeply_snapshot $got, 'schema';

done_testing;
