#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;

# --- Mock external classes ---

{
    package Test::Mock::CiliumNetworkPolicy;
    use IO::K8s::Resource;
    sub api_version { 'cilium.io/v2' }
    sub kind { 'CiliumNetworkPolicy' }
}

{
    package Test::Mock::CiliumNetworkPolicyV2;
    use IO::K8s::Resource;
    sub api_version { 'cilium.io/v2' }
    sub kind { 'NetworkPolicy' }
}

{
    package Test::Mock::ThirdPartyNetworkPolicy;
    use IO::K8s::Resource;
    sub api_version { 'example.com/v1' }
    sub kind { 'NetworkPolicy' }
}

{
    package Test::Mock::CiliumProvider;
    use Moo;
    with 'IO::K8s::Role::ResourceMap';

    sub resource_map {
        return {
            CiliumNetworkPolicy => '+Test::Mock::CiliumNetworkPolicy',
            NetworkPolicy       => '+Test::Mock::CiliumNetworkPolicyV2',
        };
    }
}

{
    package Test::Mock::ThirdPartyProvider;
    use Moo;
    with 'IO::K8s::Role::ResourceMap';

    sub resource_map {
        return {
            NetworkPolicy => '+Test::Mock::ThirdPartyNetworkPolicy',
        };
    }
}

# --- Tests ---

subtest 'add() with no collision' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add({ UniqueKind => '+Test::Mock::CiliumNetworkPolicy' });

    # Short name works
    is($k8s->expand_class('UniqueKind'), 'Test::Mock::CiliumNetworkPolicy',
        'short name resolves after add');

    # Domain-qualified also works
    is($k8s->expand_class('cilium.io/v2/UniqueKind'), 'Test::Mock::CiliumNetworkPolicy',
        'domain-qualified name resolves after add');
};

subtest 'add() with collision' => sub {
    my $k8s = IO::K8s->new;

    # NetworkPolicy already exists in default map (networking.k8s.io/v1)
    is($k8s->expand_class('NetworkPolicy'), 'IO::K8s::Api::Networking::V1::NetworkPolicy',
        'NetworkPolicy resolves to core before add');

    # Add Cilium provider which also has NetworkPolicy
    $k8s->add(Test::Mock::CiliumProvider->new);

    # Short name still resolves to original (first-registered wins)
    is($k8s->expand_class('NetworkPolicy'), 'IO::K8s::Api::Networking::V1::NetworkPolicy',
        'short name still resolves to core after collision');

    # CiliumNetworkPolicy has no collision - short name works
    is($k8s->expand_class('CiliumNetworkPolicy'), 'Test::Mock::CiliumNetworkPolicy',
        'unique kind short name works');

    # Domain-qualified: core
    is($k8s->expand_class('networking.k8s.io/v1/NetworkPolicy'),
        'IO::K8s::Api::Networking::V1::NetworkPolicy',
        'domain-qualified core NetworkPolicy resolves');

    # Domain-qualified: Cilium
    is($k8s->expand_class('cilium.io/v2/NetworkPolicy'),
        'Test::Mock::CiliumNetworkPolicyV2',
        'domain-qualified Cilium NetworkPolicy resolves');
};

subtest 'expand_class with api_version disambiguation' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add(Test::Mock::CiliumProvider->new);

    is($k8s->expand_class('NetworkPolicy', 'cilium.io/v2'),
        'Test::Mock::CiliumNetworkPolicyV2',
        'short name + api_version disambiguates to Cilium');

    is($k8s->expand_class('NetworkPolicy', 'networking.k8s.io/v1'),
        'IO::K8s::Api::Networking::V1::NetworkPolicy',
        'short name + api_version disambiguates to core');

    # Without api_version, falls back to first-registered
    is($k8s->expand_class('NetworkPolicy'),
        'IO::K8s::Api::Networking::V1::NetworkPolicy',
        'without api_version, short name goes to first-registered');
};

