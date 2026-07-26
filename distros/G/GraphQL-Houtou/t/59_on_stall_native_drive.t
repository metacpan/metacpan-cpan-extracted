use strict;
use warnings;
use Test::More;

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);
use GraphQL::Houtou::DataLoader;

BEGIN {
  eval { require Promise::XS; 1 }
    or plan skip_all => 'Promise::XS is required for async execution tests';
}

# Phase 8: execute_program's on_stall branch now drives a fast-lane-eligible
# request to completion entirely in C (gql_runtime_vm_drive_with_on_stall_sv),
# never building a Promise::XS for the response. These are the croak-safety
# checks t/34_exec_state_croak_safety.t established for the old path, run
# against the new one: a die anywhere in the chain (resolver, batch
# function, on_stall itself) must propagate correctly and leave the runtime
# usable afterward, with no leaked block_frame_t/path_frame_t.

sub live_counts { GraphQL::Houtou::XS::VM::debug_frame_live_counts_xs() }

sub assert_no_live_frames {
  my ($label) = @_;
  my $c = live_counts();
  is $c->{block_frame}, 0, "$label: no live block frames";
  is $c->{path_frame}, 0, "$label: no live path frames";
}

my $Team = GraphQL::Houtou::Type::Object->new(
  name => 'NativeDriveTeam',
  fields => {
    name => {
      type => $String,
      args => { key => { type => $String } },
      resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
    },
  },
);
my $User = GraphQL::Houtou::Type::Object->new(
  name => 'NativeDriveUser',
  fields => {
    name => { type => $String, resolve => sub { "n:$_[0]{id}" } },
    team => { type => $Team, resolve => sub { {} } },
  },
);
my $schema = GraphQL::Houtou::Schema->new(
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
my $runtime = build_native_runtime($schema, async => 1);
my $QUERY = 'query q($id: String, $k: String) { user(id: $id) { name team { name(key: $k) } } }';

subtest 'fully synchronous request needs no on_stall progress' => sub {
  assert_no_live_frames('before');
  my $loader = GraphQL::Houtou::DataLoader->new(batch => sub { die "should not dispatch\n" });
  my $r = $runtime->execute_document(
    'query q($id: String) { user(id: $id) { name } }',
    variables => { id => 'u1' },
    context => { loader => $loader },
    on_stall => sub { 0 },
  );
  is_deeply $r, { data => { user => { name => 'n:u1' } } }, 'resolves without ever calling on_stall';
  assert_no_live_frames('after fully synchronous request');
};

subtest 'DataLoader-driven nested suspend settles correctly' => sub {
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $r = $runtime->execute_document(
    $QUERY,
    variables => { id => 'u1', k => 'k1' },
    context => { loader => $loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
  );
  is_deeply $r, { data => { user => { name => 'n:u1', team => { name => 'v:k1' } } } },
    'resolves through the C-driven on_stall loop';
  assert_no_live_frames('after nested suspend');
};

subtest 'a resolver dying propagates as a field error and the runtime stays usable' => sub {
  my $Boom = GraphQL::Houtou::Type::Object->new(
    name => 'BoomUser',
    fields => {
      boom => {
        type => $String,
        resolve => sub {
          my (undef, undef, $ctx) = @_;
          return $ctx->{loader}->load('k')->then(sub { die "resolver boom\n" });
        },
      },
    },
  );
  my $boom_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => { user => { type => $Boom, resolve => sub { {} } } },
    ),
  );
  my $boom_runtime = build_native_runtime($boom_schema, async => 1);
  my $loader = GraphQL::Houtou::DataLoader->new(batch => sub { return [ map { "v:$_" } @{ $_[0] } ] });
  my $r = $boom_runtime->execute_document(
    '{ user { boom } }',
    context => { loader => $loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
  );
  is $r->{data}{user}{boom}, undef, 'the boom field is null';
  like $r->{errors}[0]{message}, qr/resolver boom/, 'the die became a field error';
  assert_no_live_frames('after resolver die');

  my $loader2 = GraphQL::Houtou::DataLoader->new(batch => sub { return [ map { "v:$_" } @{ $_[0] } ] });
  my $r2 = $boom_runtime->execute_document(
    '{ user { boom } }',
    context => { loader => $loader2 },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader2),
  );
  is $r2->{data}{user}{boom}, undef, 'boom_runtime executes normally after the escaped resolver-side die';
};

