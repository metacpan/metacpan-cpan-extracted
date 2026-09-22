#!/usr/bin/env perl
# k71: Load-format test coverage gaps.
#
# Additive coverage for existing inflation/load-path behaviour -- every
# assertion in this file already holds against unmodified lib/, no bugfix
# involved.
#
# P1: IO::K8s::List::FROM_STRUCT derives its item class via
#     $k8s->expand_class($item_kind, $api_version) (see lib/IO/K8s/List.pm).
#     Prior coverage (t/61_k64_list_from_json.t, t/44_list_api_version.t)
#     only exercised a built-in shipped Kind (v1/Pod) and an unresolvable
#     Kind (GizmoList). This exercises three more expand_class() paths List
#     inflation routes through: a CRD provider registered via `with`, a
#     class_namespaces subclass, and an AutoGen (openapi_spec) generated
#     class.
#
# P2: IO::K8s::List->from_json($json, $k8s) / FROM_STRUCT's second, optional
#     $k8s argument -- never exercised with a real provider-carrying $k8s
#     before. Without it, a provider item Kind must fail closed exactly like
#     every other unresolvable GVK in this distribution (k39/k46).
#
# P3: inflate() with no 'kind' field in the data dies with a fixed, named
#     error (lib/IO/K8s.pm).

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::List;
use IO::K8s::AutoGen;
use IO::K8s::Cilium;

# ---------------------------------------------------------------------------
# P1a: List inflation resolves an item type through a CRD provider.
# ---------------------------------------------------------------------------

subtest 'List inflation resolves item type through a CRD provider (k71 / P1)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $cnp_list_json = <<'END_JSON';
{
  "kind": "CiliumNetworkPolicyList",
  "apiVersion": "cilium.io/v2",
  "items": [
    {
      "metadata": { "name": "allow-dns", "namespace": "kube-system" },
      "spec": { "description": "allow dns egress" }
    }
  ]
}
END_JSON

    my $list = $k8s->json_to_object($cnp_list_json);
    isa_ok($list, 'IO::K8s::List', 'inflated CiliumNetworkPolicyList');
    is(scalar @{ $list->items }, 1, 'one item');
    isa_ok($list->items->[0], 'IO::K8s::Cilium::V2::CiliumNetworkPolicy',
        'item resolved to the provider class, not a core/bare hash');
    is($list->items->[0]->metadata->name, 'allow-dns', 'item metadata.name inflated');
    is($list->items->[0]->metadata->namespace, 'kube-system', 'item metadata.namespace inflated');
    is($list->items->[0]->spec->{description}, 'allow dns egress', 'item spec inflated');
    is($list->kind, 'CiliumNetworkPolicyList', 'list kind derived from the first item');
    is($list->api_version, 'cilium.io/v2', 'list api_version derived from the first item');
};

# ---------------------------------------------------------------------------
# P1b: List inflation resolves an item type through a class_namespaces
# subclass (same mechanism t/46_class_namespaces_inflate.t exercises for a
# plain, non-List inflate).
# ---------------------------------------------------------------------------

{
    package My::K8s::Api::Core::V1::Pod;
    use parent qw(IO::K8s::Api::Core::V1::Pod);
    $INC{'My/K8s/Api/Core/V1/Pod.pm'} = __FILE__;
}

subtest 'List inflation resolves item type through a class_namespaces subclass (k71 / P1)' => sub {
    my $k8s = IO::K8s->new(class_namespaces => ['My::K8s']);

    my $podlist_json = <<'END_JSON';
{
  "kind": "PodList",
  "apiVersion": "v1",
  "items": [
    { "metadata": { "name": "p1", "namespace": "default" } }
  ]
}
END_JSON

    my $list = $k8s->json_to_object($podlist_json);
    isa_ok($list, 'IO::K8s::List', 'inflated PodList');
    isa_ok($list->items->[0], 'My::K8s::Api::Core::V1::Pod',
        'item resolved to the class_namespaces subclass, not the core class');
    is($list->items->[0]->metadata->name, 'p1', 'item metadata inflated');
    is($list->kind, 'PodList', 'list kind derived from the first item');
    is($list->api_version, 'v1', 'list api_version derived from the first item');
};

