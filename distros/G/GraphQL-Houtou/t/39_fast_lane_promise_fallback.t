use strict;
use warnings;
use Test::More;
use JSON::PP ();

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String $ID);
use GraphQL::Houtou::Type::List;
use GraphQL::Houtou::Type::Union;

BEGIN {
  eval { require Promise::XS; 1 }
    or plan skip_all => 'Promise::XS is required for async execution tests';
}

use GraphQL::Houtou::Promise::PromiseXS qw(maybe_get_promise_xs);

my %calls;

sub new_schema {
  %calls = ();
  return GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        counted => {
          type => $String,
          resolve => sub { $calls{counted}++; 'counted' },
        },
        asyncUser => {
          type => GraphQL::Houtou::Type::Object->new(
            name => 'AUser', fields => { name => { type => $String } }),
          args => { id => { type => $ID } },
          resolve => sub {
            my (undef, $args) = @_;
            $calls{asyncUser}++;
            return Promise::XS::resolved({ name => "n$args->{id}" });
          },
        },
        pendingForever => {
          type => $String,
          resolve => sub { Promise::XS::deferred()->promise },
        },
      },
    ),
    mutation => GraphQL::Houtou::Type::Object->new(
      name => 'Mutation',
      fields => {
        bump => {
          type => $String,
          args => { id => { type => $ID } },
          resolve => sub { $calls{bump}++; Promise::XS::resolved('bumped') },
        },
      },
    ),
  );
}

my $QUERY = 'query Q($id: ID) { counted asyncUser(id: $id) { name } }';

subtest 'async runtime: variables + promise resolvers execute once, correctly' => sub {
  my $runtime = build_native_runtime(new_schema(), async => 1);
  my $r = maybe_get_promise_xs(
    $runtime->execute_document($QUERY, variables => { id => 'u1' }));
  is_deeply $r, {
    data => { counted => 'counted', asyncUser => { name => 'nu1' } },
  }, 'no promise objects or undefs leak into data';
  is $calls{counted}, 1, 'sync resolver ran exactly once';
  is $calls{asyncUser}, 1, 'promise resolver ran exactly once';
};

subtest 'async runtime: mutations run once on the async lane' => sub {
  my $runtime = build_native_runtime(new_schema(), async => 1);
  my $r = maybe_get_promise_xs($runtime->execute_document(
    'mutation M($id: ID) { bump(id: $id) }', variables => { id => '1' }));
  is $r->{data}{bump}, 'bumped', 'mutation resolved';
  is $calls{bump}, 1, 'mutation resolver ran exactly once';
};

subtest 'async runtime: to_json settles pre-resolved chains to JSON' => sub {
  my $runtime = build_native_runtime(new_schema(), async => 1);
  my $json = $runtime->execute_document_to_json($QUERY, variables => { id => 'u3' });
  is JSON::PP::decode_json($json)->{data}{asyncUser}{name}, 'nu3',
    'JSON via the async lane without on_stall';
};

subtest 'async runtime: a genuine stall points at on_stall' => sub {
  my $runtime = build_native_runtime(new_schema(), async => 1);
  my $err = do {
    local $@;
    eval {
      $runtime->execute_document_to_json(
        'query Q { pendingForever }');
    };
    $@;
  };
  like $err, qr/pass on_stall/, 'error names the missing hook';
};

subtest 'sync runtime: promise on the fast lane fails with an actionable error' => sub {
  my $runtime = build_native_runtime(new_schema());
  for my $case (
    [ execute => sub { $runtime->execute_document($QUERY, variables => { id => 'u5' }) } ],
    [ to_json => sub { $runtime->execute_document_to_json($QUERY, variables => { id => 'u6' }) } ],
  ) {
    my ($name, $run) = @$case;
    my $err = do { local $@; eval { $run->() }; $@ };
    like $err, qr/async => 1/, "$name: error tells you to declare async => 1";
    like $err, qr/on_stall/, "$name: error also offers on_stall";
  }
};

subtest 'sync runtime: a pending DataLoader ticket also fails with an actionable error' => sub {
  require GraphQL::Houtou::DataLoader;
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($keys) = @_; return [ map { "v:$_" } @$keys ] },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        greeting => {
          type => $String,
          args => { id => { type => $String } },
          resolve => sub { my (undef, $args) = @_; return $loader->load($args->{id}) },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($schema);
  my $err = do {
    local $@;
    eval {
      $runtime->execute_document(
        'query Q($id: String) { greeting(id: $id) }', variables => { id => 'p1' });
    };
    $@;
  };
  like $err, qr/synchronous fast lane/, 'error names the synchronous fast lane';
  like $err, qr/async => 1/, 'error tells you to declare async => 1';
  like $err, qr/on_stall/, 'error also offers on_stall';
};

subtest 'async runtime with strict_sync stays strict' => sub {
  my $runtime = build_native_runtime(new_schema(), async => 1);
  for my $case (
    [ execute => sub {
        $runtime->execute_document($QUERY,
          variables => { id => 'u7' }, strict_sync => 1) } ],
    [ to_json => sub {
        $runtime->execute_document_to_json($QUERY,
          variables => { id => 'u8' }, strict_sync => 1) } ],
    [ on_stall => sub {
        $runtime->execute_document($QUERY,
          variables => { id => 'u9' }, strict_sync => 1,
          on_stall => sub { 1 }) } ],
  ) {
    my ($name, $run) = @$case;
    my $err = do { local $@; eval { $run->() }; $@ };
    like $err, qr/synchronous fast lane/,
      "$name: strict_sync overrides async lane selection and croaks";
  }
};

