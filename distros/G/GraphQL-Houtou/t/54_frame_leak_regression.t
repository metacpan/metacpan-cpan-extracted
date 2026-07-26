use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Promise::XS; 1 }
    or plan skip_all => 'Promise::XS is required for async execution tests';
}

# R5 regression: every request path that abandons or errors mid-flight must
# release its block/path frames. The live counters count frames handed out
# minus frames released; nonzero between requests is an orphaned frame
# (the async block-frame and fast-lane path-frame regressions).

use GraphQL::Houtou qw(execute build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);
use GraphQL::Houtou::Type::List;
use GraphQL::Houtou::DataLoader;

GraphQL::Houtou::_bootstrap_xs();

sub live_counts { GraphQL::Houtou::XS::VM::debug_frame_live_counts_xs() }

sub assert_no_live_frames {
  my ($label) = @_;
  my $c = live_counts();
  is $c->{block_frame}, 0, "$label: no live block frames";
  is $c->{path_frame}, 0, "$label: no live path frames";
  is $c->{lazy_info}, 0, "$label: no live lazy info handles";
}

my $Inner = GraphQL::Houtou::Type::Object->new(
  name => 'Inner',
  fields => {
    hang => { type => $String, resolve => sub { Promise::XS::deferred()->promise } },
  },
);
my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      hello => {
        type => $String,
        args => { name => { type => $String->non_null } },
        resolve => sub { 'hi ' . $_[1]{name} },
      },
      hang => { type => $String, resolve => sub { Promise::XS::deferred()->promise } },
      inner => { type => $Inner, resolve => sub { {} } },
      user => {
        type => GraphQL::Houtou::Type::Object->new(
          name => 'User', fields => { name => { type => $String } }),
        resolve => sub { my (undef, undef, $ctx) = @_; $ctx->{users}->load('u1') },
      },
    },
  ),
);

subtest 'baseline' => sub {
  assert_no_live_frames('before any request');
};

subtest 'deadlocked stall releases the pending frames' => sub {
  # `{ inner { hang } }` is a single root object field whose own child block
  # suspends - before Phase 7 this always fell back to the generic executor,
  # so this case only started exercising gql_runtime_vm_try_execute_fast_root_continuation_sv's
  # multi-op path (and its cancel-on-deadlock handling) once Phase 7 widened
  # that path's eligibility guard. It is the regression test that caught
  # both bugs described in 'repeated single root object field promotions
  # stay clean' below.
  for my $query ('{ hang }', '{ inner { hang } }') {
    my $err = do { local $@; eval { execute($schema, $query, undef, on_stall => sub { 0 }) }; $@ };
    like $err, qr/stalled.*no progress/s, "$query reports the deadlock";
    assert_no_live_frames("deadlock $query");
  }
};

subtest 'stall without on_stall releases the pending frames' => sub {
  my $runtime = build_native_runtime($schema, async => 1);
  for my $query ('{ hang }', '{ inner { hang } }') {
    my $err = do { local $@; eval { $runtime->execute_document_to_json($query) }; $@ };
    like $err, qr/pass on_stall/, "$query points at on_stall";
    assert_no_live_frames("undriven stall $query");
  }
};

subtest 'request-time coercion failure releases the fast-lane path frames' => sub {
  my $runtime = build_native_runtime($schema);
  # A nullable variable with a default may sit in a non-null argument
  # position, and an explicit null then fails argument coercion inside the
  # fast lane - the deferred-croak path this regression guards. (A missing
  # non-null variable no longer reaches the lane: it is rejected while
  # variables are prepared, before any frame is allocated.)
  my $query = 'query Q($n: String = "x") { hello(name: $n) }';
  my $nulled = $runtime->execute_document($query, variables => { n => undef });
  like $nulled->{errors}[0]{message}, qr/given null value/, 'request error envelope';
  my $json = $runtime->execute_document_to_json($query, variables => { n => undef });
  like $json, qr/given null value/, 'request error envelope (JSON lane)';
  assert_no_live_frames('coercion failure');

  my $missing = $runtime->execute_document(
    'query Q($n: String!) { hello(name: $n) }', variables => {},
  );
  like $missing->{errors}[0]{message}, qr/was not provided/,
    'missing non-null variable is rejected at variable preparation';
  assert_no_live_frames('missing variable rejection');
};

