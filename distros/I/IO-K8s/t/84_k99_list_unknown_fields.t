#!/usr/bin/env perl
# k99: IO::K8s::List used a hand-rolled items/metadata/TO_JSON/FROM_STRUCT
# and never composed IO::K8s::Role::Resource, so the D1 _unknown_fields bag
# never applied to the list ENVELOPE (items already round-trip correctly,
# each through its own class's composition of the role). Two holes:
#
#   1. an unknown top-level key on a *List document (anything besides
#      apiVersion, kind, metadata, items, item_class) was silently dropped
#      on inflate -> TO_JSON, instead of preserved like every other
#      resource's undeclared fields (D1).
#   2. strict => 1 had the same hole: a bogus top-level key on a list
#      document was dropped instead of dying.
#
# Fix: List now composes IO::K8s::Role::Resource (reusing its exact
# _unknown_fields bag + BUILD strict mechanism) while keeping its
# own hand-rolled TO_JSON/FROM_STRUCT/to_json/from_json, since kind/api_version
# derive from the items rather than from a class name the role could use.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s;
use IO::K8s::List;

my $k8s = IO::K8s->new;

subtest 'unknown top-level key on a *List document round-trips (D1 for the envelope)' => sub {
    my $list = $k8s->inflate({
        apiVersion => 'v1',
        kind       => 'PodList',
        bogusList  => 1,
        metadata   => { resourceVersion => '1' },
        items      => [
            { metadata => { name => 'p' } },
        ],
    });
    isa_ok($list, 'IO::K8s::List');
    is_deeply($list->_unknown_fields, { bogusList => 1 }, 'the bag holds exactly the unknown top-level key');

    my $out = $list->TO_JSON;
    is($out->{bogusList}, 1, 'unknown top-level key survives inflate -> TO_JSON unchanged');
    is($out->{apiVersion}, 'v1', 'apiVersion still derived');
    is($out->{kind}, 'PodList', 'kind still derived');
    is(scalar @{$out->{items}}, 1, 'items still inflate and round-trip');
    is($out->{items}[0]{metadata}{name}, 'p', 'item content untouched');
    is($out->{metadata}{resourceVersion}, '1', 'declared metadata untouched');
};

subtest 'a declared top-level key is never shadowed by the bag' => sub {
    # kind/apiVersion/metadata/items/item_class are the envelope's own known
    # keys -- none of them should ever land in _unknown_fields.
    my $list = $k8s->inflate({
        apiVersion => 'v1',
        kind       => 'PodList',
        items      => [],
    });
    is_deeply($list->_unknown_fields, {}, 'no known key lands in the bag');
};

subtest 'strict => 1 dies on an unknown top-level List key, naming the envelope class' => sub {
    my $strict = IO::K8s->new(strict => 1);
    throws_ok {
        $strict->inflate({
            apiVersion => 'v1',
            kind       => 'PodList',
            bogusList  => 1,
            items      => [],
        });
    } qr/^Unknown field 'bogusList' for IO::K8s::List$/m,
        'strict inflate dies naming IO::K8s::List and the bad field';

    is($IO::K8s::Resource::STRICT, 0, 'the flag is restored after the strict call');

    lives_ok {
        $strict->inflate({ apiVersion => 'v1', kind => 'PodList', items => [] });
    } 'a List document with no unknown keys still lives under strict';
};

subtest 'a non-strict instance in the same process still preserves' => sub {
    my $lax = $k8s->inflate({ apiVersion => 'v1', kind => 'PodList', bogusList => 1, items => [] });
    is($lax->TO_JSON->{bogusList}, 1, 'preserved, not stricken, without strict => 1');
};

subtest 'the unknown field also survives a full JSON round-trip (to_json/from_json)' => sub {
    my $list = IO::K8s::List->FROM_STRUCT({
        apiVersion => 'v1',
        kind       => 'PodList',
        bogusList  => { nested => [ 1, 2 ] },
        items      => [],
    });
    my $again = IO::K8s::List->from_json($list->to_json);
    is_deeply($again->TO_JSON->{bogusList}, { nested => [ 1, 2 ] },
        'unknown top-level field survives a full serialize/parse cycle');
};

done_testing;