subtest 'new_object with api_version' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add({ SimpleKind => '+Test::Mock::CiliumNetworkPolicy' });

    my $obj = $k8s->new_object('SimpleKind', {});
    isa_ok($obj, 'Test::Mock::CiliumNetworkPolicy', 'new_object without api_version');

    # new_object with api_version
    $k8s->add(Test::Mock::CiliumProvider->new);
    my $cilium_obj = $k8s->new_object('NetworkPolicy', {}, 'cilium.io/v2');
    isa_ok($cilium_obj, 'Test::Mock::CiliumNetworkPolicyV2',
        'new_object with api_version disambiguates');
};

subtest 'inflate uses apiVersion from data' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add(Test::Mock::CiliumProvider->new);

    # inflate with core apiVersion
    my $core_obj = $k8s->inflate({
        kind       => 'NetworkPolicy',
        apiVersion => 'networking.k8s.io/v1',
        metadata   => { name => 'test-core' },
    });
    isa_ok($core_obj, 'IO::K8s::Api::Networking::V1::NetworkPolicy',
        'inflate with core apiVersion');

    # inflate with Cilium apiVersion
    my $cilium_obj = $k8s->inflate({
        kind       => 'NetworkPolicy',
        apiVersion => 'cilium.io/v2',
    });
    isa_ok($cilium_obj, 'Test::Mock::CiliumNetworkPolicyV2',
        'inflate with Cilium apiVersion');
};

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['Test::Mock::CiliumProvider']);

    is($k8s->expand_class('CiliumNetworkPolicy'), 'Test::Mock::CiliumNetworkPolicy',
        'with param: unique kind short name works');

    is($k8s->expand_class('cilium.io/v2/NetworkPolicy'),
        'Test::Mock::CiliumNetworkPolicyV2',
        'with param: domain-qualified resolves');
};

subtest 'multiple add() calls (3-way collision)' => sub {
    my $k8s = IO::K8s->new;

    # First collision: Cilium
    $k8s->add(Test::Mock::CiliumProvider->new);

    # Second collision: ThirdParty
    $k8s->add(Test::Mock::ThirdPartyProvider->new);

    # Short name still goes to original
    is($k8s->expand_class('NetworkPolicy'),
        'IO::K8s::Api::Networking::V1::NetworkPolicy',
        '3-way: short name still core');

    # All three reachable by domain-qualified
    is($k8s->expand_class('networking.k8s.io/v1/NetworkPolicy'),
        'IO::K8s::Api::Networking::V1::NetworkPolicy',
        '3-way: core by domain-qualified');

    is($k8s->expand_class('cilium.io/v2/NetworkPolicy'),
        'Test::Mock::CiliumNetworkPolicyV2',
        '3-way: Cilium by domain-qualified');

    is($k8s->expand_class('example.com/v1/NetworkPolicy'),
        'Test::Mock::ThirdPartyNetworkPolicy',
        '3-way: ThirdParty by domain-qualified');
};

subtest 'isolated instances' => sub {
    my $k8s1 = IO::K8s->new;
    my $k8s2 = IO::K8s->new;

    $k8s1->add({ UniqueToK8s1 => '+Test::Mock::CiliumNetworkPolicy' });

    is($k8s1->expand_class('UniqueToK8s1'), 'Test::Mock::CiliumNetworkPolicy',
        'k8s1 has the added kind');

    # k8s2 should NOT see k8s1's additions
    ok(!exists $k8s2->resource_map->{UniqueToK8s1},
        'k8s2 does not have k8s1 additions');
};

subtest 'add with raw hashref' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add({ MyCustomKind => '+Test::Mock::CiliumNetworkPolicy' });

    is($k8s->expand_class('MyCustomKind'), 'Test::Mock::CiliumNetworkPolicy',
        'hashref add: short name works');
    is($k8s->expand_class('cilium.io/v2/MyCustomKind'), 'Test::Mock::CiliumNetworkPolicy',
        'hashref add: domain-qualified works');
};

