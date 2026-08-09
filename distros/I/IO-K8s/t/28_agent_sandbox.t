#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::AgentSandbox;

# --- All AgentSandbox CRD classes (v1alpha1: served, deprecated; v1beta1: storage) ---

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
    is($provider->upstream_version, 'v0.5.4', 'upstream_version is v0.5.4');
    my $map = $provider->resource_map;
    is(scalar keys %$map, 4, 'resource_map has 4 entries');
    for my $kind (sort keys %all_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "AgentSandbox::V1beta1::$kind", "$kind maps to the v1beta1 (storage) class");
    }
};

# --- new(with => ['IO::K8s::AgentSandbox']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    # Short name resolves to the v1beta1 (storage) class
    for my $kind (sort keys %all_classes) {
        is($k8s->expand_class($kind), "IO::K8s::AgentSandbox::V1beta1::$kind",
            "expand_class('$kind') resolves to v1beta1");
    }

    # Domain-qualified access reaches the storage version registered under the
    # short name (v1beta1). The v1alpha1 track is not auto-registered under a
    # domain-qualified key (same precedent as e.g. ValidatingAdmissionPolicy in
    # IO::K8s.pm, which maps only to its GA class) — it stays reachable by its
    # full class name instead.
    is($k8s->expand_class('agents.x-k8s.io/v1beta1/Sandbox'),
        'IO::K8s::AgentSandbox::V1beta1::Sandbox',
        'domain-qualified v1beta1 Sandbox resolves');
    is($k8s->expand_class('extensions.agents.x-k8s.io/v1beta1/SandboxClaim'),
        'IO::K8s::AgentSandbox::V1beta1::SandboxClaim',
        'domain-qualified v1beta1 SandboxClaim resolves');
    ok(!defined($k8s->expand_class('agents.x-k8s.io/v1alpha1/Sandbox')),
        'domain-qualified v1alpha1 Sandbox is not auto-registered (use the full class name instead)');

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

# --- Inline struct: inner classes exist (v1alpha1 track) ---

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

