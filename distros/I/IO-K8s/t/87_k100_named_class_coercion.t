#!/usr/bin/env perl
# k100: a direct Class->new(field => { ... }) coerces a plain hashref into
# the declared nested class, not only into an inline struct or a Bool.
#
# Before this, IO::K8s::Resource::_k8s installed a coerce for is_bool,
# is_array_of_bool and is_inline_struct only, so every is_object,
# is_array_of_objects and is_hash_of_objects field died with
# "Not a blessed reference" -- while $k8s->new_object, inflate and FROM_HASH
# built the very same hashref without complaint.
#
# The coercer routes through IO::K8s::Role::Resource::_default_k8s()
# ->_struct_to_object_expanded, the call FROM_HASH makes, so the two ways of
# building an object have to agree -- which is what most of the subtests
# below assert, in both directions: construct from a hashref, then check the
# wire structure TO_JSON emits.
#
# k115 finishes it for `metadata`, the one object-bearing field of a
# top-level Kind that _k8s does not create: IO::K8s::Role::APIObject
# composes first and declares it with a plain `has`, so _k8s's "don't
# overwrite a role's attribute" guard registers metadata without installing
# anything, and a coercer added in _k8s could never reach it. The role now
# declares it with IO::K8s::Resource::_object_coercer -- _k8s's own -- so
# the two cannot drift.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Moo ();
use IO::K8s;
use IO::K8s::AgentSandbox::V1alpha1::Sandbox;
use IO::K8s::Api::Apps::V1::Deployment;
use IO::K8s::Api::Core::V1::Container;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Api::Core::V1::PodSpec;
use IO::K8s::Api::Core::V1::PodTemplateSpec;
use IO::K8s::Api::Resource::V1::Device;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
use IO::K8s::Traefik::V1alpha1::Middleware;

# A CRD written the documented way, to check that a class which gets its
# identity from import parameters rather than from its name is served by the
# same role attribute.
{
    package Test::K115::StaticWebSite;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'staticwebsites';
    k8s spec => { Str => 1 };
}

subtest 'is_object: the ticket case, a bundled Traefik Middleware' => sub {
    my $mw = IO::K8s::Traefik::V1alpha1::Middleware->new(
        spec => { rateLimit => { average => 100, burst => 50 } },
    );
    isa_ok($mw->spec, 'IO::K8s::Traefik::V1alpha1::MiddlewareSpec', 'spec');
    isa_ok($mw->spec->rateLimit, 'IO::K8s::Traefik::V1alpha1::RateLimit',
        'nested named class one level deeper');
    is($mw->spec->rateLimit->average, 100, 'average survived the coercion');

    # The direction that actually reaches Kubernetes.
    is_deeply($mw->TO_JSON, {
        apiVersion => 'traefik.io/v1alpha1',
        kind       => 'Middleware',
        spec       => { rateLimit => { average => 100, burst => 50 } },
    }, 'TO_JSON emits the manifest, ints unquoted');
};

subtest 'is_array_of_objects: hashrefs become elements' => sub {
    my $spec = IO::K8s::Api::Core::V1::PodSpec->new(
        containers => [
            { name => 'app', image => 'nginx',
              ports => [ { containerPort => 8443, protocol => 'TCP' } ] },
            { name => 'sidecar', image => 'envoy' },
        ],
    );
    isa_ok($spec->containers->[0], 'IO::K8s::Api::Core::V1::Container', 'element 0');
    isa_ok($spec->containers->[1], 'IO::K8s::Api::Core::V1::Container', 'element 1');
    isa_ok($spec->containers->[0]->ports->[0],
        'IO::K8s::Api::Core::V1::ContainerPort', 'array nested inside the element');

    is_deeply($spec->TO_JSON, {
        containers => [
            { name => 'app', image => 'nginx',
              ports => [ { containerPort => 8443, protocol => 'TCP' } ] },
            { name => 'sidecar', image => 'envoy' },
        ],
    }, 'TO_JSON round-trips the array');
};

