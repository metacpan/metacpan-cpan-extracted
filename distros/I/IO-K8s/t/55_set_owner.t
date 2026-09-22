#!/usr/bin/env perl
# k47: set_owner() built an ownerReference the API server rejects, on
# four counts, all measured on 4887f658:
#
#   1. uid => $owner->metadata->uid // '' -- a locally built owner never has
#      a uid (the server assigns it), so the common "build both objects,
#      link them, apply" path produced uid:"", which the cluster refuses.
#   2. controller => 1, hardcoded -- a second set_owner() call produced a
#      second controller:true reference; Kubernetes allows at most one.
#   3. no duplicate check -- the same owner twice produced two identical
#      entries.
#   4. a missing-metadata owner died with a bare "Can't call method "name"
#      on an undefined value at ... line 887", naming neither method nor
#      argument.
#
# This file pins the fixed contract:
#   * no uid (absent or empty metadata, or no metadata at all) -- die,
#     naming the owner, never write ''
#   * controller is a parameter (default 1); a second controller:true dies
#     naming the existing controller reference
#   * the duplicate check runs BEFORE the controller check, so re-adding the
#     same owner (by uid) is an idempotent no-op even when the repeated call
#     also asks for controller => 1 against the very reference that already
#     holds it
#   * controller => 0 omits the controller key from TO_JSON entirely (never
#     writes a literal false)
#   * blockOwnerDeletion is never set
#
# Every assertion is on TO_JSON / to_json output, not just the accessor --
# that is the direction that actually reaches the cluster. Pure local
# fixtures; no network, no cluster.
#
# The existing lives_ok in t/54_single_segment_kind.t (k38's claim,
# that a single-segment owner's kind is not undef) is untouched by this file
# and must keep passing on its own.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS;

use IO::K8s;

my $k8s = IO::K8s->new;
my $json_codec = JSON::MaybeXS->new(utf8 => 0, canonical => 1);

sub json_bool_name { $_[0] ? 'true' : 'false' }

sub make_pod {
    return $k8s->struct_to_object('Pod', { metadata => { name => 'p' } });
}

# A owner as it would come back from the cluster: has a uid.
# apps/v1 {Deployment,ReplicaSet,StatefulSet}.spec became required in v1.37
# (karr k72); these owners only exercise ownerReference behaviour, so a
# minimal valid spec is enough to construct them.
my $dep = $k8s->struct_to_object('Deployment', {
    metadata => { name => 'web', uid => 'dep-uid-1' },
    spec     => { selector => {}, template => {} },
});
my $rs = $k8s->struct_to_object('ReplicaSet', {
    metadata => { name => 'rs-1', uid => 'rs-uid-1' },
    spec     => { selector => {} },
});
my $ss = $k8s->struct_to_object('StatefulSet', {
    metadata => { name => 'ss-1', uid => 'ss-uid-1' },
    spec     => { selector => {}, serviceName => 'ss-svc', template => {} },
});

# ----------------------------------------------------------------------------
# 1 & 6: happy path -- the emitted ownerReferences entry, and the return
# value for chaining.
# ----------------------------------------------------------------------------

subtest 'happy path: exact ownerReferences structure on the wire, $self returned' => sub {
    my $pod = make_pod();

    my $ret = $pod->set_owner($dep);
    is($ret, $pod, 'set_owner returns $self for chaining');

    my $wire = $pod->TO_JSON;
    my $refs = $wire->{metadata}{ownerReferences};
    is(ref $refs, 'ARRAY', 'ownerReferences is an array');
    is(scalar(@$refs), 1, 'exactly one entry');

    my $ref = { %{ $refs->[0] } };
    my $controller = delete $ref->{controller};

    is_deeply($ref, {
        apiVersion => 'apps/v1',
        kind       => 'Deployment',
        name       => 'web',
        uid        => 'dep-uid-1',
    }, 'apiVersion/kind/name/uid are exactly right, and blockOwnerDeletion is absent');

    ok($controller, 'controller key is present and true');
    is(json_bool_name($controller), 'true', 'controller is a real JSON boolean true');

    # The direction that actually reaches the cluster: the encoded bytes.
    like($pod->to_json,
        qr/"ownerReferences":\[\{"apiVersion":"apps\/v1","controller":true,"kind":"Deployment","name":"web","uid":"dep-uid-1"\}\]/,
        'to_json carries the exact wire bytes, controller as an unquoted true, no blockOwnerDeletion');
};

# ----------------------------------------------------------------------------
# 2: controller => 0 omits the key entirely, never writes false.
# ----------------------------------------------------------------------------

subtest 'controller => 0 omits the controller key (not a literal false)' => sub {
    my $pod = make_pod();
    $pod->set_owner($dep, controller => 0);

    my $ref = $pod->TO_JSON->{metadata}{ownerReferences}[0];
    is($ref->{apiVersion}, 'apps/v1', 'apiVersion still correct');
    is($ref->{kind},       'Deployment', 'kind still correct');
    is($ref->{name},       'web', 'name still correct');
    is($ref->{uid},        'dep-uid-1', 'uid still correct');
    ok(!exists $ref->{controller}, 'controller key is absent, not present-and-false');

    unlike($pod->to_json, qr/"controller"/, 'the encoded JSON has no controller key at all');
};