subtest 'a batch function dying becomes a field error, not an exception, and cleans up' => sub {
  # DataLoader::dispatch's XS _dispatch_queue calls the batch sub with
  # G_EVAL and settles every queued ticket with the caught error instead of
  # letting the die escape - matching the framework's general "never let a
  # single resolver/loader failure abort the whole request" philosophy.
  my $loader = GraphQL::Houtou::DataLoader->new(batch => sub { die "batch boom\n" });
  my $r = $runtime->execute_document(
    $QUERY,
    variables => { id => 'u3', k => 'k3' },
    context => { loader => $loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
  );
  is $r->{data}{user}{team}{name}, undef, 'the team.name field is null';
  like $r->{errors}[0]{message}, qr/batch boom/, 'the batch die became a field error';
  assert_no_live_frames('after batch die');

  my $loader2 = GraphQL::Houtou::DataLoader->new(batch => sub { return [ map { "v:$_" } @{ $_[0] } ] });
  my $r2 = $runtime->execute_document(
    $QUERY,
    variables => { id => 'u4', k => 'k4' },
    context => { loader => $loader2 },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader2),
  );
  is_deeply $r2, { data => { user => { name => 'n:u4', team => { name => 'v:k4' } } } },
    'the runtime executes normally after the earlier batch die';
};

subtest 'on_stall itself dying while a plain Promise::XS is pending propagates cleanly' => sub {
  # A resolver-returned Promise::XS (as opposed to a DataLoader Ticket, see
  # the subtest below) is entirely internal to this request - nothing
  # external keeps a reference to it - so cancelling the exec state on the
  # caught die (gql_runtime_vm_call_on_stall_once) is sufficient to release
  # everything.
  my $pending_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        hang => { type => $String, resolve => sub { Promise::XS::deferred()->promise } },
      },
    ),
  );
  my $pending_runtime = build_native_runtime($pending_schema, async => 1);
  my $err = do {
    local $@;
    eval { $pending_runtime->execute_document('{ hang }', on_stall => sub { die "on_stall boom\n" }) };
    $@;
  };
  like $err, qr/on_stall boom/, 'the on_stall die propagates';
  assert_no_live_frames('after on_stall die (plain Promise::XS pending)');
};

subtest 'on_stall itself dying while a DataLoader Ticket is pending propagates cleanly' => sub {
  # Unlike a plain Promise::XS, a DataLoader Ticket that never gets
  # dispatched is kept alive independent of the exec state: subscribing to
  # it (gql_runtime_vm_subscribe_dataloader_ticket) pushes our resolve/
  # reject callback pair onto the Ticket's own subscriber list, which the
  # DataLoader's own queue can keep alive well past the abandoned request.
  # gql_runtime_vm_cancel_frame_tree disarms that pair's ctx (dropping its
  # state_sv/frame refs) so this does not leak the frame tree.
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $err = do {
    local $@;
    eval {
      $runtime->execute_document(
        $QUERY,
        variables => { id => 'u5', k => 'k5' },
        context => { loader => $loader },
        on_stall => sub { die "on_stall boom\n" },
      );
    };
    $@;
  };
  like $err, qr/on_stall boom/, 'the on_stall die propagates';
  assert_no_live_frames('after on_stall die (DataLoader Ticket pending)');
};

subtest 'stall detection (on_stall makes no progress) reports the deadlock and cleans up' => sub {
  # A plain Promise::XS that never settles: on_stall reporting zero
  # progress every round is the deadlock path.
  my $pending_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        hang => { type => $String, resolve => sub { Promise::XS::deferred()->promise } },
      },
    ),
  );
  my $pending_runtime = build_native_runtime($pending_schema, async => 1);
  my $err = do {
    local $@;
    eval { $pending_runtime->execute_document('{ hang }', on_stall => sub { 0 }) };
    $@;
  };
  like $err, qr/GraphQL execution stalled.*on_stall made no progress/s,
    'reports the same stall message as the Perl-driven path';
  assert_no_live_frames('after stall detection');
};

