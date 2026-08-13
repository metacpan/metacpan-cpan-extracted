#!/usr/bin/env perl
# Regression coverage for karr ticket #11:
# expand_class() only consults domain-qualified map entries
# ($api_version/$kind) for api_version-based disambiguation, and those
# were only ever populated by add() when an EXTERNAL provider collided
# with an existing short name. The built-in %DEFAULT_RESOURCE_MAP itself
# never got qualified keys, with two visible consequences:
#
#   (1) inflate({apiVersion=>"resource.k8s.io/v1beta1",
#                kind=>"DeviceClass", ...}) silently returned a
#       IO::K8s::Api::Resource::V1::DeviceClass (the GA class), not the
#       v1beta1 class. Wrong schema version, no error.
#
#   (2) inflate({apiVersion=>"resource.k8s.io/v1beta2",
#                kind=>"DeviceTaintRule", ...}) died outright with
#       'Cant locate IO/K8s/DeviceTaintRule.pm in @INC' because
#       DeviceTaintRule had no short-name entry at all and the bare
#       IO::K8s::$kind fallback does not exist.
#
# The same bug applied pre-existing to the already-shipped V1alpha3
# "classic DRA" DeviceClass/ResourceClaim/etc. and to the
# V1beta2 DeviceTaintRule family. Karr #4 added more classes that hit
# the identical gap; only the fully-qualified class reference
# (IO::K8s::Api::Resource::V1beta1::DeviceClass->new or
# ->struct_to_object with the full class name) bypasses inflate()'s
# apiVersion-based dispatch.
#
# This test covers both failure modes and both the api_version
# disambiguation path AND the domain-qualified expansion path that
# expand_class also exposes.

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s;

my $k8s = IO::K8s->new;

# ---- Failure mode 1: short-name + api_version dispatches to the
#      correct version of a Kind that has multiple shipped variants. ----

subtest 'expand_class returns the GA V1::DeviceClass when asked for resource.k8s.io/v1' => sub {
    my $cls = $k8s->expand_class('DeviceClass', 'resource.k8s.io/v1');
    is($cls, 'IO::K8s::Api::Resource::V1::DeviceClass',
        'GA resource.k8s.io/v1 resolves to V1::DeviceClass');
};

subtest 'expand_class returns V1beta1::DeviceClass when asked for resource.k8s.io/v1beta1' => sub {
    my $cls = $k8s->expand_class('DeviceClass', 'resource.k8s.io/v1beta1');
    is($cls, 'IO::K8s::Api::Resource::V1beta1::DeviceClass',
        'api_version disambiguates DeviceClass to v1beta1');
};

subtest 'expand_class returns V1beta2::DeviceClass when asked for resource.k8s.io/v1beta2' => sub {
    my $cls = $k8s->expand_class('DeviceClass', 'resource.k8s.io/v1beta2');
    is($cls, 'IO::K8s::Api::Resource::V1beta2::DeviceClass',
        'api_version disambiguates DeviceClass to v1beta2');
};

subtest 'expand_class returns V1alpha3::DeviceClass when asked for resource.k8s.io/v1alpha3' => sub {
    my $cls = $k8s->expand_class('DeviceClass', 'resource.k8s.io/v1alpha3');
    is($cls, 'IO::K8s::Api::Resource::V1alpha3::DeviceClass',
        'api_version disambiguates DeviceClass to v1alpha3');
};

# Same family for the other three short-name kinds that exist in
# %DEFAULT_RESOURCE_MAP.

for my $kind (qw(ResourceClaim ResourceClaimTemplate ResourceSlice)) {
    for my $av (qw(resource.k8s.io/v1 resource.k8s.io/v1beta1 resource.k8s.io/v1beta2)) {
        my ($group, $ver) = split m{/}, $av;
        # 'v1beta1' -> 'V1beta1', not 'V1BETA1'. lc first to lower-case the
        # version letters, then ucfirst to capitalise the leading 'v'.
        my $v_uc = ucfirst($ver);
        my $expected = "IO::K8s::Api::Resource::${v_uc}::${kind}";
        subtest "expand_class $kind + $av" => sub {
            is($k8s->expand_class($kind, $av), $expected,
                "api_version dispatches $kind to $v_uc");
        };
    }
}