subtest 'sync runtime: promise LIST ITEMS also croak with the hint (issue #33)' => sub {
  my $Row = GraphQL::Houtou::Type::Object->new(
    name => 'Row', fields => { name => { type => $String } });
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        rows => {
          type => $Row->list,
          resolve => sub { [ map { Promise::XS::resolved({ name => "r$_" }) } 1..2 ] },
        },
        tags => {
          type => $String->list,
          resolve => sub { [ Promise::XS::resolved('t1'), Promise::XS::resolved('t2') ] },
        },
      },
    ),
  );
  my $sync_rt = build_native_runtime($schema);
  # strict_sync pins the request to the synchronous fast lane, which
  # is also where variable-carrying requests run; a bare no-variables
  # request goes down the auto lane instead (asserted below).
  for my $case (
    [ 'object list / execute' => sub {
        $sync_rt->execute_document('{ rows { name } }', strict_sync => 1) } ],
    [ 'object list / to_json' => sub { $sync_rt->execute_document_to_json('{ rows { name } }') } ],
    [ 'scalar list / execute' => sub {
        $sync_rt->execute_document('{ tags }', strict_sync => 1) } ],
    [ 'scalar list / to_json' => sub { $sync_rt->execute_document_to_json('{ tags }') } ],
  ) {
    my ($name, $run) = @$case;
    my $err = do { local $@; eval { $run->() }; $@ };
    like $err, qr/async => 1/, "$name: croaks with the async => 1 hint";
  }

  my $auto = maybe_get_promise_xs($sync_rt->execute_document('{ rows { name } tags }'));
  is_deeply $auto->{data}, {
    rows => [ { name => 'r1' }, { name => 'r2' } ],
    tags => [ 't1', 't2' ],
  }, 'no-variables requests ride the auto lane and complete promise items';

  my $async_rt = build_native_runtime($schema, async => 1);
  my $r = maybe_get_promise_xs($async_rt->execute_document('{ rows { name } tags }'));
  is_deeply $r->{data}, {
    rows => [ { name => 'r1' }, { name => 'r2' } ],
    tags => [ 't1', 't2' ],
  }, 'async runtime completes pre-resolved promise list items';
};

subtest 'async runtime: root-leaf DataLoader ticket resumes through the fast continuation' => sub {
  require GraphQL::Houtou::DataLoader;
  # A single nullable root field with no directives and no child block is
  # exactly the shape gql_runtime_vm_try_execute_fast_root_continuation_sv
  # accepts, so these cases exercise the new Ticket-aware continuation
  # rather than the pre-existing generic async executor.
  my $one_field_query = 'query Q($id: String) { greeting(id: $id) }';

  subtest 'already-fulfilled ticket unwraps without suspending' => sub {
    my $calls = 0;
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { my ($keys) = @_; return [ map { "v:$_" } @$keys ] },
    );
    $loader->prime('k1', 'primed-v1');
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          greeting => {
            type => $String,
            args => { id => { type => $String } },
            resolve => sub {
              my (undef, $args) = @_;
              $calls++;
              return $loader->load($args->{id});
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document($one_field_query, variables => { id => 'k1' });
    is_deeply $r, { data => { greeting => 'primed-v1' } }, 'ready ticket value flows through';
    is $calls, 1, 'resolver ran exactly once';
  };

  subtest 'genuinely pending ticket resumes via on_stall' => sub {
    my $calls = 0;
    my $dispatches = 0;
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub {
        my ($keys) = @_;
        $dispatches++;
        return [ map { "batched:$_" } @$keys ];
      },
    );
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          greeting => {
            type => $String,
            args => { id => { type => $String } },
            resolve => sub {
              my (undef, $args) = @_;
              $calls++;
              return $loader->load($args->{id});
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      $one_field_query,
      variables => { id => 'k2' },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { greeting => 'batched:k2' } }, 'pending ticket resolves via on_stall';
    is $calls, 1, 'resolver ran exactly once';
    is $dispatches, 1, 'loader dispatched exactly once';
  };

  subtest 'rejected ticket produces a field error, not a request croak' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub {
        my ($keys) = @_;
        return [ map { GraphQL::Houtou::DataLoader::Error->new("missing: $_") } @$keys ];
      },
    );
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          greeting => {
            type => $String,
            args => { id => { type => $String } },
            resolve => sub { my (undef, $args) = @_; return $loader->load($args->{id}) },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      $one_field_query,
      variables => { id => 'bad' },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is $r->{data}{greeting}, undef, 'field nulled on rejection';
    is scalar @{ $r->{errors} }, 1, 'one error record';
    is $r->{errors}[0]{message}, 'missing: bad', 'rejection reason surfaces as the error message';
    is_deeply $r->{errors}[0]{path}, [ 'greeting' ], 'error path points at the field';
  };
};

subtest 'async runtime still honors on_stall batching' => sub {
  require GraphQL::Houtou::DataLoader;
  my $schema = new_schema();
  my $runtime = build_native_runtime($schema, async => 1);
  my @batches;
  my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @batches, [ @{ $_[0] } ];
    return [ map { { name => "loaded-$_" } } @{ $_[0] } ];
  });
  # asyncUser resolves through Promise::XS directly here; the loader-backed
  # request exercises the async runtime + on_stall combination.
  my $schema2 = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        user => {
          type => GraphQL::Houtou::Type::Object->new(
            name => 'LUser', fields => { name => { type => $String } }),
          args => { id => { type => $ID } },
          resolve => sub { my (undef,$a,$c)=@_; $c->{users}->load($a->{id}) },
        },
      },
    ),
  );
  my $rt2 = build_native_runtime($schema2, async => 1);
  my $r = $rt2->execute_document(
    'query Q($id: ID) { a: user(id: $id) { name } b: user(id: "y") { name } }',
    variables => { id => 'x' },
    context => { users => $users },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users),
  );
  is_deeply $r->{data}, {
    a => { name => 'loaded-x' }, b => { name => 'loaded-y' },
  }, 'batched request resolves synchronously via on_stall';
  is scalar @batches, 1, 'one batch per level';
};

