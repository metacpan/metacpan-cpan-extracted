#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::AgentSandbox;

# v1beta1 is modeled to full depth (D5/D6, k95) with named classes, each in
# its own file -- unlike v1alpha1's anonymous inline structs (defined as a
# side effect of loading the Kind's own .pm file), these load lazily on
# first coercion, so the "->can" checks below need them loaded explicitly.
use IO::K8s::AgentSandbox::V1beta1::SandboxSpec;
use IO::K8s::AgentSandbox::V1beta1::SandboxStatus;
use IO::K8s::AgentSandbox::V1beta1::SandboxClaimSpec;
use IO::K8s::AgentSandbox::V1beta1::SandboxClaimStatus;
use IO::K8s::AgentSandbox::V1beta1::SandboxClaimStatusSandbox;
use IO::K8s::AgentSandbox::V1beta1::SandboxTemplateSpec;
use IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolSpec;
use IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolStatus;
use IO::K8s::AgentSandbox::V1beta1::SandboxTemplateRef;
use IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolRef;
use IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolUpdateStrategy;
use IO::K8s::AgentSandbox::V1beta1::Lifecycle;

# --- All AgentSandbox CRD classes (v1alpha1: removed upstream at v1.0.0, kept as
#     back-compat for v0.5.x clusters; v1beta1: current, only upstream-served) ---

my %core_classes = (
    Sandbox => {
        v1alpha1 => { api_version => 'agents.x-k8s.io/v1alpha1', plural => 'sandboxes', namespaced => 1 },
        v1beta1  => { api_version => 'agents.x-k8s.io/v1beta1',  plural => 'sandboxes', namespaced => 1 },
    },
);
my %extension_classes = (
    SandboxClaim    => {
        v1alpha1 => { api_version => 'extensions.agents.x-k8s.io/v1alpha1', plural => 'sandboxclaims',    namespaced => 1 },
        v1beta1  => { api_version => 'extensions.agents.x-k8s.io/v1beta1',  plural => 'sandboxclaims',    namespaced => 1 },
    },
    SandboxTemplate => {
        v1alpha1 => { api_version => 'extensions.agents.x-k8s.io/v1alpha1', plural => 'sandboxtemplates', namespaced => 1 },
        v1beta1  => { api_version => 'extensions.agents.x-k8s.io/v1beta1',  plural => 'sandboxtemplates', namespaced => 1 },
    },
    SandboxWarmPool => {
        v1alpha1 => { api_version => 'extensions.agents.x-k8s.io/v1alpha1', plural => 'sandboxwarmpools', namespaced => 1 },
        v1beta1  => { api_version => 'extensions.agents.x-k8s.io/v1beta1',  plural => 'sandboxwarmpools', namespaced => 1 },
    },
);

my %all_classes = (%core_classes, %extension_classes);

# --- Load all classes (both API versions) ---

subtest 'load all AgentSandbox classes' => sub {
    for my $kind (sort keys %all_classes) {
        for my $ver (qw(v1alpha1 v1beta1)) {
            my $class = "IO::K8s::AgentSandbox::" . ucfirst($ver) . "::$kind";
            use_ok($class) or BAIL_OUT("Cannot load $class");
        }
    }
};

# --- Verify api_version, kind, resource_plural, namespaced for both versions ---

subtest 'class metadata (v1alpha1 and v1beta1)' => sub {
    for my $kind (sort keys %all_classes) {
        for my $ver (qw(v1alpha1 v1beta1)) {
            my $class = "IO::K8s::AgentSandbox::" . ucfirst($ver) . "::$kind";
            my $info  = $all_classes{$kind}{$ver};
            is($class->api_version, $info->{api_version}, "$kind ($ver) api_version");
            is($class->kind, $kind, "$kind ($ver) kind");
            is($class->resource_plural, $info->{plural}, "$kind ($ver) resource_plural");
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind ($ver) is namespaced");
        }
    }
};

# --- IO::K8s::AgentSandbox resource_map: short names resolve to the v1beta1 (storage) class ---

subtest 'IO::K8s::AgentSandbox resource_map' => sub {
    my $provider = IO::K8s::AgentSandbox->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');
    is($provider->upstream_version, 'v1.0.0', 'upstream_version is v1.0.0');
    my $map = $provider->resource_map;

    # 4 short names (each resolving to the v1beta1/storage class) plus 4
    # domain-qualified v1alpha1 keys (k58, k88) -- the v1alpha1 track was
    # removed upstream at v1.0.0 and is kept here as back-compat for v0.5.x
    # clusters, so it does not get a short name of its own; it is reachable
    # only by full class name or by its own domain-qualified key.
    is(scalar keys %$map, 8, 'resource_map has 4 short names + 4 domain-qualified v1alpha1 keys');
    for my $kind (sort keys %all_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "AgentSandbox::V1beta1::$kind", "$kind maps to the v1beta1 (storage) class");
    }
    is($map->{'agents.x-k8s.io/v1alpha1/Sandbox'}, 'AgentSandbox::V1alpha1::Sandbox',
        'domain-qualified v1alpha1 Sandbox key present');
    is($map->{'extensions.agents.x-k8s.io/v1alpha1/SandboxClaim'}, 'AgentSandbox::V1alpha1::SandboxClaim',
        'domain-qualified v1alpha1 SandboxClaim key present');
    is($map->{'extensions.agents.x-k8s.io/v1alpha1/SandboxTemplate'}, 'AgentSandbox::V1alpha1::SandboxTemplate',
        'domain-qualified v1alpha1 SandboxTemplate key present');
    is($map->{'extensions.agents.x-k8s.io/v1alpha1/SandboxWarmPool'}, 'AgentSandbox::V1alpha1::SandboxWarmPool',
        'domain-qualified v1alpha1 SandboxWarmPool key present');
};