# ---- Failure mode 2: short-name-less Kind (DeviceTaintRule,
#      ResourcePoolStatusRequest) reached via api_version ----

subtest 'expand_class DeviceTaintRule + resource.k8s.io/v1beta2' => sub {
    my $cls = $k8s->expand_class('DeviceTaintRule', 'resource.k8s.io/v1beta2');
    is($cls, 'IO::K8s::Api::Resource::V1beta2::DeviceTaintRule',
        'short-name-less kind is reachable via api_version');
};

subtest 'expand_class ResourcePoolStatusRequest + resource.k8s.io/v1alpha3' => sub {
    my $cls = $k8s->expand_class('ResourcePoolStatusRequest', 'resource.k8s.io/v1alpha3');
    is($cls, 'IO::K8s::Api::Resource::V1alpha3::ResourcePoolStatusRequest',
        'short-name-less kind is reachable via api_version');
};

# ---- Failure mode 3: domain-qualified expansion ----

subtest 'expand_class resource.k8s.io/v1beta1/DeviceClass (domain-qualified)' => sub {
    my $cls = $k8s->expand_class('resource.k8s.io/v1beta1/DeviceClass');
    is($cls, 'IO::K8s::Api::Resource::V1beta1::DeviceClass',
        'domain-qualified string resolves to v1beta1');
};

subtest 'expand_class resource.k8s.io/v1beta2/DeviceTaintRule (domain-qualified)' => sub {
    my $cls = $k8s->expand_class('resource.k8s.io/v1beta2/DeviceTaintRule');
    is($cls, 'IO::K8s::Api::Resource::V1beta2::DeviceTaintRule',
        'domain-qualified string resolves for short-name-less kind');
};

# ---- Failure mode 4: inflate() uses apiVersion from data ----
# This is the user-facing failure mode the ticket opened with. After
# the fix, the inflate call must return a V1beta1::DeviceClass object,
# not silently downgrade to V1.

subtest 'inflate of DeviceClass v1beta1 returns V1beta1::DeviceClass, not V1::DeviceClass' => sub {
    my $hash = {
        apiVersion => 'resource.k8s.io/v1beta1',
        kind       => 'DeviceClass',
        metadata   => { name => 'gpu.example.com' },
        spec       => {
            selectors => [
                { cel => { expression => q{device.driver == "gpu.example.com"} } },
            ],
        },
    };
    my $obj = $k8s->inflate($hash);
    isa_ok($obj, 'IO::K8s::Api::Resource::V1beta1::DeviceClass',
        'inflate returns the v1beta1 class');
    isnt(ref($obj), 'IO::K8s::Api::Resource::V1::DeviceClass',
        'inflate does NOT silently downgrade to V1 (GA)');
    is($obj->api_version, 'resource.k8s.io/v1beta1',
        'inflated object reports v1beta1 as its api_version');
};

subtest 'inflate of DeviceClass v1beta2 returns V1beta2::DeviceClass' => sub {
    my $hash = {
        apiVersion => 'resource.k8s.io/v1beta2',
        kind       => 'DeviceClass',
        metadata   => { name => 'gpu.example.com' },
        spec       => {
            selectors => [
                { cel => { expression => q{device.driver == "gpu.example.com"} } },
            ],
        },
    };
    my $obj = $k8s->inflate($hash);
    isa_ok($obj, 'IO::K8s::Api::Resource::V1beta2::DeviceClass',
        'inflate returns the v1beta2 class');
};

# Failure mode 5: inflate() of a short-name-less Kind used to die.
# After the fix it must succeed.

subtest 'inflate of DeviceTaintRule v1beta2 returns V1beta2::DeviceTaintRule (used to die)' => sub {
    my $hash = {
        apiVersion => 'resource.k8s.io/v1beta2',
        kind       => 'DeviceTaintRule',
        metadata   => { name => 'gpu-taint' },
        spec       => {
            deviceSelector => { cel => { expression => q{true} } },
            taint => { key => 'example.com/gpu', value => 'true', effect => 'NoSchedule' },
        },
    };
    my $obj = eval { $k8s->inflate($hash) };
    is($@, '', 'inflate does not die on short-name-less Kind') or BAIL_OUT($@);
    isa_ok($obj, 'IO::K8s::Api::Resource::V1beta2::DeviceTaintRule',
        'inflate returns V1beta2::DeviceTaintRule');
};