subtest 'add returns self for chaining' => sub {
    my $k8s = IO::K8s->new;
    my $ret = $k8s->add({ Foo => '+Test::Mock::CiliumNetworkPolicy' });
    is($ret, $k8s, 'add() returns $self');

    # Chaining: add(...)->add(...)
    my $k8s2 = IO::K8s->new;
    $k8s2->add(Test::Mock::CiliumProvider->new)
          ->add(Test::Mock::ThirdPartyProvider->new);
    is($k8s2->expand_class('CiliumNetworkPolicy'), 'Test::Mock::CiliumNetworkPolicy',
        'chained add: first provider worked');
    is($k8s2->expand_class('example.com/v1/NetworkPolicy'), 'Test::Mock::ThirdPartyNetworkPolicy',
        'chained add: second provider worked');
};

subtest 'add() with multiple providers in single call' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add(Test::Mock::CiliumProvider->new, Test::Mock::ThirdPartyProvider->new);

    is($k8s->expand_class('CiliumNetworkPolicy'), 'Test::Mock::CiliumNetworkPolicy',
        'multi-add: CiliumNetworkPolicy from first provider');
    is($k8s->expand_class('cilium.io/v2/NetworkPolicy'), 'Test::Mock::CiliumNetworkPolicyV2',
        'multi-add: Cilium NetworkPolicy via domain-qualified');
    is($k8s->expand_class('example.com/v1/NetworkPolicy'), 'Test::Mock::ThirdPartyNetworkPolicy',
        'multi-add: ThirdParty NetworkPolicy via domain-qualified');
    is($k8s->expand_class('NetworkPolicy'), 'IO::K8s::Api::Networking::V1::NetworkPolicy',
        'multi-add: short name still core');
};

subtest 'domain-qualified expand_class returns undef for unknown' => sub {
    my $k8s = IO::K8s->new;
    my $result = $k8s->expand_class('nonexistent.io/v1/UnknownKind');
    is($result, undef, 'unknown domain-qualified returns undef');
};

# --- Realistic external distribution simulation (like IO::K8s::Cilium) ---
# Uses IO::K8s::APIObject to create proper CRD classes under MyK8s:: namespace

{
    package MyK8s::Firewall::V1::FirewallRule;
    use IO::K8s::APIObject
        api_version     => 'firewall.example.com/v1',
        resource_plural => 'firewallrules';
    with 'IO::K8s::Role::Namespaced';

    k8s spec   => { Str => 1 };
    k8s status => { Str => 1 };
    1;
}

{
    # A class that collides with core NetworkPolicy
    package MyK8s::Firewall::V1::NetworkPolicy;
    use IO::K8s::APIObject
        api_version     => 'firewall.example.com/v1',
        resource_plural => 'networkpolicies';
    with 'IO::K8s::Role::Namespaced';

    k8s spec   => { Str => 1 };
    k8s status => { Str => 1 };
    1;
}

{
    package MyK8s::Firewall;
    use Moo;
    with 'IO::K8s::Role::ResourceMap';

    sub resource_map {
        return {
            FirewallRule   => '+MyK8s::Firewall::V1::FirewallRule',
            NetworkPolicy  => '+MyK8s::Firewall::V1::NetworkPolicy',
        };
    }
    1;
}

