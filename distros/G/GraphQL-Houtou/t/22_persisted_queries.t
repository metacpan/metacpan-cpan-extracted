use strict;
use warnings;
use Test::More;

use lib 'lib';
use GraphQL::Houtou qw(
  build_native_runtime
  compile_native_bundle
  compile_native_bundle_descriptor
);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $Query = GraphQL::Houtou::Type::Object->new(
  name => 'PersistedQueryTest',
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

subtest 'fixed persisted query can precompile and reuse native bundle' => sub {
  my $runtime = build_native_runtime($schema);
  my %persisted = (
    hello => compile_native_bundle($schema, '{ hello }'),
  );

  my $first = $runtime->execute_bundle($persisted{hello});
  my $second = $runtime->execute_bundle($persisted{hello});

  is_deeply $first, {
    data => { hello => 'world' },
  }, 'precompiled native bundle executes';

  is_deeply $second, $first,
    'same persisted native bundle can be reused across requests';
};

subtest 'bundle descriptor can be used as persisted native artifact' => sub {
  my $runtime = build_native_runtime($schema);
  my %persisted = (
    hello => compile_native_bundle_descriptor($schema, '{ hello }'),
  );

  my $result = $runtime->execute_bundle_descriptor($persisted{hello});

  is_deeply $result, {
    data => { hello => 'world' },
  }, 'compact native descriptor can act as persisted query artifact';
};

subtest 'variable-bearing persisted query should cache lowered program' => sub {
  my $runtime = build_native_runtime($schema);
  my %persisted = (
    greet => $runtime->compile_program(
      'query($name: String){ greet(name: $name) }',
    ),
  );

  my $alice = $runtime->execute_program(
    $persisted{greet},
    variables => { name => 'alice' },
  );
  my $bob = $runtime->execute_program(
    $persisted{greet},
    variables => { name => 'bob' },
  );

  is_deeply $alice, {
    data => { greet => 'hello alice' },
  }, 'lowered program can be reused with first variable set';

  is_deeply $bob, {
    data => { greet => 'hello bob' },
  }, 'lowered program can be reused with second variable set';
};

done_testing;