subtest 'promise on the sync fast lane releases the path frames' => sub {
  my $sync = build_native_runtime($schema);
  for my $case (
    [ 'execute'  => sub { $sync->execute_document('{ hang }', variables => {}) } ],
    [ 'to_json'  => sub { $sync->execute_document_to_json('{ hang }', variables => {}) } ],
  ) {
    my ($name, $run) = @$case;
    my $err = do { local $@; eval { $run->() }; $@ };
    like $err, qr/async => 1/, "$name croaks with the async hint";
  }
  assert_no_live_frames('sync-lane promise croak');
};

subtest 'a completed DataLoader request stays clean' => sub {
  my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_;
    return [ map { { name => "user-$_" } } @$ids ];
  });
  my $result = execute($schema, '{ user { name } }', undef,
    context => { users => $users },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users),
  );
  is $result->{data}{user}{name}, 'user-u1', 'loader request resolved';
  assert_no_live_frames('completed loader request');
};

subtest 'repeated root-leaf DataLoader ticket continuations stay clean' => sub {
  # gql_runtime_vm_fast_root_continuation_ctx_t is shared by the resolve and
  # reject arms via a cv_refcnt pair, mirroring
  # gql_runtime_vm_pending_callback_ctx_t; a refcounting mistake there would
  # only show up after many suspend/resume cycles, not a single request.
  my $leaf_schema = GraphQL::Houtou::Schema->new(
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
      },
    ),
  );
  my $runtime = build_native_runtime($leaf_schema, async => 1);
  for my $i (1 .. 200) {
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
    );
    my $r = $runtime->execute_document(
      'query Q($id: String) { greeting(id: $id) }',
      variables => { id => "k$i" },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is $r->{data}{greeting}, "v:k$i", "iteration $i resolved" or last;
  }
  assert_no_live_frames('200 pending-ticket root-leaf continuations');
};

subtest 'repeated multi-sibling root promotions stay clean' => sub {
  # Each request here promotes to a real block_frame_t + exec_state_handle_t
  # (gql_runtime_vm_try_execute_fast_root_continuation_sv's multi-sibling
  # path); a leak in that construction or in gql_runtime_vm_block_frame_finalize_sv's
  # arm/drain handoff would only show up after many requests, not one.
  my $multi_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        a => { type => $String, resolve => sub { 'sync-a' } },
        b => {
          type => $String,
          args => { id => { type => $String } },
          resolve => sub {
            my (undef, $args, $ctx) = @_;
            return $ctx->{loader}->load($args->{id});
          },
        },
        c => { type => $String, resolve => sub { 'sync-c' } },
      },
    ),
  );
  my $runtime = build_native_runtime($multi_schema, async => 1);
  for my $i (1 .. 200) {
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
    );
    my $r = $runtime->execute_document(
      'query Q($id: String) { a b(id: $id) c }',
      variables => { id => "m$i" },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, { data => { a => 'sync-a', b => "v:m$i", c => 'sync-c' } }, "iteration $i resolved"
      or last;
  }
  assert_no_live_frames('200 multi-sibling root promotions');
};

subtest 'repeated root list-item-pending promotions stay clean' => sub {
  # Each request here promotes via the item-level list_pending path added
  # for Phase 4 (gql_runtime_vm_complete_current_list_fast_sv stashing the
  # raw array, then gql_runtime_vm_exec_state_complete_current_native_async_sv
  # + gql_runtime_vm_push_pending_list_pending adopting it); a leak in that
  # handoff, or in the lazily-built exec_state_handle_t it now requires,
  # would only show up after many requests, not one.
  my $list_schema = GraphQL::Houtou::Schema->new(
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
  my $runtime = build_native_runtime($list_schema, async => 1);
  for my $i (1 .. 200) {
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
    );
    my $r = $runtime->execute_document(
      'query Q($ids: [String]) { a names(ids: $ids) }',
      variables => { ids => [ "l$i-1", "l$i-2", "l$i-3" ] },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { a => 'sync-a', names => [ "v:l$i-1", "v:l$i-2", "v:l$i-3" ] },
    }, "iteration $i resolved" or last;
  }
  assert_no_live_frames('200 root list-item-pending promotions');
};

