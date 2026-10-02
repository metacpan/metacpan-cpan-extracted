use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );

use MCP::K8s;

# Tier 3 reads $ENV{KUBECONFIG} first and $ENV{HOME}/.kube/config second
# (Kubernetes::REST::Kubeconfig). The two subtests that assert a Tier 3
# *failure* therefore only hold on a machine with no kubeconfig at all --
# with a real ~/.kube/config present the lookup succeeded and the expected
# failure never came, so the suite failed on every developer box and any CI
# that writes a kubeconfig. Point both variables at an empty directory in
# those subtests instead of assuming the machine has none.
my $NO_KUBECONFIG_HOME = tempdir( CLEANUP => 1 );

# =================================================================
# Regression tests for Issue #1: MCP_K8S_TOKEN alone did not engage
# Tier 1 (direct-token authentication).
#
# Root cause was Moo's `predicate => 1` returning false on a lazy
# attribute whose default reads from $ENV, until the reader is
# actually called once. The fix materializes the value in _build_api
# before checking it, rather than gating on the predicate.
#
# These tests pin down the post-fix behavior: Tier 1 engages when the
# env-var holds a non-empty token, falls through to Tier 3 on an
# empty token, and the predicate semantics are preserved for callers
# that don't touch ->api.
# =================================================================

# No mocks needed for Tier 1 / Tier 2 — Kubernetes::REST->new() does not
# contact the cluster on construction. Tier 3 is exercised by reaching
# the recognizable "Kubeconfig not found" failure, with $NO_KUBECONFIG_HOME
# making sure there really is none to find.

subtest 'Issue #1: env-token alone engages Tier 1 with in-cluster default' => sub {
  # The exact failure case from the bug report: MCP_K8S_TOKEN set, no
  # MCP_K8S_SERVER, no constructor arg, no in-cluster mount.
  local $ENV{MCP_K8S_TOKEN}  = 'regression-token-001';
  local $ENV{MCP_K8S_SERVER} = undef;
  delete $ENV{MCP_K8S_SERVER};

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");
  isa_ok($api, 'Kubernetes::REST', 'Tier 1 returned a Kubernetes::REST instance');
  is($api->server->{endpoint},
    'https://kubernetes.default.svc.cluster.local',
    'Tier 1 fell back to in-cluster default endpoint');
  is($api->credentials->{token}, 'regression-token-001',
    'Tier 1 carried the env-provided token');
};

subtest 'Issue #1: env-token + env-server engages Tier 1 with explicit endpoint' => sub {
  local $ENV{MCP_K8S_TOKEN}  = 'regression-token-002';
  local $ENV{MCP_K8S_SERVER} = 'https://custom.example:6443';

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");
  isa_ok($api, 'Kubernetes::REST', 'Tier 1 returned a Kubernetes::REST instance');
  is($api->server->{endpoint}, 'https://custom.example:6443',
    'Tier 1 honored the env-provided server');
  is($api->credentials->{token}, 'regression-token-002',
    'Tier 1 carried the env-provided token');
};

subtest 'Issue #1: empty env-token is treated as "no token"' => sub {
  # An explicitly-empty token must not silently engage Tier 1 — that
  # would mask a misconfiguration. Empty string falls through.
  local $ENV{MCP_K8S_TOKEN}  = '';
  local $ENV{MCP_K8S_SERVER} = undef;
  delete $ENV{MCP_K8S_SERVER};
  local $ENV{HOME} = $NO_KUBECONFIG_HOME;
  delete local $ENV{KUBECONFIG};

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  my $api = eval { $k8s->api };
  ok($@, 'api construction failed with empty env-token');
  like($@, qr/Kubeconfig not found|kubeconfig|config/i,
    'Tier 3 path reached: kubeconfig lookup attempted after Tier 1/2 fell through');
};

subtest 'Issue #1: empty env-server alongside env-token uses in-cluster default' => sub {
  local $ENV{MCP_K8S_TOKEN}  = 'regression-token-003';
  local $ENV{MCP_K8S_SERVER} = '';

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");
  is($api->server->{endpoint},
    'https://kubernetes.default.svc.cluster.local',
    'empty server string treated as "unset", in-cluster default applied');
};

subtest 'Issue #1: constructor-arg token still works (predicate path unchanged)' => sub {
  # The predicate gate was only broken for env-driven values. An
  # explicit constructor arg sets the attribute directly, so the
  # predicate is true from the start and the old code path worked.
  local $ENV{MCP_K8S_TOKEN} = undef;
  delete $ENV{MCP_K8S_TOKEN};

  my $k8s = MCP::K8s->new(
    token      => 'ctor-token-004',
    namespaces => ['default'],
  );
  ok($k8s->has_token, 'has_token predicate true with constructor arg');
  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");
  is($api->credentials->{token}, 'ctor-token-004',
    'Tier 1 carried the constructor-supplied token');
};