subtest 'async runtime: multiple sibling root leaves promote together' => sub {
  require GraphQL::Houtou::DataLoader;
  # Every field here is a nullable scalar leaf with no directives and no
  # child block, so a root block with more than one of them is exactly the
  # shape gql_runtime_vm_try_execute_fast_root_continuation_sv's multi-
  # sibling path (lazy block_frame_t promotion) accepts, rather than
  # falling back to the generic async executor.

  subtest 'one pending sibling among synchronous ones' => sub {
    my $calls = { a => 0, b => 0, c => 0 };
    my $dispatches = 0;
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      $dispatches++;
      return [ map { "loaded:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          a => { type => $String, resolve => sub { $calls->{a}++; 'sync-a' } },
          b => {
            type => $String,
            args => { id => { type => $String } },
            resolve => sub { my (undef, $args) = @_; $calls->{b}++; return $loader->load($args->{id}) },
          },
          c => { type => $String, resolve => sub { $calls->{c}++; 'sync-c' } },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($id: String) { a b(id: $id) c }',
      variables => { id => 'k1' },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { a => 'sync-a', b => 'loaded:k1', c => 'sync-c' } },
      'sync siblings and the pending one all resolve';
    is $calls->{$_}, 1, "resolver $_ ran exactly once" for qw(a b c);
    is $dispatches, 1, 'one batch dispatch';
  };

  subtest 'two siblings pending on the same batch settle together' => sub {
    my $dispatches = 0;
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      $dispatches++;
      return [ map { "v:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          f1 => { type => $String, resolve => sub { 'sync1' } },
          f2 => {
            type => $String, args => { id => { type => $String } },
            resolve => sub { my (undef, $a) = @_; return $loader->load($a->{id}) },
          },
          f3 => { type => $String, resolve => sub { 'sync3' } },
          f4 => {
            type => $String, args => { id => { type => $String } },
            resolve => sub { my (undef, $a) = @_; return $loader->load($a->{id}) },
          },
          f5 => { type => $String, resolve => sub { 'sync5' } },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($x: String, $y: String) { f1 f2(id: $x) f3 f4(id: $y) f5 }',
      variables => { x => 'x1', y => 'y1' },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { f1 => 'sync1', f2 => 'v:x1', f3 => 'sync3', f4 => 'v:y1', f5 => 'sync5' },
    }, 'both pending siblings and every sync sibling resolve';
    is $dispatches, 1, 'one batch dispatch settles both pending siblings';
  };

  subtest 'a rejected sibling nulls only its own field' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { GraphQL::Houtou::DataLoader::Error->new("bad: $_") } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          ok => { type => $String, resolve => sub { 'still-ok' } },
          bad => {
            type => $String, args => { id => { type => $String } },
            resolve => sub { my (undef, $a) = @_; return $loader->load($a->{id}) },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($id: String) { ok bad(id: $id) }',
      variables => { id => 'z1' },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is $r->{data}{ok}, 'still-ok', 'sibling of a rejected field still resolves';
    is $r->{data}{bad}, undef, 'rejected field is null';
    is scalar @{ $r->{errors} }, 1, 'one error record';
    is $r->{errors}[0]{message}, 'bad: z1', 'rejection reason surfaces as the error message';
    is_deeply $r->{errors}[0]{path}, [ 'bad' ], 'error path points at the rejected field';
  };

  subtest 'pre-resolved Promise::XS mixed with a pending Ticket sibling' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "tk:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          sync_f => { type => $String, resolve => sub { 'plain' } },
          promise_f => { type => $String, resolve => sub { Promise::XS::resolved('pre-resolved') } },
          ticket_f => {
            type => $String, args => { id => { type => $String } },
            resolve => sub { my (undef, $a) = @_; return $loader->load($a->{id}) },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($id: String) { sync_f promise_f ticket_f(id: $id) }',
      variables => { id => 't1' },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { sync_f => 'plain', promise_f => 'pre-resolved', ticket_f => 'tk:t1' },
    }, 'a promise settling synchronously during arm and a genuinely pending ticket both resolve';
  };

  subtest 'a non-null sibling forces the whole block back to the generic executor' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "v:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          strict => { type => $String->non_null, resolve => sub { 'must-have' } },
          loose => {
            type => $String, args => { id => { type => $String } },
            resolve => sub { my (undef, $a) = @_; return $loader->load($a->{id}) },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($id: String) { strict loose(id: $id) }',
      variables => { id => 'nn1' },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { strict => 'must-have', loose => 'v:nn1' } },
      'still correct via the generic executor fallback';
  };

  subtest 'a runtime-directive sibling forces fallback' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "v:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          plain => { type => $String, resolve => sub { 'plain-val' } },
          loaded => {
            type => $String, args => { id => { type => $String } },
            resolve => sub { my (undef, $a) = @_; return $loader->load($a->{id}) },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($id: String, $skipIt: Boolean!) { plain @skip(if: $skipIt) loaded(id: $id) }',
      variables => { id => 'd1', skipIt => 1 },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    ok !exists($r->{data}{plain}), 'skipped field is absent';
    is $r->{data}{loaded}, 'v:d1', 'the pending sibling still resolves via the fallback';
  };

  subtest 'a statically-pruned sibling forces fallback (bundle/native_program op_index parity)' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "v:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          plain => { type => $String, resolve => sub { die "must not run: statically skipped" } },
          other => { type => $String, resolve => sub { 'other-val' } },
          loaded => {
            type => $String, args => { id => { type => $String } },
            resolve => sub { my (undef, $a) = @_; return $loader->load($a->{id}) },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    # A literal (not variable) @skip condition is statically evaluated at
    # bundle-prep time, deleting the op outright - this is the shape the
    # bundle/native_program op_count parity guard exists for.
    my $r = $runtime->execute_document(
      'query Q($id: String) { plain @skip(if: true) other loaded(id: $id) }',
      variables => { id => 's1' },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    ok !exists($r->{data}{plain}), 'statically skipped field is absent';
    is $r->{data}{other}, 'other-val', 'the field after the pruned one still resolves correctly';
    is $r->{data}{loaded}, 'v:s1', 'the pending sibling still resolves correctly';
  };

  subtest 'many independent requests settle in one shared batch dispatch' => sub {
    my $n = 50;
    my $dispatches = 0;
    my $loader = GraphQL::Houtou::DataLoader->new(
      cache => 0,
      batch => sub { $dispatches++; return [ map { "b:$_" } @{ $_[0] } ] },
    );
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          s1 => { type => $String, resolve => sub { 'sync' } },
          p1 => {
            type => $String, args => { id => { type => $String } },
            resolve => sub { my (undef, $a) = @_; return $loader->load($a->{id}) },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my @pending;
    for my $i (1 .. $n) {
      # No on_stall: returns the still-pending Promise::XS directly instead
      # of auto-driving it, so all n requests' loads queue on the same
      # loader before anything dispatches.
      push @pending, [ $i, $runtime->execute_document(
        'query Q($id: String) { s1 p1(id: $id) }', variables => { id => "k$i" }) ];
    }
    is $loader->pending_count, $n, "all $n loads queued before dispatch";
    my $dispatched = $loader->dispatch;
    is $dispatches, 1, 'exactly one batch dispatch';
    is $dispatched, $n, "dispatch settled all $n tickets";
    my $ok = 0;
    for my $pair (@pending) {
      my ($i, $r) = @$pair;
      my $settled = maybe_get_promise_xs($r);
      $ok++ if $settled->{data}{s1} eq 'sync' && $settled->{data}{p1} eq "b:k$i";
    }
    is $ok, $n, 'every request settled with the correct value';
  };
};

subtest 'async runtime: root plain-leaf list fields promote through the fast continuation' => sub {
  require GraphQL::Houtou::DataLoader;
  # A root list field whose items are plain scalar leaves (no child block,
  # no abstract dispatch) is exactly the shape Phase 4 adds to
  # gql_runtime_vm_try_execute_fast_root_continuation_sv's eligibility
  # guard. Before Phase 4 this always fell back to the generic async
  # executor (LIST ops were unconditionally ineligible); these cases
  # exercise the new item-level list_pending continuation instead.

  subtest 'sync list resolver, all items pending in one batch' => sub {
    my $dispatches = 0;
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      $dispatches++;
      return [ map { "v:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          names => {
            type => GraphQL::Houtou::Type::List->new(of => $String),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args, $ctx) = @_;
              return [ map { $ctx->{loader}->load($_) } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String]) { names(ids: $ids) }',
      variables => { ids => [ 'x1', 'x2', 'x3' ] },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { names => [ 'v:x1', 'v:x2', 'v:x3' ] } },
      'every item resolves via the shared batch';
    is $dispatches, 1, 'one batch dispatch settles every item';
  };

  subtest 'a sync sibling alongside a list field with pending items' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "v:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          a => { type => $String, resolve => sub { 'sync-a' } },
          names => {
            type => GraphQL::Houtou::Type::List->new(of => $String),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args, $ctx) = @_;
              return [ map { $ctx->{loader}->load($_) } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String]) { a names(ids: $ids) }',
      variables => { ids => [ 'y1', 'y2' ] },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { a => 'sync-a', names => [ 'v:y1', 'v:y2' ] } },
      'the sync sibling and the list with pending items both resolve';
  };

  subtest 'a field-level pending sibling alongside item-level list pending' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "v:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          greeting => {
            type => $String,
            args => { id => { type => $String } },
            resolve => sub {
              my (undef, $args, $ctx) = @_;
              return $ctx->{loader}->load($args->{id});
            },
          },
          names => {
            type => GraphQL::Houtou::Type::List->new(of => $String),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args, $ctx) = @_;
              return [ map { $ctx->{loader}->load($_) } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($id: String, $ids: [String]) { greeting(id: $id) names(ids: $ids) }',
      variables => { id => 'g1', ids => [ 'y1', 'y2' ] },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { greeting => 'v:g1', names => [ 'v:y1', 'v:y2' ] },
    }, 'a suspended-at-the-field sibling and a suspended-in-its-items sibling both resolve';
  };

  subtest 'a rejected item nulls only its own slot' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      my ($ids) = @_;
      return [ map {
        $_ eq 'bad' ? GraphQL::Houtou::DataLoader::Error->new("no such key: $_") : "v:$_"
      } @$ids ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          names => {
            type => GraphQL::Houtou::Type::List->new(of => $String),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args, $ctx) = @_;
              return [ map { $ctx->{loader}->load($_) } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String]) { names(ids: $ids) }',
      variables => { ids => [ 'ok1', 'bad', 'ok2' ] },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r->{data}{names}, [ 'v:ok1', undef, 'v:ok2' ], 'only the failed item is null';
    is scalar @{ $r->{errors} }, 1, 'one error record';
    is $r->{errors}[0]{message}, 'no such key: bad', 'rejection reason surfaces as the error message';
    is_deeply $r->{errors}[0]{path}, [ 'names', 1 ], 'error path points at the failed item';
  };

  subtest 'a non-null item violation nulls the whole list, not just the item' => sub {
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      my ($ids) = @_;
      return [ map { $_ eq 'bad' ? undef : "v:$_" } @$ids ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          names => {
            # [String!]: item_non_null
            type => GraphQL::Houtou::Type::List->new(of => $String->non_null),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args, $ctx) = @_;
              return [ map { $ctx->{loader}->load($_) } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String]) { names(ids: $ids) }',
      variables => { ids => [ 'ok1', 'bad', 'ok2' ] },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is $r->{data}{names}, undef, 'the whole (nullable) list field is null';
    is scalar @{ $r->{errors} }, 1, 'one error record';
    like $r->{errors}[0]{message}, qr/Cannot return null for non-nullable field/,
      'error names the non-null violation';
    is_deeply $r->{errors}[0]{path}, [ 'names', 1 ], 'error path points at the offending item';
  };

  subtest 'object list items where each item itself is a pending ticket' => sub {
    # Row's own child block is flat (a single leaf field), so Phase 5's
    # eligibility guard now admits this shape into the fast continuation -
    # but each array ITEM here is itself a DataLoader ticket (a per-item
    # loader pattern), not a plain hashref, so this still exercises Phase 4's
    # pre-scan+delegate path (gql_runtime_vm_exec_state_complete_current_native_async_sv),
    # not Phase 5's per-item child-block wrapper.
    my $Row = GraphQL::Houtou::Type::Object->new(
      name => 'RowP4', fields => { name => { type => $String } });
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { { name => "row-$_" } } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          rows => {
            type => GraphQL::Houtou::Type::List->new(of => $Row),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args, $ctx) = @_;
              return [ map { $ctx->{loader}->load($_) } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String]) { rows(ids: $ids) { name } }',
      variables => { ids => [ 'i1', 'i2' ] },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { rows => [ { name => 'row-i1' }, { name => 'row-i2' } ] } },
      'object list items resolve correctly via the pre-existing delegate path';
  };
};

