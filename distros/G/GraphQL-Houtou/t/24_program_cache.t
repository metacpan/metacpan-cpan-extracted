use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec;

BEGIN {
  my $root = File::Spec->catdir($Bin, '..');
  for my $path (
    File::Spec->catdir($root, 'lib'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5', 'darwin-2level'),
  ) {
    unshift @INC, $path if -d $path;
  }
}

use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String $Int);
use GraphQL::Houtou::Runtime::NativeRuntime;

my $compile_count = 0;

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'CacheQuery',
    fields => {
      hello => { type => $String, resolve => sub { 'world' } },
      greet => {
        type => $String,
        args => { name => { type => $String } },
        resolve => sub { my ($src, $args) = @_; 'hi ' . ($args->{name} // 'x') },
      },
    },
  ),
);

subtest 'program is cached after first compile' => sub {
  my $runtime = $schema->build_native_runtime;

  is $runtime->program_cache_size, 0, 'cache empty initially';

  $runtime->execute_document('{ hello }');
  is $runtime->program_cache_size, 1, 'one entry cached after first execute';

  $runtime->execute_document('{ hello }');
  is $runtime->program_cache_size, 1, 'cache size unchanged on second execute';

  $runtime->execute_document('{ greet(name: "world") }');
  is $runtime->program_cache_size, 2, 'different query adds second entry';
};

subtest 'cached program produces correct results' => sub {
  my $runtime = $schema->build_native_runtime;

  my $r1 = $runtime->execute_document('{ hello }');
  my $r2 = $runtime->execute_document('{ hello }');

  is_deeply $r1, { data => { hello => 'world' } }, 'first call correct';
  is_deeply $r2, { data => { hello => 'world' } }, 'second call (cached) correct';
};

subtest 'variables do not affect cache key – compiled once, executed with different vars' => sub {
  my $runtime = $schema->build_native_runtime;

  $runtime->execute_document('{ greet(name: "alice") }');
  my $size_before = $runtime->program_cache_size;

  $runtime->execute_document('{ greet(name: "bob") }');
  is $runtime->program_cache_size, $size_before + 1,
    'different argument literals = different query string = different cache entry';
};

subtest 'pre-parsed AST is not cached' => sub {
  my $runtime = $schema->build_native_runtime;
  $runtime->clear_program_cache;

  my $ast = GraphQL::Houtou::parse('{ hello }');
  $runtime->execute_document($ast);
  is $runtime->program_cache_size, 0, 'AST ref is not cached (no string key)';
};

subtest 'clear_program_cache empties the cache' => sub {
  my $runtime = $schema->build_native_runtime;
  $runtime->execute_document('{ hello }');
  ok $runtime->program_cache_size > 0, 'cache has entries';

  $runtime->clear_program_cache;
  is $runtime->program_cache_size, 0, 'cache is empty after clear';

  my $result = $runtime->execute_document('{ hello }');
  is_deeply $result, { data => { hello => 'world' } },
    'execution still works after clear';
};

subtest 'program_cache_max limits cache size with FIFO eviction' => sub {
  my $runtime = GraphQL::Houtou::Runtime::NativeRuntime->new(
    runtime_schema => $schema->build_runtime,
    program_cache_max => 2,
  );

  my $q1 = '{ hello }';
  my $q2 = '{ greet(name: "a") }';
  my $q3 = '{ greet(name: "b") }';

  $runtime->execute_document($q1);
  $runtime->execute_document($q2);
  is $runtime->program_cache_size, 2, 'cache at max';

  $runtime->execute_document($q3);
  is $runtime->program_cache_size, 2, 'cache stays at max after eviction';
  ok !exists $runtime->{_program_cache}{$q1}, 'oldest entry evicted';
  ok  exists $runtime->{_program_cache}{$q3}, 'newest entry present';
};

subtest 'program_cache_max => 0 disables caching' => sub {
  my $runtime = GraphQL::Houtou::Runtime::NativeRuntime->new(
    runtime_schema => $schema->build_runtime,
    program_cache_max => 0,
  );

  $runtime->execute_document('{ hello }');
  is $runtime->program_cache_size, 0, 'nothing cached when max is 0';
};

subtest 'schema->build_native_runtime passes program_cache_max' => sub {
  my $runtime = $schema->build_native_runtime(program_cache_max => 5);
  is $runtime->{_program_cache_max}, 5, 'program_cache_max forwarded from Schema';
};