subtest 'realistic external distribution (MyK8s::Firewall)' => sub {

    subtest 'CRD classes are proper APIObjects' => sub {
        is(MyK8s::Firewall::V1::FirewallRule->api_version, 'firewall.example.com/v1',
            'FirewallRule api_version');
        is(MyK8s::Firewall::V1::FirewallRule->kind, 'FirewallRule',
            'FirewallRule kind');
        is(MyK8s::Firewall::V1::FirewallRule->resource_plural, 'firewallrules',
            'FirewallRule resource_plural');
        ok(MyK8s::Firewall::V1::FirewallRule->does('IO::K8s::Role::Namespaced'),
            'FirewallRule is namespaced');

        is(MyK8s::Firewall::V1::NetworkPolicy->api_version, 'firewall.example.com/v1',
            'NetworkPolicy api_version');
        is(MyK8s::Firewall::V1::NetworkPolicy->kind, 'NetworkPolicy',
            'NetworkPolicy kind');
    };

    subtest 'add provider and resolve classes' => sub {
        my $k8s = IO::K8s->new;
        $k8s->add('MyK8s::Firewall');

        # Unique kind: short name works
        is($k8s->expand_class('FirewallRule'), 'MyK8s::Firewall::V1::FirewallRule',
            'FirewallRule short name resolves');

        # Collision: NetworkPolicy short name stays core
        is($k8s->expand_class('NetworkPolicy'),
            'IO::K8s::Api::Networking::V1::NetworkPolicy',
            'NetworkPolicy short name stays core');

        # Domain-qualified: both reachable
        is($k8s->expand_class('firewall.example.com/v1/NetworkPolicy'),
            'MyK8s::Firewall::V1::NetworkPolicy',
            'firewall NetworkPolicy via domain-qualified');
        is($k8s->expand_class('networking.k8s.io/v1/NetworkPolicy'),
            'IO::K8s::Api::Networking::V1::NetworkPolicy',
            'core NetworkPolicy via domain-qualified');
    };

    subtest 'new_object creates proper objects' => sub {
        my $k8s = IO::K8s->new(with => ['MyK8s::Firewall']);

        # Unique kind
        my $rule = $k8s->new_object('FirewallRule',
            metadata => { name => 'allow-http', namespace => 'default' },
            spec     => { port => '80', action => 'allow' },
        );
        isa_ok($rule, 'MyK8s::Firewall::V1::FirewallRule');
        is($rule->kind, 'FirewallRule', 'kind method');
        is($rule->api_version, 'firewall.example.com/v1', 'api_version method');
        isa_ok($rule->metadata,
            'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
            'metadata is ObjectMeta');
        is($rule->metadata->name, 'allow-http', 'metadata name');
        is($rule->metadata->namespace, 'default', 'metadata namespace');

        # Collision: disambiguate with api_version
        my $fw_np = $k8s->new_object('NetworkPolicy',
            { metadata => { name => 'deny-all' }, spec => { action => 'deny' } },
            'firewall.example.com/v1',
        );
        isa_ok($fw_np, 'MyK8s::Firewall::V1::NetworkPolicy');
        is($fw_np->kind, 'NetworkPolicy', 'firewall NP kind');
        is($fw_np->api_version, 'firewall.example.com/v1', 'firewall NP api_version');

        # Default: core NetworkPolicy
        my $core_np = $k8s->new_object('NetworkPolicy',
            metadata => { name => 'core-deny' },
        );
        isa_ok($core_np, 'IO::K8s::Api::Networking::V1::NetworkPolicy');
    };

    subtest 'inflate round-trip with apiVersion disambiguation' => sub {
        my $k8s = IO::K8s->new(with => ['MyK8s::Firewall']);

        # Create a FirewallRule, serialize, re-inflate
        my $rule = $k8s->new_object('FirewallRule',
            metadata => { name => 'test-rule' },
            spec     => { port => '443' },
        );
        my $json = $k8s->object_to_json($rule);
        like($json, qr/"apiVersion":"firewall\.example\.com\/v1"/, 'JSON has apiVersion');
        like($json, qr/"kind":"FirewallRule"/, 'JSON has kind');

        my $re_inflated = $k8s->inflate($json);
        isa_ok($re_inflated, 'MyK8s::Firewall::V1::FirewallRule',
            're-inflated FirewallRule');
        is($re_inflated->metadata->name, 'test-rule', 'round-trip name preserved');

        # Inflate collision kind with firewall apiVersion
        my $fw_np = $k8s->new_object('NetworkPolicy',
            { metadata => { name => 'fw-deny' }, spec => { action => 'deny' } },
            'firewall.example.com/v1',
        );
        my $fw_json = $k8s->object_to_json($fw_np);
        like($fw_json, qr/"apiVersion":"firewall\.example\.com\/v1"/, 'FW NP JSON has apiVersion');

        my $fw_re = $k8s->inflate($fw_json);
        isa_ok($fw_re, 'MyK8s::Firewall::V1::NetworkPolicy',
            're-inflated firewall NetworkPolicy');

        # Inflate collision kind with core apiVersion
        my $core_np = $k8s->inflate({
            kind       => 'NetworkPolicy',
            apiVersion => 'networking.k8s.io/v1',
            metadata   => { name => 'core-np' },
        });
        isa_ok($core_np, 'IO::K8s::Api::Networking::V1::NetworkPolicy',
            're-inflated core NetworkPolicy');
    };

    subtest 'new_object with domain-qualified string' => sub {
        my $k8s = IO::K8s->new(with => ['MyK8s::Firewall']);

        # Domain-qualified string directly in new_object
        my $fw_np = $k8s->new_object('firewall.example.com/v1/NetworkPolicy',
            { metadata => { name => 'dq-test' }, spec => { action => 'deny' } },
        );
        isa_ok($fw_np, 'MyK8s::Firewall::V1::NetworkPolicy');
        is($fw_np->kind, 'NetworkPolicy', 'domain-qualified new_object kind');
        is($fw_np->api_version, 'firewall.example.com/v1', 'domain-qualified new_object api_version');
        is($fw_np->metadata->name, 'dq-test', 'domain-qualified new_object name');

        # Unique kind via domain-qualified (also works)
        my $rule = $k8s->new_object('firewall.example.com/v1/FirewallRule',
            { metadata => { name => 'dq-rule' } },
        );
        isa_ok($rule, 'MyK8s::Firewall::V1::FirewallRule');
        is($rule->metadata->name, 'dq-rule', 'unique kind via domain-qualified');
    };

    subtest 'to_yaml produces valid output' => sub {
        my $k8s = IO::K8s->new(with => ['MyK8s::Firewall']);

        my $rule = $k8s->new_object('FirewallRule',
            metadata => { name => 'yaml-test', namespace => 'prod' },
            spec     => { port => '22', action => 'deny' },
        );
        my $yaml = $rule->to_yaml;
        like($yaml, qr/kind: FirewallRule/, 'YAML has kind');
        like($yaml, qr/apiVersion: firewall\.example\.com\/v1/, 'YAML has apiVersion');
        like($yaml, qr/name: yaml-test/, 'YAML has name');
        like($yaml, qr/namespace: prod/, 'YAML has namespace');
    };

    subtest 'pk8s DSL with api_version disambiguation' => sub {
        require File::Temp;
        my $k8s = IO::K8s->new(with => ['MyK8s::Firewall']);

        my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.pk8s', UNLINK => 1);
        print $fh q{
            # Unique kind - no disambiguation needed
            FirewallRule {
                name => 'allow-http',
                namespace => 'default',
                spec => { port => '80' },
            };

            # Collision kind - default goes to core
            NetworkPolicy {
                name => 'core-deny',
                namespace => 'default',
                spec => { podSelector => {} },
            };

            # Collision kind - disambiguated to firewall (no comma, like grep/map)
            NetworkPolicy {
                name => 'fw-deny',
                namespace => 'default',
                spec => { action => 'deny' },
            } 'firewall.example.com/v1';
        };
        close $fh;

        my $objs = $k8s->load($filename);
        is(scalar(@$objs), 3, 'pk8s loaded 3 objects');

        my ($rule, $core_np, $fw_np) = @$objs;

        isa_ok($rule, 'MyK8s::Firewall::V1::FirewallRule');
        is($rule->metadata->name, 'allow-http', 'pk8s FirewallRule name');
        is($rule->kind, 'FirewallRule', 'pk8s FirewallRule kind');

        isa_ok($core_np, 'IO::K8s::Api::Networking::V1::NetworkPolicy');
        is($core_np->metadata->name, 'core-deny', 'pk8s core NP name');

        isa_ok($fw_np, 'MyK8s::Firewall::V1::NetworkPolicy');
        is($fw_np->metadata->name, 'fw-deny', 'pk8s firewall NP name');
        is($fw_np->api_version, 'firewall.example.com/v1', 'pk8s firewall NP api_version');
    };
};

done_testing;