subtest 'is_hash_of_objects: hashref values become objects' => sub {
    my $dev = IO::K8s::Api::Resource::V1::Device->new(
        name       => 'gpu-0',
        attributes => {
            model   => { string => 'A100' },
            healthy => { bool   => 'true' },
        },
    );
    isa_ok($dev->attributes->{model},
        'IO::K8s::Api::Resource::V1::DeviceAttribute', 'value under "model"');

    is_deeply($dev->TO_JSON, {
        name       => 'gpu-0',
        attributes => {
            model   => { string => 'A100' },
            healthy => { bool   => JSON::MaybeXS::true() },
        },
    }, 'TO_JSON keeps the map and emits a real JSON boolean');
};

subtest 'bool normalization runs inside a named struct' => sub {
    # Every spelling a caller can reach for, on a Bool field two named
    # classes deep. The claim is that the new path normalizes exactly like
    # the inflate path, so \1 / 'true' / 1 are indistinguishable on the wire.
    for my $true (\1, 'true', 1) {
        for my $false (\0, 'false', 0) {
            my $spec = IO::K8s::Api::Core::V1::PodSpec->new(
                containers => [ {
                    name => 'app', image => 'nginx',
                    securityContext => {
                        readOnlyRootFilesystem   => $true,
                        allowPrivilegeEscalation => $false,
                    },
                } ],
            );
            my $sc = $spec->TO_JSON->{containers}[0]{securityContext};
            is_deeply($sc, {
                readOnlyRootFilesystem   => JSON::MaybeXS::true(),
                allowPrivilegeEscalation => JSON::MaybeXS::false(),
            }, 'normalized to real JSON booleans');
        }
    }
};

subtest 'D1: an unknown field takes the same route as FROM_HASH' => sub {
    my $struct = {
        apiVersion => 'apps/v1', kind => 'Deployment',
        spec => {
            replicas => 2,
            selector => { matchLabels => { app => 'x' } },
            template => {
                spec => {
                    containers => [ { name => 'app', image => 'nginx',
                                      futureField => 'from a newer upstream' } ],
                },
            },
            futureSpecField => { nested => 'kept too' },
        },
    };

    my $via_new = IO::K8s::Api::Apps::V1::Deployment->new(%$struct);
    my $via_hash = IO::K8s::Api::Apps::V1::Deployment->FROM_HASH($struct);

    # The actual claim of the k100 design decision: one build path, so the
    # two cannot drift. Compared on the wire, not on accessors.
    is_deeply($via_new->TO_JSON, $via_hash->TO_JSON,
        '->new and FROM_HASH agree on the whole document');
    is($via_new->TO_JSON->{spec}{template}{spec}{containers}[0]{futureField},
        'from a newer upstream', 'unknown field inside an array element re-emitted');
    is_deeply($via_new->TO_JSON->{spec}{futureSpecField}, { nested => 'kept too' },
        'unknown field on a named nested class re-emitted');

    # And with strict on, both refuse in the same place.
    local $IO::K8s::Resource::STRICT = 1;
    throws_ok { IO::K8s::Api::Apps::V1::Deployment->new(%$struct) }
        qr/Unknown field 'futureField' for IO::K8s::Api::Core::V1::Container/,
        '->new under strict dies naming class and field';
    throws_ok { IO::K8s::Api::Apps::V1::Deployment->FROM_HASH($struct) }
        qr/Unknown field 'futureField' for IO::K8s::Api::Core::V1::Container/,
        'FROM_HASH under strict dies the same way';
};

subtest 'already built objects are passed through, not rebuilt' => sub {
    # This is what keeps IO::K8s::_inflate_struct from paying for the
    # coercion twice: it hands $class->new fully built objects.
    my $ctr  = IO::K8s::Api::Core::V1::Container->new(name => 'app', image => 'nginx');
    my $list = [ $ctr ];
    my $spec = IO::K8s::Api::Core::V1::PodSpec->new(containers => $list);
    is($spec->containers, $list, 'the arrayref itself is not copied');
    is($spec->containers->[0], $ctr, 'the element is the same object');

    my $dev_attr = IO::K8s::Api::Resource::V1::DeviceAttribute->new(string => 'A100');
    my $map = { model => $dev_attr };
    my $dev = IO::K8s::Api::Resource::V1::Device->new(name => 'g', attributes => $map);
    is($dev->attributes, $map, 'the hashref itself is not copied');
    is($dev->attributes->{model}, $dev_attr, 'the value is the same object');

    # And the coercer really is the one doing nothing here: count the calls
    # it would have to make.
    my $calls = 0;
    my $orig  = \&IO::K8s::_struct_to_object_expanded;
    {
        no warnings 'redefine';
        local *IO::K8s::_struct_to_object_expanded = sub {
            $calls++ if (caller(0))[0] eq 'IO::K8s::Resource';
            goto &$orig;
        };
        IO::K8s->new->inflate({
            apiVersion => 'v1', kind => 'Pod',
            metadata => { name => 'p' },
            spec => { containers => [ { name => 'app', image => 'nginx' } ] },
        });
        is($calls, 0, 'inflate never re-enters the coercer');

        IO::K8s::Api::Core::V1::PodSpec->new(
            containers => [ { name => 'app', image => 'nginx' } ]);
        is($calls, 1, 'a direct ->new with a hashref does');
    }
};