subtest 'Sandbox v1beta1 inline struct inner classes exist' => sub {
    my $spec_class   = 'IO::K8s::AgentSandbox::V1beta1::Sandbox::_Spec';
    my $status_class = 'IO::K8s::AgentSandbox::V1beta1::Sandbox::_Status';

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

subtest 'SandboxWarmPool inline struct inner classes exist (both versions)' => sub {
    for my $ver (qw(V1alpha1 V1beta1)) {
        my $spec_class   = "IO::K8s::AgentSandbox::${ver}::SandboxWarmPool::_Spec";
        my $status_class = "IO::K8s::AgentSandbox::${ver}::SandboxWarmPool::_Status";

        ok($spec_class->can('replicas'),           "[$ver] spec has replicas");
        ok($spec_class->can('sandboxTemplateRef'), "[$ver] spec has sandboxTemplateRef");
        ok($spec_class->can('updateStrategy'),     "[$ver] spec has updateStrategy (new in v0.5.4)");
        ok($status_class->can('replicas'),         "[$ver] status has replicas");
        ok($status_class->can('readyReplicas'),    "[$ver] status has readyReplicas");
        ok($status_class->can('selector'),         "[$ver] status has selector");

        my $ref_class = "IO::K8s::AgentSandbox::${ver}::SandboxWarmPool::_Spec::_SandboxTemplateRef";
        ok($ref_class->can('name'), "[$ver] sandboxTemplateRef has name");

        my $strategy_class = "IO::K8s::AgentSandbox::${ver}::SandboxWarmPool::_Spec::_UpdateStrategy";
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

subtest 'SandboxClaim v1beta1 inline struct inner classes exist' => sub {
    my $spec_class   = 'IO::K8s::AgentSandbox::V1beta1::SandboxClaim::_Spec';
    my $status_class = 'IO::K8s::AgentSandbox::V1beta1::SandboxClaim::_Status';

    ok(!$spec_class->can('sandboxTemplateRef'), 'spec has no sandboxTemplateRef (dropped in v1beta1)');
    ok($spec_class->can('warmPoolRef'),          'spec has warmPoolRef (the only ref field in v1beta1)');
    ok($spec_class->can('additionalPodMetadata'), 'spec has additionalPodMetadata');
    ok($spec_class->can('env'),                    'spec has env');
    ok($spec_class->can('lifecycle'),              'spec has lifecycle');
    ok($spec_class->can('volumeClaimTemplates'),   'spec has volumeClaimTemplates');

    my $warmpool_ref_class = 'IO::K8s::AgentSandbox::V1beta1::SandboxClaim::_Spec::_WarmPoolRef';
    ok($warmpool_ref_class->can('name'), 'warmPoolRef has name');

    my $lc_class = 'IO::K8s::AgentSandbox::V1beta1::SandboxClaim::_Spec::_Lifecycle';
    ok($lc_class->can('ttlSecondsAfterFinished'), 'lifecycle has ttlSecondsAfterFinished');

    my $sandbox_ref_class = 'IO::K8s::AgentSandbox::V1beta1::SandboxClaim::_Status::_Sandbox';
    ok($sandbox_ref_class->can('name'),   'status.sandbox has lowercase name');
    ok($sandbox_ref_class->can('podIPs'), 'status.sandbox has podIPs');
};

subtest 'SandboxTemplate inline struct inner classes exist (both versions)' => sub {
    for my $ver (qw(V1alpha1 V1beta1)) {
        my $spec_class = "IO::K8s::AgentSandbox::${ver}::SandboxTemplate::_Spec";

        ok($spec_class->can('podTemplate'),                 "[$ver] spec has podTemplate");
        ok($spec_class->can('networkPolicy'),                "[$ver] spec has networkPolicy");
        ok($spec_class->can('networkPolicyManagement'),      "[$ver] spec has networkPolicyManagement");
        ok($spec_class->can('envVarsInjectionPolicy'),        "[$ver] spec has envVarsInjectionPolicy (new in v0.5.4)");
        ok($spec_class->can('service'),                       "[$ver] spec has service (new in v0.5.4)");
        ok($spec_class->can('volumeClaimTemplates'),          "[$ver] spec has volumeClaimTemplates (new in v0.5.4)");
        ok($spec_class->can('volumeClaimTemplatesPolicy'),    "[$ver] spec has volumeClaimTemplatesPolicy (new in v0.5.4)");

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

    isa_ok($sandbox->spec,   'IO::K8s::AgentSandbox::V1beta1::Sandbox::_Spec');
    isa_ok($sandbox->status, 'IO::K8s::AgentSandbox::V1beta1::Sandbox::_Status');

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

    isa_ok($swp->spec,   'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool::_Spec');
    isa_ok($swp->status, 'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool::_Status');

    is($swp->spec->replicas, 3, 'spec.replicas');
    isa_ok($swp->spec->sandboxTemplateRef,
        'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool::_Spec::_SandboxTemplateRef');
    is($swp->spec->sandboxTemplateRef->name, 'my-template', 'spec.sandboxTemplateRef.name');
    isa_ok($swp->spec->updateStrategy,
        'IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool::_Spec::_UpdateStrategy');
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
            env         => { FOO => 'bar' },
        },
    );

    isa_ok($claim->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxClaim::_Spec');

    isa_ok($claim->spec->warmPoolRef,
        'IO::K8s::AgentSandbox::V1beta1::SandboxClaim::_Spec::_WarmPoolRef');
    is($claim->spec->warmPoolRef->name, 'fast-pool', 'warmPoolRef.name');

    isa_ok($claim->spec->lifecycle,
        'IO::K8s::AgentSandbox::V1beta1::SandboxClaim::_Spec::_Lifecycle');
    is($claim->spec->lifecycle->shutdownPolicy, 'Delete', 'lifecycle.shutdownPolicy');
    is($claim->spec->lifecycle->ttlSecondsAfterFinished, 300, 'lifecycle.ttlSecondsAfterFinished');
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

    isa_ok($tmpl->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxTemplate::_Spec');
    is($tmpl->spec->networkPolicyManagement, 'Managed', 'spec.networkPolicyManagement');
    is($tmpl->spec->envVarsInjectionPolicy, 'Allowed', 'spec.envVarsInjectionPolicy');
    is($tmpl->spec->service, 1, 'spec.service');
    is($tmpl->spec->volumeClaimTemplatesPolicy, 'Allowed', 'spec.volumeClaimTemplatesPolicy');
};

subtest 'SandboxTemplate volumeClaimTemplates as typed PersistentVolumeClaim array' => sub {
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
    isa_ok($tmpl->spec->volumeClaimTemplates->[0], 'IO::K8s::Api::Core::V1::PersistentVolumeClaim');
    is($tmpl->spec->volumeClaimTemplates->[0]->metadata->name, 'data', 'volumeClaimTemplates[0].metadata.name');
    is_deeply($tmpl->spec->volumeClaimTemplates->[0]->spec->accessModes, ['ReadWriteOnce'],
        'volumeClaimTemplates[0].spec.accessModes');
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