subtest 'stall detection with a pending DataLoader Ticket cleans up the same way' => sub {
  # Same root cause/fix as the subtest above, reached via the ordinary
  # zero-progress deadlock path instead of on_stall dying.
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $err = do {
    local $@;
    eval {
      $runtime->execute_document(
        $QUERY,
        variables => { id => 'u8', k => 'k8' },
        context => { loader => $loader },
        on_stall => sub { 0 },
      );
    };
    $@;
  };
  like $err, qr/GraphQL execution stalled.*on_stall made no progress/s, 'reports the stall';
  assert_no_live_frames('after stall detection (DataLoader Ticket pending)');
};

subtest 'multiple loaders via on_stall_for still resolve across rounds' => sub {
  my $Post = GraphQL::Houtou::Type::Object->new(
    name => 'MultiLoaderPost',
    fields => {
      title => {
        type => $String,
        args => { key => { type => $String } },
        resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{titles}->load($a->{key}) },
      },
      author => {
        type => GraphQL::Houtou::Type::Object->new(
          name => 'MultiLoaderAuthor',
          fields => {
            name => {
              type => $String,
              args => { key => { type => $String } },
              resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{authors}->load($a->{key}) },
            },
          },
        ),
        resolve => sub { {} },
      },
    },
  );
  my $ml_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => { post => { type => $Post, resolve => sub { {} } } },
    ),
  );
  my $ml_runtime = build_native_runtime($ml_schema, async => 1);
  my $titles = GraphQL::Houtou::DataLoader->new(batch => sub { return [ map { "title:$_" } @{ $_[0] } ] });
  my $authors = GraphQL::Houtou::DataLoader->new(batch => sub { return [ map { "author:$_" } @{ $_[0] } ] });
  my $r = $ml_runtime->execute_document(
    'query q($tk: String, $ak: String) { post { title(key: $tk) author { name(key: $ak) } } }',
    variables => { tk => 't1', ak => 'a1' },
    context => { titles => $titles, authors => $authors },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($titles, $authors),
  );
  is_deeply $r, { data => { post => { title => 'title:t1', author => { name => 'author:a1' } } } },
    'both loaders settle across on_stall_for rounds';
  assert_no_live_frames('after multi-loader request');
};

subtest 'repeated nested-suspend requests stay clean over many iterations' => sub {
  for my $i (1 .. 200) {
    my $loader = GraphQL::Houtou::DataLoader->new(
      batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
    );
    my $r = $runtime->execute_document(
      $QUERY,
      variables => { id => "u$i", k => "k$i" },
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
    is_deeply $r, {
      data => { user => { name => "n:u$i", team => { name => "v:k$i" } } },
    }, "iteration $i resolved" or last;
  }
  assert_no_live_frames('200 native-drive iterations');
};

# Item 1 (Phase 9): shapes the fast lane does not cover (a runtime directive
# present, or the nesting-depth guard exceeded) fall back to the generic
# executor, which still builds its own Promise::XS internally - but that
# promise is now driven from C too (gql_runtime_vm_drive_promise_with_on_stall_sv),
# not handed back to Perl's _settle_result. These pin the same settle/
# reject/stall/cleanup contract for that fallback path that the subtests
# above already pin for the fast lane.
subtest 'a runtime-directive sibling forces the generic-executor fallback, still driven natively' => sub {
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $directive_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        plain => { type => $String, resolve => sub { 'plain-val' } },
        loaded => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    ),
  );
  my $directive_runtime = build_native_runtime($directive_schema, async => 1);
  my $r = $directive_runtime->execute_document(
    'query Q($skipIt: Boolean!, $k: String) { plain @skip(if: $skipIt) loaded(key: $k) }',
    variables => { skipIt => 1, k => 'd1' },
    context => { loader => $loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
  );
  ok !exists($r->{data}{plain}), 'skipped field is absent';
  is $r->{data}{loaded}, 'v:d1', 'the pending sibling still resolves via the natively-driven fallback';
  assert_no_live_frames('after runtime-directive fallback settles');
};