# --- new(with => ['IO::K8s::AgentSandbox']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    # Short name resolves to the v1beta1 (storage) class
    for my $kind (sort keys %all_classes) {
        is($k8s->expand_class($kind), "IO::K8s::AgentSandbox::V1beta1::$kind",
            "expand_class('$kind') resolves to v1beta1");
    }

    # Domain-qualified access reaches BOTH tracks (k58). v1beta1 is
    # reachable via the qualified key add() derives from the short-name
    # registration; v1alpha1 is reachable because the resource_map ships its
    # own domain-qualified keys for it directly (see
    # IO::K8s::AgentSandbox::resource_map). This does NOT follow the
    # ValidatingAdmissionPolicy precedent in IO::K8s.pm (a bare short name
    # maps only to its GA class, and the older v1beta1/v1alpha1 tracks
    # fail-close under a domain-qualified lookup): that precedent applies
    # where there IS a GA release to prefer. AgentSandbox has no GA version at
    # all -- v1beta1 is the current (and now only) upstream-served version,
    # v1alpha1 was removed upstream at v1.0.0 and is kept here as back-compat,
    # and IO::K8s::AgentSandbox's own POD has always
    # promised this lookup ("via domain-qualified lookup (e.g.
    # agents.x-k8s.io/v1alpha1/Sandbox)"). All eight GVK combinations (2
    # tracks x 4 kinds) resolve; the four short names stay pinned to v1beta1
    # regardless of track.
    for my $kind (sort keys %all_classes) {
        for my $ver (qw(v1alpha1 v1beta1)) {
            my $api_version = $all_classes{$kind}{$ver}{api_version};
            my $expected = "IO::K8s::AgentSandbox::" . ucfirst($ver) . "::$kind";
            is($k8s->expand_class("$api_version/$kind"), $expected,
                "domain-qualified '$api_version/$kind' resolves");
            is($k8s->expand_class($kind, $api_version), $expected,
                "expand_class('$kind', '$api_version') resolves");
        }
    }

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'core Pod still resolves');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment',
        'core Deployment still resolves');
};

# --- new_object + inflate round-trip (short name -> v1beta1) ---

subtest 'new_object and inflate round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    # Create a Sandbox with minimal spec - resolves to v1beta1 (storage version)
    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'my-sandbox', namespace => 'default' },
    );
    isa_ok($sandbox, 'IO::K8s::AgentSandbox::V1beta1::Sandbox');
    is($sandbox->kind, 'Sandbox', 'kind');
    is($sandbox->api_version, 'agents.x-k8s.io/v1beta1', 'api_version');
    is($sandbox->metadata->name, 'my-sandbox', 'name');
    is($sandbox->metadata->namespace, 'default', 'namespace');

    # Create a SandboxClaim
    my $claim = $k8s->new_object('SandboxClaim',
        metadata => { name => 'my-claim', namespace => 'default' },
    );
    isa_ok($claim, 'IO::K8s::AgentSandbox::V1beta1::SandboxClaim');
    is($claim->api_version, 'extensions.agents.x-k8s.io/v1beta1', 'claim api_version');

    # Create a SandboxTemplate
    my $template = $k8s->new_object('SandboxTemplate',
        metadata => { name => 'my-template', namespace => 'default' },
    );
    isa_ok($template, 'IO::K8s::AgentSandbox::V1beta1::SandboxTemplate');

    # The v1alpha1 track remains constructible via its full class name
    my $legacy_sandbox = $k8s->struct_to_object(
        'IO::K8s::AgentSandbox::V1alpha1::Sandbox',
        { metadata => { name => 'legacy-sandbox', namespace => 'default' } },
    );
    isa_ok($legacy_sandbox, 'IO::K8s::AgentSandbox::V1alpha1::Sandbox');
    is($legacy_sandbox->api_version, 'agents.x-k8s.io/v1alpha1', 'legacy sandbox api_version');
    is($legacy_sandbox->metadata->name, 'legacy-sandbox', 'legacy sandbox metadata coerced');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'test-sandbox', namespace => 'default' },
    );
    my $yaml = $sandbox->to_yaml;
    like($yaml, qr/apiVersion: agents\.x-k8s\.io\/v1beta1/, 'YAML apiVersion');
    like($yaml, qr/kind: Sandbox/, 'YAML kind');
    like($yaml, qr/name: test-sandbox/, 'YAML name');
    like($yaml, qr/namespace: default/, 'YAML namespace');
};

# --- No collision with core K8s kinds ---

subtest 'no collision with core K8s kinds' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    # Core K8s resources unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'core Pod unaffected');
    is($k8s->expand_class('Service'), 'IO::K8s::Api::Core::V1::Service',
        'core Service unaffected');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment',
        'core Deployment unaffected');
};

# --- Inner classes exist: v1alpha1 stays an anonymous inline struct
#     (unmodeled below the top level, D7 back-compat); v1beta1 is modeled to
#     full depth (D5/D6, k95) with named classes -- see maint/crd-render/AgentSandbox.yaml ---

