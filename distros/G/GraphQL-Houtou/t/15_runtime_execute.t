use strict;
use warnings;

use JSON::MaybeXS ();
use Test::More 0.98;

use GraphQL::Houtou ();
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Runtime::SchemaGraph ();
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::List;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Scalar qw($Int $String);
use GraphQL::Houtou::Type::Union;

BEGIN {
  GraphQL::Houtou::_bootstrap_xs();
}

{
  package Local::AccessorUser;
  sub new { return bless { name => $_[1], display_name => $_[2] }, $_[0] }
  sub name { return $_[0]{name} }
  sub display_name { return $_[0]{display_name} }
  sub boom { die "accessor boom\n" }
}

{
  package Local::AccessorAdmin;
  our @ISA = ('Local::AccessorUser');
  sub name { return 'Admin' }
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

subtest 'fast_resolve_no_args omits the arguments hash' => sub {
  my @seen;
  my $context = { trace_id => 42 };
  my $native_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'NativeNoArgsQuery',
      fields => {
        nativeHello => {
          type => $String,
          resolver_mode => 'fast_resolve_no_args',
          resolve => sub {
            @seen = @_;
            return 'native-hi';
          },
        },
      },
    ),
  );

  my $result = $native_schema->execute('{ nativeHello }', context => $context);
  is_deeply $result, { data => { nativeHello => 'native-hi' } },
    'fast no-args resolver executes correctly';
  is scalar(@seen), 3, 'resolver receives source, context, and return type only';
  is $seen[1], $context, 'resolver receives the request context';
  is $seen[2]->name, 'String', 'resolver receives the return type';
};

subtest 'fast_resolve_no_args rejects fields that declare arguments' => sub {
  my $invalid_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'InvalidNativeNoArgsQuery',
      fields => {
        greet => {
          type => $String,
          resolver_mode => 'fast_resolve_no_args',
          args => { name => { type => $String } },
          resolve => sub { return 'unreachable' },
        },
      },
    ),
  );

  eval { $invalid_schema->build_runtime };
  like $@, qr/fast_resolve_no_args.*requires a field without arguments/,
    'invalid ABI declaration fails while compiling the runtime';
};

subtest 'fast_resolve_one_arg passes the coerced value without an args hash' => sub {
  my @seen;
  my $context = { trace_id => 84 };
  my $one_arg_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'NativeOneArgQuery',
      fields => {
        greet => {
          type => $String,
          resolver_mode => 'fast_resolve_one_arg',
          args => {
            name => { type => $String, default_value => 'Bob' },
          },
          resolve => sub {
            @seen = @_;
            return defined $_[1] ? "hello $_[1]" : 'hello NULL';
          },
        },
      },
    ),
  );

  my $result = $one_arg_schema->execute(
    'query Q($name: String) { greet(name: $name) }',
    variables => { name => 'Ana' },
    context => $context,
  );
  is_deeply $result, { data => { greet => 'hello Ana' } },
    'dynamic argument reaches the one-argument resolver';
  is scalar(@seen), 4,
    'resolver receives source, value, context, and return type';
  is $seen[1], 'Ana', 'resolver receives the argument value directly';
  is $seen[2], $context, 'one-argument resolver receives context';
  is $seen[3]->name, 'String', 'one-argument resolver receives return type';

  is_deeply $one_arg_schema->execute('{ greet }'),
    { data => { greet => 'hello Bob' } },
    'argument default reaches the direct value path';

  is_deeply $one_arg_schema->execute(
    'query Q($name: String) { greet(name: $name) }',
  ), { data => { greet => 'hello Bob' } },
    'argument default applies when a referenced variable is omitted';

  is_deeply $one_arg_schema->execute(
    'query Q($name: String) { greet(name: $name) }',
    variables => { name => undef },
  ), { data => { greet => 'hello NULL' } },
    'an explicitly null variable does not activate the argument default';
};

subtest 'fast_resolve_one_arg requires exactly one argument declaration' => sub {
  my $invalid_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'InvalidNativeOneArgQuery',
      fields => {
        hello => {
          type => $String,
          resolver_mode => 'fast_resolve_one_arg',
          resolve => sub { return 'unreachable' },
        },
      },
    ),
  );

  eval { $invalid_schema->build_runtime };
  like $@, qr/fast_resolve_one_arg.*requires exactly one argument/,
    'invalid one-argument ABI declaration is rejected';
};

subtest 'unknown resolver modes are rejected' => sub {
  my $invalid_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'UnknownResolverModeQuery',
      fields => {
        hello => {
          type => $String,
          resolver_mode => 'fast_resolve_no_arg',
          resolve => sub { return 'unreachable' },
        },
      },
    ),
  );

  eval { $invalid_schema->build_runtime };
  like $@, qr/unknown resolver_mode 'fast_resolve_no_arg'.*UnknownResolverModeQuery\.hello/,
    'a resolver mode typo cannot silently select the generic ABI';
};

