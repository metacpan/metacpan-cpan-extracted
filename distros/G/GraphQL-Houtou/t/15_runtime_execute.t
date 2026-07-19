use strict;
use warnings;

use JSON::MaybeXS ();
use Test::More 0.98;

use GraphQL::Houtou ();
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Runtime::SchemaGraph ();
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Scalar qw($Int $String);
use GraphQL::Houtou::Type::Union;

BEGIN {
  GraphQL::Houtou::_bootstrap_xs();
}

my $ProfileInput = GraphQL::Houtou::Type::InputObject->new(
  name => 'ProfileInput',
  fields => {
    name => { type => $String->non_null },
    age => { type => $Int, default_value => 20 },
  },
);

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  runtime_tag => 'user',
  fields => {
    id => { type => $String->non_null },
    name => { type => $String },
  },
);

my $Node = GraphQL::Houtou::Type::Interface->new(
  name => 'Node',
  fields => {
    id => { type => $String->non_null },
  },
  tag_resolver => sub { $_[0]{kind} },
);

my $SearchResult = GraphQL::Houtou::Type::Union->new(
  name => 'SearchResult',
  types => [ $User ],
  tag_resolver => sub { $_[0]{kind} },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      hello => { type => $String },
      viewer => {
        type => $User,
        resolve => sub { +{ id => 'u1', name => 'Ana' } },
      },
      users => {
        type => $User->list,
        resolve => sub { [ +{ id => 'u1', name => 'Ana' }, +{ id => 'u2', name => 'Bob' } ] },
      },
      greet => {
        type => $String,
        resolver_mode => 'native',
        args => {
          name => { type => $String },
        },
        resolve => sub {
          my ($source, $args) = @_;
          return "hello $args->{name}";
        },
      },
      addOne => {
        type => $Int,
        resolver_mode => 'native',
        args => {
          value => { type => $Int->non_null },
        },
        resolve => sub {
          my ($source, $args) = @_;
          return $args->{value} + 1;
        },
      },
      describeProfile => {
        type => $String,
        resolver_mode => 'native',
        args => {
          profile => { type => $ProfileInput->non_null },
        },
        resolve => sub {
          my ($source, $args) = @_;
          return join q(:), $args->{profile}{name}, $args->{profile}{age};
        },
      },
      search => {
        type => $SearchResult,
        resolve => sub { +{ kind => 'user', id => 'u3', name => 'Cara' } },
      },
    },
  ),
  types => [ $User, $Node, $SearchResult, $ProfileInput ],
);

subtest 'schema can execute runtime program' => sub {
  my $runtime = $schema->build_runtime;
  my $program = $runtime->compile_program('{ viewer { __typename id name } users { __typename id } }');
  my $result = $runtime->execute_program($program);

  is_deeply $result, {
    data => {
      viewer => { __typename => 'User', id => 'u1', name => 'Ana' },
      users => [
        { __typename => 'User', id => 'u1' },
        { __typename => 'User', id => 'u2' },
      ],
    },
  }, 'runtime executes object/list program';
};

subtest 'runtime execute_program uses native execution by default' => sub {
  my $runtime = $schema->build_runtime;
  my $program = $runtime->compile_program('{ viewer { id } }');
  my $result = $runtime->execute_program($program);

  is_deeply $result, {
    data => {
      viewer => { id => 'u1' },
    },
  }, 'default execute_program path stays on native runtime';
};

subtest 'native resolver mode lets explicit resolver use native runtime' => sub {
  my $native_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'NativeResolverQuery',
      fields => {
        nativeHello => {
          type => $String,
          resolver_mode => 'native',
          resolve => sub { return 'native-hi' },
        },
      },
    ),
  );

  my $result = $native_schema->execute('{ nativeHello }');
  is_deeply $result, {
    data => {
      nativeHello => 'native-hi',
    },
  }, 'native-safe explicit resolver still executes correctly on the auto-detect path';
};

subtest 'native resolver mode supports static literal args on native runtime' => sub {
  my $native_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'NativeArgsQuery',
      fields => {
        nativeGreet => {
          type => $String,
          resolver_mode => 'native',
          args => {
            name => { type => $String },
          },
          resolve => sub {
            my ($source, $args) = @_;
            return "hi $args->{name}";
          },
        },
      },
    ),
  );

  my $result = $native_schema->execute('{ nativeGreet(name: "vm") }');
  is_deeply $result, {
    data => {
      nativeGreet => 'hi vm',
    },
  }, 'auto-detect path passes static args to explicit resolver';
};

subtest 'native runtime specializes variable args before bundle execution' => sub {
  my $result = $schema->execute(
    'query Q($name: String = "Bob") { greet(name: $name) }',
  );
  is_deeply $result, {
    data => {
      greet => 'hello Bob',
    },
  }, 'auto-detect path materializes variable args before execution';
};