subtest 'Sandbox v1alpha1 inline struct inner classes exist' => sub {
    ok('IO::K8s::AgentSandbox::V1alpha1::Sandbox'->can('spec'),   'spec accessor exists');
    ok('IO::K8s::AgentSandbox::V1alpha1::Sandbox'->can('status'), 'status accessor exists');

    my $spec_class   = 'IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Spec';
    my $status_class = 'IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Status';

    ok($spec_class->can('podTemplate'),    'spec has podTemplate');
    ok($spec_class->can('shutdownTime'),   'spec has shutdownTime');
    ok($spec_class->can('shutdownPolicy'), 'spec has shutdownPolicy');
    ok($spec_class->can('replicas'),       'spec has replicas');
    ok($spec_class->can('service'),        'spec has service (new in v0.5.4)');

    ok($status_class->can('serviceFQDN'), 'status has serviceFQDN');
    ok($status_class->can('service'),     'status has service');
    ok($status_class->can('replicas'),    'status has replicas');
    ok($status_class->can('selector'),    'status has selector');
    ok($status_class->can('podIPs'),      'status has podIPs (new in v0.5.4)');
};

subtest 'Sandbox v1beta1 full-depth classes exist' => sub {
    # v1beta1 is modeled to full depth (D5/D6, k95): spec/status are named
    # IO::K8s::AgentSandbox::V1beta1::SandboxSpec/SandboxStatus classes, not
    # anonymous inline structs -- unlike the v1alpha1 track above.
    my $spec_class   = 'IO::K8s::AgentSandbox::V1beta1::SandboxSpec';
    my $status_class = 'IO::K8s::AgentSandbox::V1beta1::SandboxStatus';

    ok($spec_class->can('podTemplate'),    'spec has podTemplate');
    ok($spec_class->can('shutdownTime'),   'spec has shutdownTime');
    ok($spec_class->can('shutdownPolicy'), 'spec has shutdownPolicy');
    ok($spec_class->can('operatingMode'),  'spec has operatingMode (new in v1beta1)');
    ok($spec_class->can('service'),        'spec has service (new in v1beta1)');
    ok(!$spec_class->can('replicas'),      'spec has no replicas (dropped in v1beta1)');

    ok($status_class->can('serviceFQDN'), 'status has serviceFQDN');
    ok($status_class->can('selector'),    'status has selector');
    ok($status_class->can('nodeName'),    'status has nodeName (new in v1beta1)');
    ok($status_class->can('podIPs'),      'status has podIPs (new in v1beta1)');
    ok(!$status_class->can('replicas'),   'status has no replicas (dropped in v1beta1)');
};

subtest 'SandboxWarmPool spec/status classes exist (both versions)' => sub {
    # v1alpha1 stays an anonymous inline struct (::_Spec/::_Status); v1beta1
    # is full depth (D5/D6, k95) with named classes -- SandboxWarmPoolSpec/
    # SandboxWarmPoolStatus, and its nested refs carry their own upstream Go
    # type names (SandboxTemplateRef, SandboxWarmPoolUpdateStrategy) rather
    # than the inline ::_Spec::_Foo path.
    for my $ver (qw(V1alpha1 V1beta1)) {
        my $spec_class   = $ver eq 'V1alpha1'
            ? "IO::K8s::AgentSandbox::${ver}::SandboxWarmPool::_Spec"
            : "IO::K8s::AgentSandbox::${ver}::SandboxWarmPoolSpec";
        my $status_class = $ver eq 'V1alpha1'
            ? "IO::K8s::AgentSandbox::${ver}::SandboxWarmPool::_Status"
            : "IO::K8s::AgentSandbox::${ver}::SandboxWarmPoolStatus";

        ok($spec_class->can('replicas'),           "[$ver] spec has replicas");
        ok($spec_class->can('sandboxTemplateRef'), "[$ver] spec has sandboxTemplateRef");
        ok($spec_class->can('updateStrategy'),     "[$ver] spec has updateStrategy (new in v0.5.4)");
        ok($status_class->can('replicas'),         "[$ver] status has replicas");
        ok($status_class->can('readyReplicas'),    "[$ver] status has readyReplicas");
        ok($status_class->can('selector'),         "[$ver] status has selector");

        my $ref_class = $ver eq 'V1alpha1'
            ? "IO::K8s::AgentSandbox::${ver}::SandboxWarmPool::_Spec::_SandboxTemplateRef"
            : "IO::K8s::AgentSandbox::${ver}::SandboxTemplateRef";
        ok($ref_class->can('name'), "[$ver] sandboxTemplateRef has name");

        my $strategy_class = $ver eq 'V1alpha1'
            ? "IO::K8s::AgentSandbox::${ver}::SandboxWarmPool::_Spec::_UpdateStrategy"
            : "IO::K8s::AgentSandbox::${ver}::SandboxWarmPoolUpdateStrategy";
        ok($strategy_class->can('type'), "[$ver] updateStrategy has type");
    }
};

subtest 'SandboxClaim v1alpha1 inline struct inner classes exist' => sub {
    my $spec_class   = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec';
    my $status_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Status';

    ok($spec_class->can('sandboxTemplateRef'),     'spec has sandboxTemplateRef');
    ok($spec_class->can('warmpool'),               'spec has warmpool (new in v0.5.4)');
    ok($spec_class->can('lifecycle'),              'spec has lifecycle');
    ok($spec_class->can('additionalPodMetadata'),  'spec has additionalPodMetadata (new in v0.5.4)');
    ok($spec_class->can('env'),                    'spec has env (new in v0.5.4)');

    my $ref_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec::_SandboxTemplateRef';
    ok($ref_class->can('name'), 'sandboxTemplateRef has name');

    my $lc_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec::_Lifecycle';
    ok($lc_class->can('shutdownTime'),            'lifecycle has shutdownTime');
    ok($lc_class->can('shutdownPolicy'),          'lifecycle has shutdownPolicy');
    ok($lc_class->can('ttlSecondsAfterFinished'), 'lifecycle has ttlSecondsAfterFinished (new in v0.5.4)');

    ok($status_class->can('conditions'), 'status has conditions');
    ok($status_class->can('sandbox'),    'status has sandbox');

    my $sandbox_ref_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Status::_Sandbox';
    ok($sandbox_ref_class->can('name'),   'status.sandbox has lowercase name (renamed in v0.5.4)');
    ok($sandbox_ref_class->can('podIPs'), 'status.sandbox has podIPs (new in v0.5.4)');
};

