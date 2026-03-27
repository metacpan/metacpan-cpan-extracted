#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::AgentSandbox;

# --- All AgentSandbox CRD classes ---

my %core_classes = (
    Sandbox => {
        api_version => 'agents.x-k8s.io/v1alpha1',
        plural      => 'sandboxes',
        namespaced  => 1,
    },
);

my %extension_classes = (
    SandboxClaim    => { api_version => 'extensions.agents.x-k8s.io/v1alpha1', plural => 'sandboxclaims',     namespaced => 1 },
    SandboxTemplate => { api_version => 'extensions.agents.x-k8s.io/v1alpha1', plural => 'sandboxtemplates',  namespaced => 1 },
    SandboxWarmPool => { api_version => 'extensions.agents.x-k8s.io/v1alpha1', plural => 'sandboxwarmpools',  namespaced => 1 },
);

# --- Load all classes ---

subtest 'load all AgentSandbox classes' => sub {
    for my $kind (sort keys %core_classes) {
        my $class = "IO::K8s::AgentSandbox::V1alpha1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    for my $kind (sort keys %extension_classes) {
        my $class = "IO::K8s::AgentSandbox::V1alpha1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
};

# --- Verify api_version, kind, resource_plural, namespaced ---

subtest 'Core class metadata' => sub {
    for my $kind (sort keys %core_classes) {
        my $class = "IO::K8s::AgentSandbox::V1alpha1::$kind";
        my $info = $core_classes{$kind};

        is($class->api_version, $info->{api_version}, "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
    }
};

subtest 'Extension class metadata' => sub {
    for my $kind (sort keys %extension_classes) {
        my $class = "IO::K8s::AgentSandbox::V1alpha1::$kind";
        my $info = $extension_classes{$kind};

        is($class->api_version, $info->{api_version}, "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
    }
};

# --- IO::K8s::AgentSandbox resource_map ---

subtest 'IO::K8s::AgentSandbox resource_map' => sub {
    my $provider = IO::K8s::AgentSandbox->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 4, 'resource_map has 4 entries');

    for my $kind (sort keys %core_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "AgentSandbox::V1alpha1::$kind", "$kind maps to correct class");
    }
    for my $kind (sort keys %extension_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "AgentSandbox::V1alpha1::$kind", "$kind maps to correct class");
    }
};

# --- new(with => ['IO::K8s::AgentSandbox']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    # All AgentSandbox kinds should be resolvable by short name
    for my $kind (sort keys %core_classes) {
        is($k8s->expand_class($kind), "IO::K8s::AgentSandbox::V1alpha1::$kind",
            "expand_class('$kind') resolves");
    }
    for my $kind (sort keys %extension_classes) {
        is($k8s->expand_class($kind), "IO::K8s::AgentSandbox::V1alpha1::$kind",
            "expand_class('$kind') resolves");
    }

    # Domain-qualified access
    is($k8s->expand_class('agents.x-k8s.io/v1alpha1/Sandbox'),
        'IO::K8s::AgentSandbox::V1alpha1::Sandbox',
        'domain-qualified Sandbox resolves');
    is($k8s->expand_class('extensions.agents.x-k8s.io/v1alpha1/SandboxClaim'),
        'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim',
        'domain-qualified SandboxClaim resolves');

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'core Pod still resolves');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment',
        'core Deployment still resolves');
};

# --- new_object + inflate round-trip ---

subtest 'new_object and inflate round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    # Create a Sandbox with minimal spec
    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'my-sandbox', namespace => 'default' },
    );
    isa_ok($sandbox, 'IO::K8s::AgentSandbox::V1alpha1::Sandbox');
    is($sandbox->kind, 'Sandbox', 'kind');
    is($sandbox->api_version, 'agents.x-k8s.io/v1alpha1', 'api_version');
    is($sandbox->metadata->name, 'my-sandbox', 'name');
    is($sandbox->metadata->namespace, 'default', 'namespace');

    # Create a SandboxClaim
    my $claim = $k8s->new_object('SandboxClaim',
        metadata => { name => 'my-claim', namespace => 'default' },
    );
    isa_ok($claim, 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim');
    is($claim->api_version, 'extensions.agents.x-k8s.io/v1alpha1', 'claim api_version');

    # Create a SandboxTemplate
    my $template = $k8s->new_object('SandboxTemplate',
        metadata => { name => 'my-template', namespace => 'default' },
    );
    isa_ok($template, 'IO::K8s::AgentSandbox::V1alpha1::SandboxTemplate');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'test-sandbox', namespace => 'default' },
    );
    my $yaml = $sandbox->to_yaml;
    like($yaml, qr/apiVersion: agents\.x-k8s\.io\/v1alpha1/, 'YAML apiVersion');
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

