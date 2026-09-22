#!/usr/bin/env perl
# Regression coverage for k22:
#
# IO::K8s::List::api_version() used to derive the wire apiVersion for
# empty lists from item_class with a local regex that lc()-ed the
# CamelCase group component of the class name. That produces shortened,
# invalid wire versions for every group whose upstream name carries a
# ".k8s.io" suffix:
#
#   - item_class => 'IO::K8s::Api::Rbac::V1::Role'      used to compute
#     "rbac/v1", upstream is "rbac.authorization.k8s.io/v1"
#   - item_class => 'IO::K8s::Api::Storage::V1::StorageClass' used to
#     compute "storage/v1", upstream is "storage.k8s.io/v1"
#   - item_class => 'IO::K8s::Api::Events::V1::Event'   used to compute
#     "events/v1", upstream is "events.k8s.io/v1"
#
# Core ("IO::K8s::Api::Core::V1::*" -> "v1") and groups whose CamelCase
# lc-form already matches the upstream group (apps, batch, autoscaling,
# policy) were correct and must stay correct. Because TO_JSON always calls
# $self->api_version, an empty list with such an item_class serialised a
# syntactically plausible but wrong apiVersion that a real Kubernetes API
# server would reject.
#
# The fix derives the wire version from the item_class's own
# api_version class method (IO::K8s::Role::APIObject::api_version, which
# consults %API_GROUP_MAP) and returns undef for unloadable or
# non-API classes, instead of running the local regex.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use JSON::MaybeXS;

use IO::K8s;
use IO::K8s::List;
use IO::K8s::Api::Core::V1::Pod;

my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1, allow_nonref => 1);

# Empty lists with a valid API item_class must yield the item class's
# own wire apiVersion (the exact string a real server would expect).
my %EXPECTED = (
    'IO::K8s::Api::Core::V1::Pod'                       => 'v1',
    'IO::K8s::Api::Apps::V1::Deployment'                => 'apps/v1',
    'IO::K8s::Api::Rbac::V1::Role'                      => 'rbac.authorization.k8s.io/v1',
    'IO::K8s::Api::Storage::V1::StorageClass'           => 'storage.k8s.io/v1',
    'IO::K8s::Api::Events::V1::Event'                   => 'events.k8s.io/v1',
    'IO::K8s::Api::Networking::V1::NetworkPolicy'       => 'networking.k8s.io/v1',
    'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition'
        => 'apiextensions.k8s.io/v1',
    'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService'
        => 'apiregistration.k8s.io/v1',
);

for my $class (sort keys %EXPECTED) {
    my $list = IO::K8s::List->new( items => [], item_class => $class );
    is( $list->api_version, $EXPECTED{$class},
        "empty list with item_class $class derives api_version '$EXPECTED{$class}'" );

    my $wire = $json->decode($list->to_json);
    is( $wire->{apiVersion}, $EXPECTED{$class},
        "empty list with item_class $class serialises apiVersion '$EXPECTED{$class}'" );
    is( $wire->{kind}, $class =~ /::(\w+)$/ ? "$1List" : undef,
        "empty list with item_class $class serialises a kind" );
}

# An unloadable / non-API item_class must yield undef, not crash and not
# emit a bogus apiVersion in the serialised form. k49 extends this: an
# api_version() that can't answer means kind() must not answer either --
# TO_JSON must never emit 'kind' without 'apiVersion' alongside it.
for my $class (
    'IO::K8s::SomeBogusClass',       # does not exist at all
    'IO::K8s::Api::Rbac::V1::NoSuchKind',  # class name without a file
    'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta',  # loads, no api_version
    'IO::K8s::List',  # loads, api_version is instance-only: class call must not crash
) {
    my $list = IO::K8s::List->new( items => [], item_class => $class );
    is( $list->api_version, undef,
        "empty list with item_class $class derives api_version undef" );
    is( $list->kind, undef,
        "empty list with item_class $class also derives kind() undef -- "
        . 'never a kind without an apiVersion (k49)' );

    my $wire = $json->decode($list->to_json);
    ok( !exists $wire->{apiVersion},
        "empty list with item_class $class serialises without apiVersion" );
    ok( !exists $wire->{kind},
        "empty list with item_class $class serialises without kind either -- "
        . 'apiVersion and kind are emitted together or not at all (k49)' );
}