subtest 'SandboxClaim v1beta1 full-depth classes exist' => sub {
    # Full depth (D5/D6, k95): named classes, not the ::_Spec/::_Status
    # inline-struct path v1alpha1 still uses above. warmPoolRef/lifecycle
    # carry their upstream Go type names (SandboxWarmPoolRef, Lifecycle);
    # status.sandbox is a genuine Go-name collision with the Sandbox Kind's
    # own SandboxStatus class (both are literally called SandboxStatus
    # upstream, in different Go packages) so it keeps the emitter's own
    # Kind-prefixed default instead (see maint/crd-render/AgentSandbox.yaml).
    my $spec_class   = 'IO::K8s::AgentSandbox::V1beta1::SandboxClaimSpec';
    my $status_class = 'IO::K8s::AgentSandbox::V1beta1::SandboxClaimStatus';

    ok(!$spec_class->can('sandboxTemplateRef'), 'spec has no sandboxTemplateRef (dropped in v1beta1)');
    ok($spec_class->can('warmPoolRef'),          'spec has warmPoolRef (the only ref field in v1beta1)');
    ok($spec_class->can('additionalPodMetadata'), 'spec has additionalPodMetadata');
    ok($spec_class->can('env'),                    'spec has env');
    ok($spec_class->can('lifecycle'),              'spec has lifecycle');
    ok($spec_class->can('volumeClaimTemplates'),   'spec has volumeClaimTemplates');

    my $warmpool_ref_class = 'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolRef';
    ok($warmpool_ref_class->can('name'), 'warmPoolRef has name');

    my $lc_class = 'IO::K8s::AgentSandbox::V1beta1::Lifecycle';
    ok($lc_class->can('ttlSecondsAfterFinished'), 'lifecycle has ttlSecondsAfterFinished');

    my $sandbox_ref_class = 'IO::K8s::AgentSandbox::V1beta1::SandboxClaimStatusSandbox';
    ok($sandbox_ref_class->can('name'),   'status.sandbox has lowercase name');
    ok($sandbox_ref_class->can('podIPs'), 'status.sandbox has podIPs');
};

subtest 'SandboxTemplate spec classes exist (both versions)' => sub {
    for my $ver (qw(V1alpha1 V1beta1)) {
        my $spec_class = $ver eq 'V1alpha1'
            ? "IO::K8s::AgentSandbox::${ver}::SandboxTemplate::_Spec"
            : "IO::K8s::AgentSandbox::${ver}::SandboxTemplateSpec";

        ok($spec_class->can('podTemplate'),                 "[$ver] spec has podTemplate");
        ok($spec_class->can('networkPolicy'),                "[$ver] spec has networkPolicy");
        ok($spec_class->can('networkPolicyManagement'),      "[$ver] spec has networkPolicyManagement");
        ok($spec_class->can('envVarsInjectionPolicy'),        "[$ver] spec has envVarsInjectionPolicy (new in v0.5.4)");
        ok($spec_class->can('service'),                       "[$ver] spec has service (new in v0.5.4)");
        ok($spec_class->can('volumeClaimTemplates'),          "[$ver] spec has volumeClaimTemplates (new in v0.5.4)");

        # volumeClaimTemplatesPolicy is a v1beta1-only addition; the v1alpha1 CRD
        # schema does not carry it (karr k84).
        if ($ver eq 'V1beta1') {
            ok($spec_class->can('volumeClaimTemplatesPolicy'),
                "[$ver] spec has volumeClaimTemplatesPolicy (v1beta1-only)");
        }
        else {
            ok(!$spec_class->can('volumeClaimTemplatesPolicy'),
                "[$ver] spec has no volumeClaimTemplatesPolicy (v1beta1-only, absent from v1alpha1 schema)");
        }

        ok(!"IO::K8s::AgentSandbox::${ver}::SandboxTemplate"->can('status'),
            "[$ver] SandboxTemplate has no status object (upstream schema omits it)");
    }
};

# --- Hashref coercion on construction ---

subtest 'Sandbox spec/status hashref coercion (v1beta1)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'coerce-test', namespace => 'default' },
        spec     => { operatingMode => 'Suspended', shutdownPolicy => 'Retain', service => 1 },
        status   => { serviceFQDN => 'sandbox-test.default.svc.cluster.local', nodeName => 'node-1', podIPs => ['10.0.0.5'] },
    );

    isa_ok($sandbox->spec,   'IO::K8s::AgentSandbox::V1beta1::SandboxSpec');
    isa_ok($sandbox->status, 'IO::K8s::AgentSandbox::V1beta1::SandboxStatus');

    is($sandbox->spec->operatingMode,  'Suspended', 'spec.operatingMode');
    is($sandbox->spec->shutdownPolicy, 'Retain',    'spec.shutdownPolicy');
    is($sandbox->spec->service,        1,           'spec.service');
    is($sandbox->status->serviceFQDN,  'sandbox-test.default.svc.cluster.local', 'status.serviceFQDN');
    is($sandbox->status->nodeName,     'node-1',    'status.nodeName');
    is_deeply($sandbox->status->podIPs, ['10.0.0.5'], 'status.podIPs');
};