subtest 'inflate of ResourcePoolStatusRequest v1alpha3 returns V1alpha3::ResourcePoolStatusRequest (used to die)' => sub {
    my $hash = {
        apiVersion => 'resource.k8s.io/v1alpha3',
        kind       => 'ResourcePoolStatusRequest',
        metadata   => { name => 'my-pool' },
        spec       => { driver => 'gpu.example.com' },
    };
    my $obj = eval { $k8s->inflate($hash) };
    is($@, '', 'inflate does not die on short-name-less Kind') or BAIL_OUT($@);
    isa_ok($obj, 'IO::K8s::Api::Resource::V1alpha3::ResourcePoolStatusRequest',
        'inflate returns V1alpha3::ResourcePoolStatusRequest');
};

# ---- Failure mode 6: round-trip preservation through inflate->TO_JSON->inflate ----

subtest 'inflate -> TO_JSON -> inflate round-trips through the same v1beta1 class' => sub {
    my $hash = {
        apiVersion => 'resource.k8s.io/v1beta1',
        kind       => 'ResourceClaim',
        metadata   => { name => 'my-claim', namespace => 'default' },
        spec       => {
            devices => { requests => [{ name => 'req-1', deviceClassName => 'gpu.example.com' }] },
        },
    };
    my $obj  = $k8s->inflate($hash);
    isa_ok($obj, 'IO::K8s::Api::Resource::V1beta1::ResourceClaim',
        'first inflate is v1beta1');
    my $back = $k8s->object_to_struct($obj);
    my $again = $k8s->inflate($back);
    isa_ok($again, 'IO::K8s::Api::Resource::V1beta1::ResourceClaim',
        'second inflate is still v1beta1');
    is(ref($again), ref($obj),
        'round-trip preserves the class identity');
};

# ---- Negative: nothing should regress for the existing default short-name resolution ----

subtest 'expand_class "DeviceClass" with no api_version still returns V1 (first-registered wins)' => sub {
    is($k8s->expand_class('DeviceClass'),
        'IO::K8s::Api::Resource::V1::DeviceClass',
        'short name with no api_version keeps the existing first-registered behaviour');
};

# ---- Pre-existing V1alpha3 disambiguation still works ----

subtest 'expand_class Pod + v1 returns Pod (sanity check, no regression on built-in)' => sub {
    is($k8s->expand_class('Pod', 'v1'),
        'IO::K8s::Api::Core::V1::Pod',
        'built-in Pod resolves with api_version=v1');
};

# ---- Per-instance isolation: adding a custom provider must not leak
#      qualified keys into the default map of other instances ----

subtest 'per-instance isolation: add() does not share state between instances' => sub {
    my $k1 = IO::K8s->new;
    my $k2 = IO::K8s->new;

    # Both instances get a default copy of the literal qualified entries
    # in %DEFAULT_RESOURCE_MAP - that's the karr #11 mechanism and must
    # hold for every instance, not just the first one.
    ok( exists $k1->resource_map->{'v1/Pod'},
        'k1 has the built-in v1/Pod qualified key' );
    ok( exists $k2->resource_map->{'v1/Pod'},
        'k2 also has the built-in v1/Pod qualified key' );

    # But a custom addition to k1 must not leak into k2. We use a
    # shipped class so add() can introspect api_version.
    $k1->add({
        CiliumNetworkPolicy => '+IO::K8s::Cilium::V2::CiliumNetworkPolicy',
    });
    ok( exists $k1->resource_map->{'CiliumNetworkPolicy'},
        'k1 has the added CiliumNetworkPolicy short name' );
    ok( !exists $k2->resource_map->{'CiliumNetworkPolicy'},
        'k2 does NOT see the addition to k1' );
};

done_testing;