subtest 'a value that is neither hashref nor object is left to isa' => sub {
    # A coercer must not invent a type error of its own; the message has to
    # stay the type constraint's.
    throws_ok { IO::K8s::Api::Core::V1::PodSpec->new(containers => ['nope']) }
        qr/did not pass type constraint/, 'array of scalars still fails on isa';
    throws_ok { IO::K8s::Api::Core::V1::Container->new(
            name => 'c', securityContext => 'nope') }
        qr/did not pass type constraint/, 'scalar for an object field fails on isa';
};

subtest 'a bad value names the element index or the map key' => sub {
    throws_ok {
        IO::K8s::Api::Core::V1::PodSpec->new(containers => [
            { name => 'ok', image => 'nginx' },
            { name => 'bad', image => 'nginx', stdin => \\1 },
        ]);
    } qr/at element 1/, 'array element index is in the message';

    throws_ok {
        IO::K8s::Api::Resource::V1::Device->new(
            name => 'g', attributes => { broken => { bool => \\1 } });
    } qr/at key 'broken'/, 'map key is in the message';
};

subtest 'the rw setter coerces too' => sub {
    my $mw = IO::K8s::Traefik::V1alpha1::Middleware->new;
    $mw->spec({ rateLimit => { average => 7 } });
    isa_ok($mw->spec, 'IO::K8s::Traefik::V1alpha1::MiddlewareSpec', 'set spec');
    is($mw->TO_JSON->{spec}{rateLimit}{average}, 7, 'and reaches the wire');
};

subtest 'inline structs still coerce (branch left in place)' => sub {
    my $sb = IO::K8s::AgentSandbox::V1alpha1::Sandbox->new(
        spec => { replicas => 1, service => 'true',
                  podTemplate => { spec => { containers => [] } } },
    );
    like(ref $sb->spec, qr/::Sandbox::_Spec$/, 'inline struct class');
    is_deeply($sb->TO_JSON->{spec}, {
        replicas    => 1,
        service     => JSON::MaybeXS::true(),
        podTemplate => { spec => { containers => [] } },
    }, 'and serializes, bool included');
};