subtest 'Sandbox v1alpha1 spec/status hashref coercion (legacy replicas track)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $sandbox = $k8s->struct_to_object(
        'IO::K8s::AgentSandbox::V1alpha1::Sandbox',
        {
            metadata => { name => 'coerce-test', namespace => 'default' },
            spec     => { replicas => 1, shutdownPolicy => 'Retain' },
            status   => { serviceFQDN => 'sandbox-test.default.svc.cluster.local', replicas => 1 },
        },
    );

    isa_ok($sandbox->spec,   'IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Spec');
    isa_ok($sandbox->status, 'IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Status');

    is($sandbox->spec->replicas,       1,        'spec.replicas');
    is($sandbox->spec->shutdownPolicy, 'Retain', 'spec.shutdownPolicy');
    is($sandbox->status->serviceFQDN,  'sandbox-test.default.svc.cluster.local', 'status.serviceFQDN');
    is($sandbox->status->replicas,     1,        'status.replicas');
};

subtest 'SandboxWarmPool spec/status hashref coercion (v1beta1)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $swp = $k8s->new_object('SandboxWarmPool',
        metadata => { name => 'my-pool', namespace => 'default' },
        spec     => { replicas => 3, sandboxTemplateRef => { name => 'my-template' }, updateStrategy => { type => 'Recreate' } },
        status   => { replicas => 3, readyReplicas => 2, selector => 'pool=my-pool' },
    );

    isa_ok($swp->spec,   'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolSpec');
    isa_ok($swp->status, 'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolStatus');

    is($swp->spec->replicas, 3, 'spec.replicas');
    isa_ok($swp->spec->sandboxTemplateRef,
        'IO::K8s::AgentSandbox::V1beta1::SandboxTemplateRef');
    is($swp->spec->sandboxTemplateRef->name, 'my-template', 'spec.sandboxTemplateRef.name');
    isa_ok($swp->spec->updateStrategy,
        'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolUpdateStrategy');
    is($swp->spec->updateStrategy->type, 'Recreate', 'spec.updateStrategy.type');

    is($swp->status->replicas,      3,             'status.replicas');
    is($swp->status->readyReplicas, 2,             'status.readyReplicas');
    is($swp->status->selector,      'pool=my-pool', 'status.selector');
};

subtest 'SandboxClaim nested lifecycle/warmPoolRef coercion (v1beta1)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $claim = $k8s->new_object('SandboxClaim',
        metadata => { name => 'my-claim', namespace => 'default' },
        spec     => {
            warmPoolRef => { name => 'fast-pool' },
            lifecycle   => { shutdownPolicy => 'Delete', ttlSecondsAfterFinished => 300 },
            # env is an array of {name, value, containerName} EnvVar structs
            # upstream (sandboxclaim_types.go), not a bare string map -- the
            # full-depth v1beta1 model (D5) corrects the earlier opaque
            # `{ Str => 1 }` guess.
            env         => [{ name => 'FOO', value => 'bar' }],
        },
    );

    isa_ok($claim->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxClaimSpec');

    isa_ok($claim->spec->warmPoolRef,
        'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolRef');
    is($claim->spec->warmPoolRef->name, 'fast-pool', 'warmPoolRef.name');

    isa_ok($claim->spec->lifecycle,
        'IO::K8s::AgentSandbox::V1beta1::Lifecycle');
    is($claim->spec->lifecycle->shutdownPolicy, 'Delete', 'lifecycle.shutdownPolicy');
    is($claim->spec->lifecycle->ttlSecondsAfterFinished, 300, 'lifecycle.ttlSecondsAfterFinished');

    isa_ok($claim->spec->env->[0], 'IO::K8s::AgentSandbox::V1beta1::EnvVar');
    is($claim->spec->env->[0]->value, 'bar', 'env[0].value');
};

subtest 'SandboxClaim v1alpha1 sandboxTemplateRef/warmpool coercion' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $claim = $k8s->struct_to_object(
        'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim',
        {
            metadata => { name => 'my-claim', namespace => 'default' },
            spec     => {
                sandboxTemplateRef => { name => 'fast-template' },
                lifecycle          => { shutdownPolicy => 'Delete' },
            },
        },
    );

    isa_ok($claim->spec, 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec');

    isa_ok($claim->spec->sandboxTemplateRef,
        'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec::_SandboxTemplateRef');
    is($claim->spec->sandboxTemplateRef->name, 'fast-template', 'templateRef.name');

    isa_ok($claim->spec->lifecycle,
        'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec::_Lifecycle');
    is($claim->spec->lifecycle->shutdownPolicy, 'Delete', 'lifecycle.shutdownPolicy');
};

subtest 'SandboxTemplate spec hashref coercion (v1beta1)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $tmpl = $k8s->new_object('SandboxTemplate',
        metadata => { name => 'my-tmpl', namespace => 'default' },
        spec     => {
            networkPolicyManagement    => 'Managed',
            envVarsInjectionPolicy     => 'Allowed',
            service                    => 1,
            volumeClaimTemplatesPolicy => 'Allowed',
        },
    );

    isa_ok($tmpl->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxTemplateSpec');
    is($tmpl->spec->networkPolicyManagement, 'Managed', 'spec.networkPolicyManagement');
    is($tmpl->spec->envVarsInjectionPolicy, 'Allowed', 'spec.envVarsInjectionPolicy');
    is($tmpl->spec->service, 1, 'spec.service');
    is($tmpl->spec->volumeClaimTemplatesPolicy, 'Allowed', 'spec.volumeClaimTemplatesPolicy');
};

