use strict;
use warnings;

use GraphQL::Houtou qw(
  build_native_runtime
  compile_native_bundle
);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $Query = GraphQL::Houtou::Type::Object->new(
  name => 'ExampleQuery',
  fields => {
    hello => {
      type => $String,
      resolver_mode => 'native',
      resolve => sub { return 'world' },
    },
    greet => {
      type => $String,
      resolver_mode => 'native',
      args => {
        name => { type => $String },
      },
      resolve => sub {
        my ($source, $args) = @_;
        return 'hello ' . ($args->{name} || 'nobody');
      },
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(query => $Query);
my $runtime = build_native_runtime($schema);

my %persisted_bundle = (
  hello => compile_native_bundle($schema, '{ hello }'),
);

my %persisted_program = (
  greet => $runtime->compile_program(
    'query($name: String){ greet(name: $name) }',
  ),
);

my $fixed = $runtime->execute_bundle($persisted_bundle{hello});
my $dynamic = $runtime->execute_program(
  $persisted_program{greet},
  variables => { name => 'alice' },
);

use Data::Dumper;
print Dumper({
  fixed   => $fixed,
  dynamic => $dynamic,
});