# ---------------------------------------------------------------------------
# P1c: List inflation resolves an item type through AutoGen (openapi_spec).
# ---------------------------------------------------------------------------

subtest 'List inflation resolves item type through AutoGen/openapi_spec (k71 / P1)' => sub {
    my $spec = {
        definitions => {
            'io.example.v1.Widget' => {
                type => 'object',
                'x-kubernetes-group-version-kind' => [
                    { group => 'example.com', version => 'v1', kind => 'Widget' },
                ],
                properties => {
                    spec => {
                        type       => 'object',
                        properties => { size => { type => 'string' } },
                    },
                },
            },
        },
    };

    my $k8s = IO::K8s->new(openapi_spec => $spec, resource_map => {});

    my $widgetlist = {
        kind       => 'WidgetList',
        apiVersion => 'example.com/v1',
        items      => [
            { metadata => { name => 'w1' }, spec => { size => 'l' } },
        ],
    };

    my $list = eval { $k8s->inflate($widgetlist) };
    ok($list, 'inflate succeeds') or diag $@;

    SKIP: {
        skip 'inflate failed, cannot assert on item type', 5 unless $list;

        isa_ok($list, 'IO::K8s::List', 'inflated WidgetList');
        is(scalar @{ $list->items }, 1, 'one item');

        my $item = $list->items->[0];
        ok(IO::K8s::AutoGen::is_autogen(ref $item),
            'item resolved to an AutoGen-generated class, not a bare hash');
        is($item->metadata->name, 'w1', 'item metadata inflated');
        is($item->spec->{size}, 'l', 'item spec inflated');
    }
};

# ---------------------------------------------------------------------------
# P2: IO::K8s::List->from_json($json, $k8s) threads the optional $k8s
# argument through to item resolution; the same payload without it fails
# closed rather than resolving against a provider-less default instance.
# ---------------------------------------------------------------------------

subtest q{IO::K8s::List->from_json's optional $k8s argument (k71 / P2)} => sub {
    my $bytes = <<'END_JSON';
{"kind":"CiliumNetworkPolicyList","apiVersion":"cilium.io/v2","items":[{"metadata":{"name":"allow-dns","namespace":"kube-system"},"spec":{"description":"allow dns egress"}}]}
END_JSON

    my $k8s_with_provider = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $list;
    lives_ok { $list = IO::K8s::List->from_json($bytes, $k8s_with_provider) }
        'from_json with a provider-carrying $k8s inflates a provider Kind';
    if ($list) {
        isa_ok($list->items->[0], 'IO::K8s::Cilium::V2::CiliumNetworkPolicy',
            'item resolved to the provider class when $k8s is passed');
        is($list->items->[0]->metadata->name, 'allow-dns', 'item data inflated via the 2-arg from_json');
    }

    throws_ok { IO::K8s::List->from_json($bytes) }
        qr/Cannot resolve Kubernetes GVK: kind 'CiliumNetworkPolicy', apiVersion 'cilium\.io\/v2'/,
        'the same payload without the $k8s argument fails closed -- '
      . 'the default IO::K8s instance FROM_STRUCT falls back to has no Cilium provider';
};

# ---------------------------------------------------------------------------
# P3: inflate() with no 'kind' field dies with a fixed, named error.
# ---------------------------------------------------------------------------

subtest q{inflate() without a 'kind' field dies naming the missing field (k71 / P3)} => sub {
    my $k8s = IO::K8s->new;
    throws_ok { $k8s->inflate({ apiVersion => 'v1' }) }
        qr/Cannot inflate: missing 'kind' field in data/,
        q{inflate() dies with "Cannot inflate: missing 'kind' field in data"};
};

done_testing;