subtest 'fast_resolve mode supports the HashRef ABI' => sub {
  my $native_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'NativeArgsQuery',
      fields => {
        nativeGreet => {
          type => $String,
          resolver_mode => 'fast_resolve',
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
  }, 'fast_resolve passes a HashRef to the explicit resolver';
};

subtest 'accessor calls a zero-argument source method' => sub {
  my $current_user = Local::AccessorUser->new('Ana', 'Ana Tofu');
  my $AccessorUser = GraphQL::Houtou::Type::Object->new(
    name => 'AccessorUser',
    fields => {
      name => {
        type => $String,
        accessor => 'name',
      },
      displayName => {
        type => $String,
        accessor => 'display_name',
      },
      boom => {
        type => $String,
        accessor => 'boom',
      },
    },
  );
  my $accessor_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'AccessorQuery',
      fields => {
        viewer => {
          type => $AccessorUser,
          resolve => sub {
            return $current_user;
          },
        },
      },
    ),
    types => [ $AccessorUser ],
  );

  is_deeply $accessor_schema->execute('{ viewer { name displayName } }'), {
    data => {
      viewer => {
        name => 'Ana',
        displayName => 'Ana Tofu',
      },
    },
  }, 'same-name and renamed accessors execute without a resolver coderef';

  my $error_result = $accessor_schema->execute('{ viewer { name boom } }');
  is $error_result->{data}{viewer}{name}, 'Ana',
    'accessor errors do not discard sibling fields';
  is $error_result->{data}{viewer}{boom}, undef,
    'throwing accessor completes as null';
  is $error_result->{errors}[0]{message}, 'accessor boom',
    'accessor exception becomes a field error';
  is_deeply $error_result->{errors}[0]{path}, [ 'viewer', 'boom' ],
    'accessor error keeps the field path';

  $current_user = bless {
    name => 'ignored',
    display_name => 'Administrator',
  }, 'Local::AccessorAdmin';
  is $accessor_schema->execute('{ viewer { name } }')->{data}{viewer}{name},
    'Admin', 'accessor cache follows the source subclass';

  {
    no warnings 'redefine';
    eval 'sub Local::AccessorAdmin::name { return "Redefined Admin" } 1'
      or die $@;
  }
  is $accessor_schema->execute('{ viewer { name } }')->{data}{viewer}{name},
    'Redefined Admin', 'method redefinition invalidates the accessor cache';
};

subtest 'accessor rejects ambiguous field declarations' => sub {
  my $invalid_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'InvalidAccessorQuery',
      fields => {
        hello => {
          type => $String,
          accessor => 'hello',
          resolve => sub { return 'unreachable' },
        },
      },
    ),
  );

  eval { $invalid_schema->build_runtime };
  like $@, qr/accessor and resolve cannot both be specified/,
    'accessor cannot silently override an explicit resolver';
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
  my $orig = \&GraphQL::Houtou::XS::VM::execute_native_program_prepared_fast_xs;
  my $result;
  {
    no warnings 'redefine';
    local *GraphQL::Houtou::XS::VM::execute_native_program_prepared_fast_xs = sub {
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
  }, 'cached program prepares request variables inside native execution';
  ok $called, 'cached runtime/program reached fused prepare-and-execute entry';
};

subtest 'inflated runtime descriptor evaluates directive guards in the fused lane' => sub {
  my $runtime = $schema->build_runtime;
  my $inflated = GraphQL::Houtou::Runtime::SchemaGraph->inflate_schema($schema, $runtime->to_struct);
  my $program = $inflated->compile_program(
    'query Q($show: Boolean = true) { greet(name: "Ana") @include(if: $show) }',
  );

  my $called = 0;
  my $orig = \&GraphQL::Houtou::XS::VM::execute_native_program_prepared_fast_xs;
  my $result;
  {
    no warnings 'redefine';
    local *GraphQL::Houtou::XS::VM::execute_native_program_prepared_fast_xs = sub {
      $called = 1;
      goto &$orig;
    };
    $result = $inflated->execute_program($program, strict_sync => 1);
  }

  is_deeply $result, {
    data => {
      greet => 'hello Ana',
    },
  }, 'inflated runtime evaluates a defaulted directive variable';
  ok $called, 'inflated runtime uses fused prepare-and-execute for directive guards';

  is_deeply $inflated->execute_program(
    $program,
    strict_sync => 1,
    variables => { show => 0 },
  ), {
    data => {},
  }, 'false directive variable omits the field without specializing the program';
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

subtest 'prepared variable values are not coerced again as arguments' => sub {
  my $parse_count = 0;
  my $CountingInput = GraphQL::Houtou::Type::Scalar->new(
    name => 'CountingInput',
    parse_value => sub {
      $parse_count++;
      return "parsed:$_[0]";
    },
    serialize => sub { $_[0] },
  );
  my $counting_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'CountingQuery',
      fields => {
        echoCounting => {
          type => $String,
          resolver_mode => 'native',
          args => {
            value => { type => $CountingInput->non_null },
          },
          resolve => sub {
            my ($source, $args) = @_;
            return $args->{value};
          },
        },
      },
    ),
    types => [ $CountingInput ],
  );

  my $result = $counting_schema->execute(
    'query Q($value: CountingInput!) { echoCounting(value: $value) }',
    variables => { value => 'raw' },
  );

  is_deeply $result, {
    data => {
      echoCounting => 'parsed:raw',
    },
  }, 'resolver receives the value produced by variable coercion';
  is $parse_count, 1, 'custom scalar parse_value runs once for a direct variable argument';
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