subtest 'Issue #1: predicate semantics preserved when ->api is not touched' => sub {
  # Pins down the contract relied on by the existing predicate tests:
  # before any reader or builder access, the predicate reflects what
  # was explicitly provided, not what the env currently holds.
  local $ENV{MCP_K8S_TOKEN}  = 'env-token-005';
  local $ENV{MCP_K8S_SERVER} = 'https://s:6443';

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  ok(!$k8s->has_token,
    'has_token false until the reader triggers the lazy default');
  ok(!$k8s->has_server_endpoint,
    'has_server_endpoint false until the reader triggers the lazy default');

  # Reading the values once materializes them via the default builder
  # and flips the predicates — standard Moo lazy-with-default behavior.
  $k8s->token;
  $k8s->server_endpoint;
  ok($k8s->has_token, 'has_token true after reading the value');
  ok($k8s->has_server_endpoint,
    'has_server_endpoint true after reading the value');
};

subtest 'Issue #1: predicates false when env unset and api untouched' => sub {
  local $ENV{MCP_K8S_TOKEN}  = undef;
  local $ENV{MCP_K8S_SERVER} = undef;
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  ok(!$k8s->has_token,
    'has_token false when env unset and api untouched');
  ok(!$k8s->has_server_endpoint,
    'has_server_endpoint false when env unset and api untouched');
};

subtest 'Issue #1: predicate state after ->api built when Tier 1 engaged' => sub {
  # When Tier 1 engages, both token and server_endpoint readers fire
  # inside _build_api, so both predicates become true after construction.
  local $ENV{MCP_K8S_TOKEN}  = 'regression-token-006';
  local $ENV{MCP_K8S_SERVER} = 'https://s:6443';

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");
  ok($k8s->has_token,
    'has_token true after _build_api engaged Tier 1');
  ok($k8s->has_server_endpoint,
    'has_server_endpoint true after _build_api engaged Tier 1');
};

subtest 'Issue #1: predicate state after ->api built when Tier 1 fell through' => sub {
  # When Tier 1 falls through (token unset/empty), the fix only
  # materializes `token` and never reads `server_endpoint`. So the
  # token predicate flips true after _build_api runs, but
  # server_endpoint stays false. This is the asymmetry introduced
  # by the fix; pinning it here so a future refactor that reads
  # both eagerly has to think about it.
  local $ENV{MCP_K8S_TOKEN}  = '';
  local $ENV{MCP_K8S_SERVER} = undef;
  delete $ENV{MCP_K8S_SERVER};
  local $ENV{HOME} = $NO_KUBECONFIG_HOME;
  delete local $ENV{KUBECONFIG};

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  my $api = eval { $k8s->api };
  ok($@, 'api construction failed (Tier 1 skipped, no in-cluster, no kubeconfig)');
  ok($k8s->has_token,
    'has_token true after _build_api (token reader fired even though value was empty)');
  ok(!$k8s->has_server_endpoint,
    'has_server_endpoint stays false (Tier 1 did not engage, server_endpoint never read)');
};

# =================================================================
# Regression tests for Issue #2: MCP_K8S_CONTEXT alone did not
# reach Kubernetes::REST::Kubeconfig. Same predicate-with-lazy-
# default trap as Issue #1: has_context_name stays false until the
# reader fires, so an env-only context was silently dropped. The
# fix materializes via the reader and gates on definedness + length,
# passing the env value through while leaving empty/undef intact so
# Kubeconfig's current-context fallback still applies.
# =================================================================

{
  package MockKubeconfigRecorder;
  our @invocations;

  sub new {
    my ($class, %args) = @_;
    push @MockKubeconfigRecorder::invocations, {%args};
    # Bless into the recorder package, not the caller's class — the
    # override is invoked as Kubernetes::REST::Kubeconfig->new, so $class
    # is that class. Re-blessing there would route $kc->api through the
    # real Moo metaclass and re-trigger the upstream kubeconfig lookup.
    return bless { args => \%args }, __PACKAGE__;
  }

  # _build_api returns $kc->api; any truthy value suffices because
  # none of these tests inspect downstream api properties.
  sub api { return $_[0]; }
}

subtest 'Issue #2: env-context alone engages Kubeconfig context_name' => sub {
  # The exact failure case from the bug report: MCP_K8S_CONTEXT set,
  # no MCP_K8S_TOKEN, no MCP_K8S_SERVER, no constructor arg. Pre-fix
  # the predicate gate silently dropped the env value; post-fix it
  # reaches Kubeconfig.
  local $ENV{MCP_K8S_TOKEN}    = undef;
  local $ENV{MCP_K8S_SERVER}   = undef;
  local $ENV{MCP_K8S_CONTEXT}  = 'staging-cluster';
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};

  local @MockKubeconfigRecorder::invocations;

  # Capture exactly what _build_api hands to the Kubeconfig constructor.
  # The `local` restores the real constructor when this subtest returns,
  # so other subtests (and other files in the suite) are unaffected.
  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");

  is(scalar @MockKubeconfigRecorder::invocations, 1,
    'Kubeconfig->new called exactly once');
  is($MockKubeconfigRecorder::invocations[0]{context_name},
    'staging-cluster',
    'env context_name propagated to Kubeconfig');
};

