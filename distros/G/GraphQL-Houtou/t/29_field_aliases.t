use strict;
use warnings;

use Test::More;

use GraphQL::Houtou qw(execute execute_native build_native_runtime compile_native_bundle);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  fields => {
    name => { type => $String, resolve => sub { 'alice' } },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      hello => { type => $String, resolve => sub { 'world' } },
      user => { type => $User, resolve => sub { {} } },
      boom => { type => $String, resolve => sub { die "boom\n" } },
    },
  ),
  mutation => GraphQL::Houtou::Type::Object->new(
    name => 'Mutation',
    fields => {
      bump => { type => $String, resolve => sub { 'bumped' } },
    },
  ),
);

subtest 'aliases through top-level execute' => sub {
  my $result = execute($schema, '{ a: hello b: hello }');
  ok !exists $result->{errors}, 'no errors';
  is_deeply $result->{data}, { a => 'world', b => 'world' },
    'both aliases are present as response keys';
};

subtest 'aliases on nested selections' => sub {
  my $result = execute($schema, '{ u: user { n: name name } }');
  ok !exists $result->{errors}, 'no errors';
  is_deeply $result->{data}, { u => { n => 'alice', name => 'alice' } },
    'nested alias and plain field coexist';
};

subtest 'aliases on meta fields' => sub {
  my $result = execute($schema, '
    {
      q: __type(name: "Query") { name }
      t: __typename
    }
  ');
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{q}{name}, 'Query', '__type alias respected';
  is $result->{data}{t}, 'Query', '__typename alias respected';
};

subtest 'aliases through execute_document and program path' => sub {
  my $runtime = build_native_runtime($schema);
  my $r1 = $runtime->execute_document('{ a: hello b: hello }');
  is_deeply $r1->{data}, { a => 'world', b => 'world' }, 'execute_document';

  my $program = $runtime->compile_program('{ a: hello b: hello }');
  my $r2 = $runtime->execute_program($program);
  is_deeply $r2->{data}, { a => 'world', b => 'world' }, 'execute_program';
};

subtest 'aliases through execute_native and bundles' => sub {
  my $r1 = execute_native($schema, '{ a: hello b: hello }');
  is_deeply $r1->{data}, { a => 'world', b => 'world' }, 'execute_native';

  my $runtime = build_native_runtime($schema);
  my $bundle = compile_native_bundle($schema, '{ a: hello b: hello }');
  my $r2 = $runtime->execute_bundle($bundle);
  is_deeply $r2->{data}, { a => 'world', b => 'world' }, 'execute_bundle';
};

subtest 'aliases in serial mutations' => sub {
  my $result = execute($schema, 'mutation { first: bump second: bump }');
  ok !exists $result->{errors}, 'no errors';
  is_deeply $result->{data}, { first => 'bumped', second => 'bumped' },
    'serial mutation aliases respected';
};

subtest 'error paths use the alias as response key' => sub {
  my $result = execute($schema, '{ oops: boom ok: hello }');
  is_deeply $result->{data}, { oops => undef, ok => 'world' },
    'errored field appears under its alias';
  is $result->{errors}[0]{path}[0], 'oops', 'error path uses the alias';
};

subtest 'aliases with async resolvers (Promise::XS)' => sub {
  my $has_promise_xs = eval {
    require Promise::XS;
    require GraphQL::Houtou::Promise::PromiseXS;
    GraphQL::Houtou::Promise::PromiseXS->import(qw(maybe_get_promise_xs));
    1;
  };
  plan skip_all => 'Promise::XS not available' if !$has_promise_xs;

  my $async_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'AliasAsyncQuery',
      fields => {
        hello => {
          type => $String,
          resolve => sub { Promise::XS::resolved('async world') },
        },
        user => {
          type => $User,
          resolve => sub { Promise::XS::resolved({}) },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($async_schema);
  my $result = $runtime->execute_document('{ a: hello b: hello u: user { n: name } }');
  my $resolved = maybe_get_promise_xs($result);
  is_deeply $resolved->{data},
    { a => 'async world', b => 'async world', u => { n => 'alice' } },
    'async aliases respected on scalar and nested object fields';
};

done_testing;
