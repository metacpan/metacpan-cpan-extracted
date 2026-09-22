#!/usr/bin/env perl
# k38: IO::K8s::Role::APIObject::kind() derived the Kind from the last
# '::' segment of the class name and returned undef when the name had none. A
# CRD registered as a single-segment top-level package -- reached as '+Doodad',
# or through a resource_map value of '+Doodad' -- therefore serialized a
# manifest with no 'kind:' field at all, which the API server rejects.
#
# A single-segment class is a supported shape here, not an accident: '+Name' is
# documented in lib/IO/K8s.pm as THE route to a single-segment class of your
# own, '+Name' is a supported resource_map value, and k35 is what made
# those names reliably reachable (they used to be re-expanded away). Making the
# class reachable and then letting it emit a manifest the cluster refuses is
# the same silent misbehaviour k35/k37/k39 removed. The bare name is the
# consistent derivation: kind() takes the last '::' segment, and without a '::'
# the whole name is that segment.
#
# What these tests claim:
#   * the serialized struct, JSON and YAML of a single-segment CRD carry a
#     kind: -- that is the failure that reaches the cluster, and a test that
#     only reads the kind() accessor cannot fail on it
#   * every route to such a class ('+Name', a resource_map '+Name' value)
#     produces a manifest with a kind:, and that manifest inflates back to the
#     same class
#   * ownerReferences, the role's other consumer of kind(), name the owner
#   * multi-segment names are unchanged: still the last segment
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";

use IO::K8s;

# ----------------------------------------------------------------------------
# Test-local classes. Seeded into %INC so IO::K8s::load_class treats them as
# loaded -- a single-segment CRD class is never loaded by expand_class(), which
# returns a '+' name verbatim.
# ----------------------------------------------------------------------------

{
    package Doodad;
    BEGIN { $INC{'Doodad.pm'} = __FILE__ }
    use IO::K8s::APIObject
        api_version     => 'vendor.example.com/v1',
        resource_plural => 'doodads';
    k8s spec => { Str => 1 };
}

# The same CRD named in full. Its Kind is the last segment, not the whole
# name: the fallback must not change what a multi-segment class answers.
{
    package My::Doodad;
    BEGIN { $INC{'My/Doodad.pm'} = __FILE__ }
    use IO::K8s::APIObject
        api_version     => 'vendor.example.com/v1',
        resource_plural => 'doodads';
    k8s spec => { Str => 1 };
}

# ----------------------------------------------------------------------------

subtest 'kind() of a single-segment class is the bare class name' => sub {
    is(Doodad->kind, 'Doodad', 'as a class method');
    is(Doodad->new(spec => { size => 'l' })->kind, 'Doodad', 'as an instance method');

    is(My::Doodad->kind, 'Doodad', 'a multi-segment class still answers its last segment');

    # The neighbouring derivations are unaffected: both come from the import
    # parameters, which are installed before the role is composed.
    is(Doodad->api_version, 'vendor.example.com/v1', 'api_version still from the import');
    is(Doodad->resource_plural, 'doodads', 'resource_plural still from the import');
};

subtest "a '+Single' CRD serializes a manifest with a kind:" => sub {
    my $k8s = IO::K8s->new;

    my $obj = $k8s->new_object('+Doodad', { spec => { size => 'l' } });
    isa_ok($obj, 'Doodad', "new_object('+Doodad')");

    # THE BUG: the object was reachable, but TO_JSON dropped kind entirely
    # (IO::K8s::Role::Resource::TO_JSON only sets it `if $self->kind`), so the
    # manifest was one `kubectl apply -f` refuses.
    my $wire = $k8s->object_to_struct($obj);
    is($wire->{kind}, 'Doodad', 'the struct carries kind:');
    is($wire->{apiVersion}, 'vendor.example.com/v1', 'alongside its apiVersion');
    is($wire->{spec}{size}, 'l', 'and the spec payload');

    like($k8s->object_to_json($obj), qr/"kind"\s*:\s*"Doodad"/,
        'object_to_json emits kind');
    like($obj->to_yaml, qr/^kind:\s*['"]?Doodad['"]?\s*$/m,
        'to_yaml emits kind:, which is what kubectl apply reads');
};

subtest "a resource_map '+Single' value serializes, and round-trips" => sub {
    my $k8s = IO::K8s->new(resource_map => {
        %{ IO::K8s->default_resource_map },
        Doodad => '+Doodad',
    });

    my $obj = $k8s->new_object('Doodad', { spec => { size => 'xl' } });
    isa_ok($obj, 'Doodad', "new_object through a '+Single' map value");

    my $wire = $k8s->object_to_struct($obj);
    is($wire->{kind}, 'Doodad', 'the mapped route emits kind: too');

    # And the consequence of the missing field, in the direction that proves
    # it was a real manifest: without a kind: there is nothing to dispatch on,
    # so the emitted document could not even be read back.
    my $back;
    lives_ok { $back = $k8s->inflate($wire) } 'the emitted manifest inflates';
    isa_ok($back, 'Doodad', 'inflate() of our own output');
    is($back->spec->{size}, 'xl', 'and it survived the round trip')
        if ref($back) eq 'Doodad';
};

subtest 'ownerReferences name a single-segment owner' => sub {
    my $k8s = IO::K8s->new;

    my $owner = $k8s->new_object('+Doodad', {
        metadata => { name => 'demo', uid => 'uid-1' },
        spec     => { size => 'l' },
    });
    my $pod = $k8s->new_object('Pod', { metadata => { name => 'demo-pod' } });

    # set_owner() feeds $owner->kind into OwnerReference's required kind.
    lives_ok { $pod->set_owner($owner) } 'set_owner() with a single-segment owner';

    my $wire = $k8s->object_to_struct($pod);
    is($wire->{metadata}{ownerReferences}[0]{kind}, 'Doodad',
        'the ownerReference names the owner Kind');
    is($wire->{metadata}{ownerReferences}[0]{apiVersion}, 'vendor.example.com/v1',
        'and its apiVersion');
    ok($pod->is_owned_by($owner), 'is_owned_by() agrees');
};

done_testing;