subtest 'async runtime: root object/abstract list fields promote through the fast continuation (Phase 5)' => sub {
  require GraphQL::Houtou::DataLoader;
  # A root list field whose items are objects (or interface/union members)
  # is exactly the shape Phase 5 adds to gql_runtime_vm_try_execute_fast_root_continuation_sv's
  # eligibility guard, restricted to "flat" item child blocks (leaf fields
  # only, no further nesting). Before Phase 5 any child_block_index/
  # abstract_child_count on a LIST op was unconditionally ineligible; these
  # cases exercise the new per-item child-block wrapper
  # (gql_runtime_vm_execute_list_item_child_block_fast_sv) instead.

  subtest 'fully synchronous object list items need no promotion' => sub {
    my $Row = GraphQL::Houtou::Type::Object->new(
      name => 'SyncRow', fields => { id => { type => $String }, label => { type => $String } });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          rows => {
            type => GraphQL::Houtou::Type::List->new(of => $Row),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_, label => "l-$_" } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String]) { rows(ids: $ids) { id label } }',
      variables => { ids => [ 'a', 'b' ] },
    );
    is_deeply $r, {
      data => { rows => [
        { id => 'a', label => 'l-a' }, { id => 'b', label => 'l-b' },
      ] },
    }, 'no DataLoader involved, resolves synchronously';
  };

  subtest 'a later field in the same item suspends without re-running an earlier sibling resolver' => sub {
    my %calls = (name => 0, pending => 0);
    my $Row = GraphQL::Houtou::Type::Object->new(
      name => 'MixedRow',
      fields => {
        name => { type => $String, resolve => sub { $calls{name}++; "custom:$_[0]{id}" } },
        pending => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub {
            my (undef, $args, $ctx) = @_;
            $calls{pending}++;
            return $ctx->{loader}->load($args->{key});
          },
        },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "loaded:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          rows => {
            type => GraphQL::Houtou::Type::List->new(of => $Row),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_ } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String], $k: String) { rows(ids: $ids) { name pending(key: $k) } }',
      variables => { ids => [ 'x', 'y', 'z' ], k => 'k1' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { rows => [
        map { { name => "custom:$_", pending => 'loaded:k1' } } qw(x y z)
      ] },
    }, 'every item resolves with both fields correct';
    is $calls{name}, 3, 'the already-resolved sibling resolver ran exactly once per item, not twice';
    is $calls{pending}, 3, 'the suspending resolver also ran exactly once per item';
  };

  subtest 'a non-null field violation after an earlier sibling suspended nulls the whole item' => sub {
    my $Row = GraphQL::Houtou::Type::Object->new(
      name => 'NonNullRow',
      fields => {
        pending => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
        req => {
          type => $String->non_null,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader2}->load($a->{key}) },
        },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { return [ map { "v:$_" } @{ $_[0] } ] },
    );
    my $loader2 = GraphQL::Houtou::DataLoader->new(
      batch => sub { return [ map { undef } @{ $_[0] } ] },
    );
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          rows => {
            type => GraphQL::Houtou::Type::List->new(of => $Row),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_ } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String], $k1: String, $k2: String) { rows(ids: $ids) { pending(key: $k1) req(key: $k2) } }',
      variables => { ids => [ 'x' ], k1 => 'p1', k2 => 'r1' },
      context => { loader => $loader, loader2 => $loader2 },
      on_stall => sub {
        my $progressed = 0;
        $progressed = 1 if $loader->pending_count && $loader->dispatch;
        $progressed = 1 if $loader2->pending_count && $loader2->dispatch;
        return $progressed;
      },
    );
    is $r->{data}{rows}[0], undef, 'the item is null, not partially filled with the already-resolved sibling';
    is scalar @{ $r->{errors} }, 1, 'one error record';
    like $r->{errors}[0]{message}, qr/Cannot return null for non-nullable field NonNullRow\.req/,
      'error names the non-null violation';
    is_deeply $r->{errors}[0]{path}, [ 'rows', 0, 'req' ], 'error path points at the offending field';
  };

  subtest 'multiple items suspend on the same batch' => sub {
    # val's resolver derives its loader key from the item's own `id`
    # (the source, not a field arg), so each of the 3 items queues a
    # different key - exercising several item-level frames settling
    # together off one shared batch dispatch.
    my $Row = GraphQL::Houtou::Type::Object->new(
      name => 'BatchRow',
      fields => {
        id => { type => $String },
        val => {
          type => $String,
          resolve => sub { my ($source, undef, $ctx) = @_; return $ctx->{loader}->load($source->{id}) },
        },
      },
    );
    my $dispatches = 0;
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      $dispatches++;
      return [ map { "v:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          rows => {
            type => GraphQL::Houtou::Type::List->new(of => $Row),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_ } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($ids: [String]) { rows(ids: $ids) { id val } }',
      variables => { ids => [ 'm1', 'm2', 'm3' ] },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { rows => [ map { { id => $_, val => "v:$_" } } qw(m1 m2 m3) ] },
    }, 'all three items resolved with the correct per-item value';
    is $dispatches, 1, 'one batch dispatch settles every suspended item';
  };

  subtest 'abstract (union) list items dispatch to the right member and can suspend' => sub {
    my $Cat = GraphQL::Houtou::Type::Object->new(
      name => 'CatP5', runtime_tag => 'cat',
      fields => {
        name => { type => $String },
        meow => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    );
    my $Dog = GraphQL::Houtou::Type::Object->new(
      name => 'DogP5', runtime_tag => 'dog',
      fields => { name => { type => $String } },
    );
    my $Pet = GraphQL::Houtou::Type::Union->new(
      name => 'PetP5', types => [ $Cat, $Dog ], tag_resolver => sub { $_[0]{kind} },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "sound:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          pets => {
            type => GraphQL::Houtou::Type::List->new(of => $Pet),
            resolve => sub {
              return [
                { kind => 'cat', name => 'Tama' },
                { kind => 'dog', name => 'Pochi' },
              ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($k: String) { pets { ... on CatP5 { name meow(key: $k) } ... on DogP5 { name } } }',
      variables => { k => 'purr' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { pets => [
        { name => 'Tama', meow => 'sound:purr' },
        { name => 'Pochi' },
      ] },
    }, 'the cat member suspends and resolves, the dog member has no such field';
  };

  subtest 'a nested object field within an item (fully synchronous)' => sub {
    # Written when Phase 5 excluded this shape entirely (any nested
    # object/abstract field forced a fallback); Phase 6 lifts that
    # restriction (see the subtest block below), so this now resolves via
    # the fast continuation's recursive per-item wrapper instead - kept
    # as a plain synchronous regression check either way.
    my $Inner = GraphQL::Houtou::Type::Object->new(
      name => 'InnerP5', fields => { v => { type => $String } });
    my $Row = GraphQL::Houtou::Type::Object->new(
      name => 'NestedRow',
      fields => {
        id => { type => $String },
        inner => { type => $Inner, resolve => sub { { v => 'nested' } } },
      },
    );
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          rows => {
            type => GraphQL::Houtou::Type::List->new(of => $Row),
            resolve => sub { return [ { id => 'n1' } ] },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document('{ rows { id inner { v } } }');
    is_deeply $r, { data => { rows => [ { id => 'n1', inner => { v => 'nested' } } ] } },
      'resolves correctly';
  };
};

subtest 'async runtime: nested object/abstract fields inside a list item promote through the fast continuation (Phase 6)' => sub {
  require GraphQL::Houtou::DataLoader;
  # Phase 5 required a list item's own child block to be "flat" (no
  # further object/abstract nesting). Phase 6 lifts that restriction by
  # making gql_runtime_vm_fast_lane_list_item_block_is_eligible recurse,
  # and reusing gql_runtime_vm_execute_safe_child_block_fast_sv (Phase 5's
  # sibling-preserving wrapper) at the plain OBJECT/ABSTRACT field
  # child-block call sites too - these cases exercise a nested field
  # itself suspending, one or more levels below the list item.

  subtest 'fully synchronous 2-level nesting needs no promotion' => sub {
    my $Author = GraphQL::Houtou::Type::Object->new(
      name => 'SyncAuthor', fields => { name => { type => $String } });
    my $Post = GraphQL::Houtou::Type::Object->new(
      name => 'SyncPost',
      fields => {
        title => { type => $String },
        author => { type => $Author, resolve => sub { { name => "a:$_[0]{id}" } } },
      },
    );
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          posts => {
            type => GraphQL::Houtou::Type::List->new(of => $Post),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_, title => "t:$_" } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query q($ids: [String]) { posts(ids: $ids) { title author { name } } }',
      variables => { ids => [ 'p1', 'p2' ] },
    );
    is_deeply $r, {
      data => { posts => [
        { title => 't:p1', author => { name => 'a:p1' } },
        { title => 't:p2', author => { name => 'a:p2' } },
      ] },
    }, 'no DataLoader involved, resolves synchronously';
  };

  subtest 'a nested field suspends without re-running an already-resolved sibling two levels up' => sub {
    my %calls = (title => 0, name => 0);
    my $Author = GraphQL::Houtou::Type::Object->new(
      name => 'NestedAuthor',
      fields => {
        name => { type => $String, resolve => sub { $calls{name}++; "n:$_[0]{id}" } },
        pendingField => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub {
            my (undef, $args, $ctx) = @_;
            return $ctx->{loader}->load($args->{key});
          },
        },
      },
    );
    my $Post = GraphQL::Houtou::Type::Object->new(
      name => 'NestedPost',
      fields => {
        title => { type => $String, resolve => sub { $calls{title}++; "t:$_[0]{id}" } },
        author => { type => $Author, resolve => sub { { id => $_[0]{id} } } },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "loaded:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          posts => {
            type => GraphQL::Houtou::Type::List->new(of => $Post),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_ } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query q($ids: [String], $k: String) { posts(ids: $ids) { title author { name pendingField(key: $k) } } }',
      variables => { ids => [ 'p1', 'p2' ], k => 'k1' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { posts => [
        { title => 't:p1', author => { name => 'n:p1', pendingField => 'loaded:k1' } },
        { title => 't:p2', author => { name => 'n:p2', pendingField => 'loaded:k1' } },
      ] },
    }, 'every post and its nested author resolve correctly';
    is $calls{title}, 2, 'title (an item-level sibling of the nested object) ran exactly once per item';
    is $calls{name}, 2, 'name (a sibling of the suspending field, one level deeper) ran exactly once per item';
  };

  subtest 'true recursion: a 3-level-deep nested field can suspend' => sub {
    my $Team = GraphQL::Houtou::Type::Object->new(
      name => 'DeepTeam',
      fields => {
        name => { type => $String, resolve => sub { "team:$_[0]{id}" } },
        secret => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    );
    my $Author = GraphQL::Houtou::Type::Object->new(
      name => 'DeepAuthor',
      fields => {
        name => { type => $String, resolve => sub { "author:$_[0]{id}" } },
        team => { type => $Team, resolve => sub { { id => $_[0]{id} } } },
      },
    );
    my $Post = GraphQL::Houtou::Type::Object->new(
      name => 'DeepPost',
      fields => {
        title => { type => $String, resolve => sub { "t:$_[0]{id}" } },
        author => { type => $Author, resolve => sub { { id => $_[0]{id} } } },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "secret:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          posts => {
            type => GraphQL::Houtou::Type::List->new(of => $Post),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_ } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query q($ids: [String], $k: String) { posts(ids: $ids) { title author { name team { name secret(key: $k) } } } }',
      variables => { ids => [ 'p1' ], k => 'k1' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { posts => [ {
        title => 't:p1',
        author => { name => 'author:p1', team => { name => 'team:p1', secret => 'secret:k1' } },
      } ] },
    }, 'three levels of nesting resolve correctly, not just a hardcoded two';
  };

  subtest 'a non-null violation in a nested field nulls only that field, sibling data intact' => sub {
    my $Author = GraphQL::Houtou::Type::Object->new(
      name => 'NonNullAuthor',
      fields => {
        name => { type => $String, resolve => sub { "n:$_[0]{id}" } },
        req => {
          type => $String->non_null,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    );
    my $Post = GraphQL::Houtou::Type::Object->new(
      name => 'NonNullPost',
      fields => {
        title => { type => $String, resolve => sub { "t:$_[0]{id}" } },
        author => { type => $Author, resolve => sub { { id => $_[0]{id} } } },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { undef } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          posts => {
            type => GraphQL::Houtou::Type::List->new(of => $Post),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_ } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query q($ids: [String], $k: String) { posts(ids: $ids) { title author { name req(key: $k) } } }',
      variables => { ids => [ 'p1' ], k => 'k1' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is $r->{data}{posts}[0]{title}, 't:p1', 'the item-level sibling (title) is unaffected';
    is $r->{data}{posts}[0]{author}, undef, 'the nested object itself is null (its own non-null field violated)';
    is scalar @{ $r->{errors} }, 1, 'one error record';
    like $r->{errors}[0]{message}, qr/Cannot return null for non-nullable field NonNullAuthor\.req/,
      'error names the non-null violation';
    is_deeply $r->{errors}[0]{path}, [ 'posts', 0, 'author', 'req' ], 'error path points at the offending nested field';
  };

  subtest 'an abstract (union) field nested inside a list item can suspend' => sub {
    my $Cat = GraphQL::Houtou::Type::Object->new(
      name => 'NestedCat', runtime_tag => 'cat',
      fields => {
        name => { type => $String },
        meow => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    );
    my $Dog = GraphQL::Houtou::Type::Object->new(
      name => 'NestedDog', runtime_tag => 'dog',
      fields => { name => { type => $String } },
    );
    my $Pet = GraphQL::Houtou::Type::Union->new(
      name => 'NestedPet', types => [ $Cat, $Dog ], tag_resolver => sub { $_[0]{kind} },
    );
    my $Owner = GraphQL::Houtou::Type::Object->new(
      name => 'NestedOwner',
      fields => {
        name => { type => $String, resolve => sub { "owner:$_[0]{id}" } },
        pet => {
          type => $Pet,
          resolve => sub { { kind => 'cat', name => 'Tama', id => $_[0]{id} } },
        },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "sound:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          owners => {
            type => GraphQL::Houtou::Type::List->new(of => $Owner),
            args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
            resolve => sub {
              my (undef, $args) = @_;
              return [ map { { id => $_ } } @{ $args->{ids} } ];
            },
          },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query q($ids: [String], $k: String) { owners(ids: $ids) { name pet { ... on NestedCat { name meow(key: $k) } ... on NestedDog { name } } } }',
      variables => { ids => [ 'o1' ], k => 'purr' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { owners => [ {
        name => 'owner:o1',
        pet => { name => 'Tama', meow => 'sound:purr' },
      } ] },
    }, 'the union member nested inside a list item resolves after its own field suspends';
  };

  subtest 'nesting deeper than the recursion guard falls back safely' => sub {
    # GQL_VM_FAST_LANE_MAX_NESTING_DEPTH is 16 - build a chain of plain
    # object types one field deeper than that (17 levels below the root
    # list item) and confirm gql_runtime_vm_fast_lane_list_item_block_is_eligible
    # fails closed (falls back to the generic executor) rather than
    # crashing or mishandling the query, and that the query still
    # produces the correct result either way.
    my $depth = 17;
    # Every "next" field uses the default resolver (reads $source->{next}),
    # so a single nested Perl hash built once, matching the type chain
    # shape exactly, is enough - no per-level resolve callbacks needed.
    my $item_value = { v => 'bottom' };
    for (1 .. $depth) {
      $item_value = { next => $item_value };
    }
    my $innermost = GraphQL::Houtou::Type::Object->new(
      name => "DeepLevel$depth", fields => { v => { type => $String } });
    my @levels = ($innermost);
    for (my $lvl = $depth - 1; $lvl >= 0; $lvl--) {
      my $child = $levels[0];
      unshift @levels, GraphQL::Houtou::Type::Object->new(
        name => "DeepLevel$lvl",
        fields => { next => { type => $child } },
      );
    }
    my $query_inner = join(' ', ('next {') x $depth) . ' v ' . ('}' x $depth);
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          rows => {
            type => GraphQL::Houtou::Type::List->new(of => $levels[0]),
            resolve => sub { return [ $item_value ] },
          },
        },
      ),
    );
    # The query is deeper than the schema's default max_depth (an
    # unrelated request-validation limit, not the fast-lane recursion
    # guard under test), so raise it here.
    my $runtime = build_native_runtime($schema, async => 1, max_depth => $depth + 5);
    my $r = $runtime->execute_document("{ rows { $query_inner } }");
    my $expected = $item_value;
    is_deeply $r, { data => { rows => [ $expected ] } },
      'the over-depth query still resolves correctly via the generic executor fallback';
  };
};

subtest 'async runtime: a single (non-list) root object/abstract field promotes through the fast continuation (Phase 7)' => sub {
  # `{ user { name } }`-shaped queries: before Phase 7,
  # gql_runtime_vm_try_execute_fast_root_continuation_sv's root eligibility
  # loop rejected any root op whose complete_code was GQL_VM_COMPLETE_OBJECT
  # or GQL_VM_COMPLETE_ABSTRACT outright, so these always fell back to the
  # generic executor. Phase 7 lifts that restriction and reuses the same
  # recursive child-block eligibility check and execute_block_fast_multi_sv/
  # execute_safe_child_block_fast_sv machinery Phase 5/6 already exercise
  # from list items and nested fields - the root op loop now just calls it
  # on the root op's own child_block_index/abstract_child_indexes too.

  subtest 'fully synchronous single object root field needs no promotion' => sub {
    my $User = GraphQL::Houtou::Type::Object->new(
      name => 'SyncUser', fields => { id => { type => $String }, name => { type => $String } });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          user => { type => $User, resolve => sub { { id => 'u1', name => 'Ada' } } },
        },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document('{ user { id name } }');
    is_deeply $r, { data => { user => { id => 'u1', name => 'Ada' } } },
      'no DataLoader involved, resolves synchronously';
  };

  subtest 'a later field in the child block suspends without re-running an earlier sibling resolver' => sub {
    my %calls = (name => 0, pending => 0);
    my $User = GraphQL::Houtou::Type::Object->new(
      name => 'MixedUser',
      fields => {
        name => { type => $String, resolve => sub { $calls{name}++; 'Ada' } },
        pending => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub {
            my (undef, $args, $ctx) = @_;
            $calls{pending}++;
            return $ctx->{loader}->load($args->{key});
          },
        },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "loaded:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => { user => { type => $User, resolve => sub { {} } } },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($k: String) { user { name pending(key: $k) } }',
      variables => { k => 'k1' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { user => { name => 'Ada', pending => 'loaded:k1' } } },
      'both fields resolve correctly';
    is $calls{name}, 1, 'the already-resolved sibling resolver ran exactly once, not twice';
    is $calls{pending}, 1, 'the suspending resolver also ran exactly once';
  };

  subtest 'a non-null field violation after an earlier sibling suspended nulls the whole field' => sub {
    my $User = GraphQL::Houtou::Type::Object->new(
      name => 'NonNullUser',
      fields => {
        pending => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
        req => {
          type => $String->non_null,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader2}->load($a->{key}) },
        },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { return [ map { "v:$_" } @{ $_[0] } ] },
    );
    my $loader2 = GraphQL::Houtou::DataLoader->new(
      batch => sub { return [ map { undef } @{ $_[0] } ] },
    );
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => { user => { type => $User, resolve => sub { {} } } },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($k1: String, $k2: String) { user { pending(key: $k1) req(key: $k2) } }',
      variables => { k1 => 'p1', k2 => 'r1' },
      context => { loader => $loader, loader2 => $loader2 },
      on_stall => sub {
        my $progressed = 0;
        $progressed = 1 if $loader->pending_count && $loader->dispatch;
        $progressed = 1 if $loader2->pending_count && $loader2->dispatch;
        return $progressed;
      },
    );
    is $r->{data}{user}, undef, 'the field is null, not partially filled with the already-resolved sibling';
    is scalar @{ $r->{errors} }, 1, 'one error record';
    like $r->{errors}[0]{message}, qr/Cannot return null for non-nullable field NonNullUser\.req/,
      'error names the non-null violation';
    is_deeply $r->{errors}[0]{path}, [ 'user', 'req' ], 'error path points at the offending field';
  };

  subtest 'a single root abstract (union) field dispatches to the right member and can suspend' => sub {
    my $Cat = GraphQL::Houtou::Type::Object->new(
      name => 'CatP7', runtime_tag => 'cat',
      fields => {
        name => { type => $String },
        meow => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    );
    my $Dog = GraphQL::Houtou::Type::Object->new(
      name => 'DogP7', runtime_tag => 'dog',
      fields => { name => { type => $String } },
    );
    my $Pet = GraphQL::Houtou::Type::Union->new(
      name => 'PetP7', types => [ $Cat, $Dog ], tag_resolver => sub { $_[0]{kind} },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "sound:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => { pet => { type => $Pet, resolve => sub { { kind => 'cat', name => 'Tama' } } } },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($k: String) { pet { ... on CatP7 { name meow(key: $k) } ... on DogP7 { name } } }',
      variables => { k => 'purr' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { pet => { name => 'Tama', meow => 'sound:purr' } } },
      'the cat member suspends and resolves';
  };

  subtest 'the child block may itself nest a further object field (Phase 6 reuse)' => sub {
    # team's own resolver settles synchronously; the suspension happens one
    # level deeper, inside team's own child block (team.name) - the exact
    # gql_runtime_vm_execute_safe_child_block_fast_sv recursion Phase 6 added
    # for list items, now reached from a single root object field instead.
    my $Team = GraphQL::Houtou::Type::Object->new(
      name => 'TeamP7',
      fields => {
        name => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    );
    my $User = GraphQL::Houtou::Type::Object->new(
      name => 'NestedUser',
      fields => {
        name => { type => $String },
        team => { type => $Team, resolve => sub { {} } },
      },
    );
    my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
      return [ map { "team:$_" } @{ $_[0] } ];
    });
    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => { user => { type => $User, resolve => sub { { name => 'Ada' } } } },
      ),
    );
    my $runtime = build_native_runtime($schema, async => 1);
    my $r = $runtime->execute_document(
      'query Q($k: String) { user { name team { name(key: $k) } } }',
      variables => { k => 't1' },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { user => { name => 'Ada', team => { name => 'team:t1' } } } },
      'the nested object field resolves through the reused Phase 6 machinery';
  };
};

done_testing;