subtest 'repeated root object-list item-child-block promotions stay clean' => sub {
  # Each request here promotes via Phase 5's per-item wrapper
  # (gql_runtime_vm_execute_list_item_child_block_fast_sv): item 0's own
  # child block resolves a sync sibling then suspends on a second field,
  # finalizing that item's own frame (block_frame_finalize_sv mode 2)
  # before Layer 2 aggregates it with the rest of the list. A leak in
  # either the per-item frame's own lifecycle or its aggregation into the
  # list_pending/root frame chain would only show up after many requests.
  my $Row = GraphQL::Houtou::Type::Object->new(
    name => 'LeakRow',
    fields => {
      name => { type => $String, resolve => sub { "n:$_[0]{id}" } },
      pending => {
        type => $String,
        args => { key => { type => $String } },
        resolve => sub {
          my (undef, $args, $ctx) = @_;
          return $ctx->{loader}->load($args->{key});
        },
      },
    },
  );
  my $list_schema = GraphQL::Houtou::Schema->new(
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
  my $runtime = build_native_runtime($list_schema, async => 1);
  for my $i (1 .. 200) {
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
    );
    my $r = $runtime->execute_document(
      'query Q($ids: [String], $k: String) { rows(ids: $ids) { name pending(key: $k) } }',
      variables => { ids => [ "r$i-1", "r$i-2" ], k => "k$i" },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { rows => [
        { name => "n:r$i-1", pending => "v:k$i" },
        { name => "n:r$i-2", pending => "v:k$i" },
      ] },
    }, "iteration $i resolved" or last;
  }
  assert_no_live_frames('200 root object-list item-child-block promotions');
};