# kind() must still derive from item_class for empty lists (regression).
{
    my $list = IO::K8s::List->new(
        items      => [],
        item_class => 'IO::K8s::Api::Rbac::V1::Role',
    );
    is( $list->kind, 'RoleList', 'kind() still derives RoleList from item_class' );
}

# Non-empty lists must keep deriving from the first item.
{
    my $pod = IO::K8s::List->new(
        items => [ IO::K8s::Api::Core::V1::Pod->new ],
    );
    is( $pod->api_version, 'v1', 'api_version still derived from first item' );
    is( $pod->kind, 'PodList', 'kind still derived from first item' );
}

# ---------------------------------------------------------------------------
# k41: the item_class fallback in kind() derived the Kind from the last
# '::' segment and returned undef when the name had none, so an empty list of
# a single-segment CRD Kind serialised apiVersion but no kind: at all -- a
# manifest the API server rejects. That empty list is precisely what
# item_class exists for ("Used for empty lists where the type can't be
# inferred"), so the fallback failed in its only case. Same defect as k38,
# which fixed the equivalent derivation in IO::K8s::Role::APIObject and
# thereby the first-item path here.
# ---------------------------------------------------------------------------

{
    package Bauble;
    BEGIN { $INC{'Bauble.pm'} = __FILE__ }
    use IO::K8s::APIObject
        api_version     => 'vendor.example.com/v1',
        resource_plural => 'baubles';
    k8s spec => { Str => 1 };
}

# The fix: an EMPTY list with a single-segment item_class. There is no first
# item to ask, so kind() must fall back to item_class -- with no '::' the
# whole name is the last segment.
{
    my $list = IO::K8s::List->new( items => [], item_class => 'Bauble' );
    is( $list->kind, 'BaubleList',
        'empty list with single-segment item_class derives kind BaubleList' );
    is( $list->api_version, 'vendor.example.com/v1',
        'and still derives the item class api_version' );

    my $wire = $json->decode($list->to_json);
    is( $wire->{kind}, 'BaubleList',
        'empty list with single-segment item_class serialises kind: -- the field whose absence the API server rejects' );
    is( $wire->{apiVersion}, 'vendor.example.com/v1',
        'alongside its apiVersion' );
    is_deeply( $wire->{items}, [], 'and an empty items array' );
}

# The control: a NON-empty list of the same single-segment class goes through
# the first-item path, which k38 already fixed. Asserted here so a later
# rework of either path cannot silently drop the kind again.
{
    my $list = IO::K8s::List->new(
        items => [ Bauble->new( spec => { size => 'l' } ) ],
    );
    is( $list->kind, 'BaubleList',
        'non-empty list of a single-segment class derives kind from the first item' );

    my $wire = $json->decode($list->to_json);
    is( $wire->{kind}, 'BaubleList',
        'non-empty list of a single-segment class serialises kind:' );
    is( $wire->{apiVersion}, 'vendor.example.com/v1',
        'and the first item api_version' );
    is( $wire->{items}[0]{kind}, 'Bauble',
        'the item itself carries its own kind (k38)' );
}

# ---------------------------------------------------------------------------
# k49: item_class is accepted only as a FULLY QUALIFIED class name.
#
#   - A leading '+' is stripped, exactly like every other place in this
#     distribution that spells "this is already a full class name" (see
#     expand_class()'s '+FullClassName' handling in lib/IO/K8s.pm).
#   - A short or partially-qualified name (no leading IO::K8s::, no leading
#     '+') must NOT be guessed at: IO::K8s::List has no IO::K8s instance to
#     consult resource_map/expand_class through, so deriving a Kind from the
#     last '::' segment of e.g. 'Pod' produced a kind() ('PodList') that
#     api_version() could never confirm for the same item_class. That
#     half-answer is the bug: kind() must refuse to answer (undef, not the
#     guessed string) whenever api_version() for the SAME item_class is
#     unresolvable.
#
# On 4887f658 (pre-fix) this block is red for every row except the
# fully-qualified-no-'+' one, which was already correct and must stay so.
# ---------------------------------------------------------------------------

