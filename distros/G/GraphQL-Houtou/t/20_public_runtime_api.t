use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use lib 'lib';
use GraphQL::Houtou ();
use GraphQL::Houtou qw(
  execute
  execute_native
  compile_runtime
  build_runtime
  build_native_runtime
  compile_native_program
  compile_native_bundle
  compile_native_bundle_descriptor
);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

BEGIN {
  GraphQL::Houtou::_bootstrap_xs();
}

my $Query = GraphQL::Houtou::Type::Object->new(
  name => 'PublicRuntimeQuery',
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

subtest 'top-level execute uses runtime-backed API' => sub {
  my $result = execute($schema, '{ hello }');
  is_deeply $result, {
    data => { hello => 'world' },
  }, 'top-level execute returns runtime result';
};

subtest 'top-level execute accepts variable hashref as third arg' => sub {
  my $result = execute(
    $schema,
    'query($name: String){ greet(name: $name) }',
    { name => 'alice' },
  );
  is_deeply $result, {
    data => { greet => 'hello alice' },
  }, 'top-level execute treats third hashref as variables';
};

subtest 'top-level compile_runtime returns schema runtime' => sub {
  my $runtime = compile_runtime($schema);
  isa_ok $runtime, 'GraphQL::Houtou::Runtime::SchemaGraph';
  my $program = $runtime->compile_program('{ hello }');
  isa_ok $program, 'GraphQL::Houtou::Runtime::NativeProgram';
  my $result = $runtime->execute_program($program);
  is_deeply $result, {
    data => { hello => 'world' },
  }, 'compiled runtime can execute operation';
};

subtest 'schema runtime descriptor helpers prefer program/native names' => sub {
  my ($program_fh, $program_path) = tempfile();
  close $program_fh;

  my $program_descriptor = $schema->dump_program_descriptor('{ hello }', $program_path);
  my $program = $schema->load_program_descriptor($program_path);

  isa_ok $program, 'GraphQL::Houtou::Runtime::NativeProgram';
  ok $program_descriptor->{blocks_compact}, 'program descriptor payload is written to disk';
  is_deeply $schema->build_runtime->execute_program($program), {
    data => { hello => 'world' },
  }, 'program descriptor helpers round-trip through file boundary';

  my ($runtime_fh, $runtime_path) = tempfile();
  close $runtime_fh;

  my $runtime_descriptor = $schema->dump_native_runtime_descriptor($runtime_path);
  my $loaded = $schema->load_native_runtime_descriptor($runtime_path);

  is_deeply $loaded, $runtime_descriptor,
    'native runtime descriptor helpers use native_runtime names';
};

subtest 'top-level build_runtime returns cached schema runtime' => sub {
  my $first = build_runtime($schema);
  my $second = build_runtime($schema);

  isa_ok $first, 'GraphQL::Houtou::Runtime::SchemaGraph';
  is $second, $first, 'top-level build_runtime reuses cached runtime graph';
};

subtest 'schema build_runtime caches no-opt runtime graph' => sub {
  my $first = $schema->build_runtime;
  my $second = $schema->build_runtime;

  is $second, $first, 'build_runtime reuses cached runtime graph';

  $schema->clear_runtime_cache;
  my $third = $schema->build_runtime;
  isnt $third, $first, 'clear_runtime_cache drops cached runtime graph';
};

subtest 'top-level build_native_runtime returns cached native runtime wrapper' => sub {
  my $native = build_native_runtime($schema);
  isa_ok $native, 'GraphQL::Houtou::Runtime::NativeRuntime';

  my $program = $native->compile_program(
    'query Q($name: String = "bob") { greet(name: $name) }',
  );
  isa_ok $program, 'GraphQL::Houtou::Runtime::NativeProgram';
  my $result = $native->execute_program($program, variables => { name => 'cached' });

  is_deeply $result, {
    data => { greet => 'hello cached' },
  }, 'cached native runtime executes request-specialized program';
};

subtest 'schema build_native_runtime caches no-opt native wrapper' => sub {
  my $first = $schema->build_native_runtime;
  my $second = $schema->build_native_runtime;

  is $second, $first, 'build_native_runtime reuses cached native wrapper';

  $schema->clear_runtime_cache;
  my $third = $schema->build_native_runtime;
  isnt $third, $first, 'clear_runtime_cache drops cached native wrapper';
};

subtest 'native runtime can compile reusable bundle from cached program' => sub {
  my $native = $schema->build_native_runtime;
  my $program = $native->compile_program('{ hello }');
  my $bundle = $native->compile_bundle($program);

  isa_ok $bundle, 'GraphQL::Houtou::Runtime::NativeBundle';
  my $result = $native->execute_bundle($bundle);

  is_deeply $result, {
    data => { hello => 'world' },
  }, 'compiled native bundle executes through wrapper';
};

subtest 'native runtime can round-trip bundle descriptors' => sub {
  my $native = $schema->build_native_runtime;
  my $program = $native->compile_program(
    'query Q($name: String = "bob") { greet(name: $name) }',
  );
  my ($fh, $path) = tempfile();
  close $fh;

  my $descriptor = $native->dump_bundle_descriptor(
    $program,
    $path,
    variables => { name => 'persisted' },
  );
  my $bundle = $native->load_bundle_descriptor_file($path);
  my $result = $native->execute_bundle($bundle);

  ok $descriptor->{program}, 'bundle descriptor keeps native program payload';
  is_deeply $result, {
    data => { greet => 'hello persisted' },
  }, 'dumped and loaded native bundle descriptor still executes';
};

subtest 'top-level compile_native_bundle returns executable bundle' => sub {
  my $bundle = compile_native_bundle($schema, '{ hello }');
  my $native = build_native_runtime($schema);
  isa_ok $bundle, 'GraphQL::Houtou::Runtime::NativeBundle';
  my $result = $native->execute_bundle($bundle);
  is_deeply $result, {
    data => { hello => 'world' },
  }, 'top-level bundle compile returns executable native bundle';
};

subtest 'top-level compile_native_program returns executable native program handle' => sub {
  my $program = compile_native_program($schema, '{ hello }');
  my $native = build_native_runtime($schema);
  isa_ok $program, 'GraphQL::Houtou::Runtime::NativeProgram';
  my $result = $native->execute_program($program);
  is_deeply $result, {
    data => { hello => 'world' },
  }, 'top-level native program compile returns executable handle';
};

subtest 'top-level compile_native_bundle_descriptor returns compact descriptor' => sub {
  my $descriptor = compile_native_bundle_descriptor($schema, '{ hello }');
  ok $descriptor->{runtime}, 'descriptor keeps runtime payload';
  ok $descriptor->{program}, 'descriptor keeps program payload';
};

subtest 'schema execute_native reuses cached native runtime handle' => sub {
  $schema->clear_runtime_cache;
  my $load_count = 0;
  my $orig = \&GraphQL::Houtou::XS::VM::load_native_runtime_xs;

  {
    no warnings 'redefine';
    local *GraphQL::Houtou::XS::VM::load_native_runtime_xs = sub {
      $load_count++;
      goto &$orig;
    };

    my $first = $schema->execute_native('{ hello }');
    my $second = $schema->execute_native('{ hello }');

    is_deeply $first, {
      data => { hello => 'world' },
    }, 'first native runtime execution succeeds';
    is_deeply $second, {
      data => { hello => 'world' },
    }, 'second native runtime execution succeeds';
  }

  is $load_count, 1, 'execute_native reuses cached native runtime handle';
};

subtest 'top-level execute_native uses cached native path' => sub {
  my $result = execute_native($schema, '{ hello }');
  is_deeply $result, {
    data => { hello => 'world' },
  }, 'top-level execute_native delegates to schema native runtime';
};

done_testing;