subtest 'SandboxTemplate volumeClaimTemplates as typed PersistentVolumeClaimTemplate array' => sub {
    # Upstream's PersistentVolumeClaimTemplate (sandbox_types.go) is a
    # trimmed {metadata: EmbeddedObjectMetadata, spec: PersistentVolumeClaimSpec}
    # struct, not a full corev1.PersistentVolumeClaim (no apiVersion/kind/
    # status) -- the full-depth v1beta1 model (D5) corrects the earlier
    # `['Core::V1::PersistentVolumeClaim']` guess.
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $tmpl = $k8s->new_object('SandboxTemplate',
        metadata => { name => 'my-tmpl', namespace => 'default' },
        spec     => {
            volumeClaimTemplates => [
                { metadata => { name => 'data' }, spec => { accessModes => ['ReadWriteOnce'] } },
            ],
        },
    );

    is(ref $tmpl->spec->volumeClaimTemplates, 'ARRAY', 'volumeClaimTemplates is an array');
    isa_ok($tmpl->spec->volumeClaimTemplates->[0], 'IO::K8s::AgentSandbox::V1beta1::PersistentVolumeClaimTemplate');
    isa_ok($tmpl->spec->volumeClaimTemplates->[0]->metadata, 'IO::K8s::AgentSandbox::V1beta1::EmbeddedObjectMetadata');
    is($tmpl->spec->volumeClaimTemplates->[0]->metadata->name, 'data', 'volumeClaimTemplates[0].metadata.name');
    isa_ok($tmpl->spec->volumeClaimTemplates->[0]->spec, 'IO::K8s::Api::Core::V1::PersistentVolumeClaimSpec');
    is_deeply($tmpl->spec->volumeClaimTemplates->[0]->spec->accessModes, ['ReadWriteOnce'],
        'volumeClaimTemplates[0].spec.accessModes');
};

# --- Full depth round-trip (k95/D5): each v1beta1 Kind's manifest, written
# from the upstream kubernetes-sigs/agent-sandbox v1.0.0 Go sources
# (api/v1beta1/sandbox_types.go, extensions/api/v1beta1/*.go), inflates into
# typed nested objects several levels deep and TO_JSON reproduces it. Built
# via new_object (coercing; NOT ->new(spec => {hashref}), which does not
# coerce -- k100). ---