# --- Inline struct: inner classes generated ---

subtest 'Sandbox inline struct inner classes exist' => sub {
    ok('IO::K8s::AgentSandbox::V1alpha1::Sandbox'->can('spec'),   'spec accessor exists');
    ok('IO::K8s::AgentSandbox::V1alpha1::Sandbox'->can('status'), 'status accessor exists');

    my $spec_class   = 'IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Spec';
    my $status_class = 'IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Status';

    ok($spec_class->can('podTemplate'),    'spec has podTemplate');
    ok($spec_class->can('shutdownTime'),   'spec has shutdownTime');
    ok($spec_class->can('shutdownPolicy'), 'spec has shutdownPolicy');
    ok($spec_class->can('replicas'),       'spec has replicas');

    ok($status_class->can('serviceFQDN'), 'status has serviceFQDN');
    ok($status_class->can('service'),     'status has service');
    ok($status_class->can('replicas'),    'status has replicas');
    ok($status_class->can('selector'),    'status has selector');
};

subtest 'SandboxWarmPool inline struct inner classes exist' => sub {
    my $spec_class   = 'IO::K8s::AgentSandbox::V1alpha1::SandboxWarmPool::_Spec';
    my $status_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxWarmPool::_Status';

    ok($spec_class->can('replicas'),          'spec has replicas');
    ok($spec_class->can('sandboxTemplateRef'), 'spec has sandboxTemplateRef');
    ok($status_class->can('replicas'),        'status has replicas');
    ok($status_class->can('readyReplicas'),   'status has readyReplicas');
    ok($status_class->can('selector'),        'status has selector');

    # Nested inline struct for templateRef
    my $ref_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxWarmPool::_Spec::_SandboxTemplateRef';
    ok($ref_class->can('name'), 'sandboxTemplateRef has name');
};

subtest 'SandboxClaim inline struct inner classes exist' => sub {
    my $spec_class   = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec';
    my $status_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Status';

    ok($spec_class->can('sandboxTemplateRef'), 'spec has sandboxTemplateRef');
    ok($spec_class->can('lifecycle'),          'spec has lifecycle');

    # Nested inline struct: sandboxTemplateRef
    my $ref_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec::_SandboxTemplateRef';
    ok($ref_class->can('name'), 'sandboxTemplateRef has name');

    # Nested inline struct: lifecycle
    my $lc_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxClaim::_Spec::_Lifecycle';
    ok($lc_class->can('shutdownTime'),   'lifecycle has shutdownTime');
    ok($lc_class->can('shutdownPolicy'), 'lifecycle has shutdownPolicy');

    ok($status_class->can('conditions'), 'status has conditions');
    ok($status_class->can('sandbox'),    'status has sandbox');
};

subtest 'SandboxTemplate inline struct inner classes exist' => sub {
    my $spec_class = 'IO::K8s::AgentSandbox::V1alpha1::SandboxTemplate::_Spec';

    ok($spec_class->can('podTemplate'),             'spec has podTemplate');
    ok($spec_class->can('networkPolicy'),            'spec has networkPolicy');
    ok($spec_class->can('networkPolicyManagement'),  'spec has networkPolicyManagement');
};

# --- Hashref coercion on construction ---