# ----------------------------------------------------------------------------
# 3: two different owners -- first controller, second non-controlling --
# then a THIRD, distinct owner asking for controller => 1 dies. (Re-asking
# controller => 1 on the *second* owner itself would not exercise this path:
# it is already referenced by uid, so the duplicate check in subtest 4 below
# wins first and it is a no-op, not a die -- that ordering is the point of
# subtest 4. A controller conflict only fires for an owner not yet
# referenced at all.)
# ----------------------------------------------------------------------------

subtest 'two different owners: one controller, one not; a third owner as controller dies' => sub {
    my $pod = make_pod();
    $pod->set_owner($dep, controller => 1);
    $pod->set_owner($rs,  controller => 0);

    my $refs = $pod->TO_JSON->{metadata}{ownerReferences};
    is(scalar(@$refs), 2, 'two distinct owners produce two entries');

    my ($dep_ref) = grep { $_->{uid} eq 'dep-uid-1' } @$refs;
    my ($rs_ref)  = grep { $_->{uid} eq 'rs-uid-1' } @$refs;
    ok($dep_ref->{controller}, 'the Deployment entry is the controller');
    ok(!exists $rs_ref->{controller}, 'the ReplicaSet entry is not');

    throws_ok { $pod->set_owner($ss, controller => 1) }
        qr{\Qset_owner: cannot add StatefulSet/ss-1 as controller: Deployment/web is already the controller reference; Kubernetes allows at most one, pass controller => 0 to add a non-controlling owner\E},
        'a not-yet-referenced owner asking to become controller dies naming both itself and the existing controller';

    my $after = $pod->TO_JSON->{metadata}{ownerReferences};
    is(scalar(@$after), 2, 'the rejected owner was not appended: still exactly two entries');
};

# ----------------------------------------------------------------------------
# 4 & 7: duplicate (same uid) is an idempotent no-op, even against controller
# => 1 repeated on the reference that already holds it -- the duplicate check
# runs before the controller check. is_owned_by() as a roundtrip guard on the
# read side.
# ----------------------------------------------------------------------------

subtest 'duplicate owner (same uid) is an idempotent no-op, checked before the controller conflict' => sub {
    my $pod = make_pod();

    lives_ok { $pod->set_owner($dep, controller => 1) } 'first set_owner call';
    my $before = $pod->TO_JSON->{metadata}{ownerReferences};
    is(scalar(@$before), 1, 'one entry after the first call');

    # Same owner (same uid) again, still asking for controller => 1, against
    # the very reference that is already the controller: this must be a
    # no-op, not the "already the controller reference" die.
    lives_ok { $pod->set_owner($dep, controller => 1) }
        'setting the same owner again (still controller => 1) does not die';

    my $after = $pod->TO_JSON->{metadata}{ownerReferences};
    is(scalar(@$after), 1, 'still exactly one entry -- no duplicate appended');
    is_deeply($after, $before, 'the existing reference is left byte-for-byte untouched by the duplicate call');

    ok($pod->is_owned_by($dep), 'is_owned_by() agrees the pod is owned by the Deployment');
};

# ----------------------------------------------------------------------------
# 5: missing uid / missing metadata entirely -- die, naming the owner.
# ----------------------------------------------------------------------------

subtest 'owner with no uid, or no metadata at all: dies naming the owner' => sub {
    my $owner_no_uid = $k8s->struct_to_object('Deployment', {
        metadata => { name => 'web' },
        spec     => { selector => {}, template => {} },
    });
    throws_ok { make_pod()->set_owner($owner_no_uid) }
        qr{\Qset_owner: cannot reference Deployment/web: owner has no uid; the uid is assigned by the API server, so only an object read back from the cluster can be referenced\E},
        'metadata present but uid absent: dies naming Kind/name';

    my $owner_no_metadata = $k8s->struct_to_object('Deployment', {
        spec => { selector => {}, template => {} },
    });
    throws_ok { make_pod()->set_owner($owner_no_metadata) }
        qr{\Qset_owner: cannot reference Deployment: owner has no uid; the uid is assigned by the API server, so only an object read back from the cluster can be referenced\E},
        'no metadata at all: dies naming just the Kind, no /name';
};

# ----------------------------------------------------------------------------
# 8: inflation roundtrip -- an object with ownerReferences already set,
# inflated from a literal manifest via struct_to_object, and serialized back
# via TO_JSON, is structurally identical in both directions.
# ----------------------------------------------------------------------------

subtest 'ownerReferences survive struct_to_object -> TO_JSON unchanged' => sub {
    my $manifest = {
        apiVersion => 'v1',
        kind       => 'Pod',
        metadata   => {
            name            => 'p',
            ownerReferences => [
                {
                    apiVersion => 'apps/v1',
                    kind       => 'Deployment',
                    name       => 'web',
                    uid        => 'dep-uid-1',
                    controller => JSON::MaybeXS::true,
                },
                {
                    apiVersion => 'apps/v1',
                    kind       => 'ReplicaSet',
                    name       => 'rs-1',
                    uid        => 'rs-uid-1',
                },
            ],
        },
    };

    my $obj = $k8s->struct_to_object($manifest);
    isa_ok($obj, 'IO::K8s::Api::Core::V1::Pod');

    is($json_codec->encode($obj->TO_JSON), $json_codec->encode($manifest),
        'TO_JSON of the inflated object canonically encodes identically to the input manifest '
      . '(the controller boolean and the absence of blockOwnerDeletion both survive)');
};

done_testing;