subtest 'native runtime specializes directive guards before bundle execution' => sub {
  my $result = $schema->execute(
    'query Q($show: Boolean = true) { greet(name: "Ana") @include(if: $show) }',
  );
  is_deeply $result, {
    data => {
      greet => 'hello Ana',
    },
  }, 'auto-detect path prunes dynamic include guard before execution';
};

subtest 'runtime keeps __typename on abstract/object corridors' => sub {
  my $result = $schema->execute('{ search { __typename ... on User { id name } } }');
  is_deeply $result, {
    data => {
      search => {
        __typename => 'User',
        id => 'u3',
        name => 'Cara',
      },
    },
  }, '__typename survives runtime abstract/object execution';
};

subtest 'native runtime preserves static arg coercion and defaults' => sub {
  my $result = $schema->execute(
    '{ describeProfile(profile: { name: "Ana" }) }',
  );
  is_deeply $result, {
    data => {
      describeProfile => 'Ana:20',
    },
  }, 'auto-detect path sees coerced static args with input defaults applied';
};

subtest 'cached runtime program can execute on native runtime with request variables' => sub {
  my $runtime = $schema->build_runtime;
  my $program = $runtime->compile_program(
    'query Q($name: String = "Bob") { greet(name: $name) }',
  );

  my $called = 0;
  my $orig = \&GraphQL::Houtou::XS::VM::execute_native_program_handle_xs;
  my $result;
  {
    no warnings 'redefine';
    local *GraphQL::Houtou::XS::VM::execute_native_program_handle_xs = sub {
      $called = 1;
      goto &$orig;
    };
    $result = $runtime->execute_program(
      $program,
      strict_sync => 1,
      variables => { name => 'cached' },
    );
  }

  is_deeply $result, {
    data => {
      greet => 'hello cached',
    },
  }, 'cached program uses request-time specialization before native execution';
  ok $called, 'cached runtime/program still reached native execution';
};

subtest 'inflated runtime descriptor can still drive native specialization' => sub {
  my $runtime = $schema->build_runtime;
  my $inflated = GraphQL::Houtou::Runtime::SchemaGraph->inflate_schema($schema, $runtime->to_struct);
  my $program = $inflated->compile_program(
    'query Q($show: Boolean = true) { greet(name: "Ana") @include(if: $show) }',
  );

  my $called = 0;
  my $orig = \&GraphQL::Houtou::XS::VM::execute_native_program_handle_xs;
  my $result;
  {
    no warnings 'redefine';
    local *GraphQL::Houtou::XS::VM::execute_native_program_handle_xs = sub {
      $called = 1;
      goto &$orig;
    };
    $result = $inflated->execute_program($program, strict_sync => 1);
  }

  is_deeply $result, {
    data => {
      greet => 'hello Ana',
    },
  }, 'inflated runtime still specializes directive guards before native execution';
  ok $called, 'inflated runtime also uses native execution';
};

subtest 'schema helper can compile and execute in one call' => sub {
  my $result = $schema->execute('{ viewer { id } }');
  is_deeply $result, {
    data => {
      viewer => { id => 'u1' },
    },
  }, 'schema helper executes runtime program';
};

subtest 'default resolver path reads root hash values' => sub {
  my $result = $schema->execute('{ hello }', root_value => { hello => 'world' });
  is_deeply $result, {
    data => {
      hello => 'world',
    },
  }, 'default resolver path works in runtime program';
};

subtest 'abstract fields dispatch through lowered child blocks' => sub {
  my $result = $schema->execute('{ search { ... on User { id name } } }');
  is_deeply $result, {
    data => {
      search => {
        id => 'u3',
        name => 'Cara',
      },
    },
  }, 'abstract field resolves through runtime tag dispatch';
};

subtest 'static literal args are executed through lowered payloads' => sub {
  my $result = $schema->execute('{ greet(name: "Ana") }');
  is_deeply $result, {
    data => {
      greet => 'hello Ana',
    },
  }, 'static args are passed to resolver';
};

subtest 'variable args are materialized at execution time' => sub {
  my $result = $schema->execute(
    'query Q($name: String) { greet(name: $name) }',
    variables => { name => 'Bob' },
  );
  is_deeply $result, {
    data => {
      greet => 'hello Bob',
    },
  }, 'dynamic args are passed to resolver';
};

subtest 'variable defaults are materialized from lowered program metadata' => sub {
  my $result = $schema->execute(
    'query Q($name: String = "Ana") { greet(name: $name) }',
  );
  is_deeply $result, {
    data => {
      greet => 'hello Ana',
    },
  }, 'variable defaults flow through execution program metadata';
};

subtest 'variable values are coerced through lowered variable defs' => sub {
  my $result = $schema->execute(
    'query Q($value: Int!) { addOne(value: $value) }',
    variables => { value => '41' },
  );
  is_deeply $result, {
    data => {
      addOne => 42,
    },
  }, 'variable coercion uses graphql_to_perl';
};