subtest 'Sandbox spec hashref coercion' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'coerce-test', namespace => 'default' },
        spec     => { replicas => 1, shutdownPolicy => 'Retain' },
        status   => { serviceFQDN => 'sandbox-test.default.svc.cluster.local', replicas => 1 },
    );

    isa_ok($sandbox->spec,   'IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Spec');
    isa_ok($sandbox->status, 'IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Status');

    is($sandbox->spec->replicas,       1,        'spec.replicas');
    is($sandbox->spec->shutdownPolicy, 'Retain', 'spec.shutdownPolicy');
    is($sandbox->status->serviceFQDN,  'sandbox-test.default.svc.cluster.local', 'status.serviceFQDN');
    is($sandbox->status->replicas,     1,        'status.replicas');
};

subtest 'SandboxWarmPool spec/status hashref coercion' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $swp = $k8s->new_object('SandboxWarmPool',
        metadata => { name => 'my-pool', namespace => 'default' },
        spec     => { replicas => 3, sandboxTemplateRef => { name => 'my-template' } },
        status   => { replicas => 3, readyReplicas => 2, selector => 'pool=my-pool' },
    );

    isa_ok($swp->spec,   'IO::K8s::AgentSandbox::V1alpha1::SandboxWarmPool::_Spec');
    isa_ok($swp->status, 'IO::K8s::AgentSandbox::V1alpha1::SandboxWarmPool::_Status');

    is($swp->spec->replicas, 3, 'spec.replicas');
    isa_ok($swp->spec->sandboxTemplateRef,
        'IO::K8s::AgentSandbox::V1alpha1::SandboxWarmPool::_Spec::_SandboxTemplateRef');
    is($swp->spec->sandboxTemplateRef->name, 'my-template', 'spec.sandboxTemplateRef.name');

    is($swp->status->replicas,      3,             'status.replicas');
    is($swp->status->readyReplicas, 2,             'status.readyReplicas');
    is($swp->status->selector,      'pool=my-pool', 'status.selector');
};

subtest 'SandboxClaim nested lifecycle coercion' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $claim = $k8s->new_object('SandboxClaim',
        metadata => { name => 'my-claim', namespace => 'default' },
        spec     => {
            sandboxTemplateRef => { name => 'fast-template' },
            lifecycle          => { shutdownPolicy => 'Delete' },
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

subtest 'SandboxTemplate spec hashref coercion' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $tmpl = $k8s->new_object('SandboxTemplate',
        metadata => { name => 'my-tmpl', namespace => 'default' },
        spec     => { networkPolicyManagement => 'Managed' },
    );

    isa_ok($tmpl->spec, 'IO::K8s::AgentSandbox::V1alpha1::SandboxTemplate::_Spec');
    is($tmpl->spec->networkPolicyManagement, 'Managed', 'spec.networkPolicyManagement');
};

# --- TO_JSON round-trip ---

subtest 'Sandbox TO_JSON round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'json-test', namespace => 'default' },
        spec     => { replicas => 1, shutdownPolicy => 'Retain' },
        status   => { service => 'json-test', replicas => 1 },
    );

    my $json = $sandbox->TO_JSON;
    is(ref $json->{spec},   'HASH', 'spec serializes to hash');
    is(ref $json->{status}, 'HASH', 'status serializes to hash');
    is($json->{spec}{replicas},       1,        'spec.replicas in JSON');
    is($json->{spec}{shutdownPolicy}, 'Retain', 'spec.shutdownPolicy in JSON');
    is($json->{status}{service},      'json-test', 'status.service in JSON');
    is($json->{status}{replicas},     1,        'status.replicas in JSON');
};

subtest 'SandboxWarmPool TO_JSON round-trip' => sub {
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

subtest 'SandboxClaim TO_JSON round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $claim = $k8s->new_object('SandboxClaim',
        metadata => { name => 'claim-json', namespace => 'default' },
        spec     => {
            sandboxTemplateRef => { name => 'my-tmpl' },
            lifecycle          => { shutdownPolicy => 'Delete' },
        },
    );

    my $json = $claim->TO_JSON;
    is(ref $json->{spec}, 'HASH', 'spec serializes to hash');
    is(ref $json->{spec}{sandboxTemplateRef}, 'HASH', 'sandboxTemplateRef serializes to hash');
    is($json->{spec}{sandboxTemplateRef}{name}, 'my-tmpl', 'sandboxTemplateRef.name in JSON');
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