subtest 'full depth round-trip: Sandbox' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'agent-1', namespace => 'default' },
        spec => {
            operatingMode  => 'Running',
            service        => 1,
            shutdownPolicy => 'Retain',
            podTemplate    => {
                metadata => { labels => { app => 'agent' }, annotations => { note => 'x' } },
                spec     => {
                    containers       => [{ name => 'agent', image => 'agent:latest', imagePullPolicy => 'IfNotPresent' }],
                    imagePullSecrets => [{ name => 'registry-creds' }],
                    os               => { name => 'linux' },
                    schedulingGroup  => { podGroupName => 'agent-group' },
                    readinessGates   => [{ conditionType => 'agents.x-k8s.io/ready' }],
                    schedulingGates  => [{ name => 'wait-for-quota' }],
                    restartPolicy    => 'Never',
                },
            },
            volumeClaimTemplates => [
                {
                    metadata => { name => 'workspace', labels => { tier => 'scratch' } },
                    spec     => { accessModes => ['ReadWriteOnce'], resources => { requests => { storage => '10Gi' } } },
                },
            ],
        },
    );

    isa_ok($sandbox->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxSpec');
    isa_ok($sandbox->spec->podTemplate, 'IO::K8s::AgentSandbox::V1beta1::PodTemplate');
    isa_ok($sandbox->spec->podTemplate->metadata, 'IO::K8s::AgentSandbox::V1beta1::PodMetadata');
    isa_ok($sandbox->spec->podTemplate->spec, 'IO::K8s::AgentSandbox::V1beta1::PodSpec');
    isa_ok($sandbox->spec->podTemplate->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container');
    isa_ok($sandbox->spec->podTemplate->spec->imagePullSecrets->[0], 'IO::K8s::AgentSandbox::V1beta1::LocalObjectReference');
    isa_ok($sandbox->spec->podTemplate->spec->os, 'IO::K8s::AgentSandbox::V1beta1::PodOS');
    isa_ok($sandbox->spec->podTemplate->spec->schedulingGroup, 'IO::K8s::AgentSandbox::V1beta1::PodSchedulingGroup');
    isa_ok($sandbox->spec->podTemplate->spec->readinessGates->[0], 'IO::K8s::AgentSandbox::V1beta1::PodReadinessGate');
    isa_ok($sandbox->spec->podTemplate->spec->schedulingGates->[0], 'IO::K8s::AgentSandbox::V1beta1::PodSchedulingGate');
    isa_ok($sandbox->spec->volumeClaimTemplates->[0], 'IO::K8s::AgentSandbox::V1beta1::PersistentVolumeClaimTemplate');
    isa_ok($sandbox->spec->volumeClaimTemplates->[0]->metadata, 'IO::K8s::AgentSandbox::V1beta1::EmbeddedObjectMetadata');
    isa_ok($sandbox->spec->volumeClaimTemplates->[0]->spec, 'IO::K8s::Api::Core::V1::PersistentVolumeClaimSpec');

    is($sandbox->spec->podTemplate->spec->containers->[0]->image, 'agent:latest', 'podTemplate.spec.containers[0].image');
    is($sandbox->spec->podTemplate->metadata->labels->{app}, 'agent', 'podTemplate.metadata.labels.app');
    is($sandbox->spec->podTemplate->spec->os->name, 'linux', 'podTemplate.spec.os.name');
    is($sandbox->spec->podTemplate->spec->schedulingGroup->podGroupName, 'agent-group', 'podTemplate.spec.schedulingGroup.podGroupName');
    is($sandbox->spec->podTemplate->spec->readinessGates->[0]->conditionType, 'agents.x-k8s.io/ready',
        'podTemplate.spec.readinessGates[0].conditionType');
    is($sandbox->spec->volumeClaimTemplates->[0]->metadata->name, 'workspace', 'volumeClaimTemplates[0].metadata.name');

    my $json = $sandbox->TO_JSON;
    is($json->{spec}{podTemplate}{spec}{containers}[0]{name}, 'agent', 'TO_JSON podTemplate.spec.containers[0].name');
    is($json->{spec}{podTemplate}{spec}{os}{name}, 'linux', 'TO_JSON podTemplate.spec.os.name');
    is($json->{spec}{podTemplate}{spec}{imagePullSecrets}[0]{name}, 'registry-creds',
        'TO_JSON podTemplate.spec.imagePullSecrets[0].name');
    is($json->{spec}{volumeClaimTemplates}[0]{spec}{resources}{requests}{storage}, '10Gi',
        'TO_JSON volumeClaimTemplates[0].spec.resources.requests.storage');

    my $re = $k8s->inflate($k8s->object_to_json($sandbox));
    isa_ok($re, 'IO::K8s::AgentSandbox::V1beta1::Sandbox');
    is($re->spec->podTemplate->spec->schedulingGates->[0]->name, 'wait-for-quota',
        'JSON round-trip preserves podTemplate.spec.schedulingGates[0].name');
};

subtest 'full depth round-trip: SandboxClaim' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $claim = $k8s->new_object('SandboxClaim',
        metadata => { name => 'claim-1', namespace => 'default' },
        spec => {
            warmPoolRef            => { name => 'fast-pool' },
            lifecycle              => { shutdownPolicy => 'DeleteForeground', ttlSecondsAfterFinished => 600 },
            additionalPodMetadata  => { labels => { team => 'agents' } },
            env                    => [
                { name => 'MODEL', value => 'gpt' },
                { name => 'TIMEOUT', value => '30', containerName => 'agent' },
            ],
            volumeClaimTemplates => [
                { metadata => { name => 'scratch' }, spec => { accessModes => ['ReadWriteOnce'] } },
            ],
        },
        status => {
            conditions => [{
                type => 'Ready', status => 'True', reason => 'DependenciesReady',
                message => 'ready', lastTransitionTime => '2026-01-01T00:00:00Z',
            }],
            sandbox => { name => 'agent-1', podIPs => ['10.0.0.9'], serviceFQDN => 'agent-1.default.svc.cluster.local' },
        },
    );

    isa_ok($claim->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxClaimSpec');
    isa_ok($claim->spec->warmPoolRef, 'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolRef');
    isa_ok($claim->spec->lifecycle, 'IO::K8s::AgentSandbox::V1beta1::Lifecycle');
    isa_ok($claim->spec->additionalPodMetadata, 'IO::K8s::AgentSandbox::V1beta1::PodMetadata');
    isa_ok($claim->spec->env->[0], 'IO::K8s::AgentSandbox::V1beta1::EnvVar');
    isa_ok($claim->spec->volumeClaimTemplates->[0], 'IO::K8s::AgentSandbox::V1beta1::PersistentVolumeClaimTemplate');
    isa_ok($claim->status, 'IO::K8s::AgentSandbox::V1beta1::SandboxClaimStatus');
    isa_ok($claim->status->conditions->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition');
    isa_ok($claim->status->sandbox, 'IO::K8s::AgentSandbox::V1beta1::SandboxClaimStatusSandbox');

    is($claim->spec->env->[1]->containerName, 'agent', 'env[1].containerName');
    is($claim->spec->lifecycle->ttlSecondsAfterFinished, 600, 'lifecycle.ttlSecondsAfterFinished');
    is($claim->status->sandbox->podIPs->[0], '10.0.0.9', 'status.sandbox.podIPs[0]');

    my $json = $claim->TO_JSON;
    is($json->{spec}{env}[0]{value}, 'gpt', 'TO_JSON env[0].value');
    is($json->{spec}{warmPoolRef}{name}, 'fast-pool', 'TO_JSON warmPoolRef.name');
    is($json->{status}{sandbox}{serviceFQDN}, 'agent-1.default.svc.cluster.local', 'TO_JSON status.sandbox.serviceFQDN');

    my $re = $k8s->inflate($k8s->object_to_json($claim));
    isa_ok($re, 'IO::K8s::AgentSandbox::V1beta1::SandboxClaim');
    is($re->spec->env->[1]->name, 'TIMEOUT', 'JSON round-trip preserves env[1].name');
};

subtest 'full depth round-trip: SandboxTemplate' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $tmpl = $k8s->new_object('SandboxTemplate',
        metadata => { name => 'tmpl-1', namespace => 'default' },
        spec => {
            envVarsInjectionPolicy  => 'Overrides',
            networkPolicyManagement => 'Managed',
            networkPolicy => {
                ingress => [{ from => [{ podSelector => { matchLabels => { role => 'router' } } }] }],
                egress  => [{ to => [{ ipBlock => { cidr => '0.0.0.0/0' } }] }],
            },
            podTemplate => {
                spec => { containers => [{ name => 'agent', image => 'agent:latest' }] },
            },
            volumeClaimTemplatesPolicy => 'Allowed',
        },
    );

    isa_ok($tmpl->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxTemplateSpec');
    isa_ok($tmpl->spec->networkPolicy, 'IO::K8s::AgentSandbox::V1beta1::NetworkPolicySpec');
    isa_ok($tmpl->spec->networkPolicy->ingress->[0], 'IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule');
    isa_ok($tmpl->spec->networkPolicy->egress->[0], 'IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule');
    isa_ok($tmpl->spec->podTemplate, 'IO::K8s::AgentSandbox::V1beta1::PodTemplate');

    is($tmpl->spec->networkPolicy->ingress->[0]->from->[0]->podSelector->matchLabels->{role}, 'router',
        'networkPolicy.ingress[0].from[0].podSelector.matchLabels.role');

    my $json = $tmpl->TO_JSON;
    is($json->{spec}{networkPolicy}{egress}[0]{to}[0]{ipBlock}{cidr}, '0.0.0.0/0',
        'TO_JSON networkPolicy.egress[0].to[0].ipBlock.cidr');

    my $re = $k8s->inflate($k8s->object_to_json($tmpl));
    isa_ok($re, 'IO::K8s::AgentSandbox::V1beta1::SandboxTemplate');
    is($re->spec->networkPolicy->ingress->[0]->from->[0]->podSelector->matchLabels->{role}, 'router',
        'JSON round-trip preserves networkPolicy.ingress[0].from[0].podSelector.matchLabels.role');
};

subtest 'full depth round-trip: SandboxWarmPool' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $swp = $k8s->new_object('SandboxWarmPool',
        metadata => { name => 'pool-1', namespace => 'default' },
        spec => {
            replicas           => 5,
            sandboxTemplateRef => { name => 'tmpl-1' },
            updateStrategy     => { type => 'Recreate' },
        },
        status => {
            replicas           => 5,
            readyReplicas      => 4,
            selector           => 'pool=pool-1',
            observedGeneration => 3,
        },
    );

    isa_ok($swp->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolSpec');
    isa_ok($swp->spec->sandboxTemplateRef, 'IO::K8s::AgentSandbox::V1beta1::SandboxTemplateRef');
    isa_ok($swp->spec->updateStrategy, 'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolUpdateStrategy');
    isa_ok($swp->status, 'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPoolStatus');

    my $json = $swp->TO_JSON;
    is($json->{spec}{sandboxTemplateRef}{name}, 'tmpl-1', 'TO_JSON sandboxTemplateRef.name');
    is($json->{status}{observedGeneration}, 3, 'TO_JSON status.observedGeneration');

    my $re = $k8s->inflate($k8s->object_to_json($swp));
    isa_ok($re, 'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool');
    is($re->spec->updateStrategy->type, 'Recreate', 'JSON round-trip preserves updateStrategy.type');
};

# --- TO_JSON round-trip ---

subtest 'Sandbox TO_JSON round-trip (v1beta1)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'json-test', namespace => 'default' },
        spec     => { operatingMode => 'Running', shutdownPolicy => 'Retain' },
        status   => { service => 'json-test', nodeName => 'node-9' },
    );

    my $json = $sandbox->TO_JSON;
    is(ref $json->{spec},   'HASH', 'spec serializes to hash');
    is(ref $json->{status}, 'HASH', 'status serializes to hash');
    is($json->{spec}{operatingMode},  'Running', 'spec.operatingMode in JSON');
    is($json->{spec}{shutdownPolicy}, 'Retain',  'spec.shutdownPolicy in JSON');
    is($json->{status}{service},      'json-test', 'status.service in JSON');
    is($json->{status}{nodeName},     'node-9',  'status.nodeName in JSON');
};