subtest 'nesting deeper than the recursion guard falls back safely, still driven natively' => sub {
  # GQL_VM_FAST_LANE_MAX_NESTING_DEPTH is 16 - one level deeper than that
  # forces the generic-executor fallback (see
  # t/39_fast_lane_promise_fallback.t's equivalent depth-guard subtest),
  # this time with a genuinely pending DataLoader ticket at the bottom so
  # the fallback's own Promise::XS response is driven through on_stall.
  my $depth = 17;
  my $innermost = GraphQL::Houtou::Type::Object->new(
    name => 'DeepDriveLevelBottom',
    fields => {
      v => {
        type => $String,
        args => { key => { type => $String } },
        resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
      },
    },
  );
  my @levels = ($innermost);
  for (my $lvl = $depth - 1; $lvl >= 0; $lvl--) {
    my $child = $levels[0];
    unshift @levels, GraphQL::Houtou::Type::Object->new(
      name => "DeepDriveLevel$lvl",
      fields => { next => { type => $child } },
    );
  }
  my $query_inner = join(' ', ('next {') x $depth) . ' v(key: "dd1") ' . ('}' x $depth);
  my $chain_value = {};
  for (1 .. $depth) {
    $chain_value = { next => $chain_value };
  }
  my $deep_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => { root => { type => $levels[0], resolve => sub { $chain_value } } },
    ),
  );
  my $deep_runtime = build_native_runtime($deep_schema, async => 1, max_depth => $depth + 5);
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $r = $deep_runtime->execute_document(
    "{ root { $query_inner } }",
    context => { loader => $loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
  );
  my $expected = { v => 'v:dd1' };
  for (1 .. $depth) {
    $expected = { next => $expected };
  }
  is_deeply $r->{data}{root}, $expected,
    'the over-depth query resolves correctly through the natively-driven fallback';
  assert_no_live_frames('after depth-guard fallback settles');
};

subtest 'a rejection through the generic-executor fallback propagates as a field error and cleans up' => sub {
  my $loader = GraphQL::Houtou::DataLoader->new(batch => sub { die "fallback batch boom\n" });
  my $directive_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        plain => { type => $String, resolve => sub { 'plain-val' } },
        loaded => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    ),
  );
  my $directive_runtime = build_native_runtime($directive_schema, async => 1);
  my $r = $directive_runtime->execute_document(
    'query Q($skipIt: Boolean!, $k: String) { plain @skip(if: $skipIt) loaded(key: $k) }',
    variables => { skipIt => 1, k => 'd2' },
    context => { loader => $loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
  );
  is $r->{data}{loaded}, undef, 'the loaded field is null';
  like $r->{errors}[0]{message}, qr/fallback batch boom/, 'the batch die became a field error';
  assert_no_live_frames('after fallback batch die');
};

subtest 'on_stall itself dying through the generic-executor fallback propagates cleanly' => sub {
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $directive_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        plain => { type => $String, resolve => sub { 'plain-val' } },
        loaded => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    ),
  );
  my $directive_runtime = build_native_runtime($directive_schema, async => 1);
  my $err = do {
    local $@;
    eval {
      $directive_runtime->execute_document(
        'query Q($skipIt: Boolean!, $k: String) { plain @skip(if: $skipIt) loaded(key: $k) }',
        variables => { skipIt => 1, k => 'd3' },
        context => { loader => $loader },
        on_stall => sub { die "fallback on_stall boom\n" },
      );
    };
    $@;
  };
  like $err, qr/fallback on_stall boom/, 'the on_stall die propagates';
  assert_no_live_frames('after fallback on_stall die');
};

subtest 'stall detection through the generic-executor fallback reports the deadlock and cleans up' => sub {
  my $loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($ids) = @_; return [ map { "v:$_" } @$ids ] },
  );
  my $directive_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        plain => { type => $String, resolve => sub { 'plain-val' } },
        loaded => {
          type => $String,
          args => { key => { type => $String } },
          resolve => sub { my (undef, $a, $ctx) = @_; return $ctx->{loader}->load($a->{key}) },
        },
      },
    ),
  );
  my $directive_runtime = build_native_runtime($directive_schema, async => 1);
  my $err = do {
    local $@;
    eval {
      $directive_runtime->execute_document(
        'query Q($skipIt: Boolean!, $k: String) { plain @skip(if: $skipIt) loaded(key: $k) }',
        variables => { skipIt => 1, k => 'd4' },
        context => { loader => $loader },
        on_stall => sub { 0 },
      );
    };
    $@;
  };
  like $err, qr/GraphQL execution stalled.*on_stall made no progress/s, 'reports the stall';
  assert_no_live_frames('after fallback stall detection');
};

done_testing;
