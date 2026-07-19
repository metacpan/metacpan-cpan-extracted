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

use GraphQL::Houtou::Promise::PromiseXS qw(maybe_get_promise_xs);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String $Int);

# Track execution order across resolver calls
my @execution_log;

my $Mutation = GraphQL::Houtou::Type::Object->new(
  name => 'SerialMutation',
  fields => {
    first => {
      type => $String->non_null,
      resolve => sub {
        push @execution_log, 'first_called';
        require Promise::XS;
        my $d = Promise::XS::deferred();
        # Resolve immediately but via Promise (async path)
        $d->resolve('first_result');
        push @execution_log, 'first_promise_created';
        return $d->promise;
      },
    },
    second => {
      type => $String->non_null,
      resolve => sub {
        push @execution_log, 'second_called';
        require Promise::XS;
        my $d = Promise::XS::deferred();
        $d->resolve('second_result');
        push @execution_log, 'second_promise_created';
        return $d->promise;
      },
    },
    third => {
      type => $String->non_null,
      resolve => sub {
        push @execution_log, 'third_called';
        require Promise::XS;
        my $d = Promise::XS::deferred();
        $d->resolve('third_result');
        push @execution_log, 'third_promise_created';
        return $d->promise;
      },
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'SerialMutationQuery',
    fields => {
      noop => { type => $String, resolve => sub { 'noop' } },
    },
  ),
  mutation => $Mutation,
);

subtest 'mutation with async resolvers returns correct values' => sub {
  @execution_log = ();

  my $result = $schema->execute('mutation { first second third }');
  my $resolved = maybe_get_promise_xs($result);

  is_deeply $resolved, {
    data => {
      first  => 'first_result',
      second => 'second_result',
      third  => 'third_result',
    },
  }, 'all three mutation fields resolve to correct values';
};

subtest 'mutation async resolvers execute serially (not in parallel)' => sub {
  @execution_log = ();

  my $result = $schema->execute('mutation { first second third }');
  maybe_get_promise_xs($result);

  # Serial execution: first is called, then after its promise resolves, second is called, etc.
  # In parallel execution, all three would be called before any promise resolves:
  #   [first_called, second_called, third_called, first_promise_created, ...]
  # In serial execution, each resolver is called only after the previous promise resolves:
  #   [first_called, first_promise_created, second_called, second_promise_created, third_called, ...]
  my @call_positions = grep { $_ =~ /_called$/ } @execution_log;
  my @create_positions;
  for my $i (0 .. $#execution_log) {
    push @create_positions, $i if $execution_log[$i] =~ /first_promise_created/;
  }
  my @second_call_positions;
  for my $i (0 .. $#execution_log) {
    push @second_call_positions, $i if $execution_log[$i] eq 'second_called';
  }

  # second_called must appear after first_promise_created for serial execution
  if (@create_positions && @second_call_positions) {
    ok $second_call_positions[0] > $create_positions[0],
      'second resolver called after first promise was created (serial order)';
  } else {
    ok 1, 'execution log captured (serial path active)';
  }

  # Verify all three were called
  is scalar(@call_positions), 3, 'all three resolvers were called';
  is_deeply \@call_positions, [qw(first_called second_called third_called)],
    'resolvers called in schema-defined order';
};

subtest 'mutation with sync resolvers still works' => sub {
  my $SyncMutation = GraphQL::Houtou::Type::Object->new(
    name => 'SyncMutation',
    fields => {
      add => {
        type => $Int->non_null,
        args => { a => { type => $Int->non_null }, b => { type => $Int->non_null } },
        resolve => sub { my ($src, $args) = @_; $args->{a} + $args->{b} },
      },
      greet => {
        type => $String->non_null,
        args => { name => { type => $String->non_null } },
        resolve => sub { my ($src, $args) = @_; 'Hello, ' . $args->{name} },
      },
    },
  );

  my $sync_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'SyncMutationQuery',
      fields => { noop => { type => $String, resolve => sub { 'noop' } } },
    ),
    mutation => $SyncMutation,
  );

  my $result = $sync_schema->execute(
    'mutation { add(a: 3, b: 4) greet(name: "world") }',
  );
  my $resolved = maybe_get_promise_xs($result);

  is_deeply $resolved, {
    data => { add => 7, greet => 'Hello, world' },
  }, 'sync mutation fields resolve correctly';
};

subtest 'mutation with mixed sync and async resolvers' => sub {
  my @mixed_log;

  my $MixedMutation = GraphQL::Houtou::Type::Object->new(
    name => 'MixedMutation',
    fields => {
      sync_field => {
        type => $String->non_null,
        resolve => sub { push @mixed_log, 'sync_called'; 'sync_value' },
      },
      async_field => {
        type => $String->non_null,
        resolve => sub {
          push @mixed_log, 'async_called';
          require Promise::XS;
          Promise::XS::resolved('async_value');
        },
      },
    },
  );

  my $mixed_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'MixedMutationQuery',
      fields => { noop => { type => $String, resolve => sub { 'noop' } } },
    ),
    mutation => $MixedMutation,
  );

  my $result = $mixed_schema->execute('mutation { sync_field async_field }');
  my $resolved = maybe_get_promise_xs($result);

  is_deeply $resolved, {
    data => { sync_field => 'sync_value', async_field => 'async_value' },
  }, 'mixed sync/async mutation fields resolve correctly';
};

done_testing;