my @ITEM_CLASS_QUALIFICATION_CASES = (
    {
        item_class => 'Pod',
        exp_kind   => undef,
        exp_av     => undef,
        desc       => 'bare short name is not a class path -- fails closed, not PodList',
    },
    {
        item_class => 'Api::Core::V1::Pod',
        exp_kind   => undef,
        exp_av     => undef,
        desc       => 'partially-qualified name (missing IO::K8s::, no +) fails closed',
    },
    {
        item_class => 'IO::K8s::Api::Core::V1::Pod',
        exp_kind   => 'PodList',
        exp_av     => 'v1',
        desc       => 'fully-qualified, no leading + -- already correct, must stay correct',
    },
    {
        item_class => '+IO::K8s::Api::Core::V1::Pod',
        exp_kind   => 'PodList',
        exp_av     => 'v1',
        desc       => q{leading '+' is stripped and resolves exactly like the unprefixed name},
    },
);

for my $case (@ITEM_CLASS_QUALIFICATION_CASES) {
    my $list = IO::K8s::List->new( items => [], item_class => $case->{item_class} );

    is( $list->api_version, $case->{exp_av},
        "item_class '$case->{item_class}': $case->{desc} (api_version)" );
    is( $list->kind, $case->{exp_kind},
        "item_class '$case->{item_class}': $case->{desc} (kind)" );

    # The invariant this ticket establishes: kind() must never answer when
    # api_version() can't.
    if ( !defined $list->api_version ) {
        is( $list->kind, undef,
            "item_class '$case->{item_class}': api_version() undef => kind() must be undef too (never kind without apiVersion)" );
    }

    my $wire = $json->decode($list->to_json);
    is( ( exists $wire->{kind} ? 1 : 0 ), ( exists $wire->{apiVersion} ? 1 : 0 ),
        "item_class '$case->{item_class}': wire form carries kind and apiVersion together, or neither" );
}

# ---------------------------------------------------------------------------
# k46: IO::K8s::List could not inflate a List payload at all --
# $k8s->json_to_object() / struct_to_object() died with "Cannot resolve
# Kubernetes GVK: kind 'PodList', apiVersion 'v1'" because 'PodList' has no
# resource_map entry (the *List classes were removed in 1.105 in favour of
# this generic container) and inflate()'s dispatch never special-cased a
# List-shaped kind.
#
# Decided fix (option a): a real inflate. The item type is derived from the
# list's own KIND minus its 'List' suffix, combined with the list's own
# apiVersion (kind: PodList, apiVersion: v1 -> items are v1/Pod); item_class
# remains available as an explicit override for a Kind that yields nothing
# useful on its own (a generic 'kind: List' payload). An item GVK that still
# can't be resolved must fail closed -- an error, never a silent empty or
# half-inflated list (k39's fail-closed guarantee, reopened here for
# the List path specifically, must hold to the same standard).
# ---------------------------------------------------------------------------

my $k8s = IO::K8s->new;