subtest 'Issue #2: empty env-context drops context_name from Kubeconfig args' => sub {
  # An explicitly-empty context_name must not be passed — passing ''
  # would defeat Kubeconfig's current-context fallback, which a
  # user expects when they unset MCP_K8S_CONTEXT by emptying it.
  local $ENV{MCP_K8S_TOKEN}    = undef;
  local $ENV{MCP_K8S_SERVER}   = undef;
  local $ENV{MCP_K8S_CONTEXT}  = '';
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};

  local @MockKubeconfigRecorder::invocations;

  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");

  is(scalar @MockKubeconfigRecorder::invocations, 1,
    'Kubeconfig->new called exactly once');
  ok(!exists $MockKubeconfigRecorder::invocations[0]{context_name},
    'empty env-context not passed to Kubeconfig (preserves current-context fallback)');
};

subtest 'Issue #2: constructor-arg context_name still flows through (predicate path)' => sub {
  # The predicate gate was only broken for env-driven values. An
  # explicit constructor arg sets the attribute directly, so the
  # predicate is true from the start and the old code path worked.
  local $ENV{MCP_K8S_TOKEN}    = undef;
  local $ENV{MCP_K8S_SERVER}   = undef;
  local $ENV{MCP_K8S_CONTEXT}  = undef;
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};
  delete $ENV{MCP_K8S_CONTEXT};

  local @MockKubeconfigRecorder::invocations;

  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s = MCP::K8s->new(
    context_name => 'dev-cluster',
    namespaces   => ['default'],
  );
  ok($k8s->has_context_name,
    'has_context_name true with explicit constructor arg');

  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");

  is(scalar @MockKubeconfigRecorder::invocations, 1,
    'Kubeconfig->new called exactly once');
  is($MockKubeconfigRecorder::invocations[0]{context_name}, 'dev-cluster',
    'constructor-arg context_name propagated to Kubeconfig');
};

subtest 'Issue #2: no context_name when env unset and ctor absent' => sub {
  # Default behavior: user provides nothing for MCP_K8S_CONTEXT and
  # does not pass a constructor arg. Kubeconfig's current-context
  # fallback should remain in effect — no context_name in the args.
  local $ENV{MCP_K8S_TOKEN}    = undef;
  local $ENV{MCP_K8S_SERVER}   = undef;
  local $ENV{MCP_K8S_CONTEXT}  = undef;
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};
  delete $ENV{MCP_K8S_CONTEXT};

  local @MockKubeconfigRecorder::invocations;

  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  ok(!$k8s->has_context_name,
    'has_context_name false when env unset and ctor absent');

  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");

  is(scalar @MockKubeconfigRecorder::invocations, 1,
    'Kubeconfig->new called exactly once');
  ok(!exists $MockKubeconfigRecorder::invocations[0]{context_name},
    'context_name not passed when nothing set (Kubeconfig falls back to current-context)');
};

subtest 'Issue #2: predicate semantics preserved when ->api is not touched' => sub {
  # Pin down the lazy-with-default contract: the predicate reflects
  # whether the attribute has been materialized, not what the env
  # currently holds. Callers that inspect has_context_name without
  # triggering _build_api rely on this — same shape as Issue #1.
  local $ENV{MCP_K8S_TOKEN}   = undef;
  local $ENV{MCP_K8S_SERVER}  = undef;
  local $ENV{MCP_K8S_CONTEXT} = 'env-only-context';
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  ok(!$k8s->has_context_name,
    'has_context_name false until the reader triggers the lazy default');

  $k8s->context_name;
  ok($k8s->has_context_name,
    'has_context_name true after reading the value');

  # Distinct instance, env unset, no ctor, no read — predicate stays false
  local $ENV{MCP_K8S_CONTEXT} = undef;
  delete $ENV{MCP_K8S_CONTEXT};
  my $k8s2 = MCP::K8s->new(namespaces => ['default']);
  ok(!$k8s2->has_context_name,
    'has_context_name false when env unset, no ctor, no read');
};

