use strict;
use Test::More 0.98;
use File::Spec;
use Test::Snapshot;
use lib 't/lib-dbicschema';
use Schema;

use_ok 'GraphQL::Plugin::Convert::DBIC';

my $dbic_class = 'Schema';
my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(
  sub { $dbic_class->connect }
);
my $got = $converted->{schema}->to_doc;
#open my $fh, '>', 'tf'; print $fh $got; # uncomment to regenerate
is_deeply_snapshot $got, 'schema';

done_testing;
