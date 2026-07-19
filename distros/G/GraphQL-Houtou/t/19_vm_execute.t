use strict;
use warnings;
use Test::More;

use lib 'lib';
use GraphQL::Houtou ();
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

BEGIN {
  GraphQL::Houtou::_bootstrap_xs();
}

my $Node = GraphQL::Houtou::Type::Interface->new(
  name => 'VmExecNode',
  fields => {
    id => { type => $String },
  },
  tag_resolver => sub { $_[0]{kind} },
);

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'VmExecUser',
  interfaces => [ $Node ],
  runtime_tag => 'user',
  fields => {
    id => { type => $String },
    name => { type => $String },
  },
);

my $Query = GraphQL::Houtou::Type::Object->new(
  name => 'VmExecQuery',
  fields => {
    viewer => {
      type => $User,
      resolver_mode => 'native',
      resolve => sub { return { id => 'u1', name => 'Alice' } },
    },
    users => {
      type => GraphQL::Houtou::Type::List->new(of => $User),
      resolve => sub { return [ { id => 'u1', name => 'Alice' }, { id => 'u2', name => 'Bob' } ] },
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
    node => {
      type => $Node,
      resolver_mode => 'native',
      resolve => sub { return { kind => 'user', id => 'u3', name => 'Carol' } },
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => $Query,
  types => [ $User, $Node ],
);

subtest 'schema can execute VM-lowered program' => sub {
  my $program = $schema->compile_program('{ viewer { __typename id name } users { __typename id } node { __typename id } }');
  my $result = $schema->build_runtime->execute_program($program);
  is_deeply $result, {
    data => {
      viewer => { __typename => 'VmExecUser', id => 'u1', name => 'Alice' },
      users => [
        { __typename => 'VmExecUser', id => 'u1' },
        { __typename => 'VmExecUser', id => 'u2' },
      ],
      node => { __typename => 'VmExecUser', id => 'u3' },
    },
  }, 'VM executor runs object/list/abstract fields';
};

subtest 'schema helper can compile and execute VM in one call' => sub {
  my $result = $schema->execute('{ viewer { id } }');
  is_deeply $result, {
    data => { viewer => { id => 'u1' } },
  }, 'schema helper executes VM runtime';
};

subtest 'VM descriptor can round-trip and still execute' => sub {
  my $descriptor = $schema->compile_program_descriptor('{ node { id } }');
  my $program = $schema->inflate_program($descriptor);
  my $result = $schema->build_runtime->execute_program($program);
  is_deeply $result, {
    data => { node => { id => 'u3' } },
  }, 'inflated VM program executes abstract child blocks';
};

subtest 'native VM bundle descriptor can execute through schema helper' => sub {
  my $bundle = $schema->compile_native_bundle_descriptor('{ node { id } }');
  my $result = $schema->execute_native_bundle_descriptor($bundle);
  is_deeply $result, {
    data => { node => { id => 'u3' } },
  }, 'native VM bundle executes through runtime slot catalog binding';
};

subtest 'schema helper can compile and execute native VM bundle in one call' => sub {
  my $result = $schema->execute_native('{ viewer { id } }');
  is_deeply $result, {
    data => { viewer => { id => 'u1' } },
  }, 'schema helper executes native VM bundle runtime';
};

subtest 'schema helper can execute native VM runtime with specialized variables' => sub {
  my $result = $schema->execute_native(
    'query Q($name: String = "dora") { greet(name: $name) }',
  );
  is_deeply $result, {
    data => { greet => 'hello dora' },
  }, 'native runtime specializes variable args before native execution';
};

subtest 'schema helper can execute native VM runtime with specialized directives' => sub {
  my $result = $schema->execute_native(
    'query Q($show: Boolean = true) { greet(name: "eve") @include(if: $show) }',
  );
  is_deeply $result, {
    data => { greet => 'hello eve' },
  }, 'native runtime specializes dynamic include guard before native execution';
};

subtest 'schema helper can execute native VM runtime through abstract tag dispatch' => sub {
  my $result = $schema->execute_native('{ node { __typename id } }');
  is_deeply $result, {
    data => { node => { __typename => 'VmExecUser', id => 'u3' } },
  }, 'native runtime keeps abstract tag dispatch on native path';
};

subtest 'XS native bundle handle can execute directly' => sub {
  my $runtime = $schema->build_runtime;
  my $native_runtime = GraphQL::Houtou::XS::VM::load_native_runtime_xs(
    $runtime->to_native_exec_struct
  );
  my $bundle = GraphQL::Houtou::XS::VM::load_native_bundle_xs(
    $schema->compile_native_bundle_descriptor('{ viewer { id name } node { id } }')
  );
  my $result = GraphQL::Houtou::XS::VM::execute_native_bundle_xs(
    $native_runtime,
    $bundle,
  );
  is_deeply $result, {
    data => {
      viewer => { id => 'u1', name => 'Alice' },
      node => { id => 'u3' },
    },
  }, 'direct XS native bundle execution works';
};

done_testing;