subtest 'Issue #2: predicate state after _build_api with env-set context_name' => sub {
  # Mirror of the Issue #1 "predicate state after ->api built" pin, but
  # for context_name. After _build_api materializes the lazy default,
  # has_context_name becomes true — same Moo lazy-with-default shape.
  local $ENV{MCP_K8S_TOKEN}   = undef;
  local $ENV{MCP_K8S_SERVER}  = undef;
  local $ENV{MCP_K8S_CONTEXT} = 'staging-cluster';
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};

  local @MockKubeconfigRecorder::invocations;

  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  ok(!$k8s->has_context_name,
    'has_context_name false before _build_api (env default not yet triggered)');

  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");

  ok($k8s->has_context_name,
    'has_context_name true after _build_api (context_name reader fired)');
};

subtest 'Issue #2: predicate state after _build_api with constructor context_name' => sub {
  # The ctor arg sets the attribute directly, so has_context_name is
  # true from the start and stays true after _build_api.
  local $ENV{MCP_K8S_TOKEN}   = undef;
  local $ENV{MCP_K8S_SERVER}  = undef;
  local $ENV{MCP_K8S_CONTEXT} = undef;
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};
  delete $ENV{MCP_K8S_CONTEXT};

  local @MockKubeconfigRecorder::invocations;

  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s = MCP::K8s->new(
    context_name => 'ctor-context',
    namespaces   => ['default'],
  );
  ok($k8s->has_context_name,
    'has_context_name true at construction with ctor arg');

  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");

  ok($k8s->has_context_name,
    'has_context_name remains true after _build_api');
};

subtest 'Issue #2: predicate stays false after _build_api when nothing was set' => sub {
  # The fix materializes the lazy default inside _build_api even when
  # its value is empty/undef — same asymmetry Issue #1 pins for the
  # token side. Mirroring: has_context_name flips true after _build_api
  # regardless of the materialized value, because the reader fired.
  local $ENV{MCP_K8S_TOKEN}   = undef;
  local $ENV{MCP_K8S_SERVER}  = undef;
  local $ENV{MCP_K8S_CONTEXT} = undef;
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};
  delete $ENV{MCP_K8S_CONTEXT};

  local @MockKubeconfigRecorder::invocations;

  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  ok(!$k8s->has_context_name,
    'has_context_name false before _build_api');

  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");

  ok($k8s->has_context_name,
    'has_context_name true after _build_api (reader fired on undef env)');
  is($k8s->context_name, undef,
    'context_name materializes to undef when env unset');
};

subtest 'Issue #2: empty-string env and undef env produce equivalent Kubeconfig args' => sub {
  # Both `MCP_K8S_CONTEXT=""` and an unset MCP_K8S_CONTEXT must result
  # in NO context_name reaching Kubeconfig — the length check treats
  # them identically so Kubeconfig keeps its current-context fallback.
  local $ENV{MCP_K8S_TOKEN}   = undef;
  local $ENV{MCP_K8S_SERVER}  = undef;
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};

  local @MockKubeconfigRecorder::invocations;

  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  # Case A: empty-string env
  local $ENV{MCP_K8S_CONTEXT} = '';
  my $k8s_empty = MCP::K8s->new(namespaces => ['default']);
  my $api_empty = eval { $k8s_empty->api };
  ok(!$@, 'empty-string env: api built without error');
  ok(!exists $MockKubeconfigRecorder::invocations[-1]{context_name},
    'empty-string env: context_name absent from Kubeconfig args');

  # Case B: undef/unset env
  local $ENV{MCP_K8S_CONTEXT} = undef;
  delete $ENV{MCP_K8S_CONTEXT};
  my $k8s_undef = MCP::K8s->new(namespaces => ['default']);
  my $api_undef = eval { $k8s_undef->api };
  ok(!$@, 'unset env: api built without error');
  ok(!exists $MockKubeconfigRecorder::invocations[-1]{context_name},
    'unset env: context_name absent from Kubeconfig args');

  is(scalar @MockKubeconfigRecorder::invocations, 2,
    'Kubeconfig->new was called for each scenario');
};

subtest 'Issue #2: explicit ctor context_name wins over env value' => sub {
  # When both MCP_K8S_CONTEXT and a constructor arg are set, the
  # constructor arg takes precedence — Moo stores only the ctor value
  # and the env-backed default never fires. Pin this precedence so a
  # future refactor doesn't accidentally clobber an explicit arg.
  local $ENV{MCP_K8S_TOKEN}   = undef;
  local $ENV{MCP_K8S_SERVER}  = undef;
  local $ENV{MCP_K8S_CONTEXT} = 'env-would-set-this';
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};

  local @MockKubeconfigRecorder::invocations;

  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s = MCP::K8s->new(
    context_name => 'ctor-wins',
    namespaces   => ['default'],
  );

  is($k8s->context_name, 'ctor-wins',
    'context_name reader returns ctor value, not env value');

  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag("error: $@");

  is($MockKubeconfigRecorder::invocations[0]{context_name}, 'ctor-wins',
    'ctor value reaches Kubeconfig, env value is shadowed');
};

done_testing;