subtest 'argument values are coerced through lowered arg defs' => sub {
  my $result = $schema->execute(
    '{ describeProfile(profile: { name: "Ana" }) }',
  );
  is_deeply $result, {
    data => {
      describeProfile => 'Ana:20',
    },
  }, 'static arg coercion uses input defaults';
};

subtest 'dynamic argument values are coerced through lowered arg defs' => sub {
  my $result = $schema->execute(
    'query Q($profile: ProfileInput!) { describeProfile(profile: $profile) }',
    variables => { profile => { name => 'Bob' } },
  );
  is_deeply $result, {
    data => {
      describeProfile => 'Bob:20',
    },
  }, 'dynamic arg coercion uses lowered arg defs';
};

subtest 'resolver receives lazy info hash' => sub {
  my $saw = {};
  my $info_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'InfoQuery',
      fields => {
        hello => {
          type => $String,
          resolve => sub {
            my ($source, $args, $context, $info, $return_type) = @_;
            $saw->{field_name} = $info->{field_name};
            $saw->{parent_type} = $info->{parent_type}->name;
            $saw->{return_type} = $info->{return_type}->name;
            $saw->{path} = $info->{path};
            $saw->{context_value} = $info->{context_value};
            return $return_type->name;
          },
        },
      },
    ),
  );

  my $result = $info_schema->execute('{ hello }', context => { trace_id => 1 });
  is_deeply $result, { data => { hello => 'String' } }, 'resolver still executes';
  is_deeply $saw, {
    field_name => 'hello',
    parent_type => 'InfoQuery',
    return_type => 'String',
    path => [ 'hello' ],
    context_value => { trace_id => 1 },
  }, 'lazy info exposes compatible keys on demand';
};

subtest 'abstract callbacks receive lazy info hash' => sub {
  my $seen = {};
  my $Abstract = GraphQL::Houtou::Type::Interface->new(
    name => 'TaggedNode',
    fields => {
      id => { type => $String->non_null },
    },
    tag_resolver => sub {
      my ($value, $context, $info, $abstract_type) = @_;
      $seen->{field_name} = $info->{field_name};
      $seen->{parent_type} = $info->{parent_type}->name;
      $seen->{return_type} = $info->{return_type}->name;
      $seen->{path} = $info->{path};
      $seen->{abstract_type} = $abstract_type->name;
      return $value->{kind};
    },
  );
  my $Tagged = GraphQL::Houtou::Type::Object->new(
    name => 'TaggedUser',
    interfaces => [ $Abstract ],
    runtime_tag => 'user',
    fields => {
      id => { type => $String->non_null },
    },
  );
  my $tag_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'TaggedQuery',
      fields => {
        node => {
          type => $Abstract,
          resolve => sub { +{ kind => 'user', id => 'u1' } },
        },
      },
    ),
    types => [ $Tagged, $Abstract ],
  );

  my $result = $tag_schema->execute('{ node { ... on TaggedUser { id } } }');
  is_deeply $result, { data => { node => { id => 'u1' } } }, 'abstract dispatch still executes';
  is_deeply $seen, {
    field_name => 'node',
    parent_type => 'TaggedQuery',
    return_type => 'TaggedNode',
    path => [ 'node' ],
    abstract_type => 'TaggedNode',
  }, 'abstract callback sees lazy info keys';
};

subtest 'fragment spreads execute through lowered child blocks' => sub {
  my $result = $schema->execute(<<'GRAPHQL');
query Q {
  viewer { ...UserBits }
}

fragment UserBits on User {
  id
  name
}
GRAPHQL

  is_deeply $result, {
    data => {
      viewer => {
        id => 'u1',
        name => 'Ana',
      },
    },
  }, 'fragment spread path executes in runtime program';
};

subtest 'dynamic include directives execute through lowered runtime guards' => sub {
  # $show must be Boolean! (or carry a default): a nullable variable
  # without a default is not allowed for @include(if: Boolean!) per the
  # spec's AllowedVariableUsage, and request validation now enforces it.
  my $result = $schema->execute(
    'query Q($show: Boolean!) { viewer { id name @include(if: $show) } }',
    variables => { show => JSON::MaybeXS::true() },
  );

  is_deeply $result, {
    data => {
      viewer => {
        id => 'u1',
        name => 'Ana',
      },
    },
  }, 'dynamic include guard allows field';
};

subtest 'static skip directives prune fields during lowering' => sub {
  my $result = $schema->execute(
    '{ viewer { id name @skip(if: true) } }',
  );

  is_deeply $result, {
    data => {
      viewer => {
        id => 'u1',
      },
    },
  }, 'static skip removes field from runtime output';
};

done_testing;