subtest 'variable-invariant programs skip the specialized program cache' => sub {
  my $runtime = $schema->build_native_runtime;
  my $query = 'query Q($name: String) { greet(name: $name) }';

  for my $name (qw(alice bob carol)) {
    my $result = $runtime->execute_document($query, variables => { name => $name });
    is_deeply $result, { data => { greet => "hi $name" } },
      "fresh variables ($name) execute correctly";
  }

  is scalar(keys %{ $runtime->{_specialized_program_cache} || {} }), 0,
    'no per-variables specialized programs were cached';
};

subtest 'runtime-directive programs still use the specialized cache' => sub {
  require GraphQL::Houtou::Directive;
  my $mask = GraphQL::Houtou::Directive->new(
    name => 'mask',
    locations => [qw(FIELD)],
    args => { enabled => { type => $Int } },
    apply_field_result => sub {
      my ($value, undef, undef, undef, undef, undef, $directive_args) = @_;
      return $directive_args->{enabled} ? '***' : $value;
    },
  );
  my $directive_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'MaskQuery',
      fields => {
        secret => { type => $String, resolve => sub { 'classified' } },
      },
    ),
    directives => [ @GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES, $mask ],
  );
  my $runtime = $directive_schema->build_native_runtime;
  # $on must match the directive argument's declared Int type now that
  # request validation checks variable/argument type compatibility.
  my $query = 'query Q($on: Int) { secret @mask(enabled: $on) }';

  my $masked = $runtime->execute_document($query, variables => { on => 1 });
  is $masked->{data}{secret}, '***', 'runtime directive applied with variables';

  my $plain = $runtime->execute_document($query, variables => { on => 0 });
  is $plain->{data}{secret}, 'classified', 'runtime directive respects falsy variable';

  cmp_ok scalar(keys %{ $runtime->{_specialized_program_cache} || {} }), '>', 0,
    'variable-dependent runtime directives still specialize per variables';
};

subtest 'operation_name caches per (document, operationName) pair' => sub {
  my $runtime = $schema->build_native_runtime;
  $runtime->clear_program_cache;
  my $doc = 'query A { hello } query B { greet(name: "b") }';

  my $a = $runtime->execute_document($doc, operation_name => 'A');
  is_deeply $a->{data}, { hello => 'world' }, 'operation A executed';
  is $runtime->program_cache_size, 1, 'operation A cached';

  my $b = $runtime->execute_document($doc, operation_name => 'B');
  is_deeply $b->{data}, { greet => 'hi b' }, 'operation B executed';
  is $runtime->program_cache_size, 2, 'operation B cached under its own key';

  my $a2 = $runtime->execute_document($doc, operation_name => 'A');
  is_deeply $a2->{data}, { hello => 'world' }, 'cached operation A still correct';
  my $b2 = $runtime->execute_document($doc, operation_name => 'B');
  is_deeply $b2->{data}, { greet => 'hi b' }, 'cached operation B still correct';
  is $runtime->program_cache_size, 2, 'repeat requests hit the cache';

  # Without operation_name the compiler takes the first operation; the
  # plain-document key must not collide with the composite keys.
  my $first = $runtime->execute_document($doc);
  is_deeply $first->{data}, { hello => 'world' }, 'no operation_name runs the first operation';
  is $runtime->program_cache_size, 3, 'plain document key is a separate entry';

  my $json = $runtime->execute_document_to_json($doc, operation_name => 'B');
  like $json, qr/"greet":"hi b"/, 'to_json lane honors operation_name';
  is $runtime->program_cache_size, 3, 'to_json reuses the same cache entry';
};

subtest 'unknown operation_name is a request error and is not cached' => sub {
  my $runtime = $schema->build_native_runtime;
  $runtime->clear_program_cache;
  my $doc = 'query A { hello }';

  my $result = $runtime->execute_document($doc, operation_name => 'Nope');
  ok !exists $result->{data}, 'errors-only envelope';
  like $result->{errors}[0]{message}, qr/"Nope" was not found/,
    'names the missing operation';
  is $runtime->program_cache_size, 0, 'nothing cached for the failed request';

  my $json = $runtime->execute_document_to_json($doc, operation_name => 'Nope');
  like $json, qr/^\{"errors":/, 'to_json returns an errors-only envelope';
};

done_testing;
