use strict;
use Test::More 0.98;
use File::Spec;
use Test::Snapshot;
use lib 't/lib-schema-employees';
use Schema;
use SQL::Translator;

use_ok 'GraphQL::Plugin::Convert::DBIC';

my $dbic_class = 'Schema';
my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(
  sub { $dbic_class->connect }
);
my $got = $converted->{schema}->to_doc;
is_deeply_snapshot $got, 'schema';

done_testing;