# 1-3: a realistic two-item PodList round-trips end to end through the
# public one-arg entry points. Items carry no apiVersion/kind of their own
# in the wire payload -- exactly what a real Kubernetes API list response
# looks like.
{
    my $podlist_json = <<'END_JSON';
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": { "resourceVersion": "12345" },
  "items": [
    {
      "metadata": { "name": "pod-a", "namespace": "default", "labels": { "app": "a" } },
      "spec": {
        "containers": [ { "name": "c1", "image": "nginx:1.25" } ],
        "restartPolicy": "Always"
      },
      "status": { "phase": "Running", "podIP": "10.0.0.1" }
    },
    {
      "metadata": { "name": "pod-b", "namespace": "default", "labels": { "app": "b" } },
      "spec": {
        "containers": [ { "name": "c2", "image": "redis:7" } ],
        "restartPolicy": "Always"
      },
      "status": { "phase": "Pending" }
    }
  ]
}
END_JSON

    my $list;
    lives_ok { $list = $k8s->json_to_object($podlist_json) }
        q{json_to_object inflates a PodList payload without dying (currently dies: "Cannot resolve Kubernetes GVK: kind 'PodList', apiVersion 'v1'")};

    # Everything below depends on the inflate above having actually
    # succeeded -- guarded rather than chained, so a pre-fix die reports as
    # exactly one failing assertion instead of crashing the rest of this
    # test file (and the full-suite sweep) via a call on an undef $list.
    if ( defined $list ) {
        isa_ok( $list, 'IO::K8s::List', 'inflated PodList payload' );

        is( scalar @{ $list->items }, 2, 'both items are present' );
        isa_ok( $list->items->[0], 'IO::K8s::Api::Core::V1::Pod',
            'item 0 is a fully inflated Pod object, not a bare hash' );
        isa_ok( $list->items->[1], 'IO::K8s::Api::Core::V1::Pod',
            'item 1 is a fully inflated Pod object, not a bare hash' );
        is( $list->items->[0]->metadata->name, 'pod-a', 'item 0 metadata inflated' );
        is( $list->items->[0]->spec->containers->[0]->image, 'nginx:1.25', 'item 0 spec inflated' );
        is( $list->items->[0]->status->phase, 'Running', 'item 0 status inflated' );
        is( $list->items->[1]->metadata->name, 'pod-b', 'item 1 metadata inflated' );
        is( $list->items->[1]->status->phase, 'Pending', 'item 1 status inflated' );

        # Full structural round-trip, not a spot-check. Every Pod is also an
        # APIObject in its own right, so TO_JSON() on the fully-inflated
        # item stamps its own apiVersion/kind unconditionally (see
        # IO::K8s::Role::Resource::TO_JSON) even though the wire payload
        # above -- like a real API list response -- did not carry them per
        # item. $expected models that: same input, plus that per-item stamp.
        my $expected = $json->decode($podlist_json);
        for my $item ( @{ $expected->{items} } ) {
            $item->{apiVersion} = 'v1';
            $item->{kind}       = 'Pod';
        }
        cmp_deeply( $list->TO_JSON, $expected,
            'TO_JSON round-trips the full PodList: same top-level apiVersion/kind/metadata, same item data' );

        # struct_to_object($hashref) is the other documented one-arg entry
        # point and must behave identically.
        my $list2 = $k8s->struct_to_object( $json->decode($podlist_json) );
        isa_ok( $list2, 'IO::K8s::List', 'struct_to_object inflates the same payload' );
        cmp_deeply( $list2->TO_JSON, $expected, 'struct_to_object agrees with json_to_object' );
    }
}

# 4: an item Kind that cannot be resolved must fail closed -- never a
# silent empty or half-inflated list. Reuses the exact GVK error format
# every other entry point in this distribution dies with (k39), naming
# the ITEM's derived kind/apiVersion ('Gizmo'/'v1'), not the list's own
# ('GizmoList'/'v1') -- it is the item lookup that fails.
{
    my $bad_json = <<'END_JSON';
{
  "kind": "GizmoList",
  "apiVersion": "v1",
  "items": [ { "metadata": { "name": "g1" } } ]
}
END_JSON

    my $list;
    throws_ok { $list = $k8s->json_to_object($bad_json) }
        qr/Cannot resolve Kubernetes GVK: kind 'Gizmo', apiVersion 'v1'/,
        'an unresolvable item Kind dies with the GVK error, never a silent list';
    is( $list, undef, 'no partial/half-inflated object escapes the failed inflate' );
}

# 5: item_class as an explicit override -- the escape hatch for a Kind whose
# own name yields nothing to derive an item type from (a generic
# 'kind: List'). Mechanism assumed here, since List.pm ships no FROM_STRUCT
# yet to check this against: the override travels as a sibling key in the
# same struct that carries kind/apiVersion/items -- the same meaning
# item_class already has for the empty-list case above ("use this class,
# don't derive one"), just extended from serialisation to inflation.
{
    my $override_struct = {
        kind       => 'List',
        apiVersion => 'v1',
        item_class => 'IO::K8s::Api::Core::V1::Pod',
        items      => [
            { metadata => { name => 'override-pod' },
              spec     => { containers => [ { name => 'c1', image => 'nginx:1.25' } ] } },
        ],
    };

    my $list;
    lives_ok { $list = $k8s->struct_to_object($override_struct) }
        'struct_to_object inflates a generic kind:List payload using the item_class override';

    if ( defined $list ) {
        isa_ok( $list, 'IO::K8s::List', 'generic List with item_class override' );
        isa_ok( $list->items->[0], 'IO::K8s::Api::Core::V1::Pod',
            'item_class override drives inflation of items when the Kind itself has nothing to derive ("List" minus "List" is empty)' );
        is( $list->items->[0]->metadata->name, 'override-pod',
            'the overridden item class actually inflated the item data, not just typed it' );
    }
}

done_testing;