subtest 'k115: metadata on a real bundled Kind coerces' => sub {
    # Pod is the case the ticket is about: metadata is supplied by
    # IO::K8s::Role::APIObject, outside the schema properties, and
    # IO::K8s::APIObject::import only *registers* it via the k8s DSL. It is
    # also the form practically every caller writes.
    my $pod = IO::K8s::Api::Core::V1::Pod->new(
        metadata => { name => 'web', namespace => 'prod',
                      labels => { app => 'web' } },
        spec     => { containers => [ { name => 'c', image => 'nginx' } ] },
    );
    isa_ok($pod->metadata,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta', 'metadata');
    is($pod->metadata->name, 'web', 'name survived');

    is_deeply($pod->TO_JSON, {
        apiVersion => 'v1',
        kind       => 'Pod',
        metadata   => { name => 'web', namespace => 'prod',
                        labels => { app => 'web' } },
        spec       => { containers => [ { name => 'c', image => 'nginx' } ] },
    }, 'TO_JSON emits the whole manifest');

    # The role helpers keep working on a metadata that arrived as a hashref.
    $pod->add_label(tier => 'frontend');
    is($pod->TO_JSON->{metadata}{labels}{tier}, 'frontend',
        'add_label still writes into the coerced ObjectMeta');
};

subtest 'k115: the role-supplied metadata and a declared one agree' => sub {
    # PodTemplateSpec declares `k8s metadata => Meta::V1::ObjectMeta` itself
    # and is NOT an APIObject, so its metadata attribute is the one _k8s
    # creates -- the k100 path. Pod's is the role's -- the k115 path. Same
    # input has to give the same wire output, which is the whole point of
    # both using IO::K8s::Resource::_object_coercer.
    my $meta_in = { name => 'x', annotations => { 'a/b' => 'c' } };

    my $tpl = IO::K8s::Api::Core::V1::PodTemplateSpec->new(metadata => $meta_in);
    my $pod = IO::K8s::Api::Core::V1::Pod->new(metadata => $meta_in);

    isa_ok($tpl->metadata,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta', '_k8s-created');
    isa_ok($pod->metadata,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta', 'role-supplied');
    is_deeply($tpl->TO_JSON->{metadata}, $pod->TO_JSON->{metadata},
        'both routes produce the same metadata on the wire');

    # One coercion, shared: every APIObject class carries the very coderef
    # the role installed, not a per-class copy that could drift.
    my $pod_spec = Moo->_constructor_maker_for('IO::K8s::Api::Core::V1::Pod')
        ->all_attribute_specs->{metadata};
    my $dep_spec = Moo->_constructor_maker_for('IO::K8s::Api::Apps::V1::Deployment')
        ->all_attribute_specs->{metadata};
    ok($pod_spec->{coerce}, 'metadata carries a coercion');
    is($pod_spec->{coerce}, $dep_spec->{coerce},
        'and it is one shared coderef across every APIObject class');
};

subtest 'k115: ->new and FROM_HASH agree on metadata, D1 included' => sub {
    my $struct = {
        apiVersion => 'v1', kind => 'Pod',
        metadata   => { name => 'web', namespace => 'prod',
                        futureMetaField => 'from a newer upstream' },
        spec       => { containers => [ { name => 'c', image => 'nginx' } ] },
    };

    my $via_new  = IO::K8s::Api::Core::V1::Pod->new(%$struct);
    my $via_hash = IO::K8s::Api::Core::V1::Pod->FROM_HASH($struct);

    is_deeply($via_new->TO_JSON, $via_hash->TO_JSON,
        '->new and FROM_HASH agree on the whole document');
    is($via_new->TO_JSON->{metadata}{futureMetaField}, 'from a newer upstream',
        'an unknown field inside metadata is kept and re-emitted');

    local $IO::K8s::Resource::STRICT = 1;
    throws_ok { IO::K8s::Api::Core::V1::Pod->new(%$struct) }
        qr/Unknown field 'futureMetaField' for IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta/,
        '->new under strict dies inside ObjectMeta';
    throws_ok { IO::K8s::Api::Core::V1::Pod->FROM_HASH($struct) }
        qr/Unknown field 'futureMetaField' for IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta/,
        'FROM_HASH under strict dies the same way';
};

subtest 'k115: metadata pass-through, setter and non-hashref' => sub {
    my $meta = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'x');
    my $pod  = IO::K8s::Api::Core::V1::Pod->new(metadata => $meta);
    is($pod->metadata, $meta, 'an ObjectMeta is passed through, not rebuilt');

    $pod->metadata({ name => 'y', namespace => 'ns' });
    isa_ok($pod->metadata,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta', 'setter result');
    is($pod->TO_JSON->{metadata}{name}, 'y', 'and reaches the wire');

    throws_ok { IO::K8s::Api::Core::V1::Pod->new(metadata => 'nope') }
        qr/did not pass type constraint/,
        'a scalar is still left to the type constraint';
};

subtest 'k115: a CRD class gets it from the same role' => sub {
    my $site = Test::K115::StaticWebSite->new(
        metadata => { name => 'blog', namespace => 'web' },
        spec     => { domain => 'example.com' },
    );
    isa_ok($site->metadata,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta', 'CRD metadata');
    is_deeply($site->TO_JSON, {
        apiVersion => 'homelab.example.com/v1',
        kind       => 'StaticWebSite',
        metadata   => { name => 'blog', namespace => 'web' },
        spec       => { domain => 'example.com' },
    }, 'CRD manifest on the wire');
};

done_testing;