subtest 'repeated 2-level nested object field promotions stay clean' => sub {
  # Phase 6: each request here promotes THREE frames per item (the root
  # list frame, the item's own frame, and the nested object field's own
  # frame - see gql_runtime_vm_execute_safe_child_block_fast_sv's
  # recursive reuse). A leak here was caught during development (missing
  # gql_runtime_vm_ensure_fast_lane_state_sv call on the new "completion
  # produced a promise" channel in gql_runtime_vm_execute_block_fast_multi_sv)
  # and would only show up after many requests, not one.
  my $Author = GraphQL::Houtou::Type::Object->new(
    name => 'LeakAuthor',
    fields => {
      name => { type => $String, resolve => sub { "n:$_[0]{id}" } },
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
    name => 'LeakPost',
    fields => {
      title => { type => $String, resolve => sub { "t:$_[0]{id}" } },
      author => { type => $Author, resolve => sub { { id => $_[0]{id} } } },
    },
  );
  my $nested_schema = GraphQL::Houtou::Schema->new(
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
  my $runtime = build_native_runtime($nested_schema, async => 1);
  for my $i (1 .. 200) {
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
    );
    my $r = $runtime->execute_document(
      'query q($ids: [String], $k: String) { posts(ids: $ids) { title author { name pendingField(key: $k) } } }',
      variables => { ids => [ "p$i-1", "p$i-2" ], k => "k$i" },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { posts => [
        { title => "t:p$i-1", author => { name => "n:p$i-1", pendingField => "v:k$i" } },
        { title => "t:p$i-2", author => { name => "n:p$i-2", pendingField => "v:k$i" } },
      ] },
    }, "iteration $i resolved" or last;
  }
  assert_no_live_frames('200 nested object field promotions');
};

subtest 'repeated single root object field promotions stay clean' => sub {
  # Phase 7: a single (non-list) root object field now reaches
  # gql_runtime_vm_try_execute_fast_root_continuation_sv's multi-op path
  # too (previously only multi-sibling/list-shaped root queries did).
  # Developing this phase caught two real, previously-unreached bugs, both
  # only visible via a genuine stall/abandonment, not this happy-path
  # stress loop:
  #   1. that path's returned promise never carried the magic that lets
  #      the Perl driver break the exec_state reference cycle on a
  #      deadlocked stall (gql_runtime_vm_attach_response_state_magic was
  #      only ever called from the generic executor's own entry point) -
  #      a pre-existing gap in every multi-sibling/list root shape, just
  #      never exercised by a deadlock in that combination before.
  #   2. gql_runtime_vm_cancel_frame_tree only walked GQL_VM_PENDING_BLOCK_FRAME_PTR
  #      children, so it could not reach a nested OBJECT/ABSTRACT field's own
  #      suspended child frame - reachable only via its bridging Promise::XS
  #      (see gql_runtime_vm_attach_child_frame_magic/gql_runtime_vm_child_frame_from_promise_sv).
  # Both are exercised by the existing 'deadlocked stall releases the
  # pending frames' subtest above (its `{ inner { hang } }` case), now that
  # Phase 7 makes that shape reach this path; this subtest instead stresses
  # the ordinary happy-path settle/free cycle many times over.
  my $Team = GraphQL::Houtou::Type::Object->new(
    name => 'LeakTeam',
    fields => {
      name => {
        type => $String,
        args => { key => { type => $String } },
        resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
      },
    },
  );
  my $User = GraphQL::Houtou::Type::Object->new(
    name => 'LeakUser',
    fields => {
      name => { type => $String, resolve => sub { "n:$_[0]{id}" } },
      team => { type => $Team, resolve => sub { {} } },
    },
  );
  my $root_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        user => {
          type => $User,
          args => { id => { type => $String } },
          resolve => sub { my (undef, $args) = @_; return { id => $args->{id} } },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($root_schema, async => 1);
  for my $i (1 .. 200) {
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
    );
    my $r = $runtime->execute_document(
      'query q($id: String, $k: String) { user(id: $id) { name team { name(key: $k) } } }',
      variables => { id => "u$i", k => "k$i" },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { user => { name => "n:u$i", team => { name => "v:k$i" } } },
    }, "iteration $i resolved" or last;
  }
  assert_no_live_frames('200 single root object field promotions');
};

subtest 'repeated args-bearing resolver calls exercise the LazyInfo pool cleanly' => sub {
  # Phase 10: gql_runtime_vm_lazy_info_t is pooled instead of Newxz/Safefree
  # per call. Every field here declares args, so every call goes through
  # the cb5 ABI and builds/tears down a pooled LazyInfo - some resolvers die,
  # to also exercise the pool along the field-error path.
  my $Item = GraphQL::Houtou::Type::Object->new(
    name => 'LazyInfoPoolItem',
    fields => {
      label => {
        type => $String,
        args => { prefix => { type => $String } },
        resolve => sub {
          my (undef, $args, undef, $info) = @_;
          die "boom for $info->{field_name}\n" if $args->{prefix} eq 'boom';
          return "$args->{prefix}:$info->{path}[-1]";
        },
      },
    },
  );
  my $pool_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
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
  for my $i (1 .. 200) {
    my $prefix = $i % 5 == 0 ? 'boom' : "p$i";
    my $r = $pool_schema->execute(
      'query Q($ids: [String], $p: String) { items(ids: $ids) { label(prefix: $p) } }',
      variables => { ids => [ map { "id$_" } 1 .. 10 ], p => $prefix },
    );
    if ($prefix eq 'boom') {
      ok $r->{errors} && @{ $r->{errors} } == 10, "iteration $i: every item errors" or last;
    } else {
      is scalar(@{ $r->{data}{items} }), 10, "iteration $i: every item resolved" or last;
    }
  }
  assert_no_live_frames('200 args-bearing resolver iterations (LazyInfo pool)');
};

subtest 'cancelling a request with a suspended list-item child block stays clean' => sub {
  # Phase 11: a list item's own child block now suspends via a raw
  # block_frame_t linked directly into list_pending (gql_runtime_vm_
  # list_pending_link_child_frame), not a Promise::XS. Abandoning the
  # request while that item is still genuinely pending - on_stall dies,
  # or a stall is detected - must reach and release that linked child
  # frame via gql_runtime_vm_cancel_frame_tree's new LIST_PENDING_PTR
  # recursion, or it (and the list_pending itself) leaks.
  my $Row = GraphQL::Houtou::Type::Object->new(
    name => 'CancelRow',
    fields => {
      name => { type => $String, resolve => sub { "n:$_[0]{id}" } },
      pending => {
        type => $String,
        args => { key => { type => $String } },
        resolve => sub {
          my (undef, $args, $ctx) = @_;
          return $ctx->{loader}->load($args->{key});
        },
      },
    },
  );
  my $cancel_schema = GraphQL::Houtou::Schema->new(
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
  my $runtime = build_native_runtime($cancel_schema, async => 1);

  my $loader1 = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $err1 = do {
    local $@;
    eval {
      $runtime->execute_document(
        'query Q($ids: [String], $k: String) { rows(ids: $ids) { name pending(key: $k) } }',
        variables => { ids => [ 'a1', 'a2' ], k => 'k1' },
        context => { loader => $loader1 },
        on_stall => sub { die "on_stall boom\n" },
      );
    };
    $@;
  };
  like $err1, qr/on_stall boom/, 'the on_stall die propagates';
  assert_no_live_frames('after on_stall die with a suspended list item');

  my $loader2 = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $err2 = do {
    local $@;
    eval {
      $runtime->execute_document(
        'query Q($ids: [String], $k: String) { rows(ids: $ids) { name pending(key: $k) } }',
        variables => { ids => [ 'b1', 'b2' ], k => 'k2' },
        context => { loader => $loader2 },
        on_stall => sub { 0 },
      );
    };
    $@;
  };
  like $err2, qr/GraphQL execution stalled.*on_stall made no progress/s, 'reports the stall';
  assert_no_live_frames('after stall detection with a suspended list item');

  my $loader3 = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $r = $runtime->execute_document(
    'query Q($ids: [String], $k: String) { rows(ids: $ids) { name pending(key: $k) } }',
    variables => { ids => [ 'c1', 'c2' ], k => 'k3' },
    context => { loader => $loader3 },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader3),
  );
  is_deeply $r, {
    data => { rows => [
      { name => 'n:c1', pending => 'v:k3' },
      { name => 'n:c2', pending => 'v:k3' },
    ] },
  }, 'the runtime executes normally after the earlier cancellations';
  assert_no_live_frames('after a normal request following the cancellations');
};

subtest 'a mix of sync, ticket-mediated, and raw-linked list items settles together' => sub {
  # Phase 11 only changes items whose OWN child block suspends (an
  # object/abstract item field); a leaf-typed list item whose resolver
  # directly returns a pending Ticket (no child block at all) still goes
  # through the existing Promise::XS/Ticket-subscribe path in
  # gql_runtime_vm_list_pending_handle_sv. Mix both shapes plus an
  # already-synchronous item in one request to confirm they settle
  # together correctly.
  my $Item = GraphQL::Houtou::Type::Object->new(
    name => 'MixedItem',
    fields => {
      label => { type => $String, resolve => sub { "label:$_[0]{id}" } },
      pending => {
        type => $String,
        args => { key => { type => $String } },
        resolve => sub {
          my (undef, $args, $ctx) = @_;
          return $ctx->{loader}->load($args->{key});
        },
      },
    },
  );
  my $mixed_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        # An object-typed list: items whose own "pending" field suspends
        # go through the new raw-frame linkage.
        items => {
          type => GraphQL::Houtou::Type::List->new(of => $Item),
          args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
          resolve => sub {
            my (undef, $args) = @_;
            return [ map { { id => $_ } } @{ $args->{ids} } ];
          },
        },
        # A leaf-typed list whose resolver returns the tickets directly:
        # no child block, so this stays on the existing Ticket-subscribe
        # path in list_pending_handle_sv.
        leaves => {
          type => GraphQL::Houtou::Type::List->new(of => $String),
          args => { ids => { type => GraphQL::Houtou::Type::List->new(of => $String) } },
          resolve => sub {
            my (undef, $args, $ctx) = @_;
            return [ map { $ctx->{leaf_loader}->load($_) } @{ $args->{ids} } ];
          },
        },
      },
    ),
  );
  my $mixed_runtime = build_native_runtime($mixed_schema, async => 1);
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $leaf_loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "leaf:$_" } @$ids ] },
  );
  my $r = $mixed_runtime->execute_document(
    'query Q($ids: [String], $lids: [String], $k: String) {
      items(ids: $ids) { label pending(key: $k) }
      leaves(ids: $lids)
    }',
    variables => { ids => [ 'm1', 'm2' ], lids => [ 'l1', 'l2' ], k => 'k1' },
    context => { loader => $loader, leaf_loader => $leaf_loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader, $leaf_loader),
  );
  is_deeply $r, {
    data => {
      items => [
        { label => 'label:m1', pending => 'v:k1' },
        { label => 'label:m2', pending => 'v:k1' },
      ],
      leaves => [ 'leaf:l1', 'leaf:l2' ],
    },
  }, 'raw-linked object items and ticket-mediated leaf items both settle correctly';
  assert_no_live_frames('after a mixed sync/ticket/raw-linked request');
};

done_testing;