subtest 'variables nested in input literals use the prepared variables fallback' => sub {
  my $result = $schema->execute(
    'query Q($name: String!) { describeProfile(profile: { name: $name }) }',
    variables => { name => 'Cara' },
  );
  is_deeply $result, {
    data => {
      describeProfile => 'Cara:20',
    },
  }, 'nested variable references materialize the compatibility variables hash';
};

subtest 'resolver receives lazy info hash' => sub {
  my $saw = {};
  my $info_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'InfoQuery',
      fields => {
        hello => {
          type => $String,
          args => {
            name => { type => $String },
          },
          resolve => sub {
            my ($source, $args, $context, $info, $return_type) = @_;
            $saw->{field_name} = $info->{field_name};
            $saw->{parent_type} = $info->{parent_type}->name;
            $saw->{return_type} = $info->{return_type}->name;
            $saw->{path} = $info->{path};
            $saw->{context_value} = $info->{context_value};
            $saw->{variable_values} = $info->{variable_values};
            return $return_type->name;
          },
        },
      },
    ),
  );

  my $result = $info_schema->execute(
    'query Q($name: String) { hello(name: $name) }',
    context => { trace_id => 1 },
    variables => { name => 'Ana', extra => 'kept' },
  );
  is_deeply $result, { data => { hello => 'String' } }, 'resolver still executes';
  is_deeply $saw, {
    field_name => 'hello',
    parent_type => 'InfoQuery',
    return_type => 'String',
    path => [ 'hello' ],
    context_value => { trace_id => 1 },
    variable_values => { name => 'Ana', extra => 'kept' },
  }, 'lazy info exposes compatible keys on demand';
};

subtest 'LazyInfo pool reuse attributes each call to the right field/path' => sub {
  # Phase 10: gql_runtime_vm_lazy_info_t is now pooled (a capped free-list,
  # like block_frame/path_frame) instead of Newxz/Safefree per call. A
  # stale or cross-contaminated reused struct would show up here as a
  # wrong field_name or path on some item, since every item's resolver
  # runs through the pool and each item's path index must differ.
  my @seen;
  my $Item = GraphQL::Houtou::Type::Object->new(
    name => 'PoolReuseItem',
    fields => {
      label => {
        type => $String,
        args => { prefix => { type => $String } },
        resolve => sub {
          my ($source, $args, undef, $info) = @_;
          push @seen, {
            field_name => $info->{field_name},
            parent_type => $info->{parent_type}->name,
            path => $info->{path},
          };
          return "$args->{prefix}:$source->{id}";
        },
      },
    },
  );
  my $pool_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'PoolReuseQuery',
      fields => {
        items => {
          type => GraphQL::Houtou::Type::List->new(of => $Item),
          args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
          resolve => sub {
            my (undef, $args) = @_;
            return [ map { { id => $_ } } @{ $args->{ids} } ];
          },
        },
      },
    ),
  );
  my $width = 30;
  my $result = $pool_schema->execute(
    'query Q($ids: [String], $p: String) { items(ids: $ids) { label(prefix: $p) } }',
    variables => { ids => [ map { "id$_" } 1 .. $width ], p => 'pfx' },
  );
  is_deeply $result, {
    data => { items => [ map { { label => "pfx:id$_" } } 1 .. $width ] },
  }, 'every item resolves to its own value';
  is scalar(@seen), $width, "every item's resolver ran exactly once";
  for my $i (1 .. $width) {
    my $entry = $seen[$i - 1];
    is $entry->{field_name}, 'label', "item $i: field_name is 'label', not stale from another call";
    is $entry->{parent_type}, 'PoolReuseItem', "item $i: parent_type is correct";
    is_deeply $entry->{path}, [ 'items', $i - 1, 'label' ], "item $i: path index is correct, not stale";
  }
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