subtest 'SandboxWarmPool TO_JSON round-trip (v1beta1)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $swp = $k8s->new_object('SandboxWarmPool',
        metadata => { name => 'pool-json', namespace => 'default' },
        spec     => { replicas => 5, sandboxTemplateRef => { name => 'tmpl' } },
        status   => { replicas => 5, readyReplicas => 4 },
    );

    my $json = $swp->TO_JSON;
    is(ref $json->{spec},   'HASH', 'spec serializes to hash');
    is(ref $json->{status}, 'HASH', 'status serializes to hash');
    is($json->{spec}{replicas},                    5,      'spec.replicas in JSON');
    is(ref $json->{spec}{sandboxTemplateRef},       'HASH', 'sandboxTemplateRef serializes to hash');
    is($json->{spec}{sandboxTemplateRef}{name},     'tmpl', 'sandboxTemplateRef.name in JSON');
    is($json->{status}{replicas},                   5,      'status.replicas in JSON');
    is($json->{status}{readyReplicas},              4,      'status.readyReplicas in JSON');
};

subtest 'SandboxClaim TO_JSON round-trip (v1beta1)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $claim = $k8s->new_object('SandboxClaim',
        metadata => { name => 'claim-json', namespace => 'default' },
        spec     => {
            warmPoolRef => { name => 'my-pool' },
            lifecycle   => { shutdownPolicy => 'Delete' },
        },
    );

    my $json = $claim->TO_JSON;
    is(ref $json->{spec}, 'HASH', 'spec serializes to hash');
    is(ref $json->{spec}{warmPoolRef}, 'HASH', 'warmPoolRef serializes to hash');
    is($json->{spec}{warmPoolRef}{name}, 'my-pool', 'warmPoolRef.name in JSON');
    is(ref $json->{spec}{lifecycle}, 'HASH', 'lifecycle serializes to hash');
    is($json->{spec}{lifecycle}{shutdownPolicy}, 'Delete', 'lifecycle.shutdownPolicy in JSON');
};

# --- Optional (undef when not set) ---

subtest 'inline struct optional when not set' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'bare', namespace => 'default' },
    );
    is($sandbox->spec,   undef, 'spec is undef when not set');
    is($sandbox->status, undef, 'status is undef when not set');

    my $swp = $k8s->new_object('SandboxWarmPool',
        metadata => { name => 'bare-pool', namespace => 'default' },
    );
    is($swp->spec,   undef, 'WarmPool spec is undef when not set');
    is($swp->status, undef, 'WarmPool status is undef when not set');
};

done_testing;
