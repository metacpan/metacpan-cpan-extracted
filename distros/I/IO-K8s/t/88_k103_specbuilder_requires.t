#!/usr/bin/env perl
# k103: the builder roles declare their dependency on
# IO::K8s::Role::SpecBuilder, and IO::K8s::Role::APIObject composes that role
# for every top-level Kind rather than only for CRD classes.
#
# The claim under test is *where* the coupling surfaces. Before k103,
# composing CertManaged/Routable/NetworkPolicy/... onto a class without
# SpecBuilder succeeded and then died at the first setter call with
# "Can't locate object method spec_push". It now fails at composition time,
# naming the missing method -- which is only a correct thing to require
# because every APIObject has the methods.
#
# The three things that can break that arrangement, and are asserted below:
#   1. a builder role composed without SpecBuilder must fail *at `with`*
#   2. every shipped top-level Kind must actually carry the spec_* surface
#   3. the Kinds with no `spec` field at all -- ConfigMap, Secret, the RBAC
#      kinds -- carry the methods too and must say so intelligibly
# plus the regression the change most endangers: the two *core* Kinds that
# compose a builder role (networking/v1 Ingress via Routable, networking/v1
# NetworkPolicy via NetworkPolicy) still serialize in both directions.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny ();

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::Api::Networking::V1::Ingress;
use IO::K8s::Api::Networking::V1::NetworkPolicy;
use IO::K8s::Api::Core::V1::ConfigMap;
use IO::K8s::Api::Rbac::V1::Role;

# role => [ the spec_* methods it declares, the format hook it needs,
#           a method it installs ]
my %ROLE = (
    CertManaged          => { needs => [qw( spec_push spec_set )],
                              hook  => '',                          has => 'for_domains' },
    HelmManaged          => { needs => [qw( spec_hash spec_set )],
                              hook  => '',                          has => 'from_repo' },
    MiddlewareBuilder    => { needs => [qw( spec_hash spec_set )],
                              hook  => '',                          has => 'rate_limit' },
    MiddlewareTCPBuilder => { needs => [qw( spec_set )],
                              hook  => '',                          has => 'in_flight_conn' },
    Loadbalanced         => { needs => [qw( spec_array spec_get spec_push spec_set )],
                              hook  => '',                          has => 'set_weighted' },
    Routable             => { needs => [qw( spec_get spec_push spec_set )],
                              hook  => "sub _route_format { 'gateway' }",
                                                                    has => 'add_hostname' },
    NetworkPolicy        => { needs => [qw( spec_push spec_set )],
                              hook  => "sub _netpol_format { 'cilium' }",
                                                                    has => 'select_pods' },
);

subtest 'a builder role refuses a consumer that has no SpecBuilder' => sub {
    my $n = 0;
    for my $role (sort keys %ROLE) {
        my $info = $ROLE{$role};
        my $pkg  = 'T88::NoSB::' . $role;

        # A plain Moo class with a spec attribute and the role's own format
        # hook: everything the role asks for *except* the spec_* methods.
        eval "package $pkg;
              use Moo;
              has spec => ( is => 'rw' );
              $info->{hook};
              with 'IO::K8s::Role::$role';
              1";
        my $err = $@;

        ok($err, "$role: composition fails");
        like($err, qr/\QCan't apply IO::K8s::Role::$role to $pkg\E/,
            "$role: the failure names the role and the consumer");
        like($err, qr/missing \Q@{[ join ', ', @{$info->{needs}} ]}\E/,
            "$role: it names every spec_* method the role uses");

        # Composition-time, not call-time. Before k103 the `with` above
        # succeeded and the class only broke later, at the first setter
        # call, with 'Can't locate object method "spec_push"'. That shape
        # of failure must not be what comes back any more -- and because
        # the die happens inside `with`, the package never finishes
        # loading, so there is no half-built class to call into.
        unlike($err, qr/\QCan't locate object method\E/,
            "$role: not the old call-time failure");
        $n++;
    }
    is($n, 7, 'all seven builder roles checked');
};

subtest 'the same consumer composes once SpecBuilder is there' => sub {
    for my $role (sort keys %ROLE) {
        my $info = $ROLE{$role};
        my $pkg  = 'T88::WithSB::' . $role;
        eval "package $pkg;
              use Moo;
              has spec => ( is => 'rw' );
              $info->{hook};
              with 'IO::K8s::Role::SpecBuilder', 'IO::K8s::Role::$role';
              1";
        is($@, '', "$role: composes with SpecBuilder in front");
        ok($pkg->can($info->{has}), "$role: $info->{has} installed");
    }
};

subtest 'every top-level Kind carries the spec_* surface' => sub {
    # The design decision k103 rests on: SpecBuilder on *every* APIObject,
    # not only on CRD classes. A representative Kind per shipped namespace,
    # plus the two synthetic routes into IO::K8s::Role::APIObject.
    my @kinds = qw(
        IO::K8s::Api::Core::V1::Pod
        IO::K8s::Api::Core::V1::Service
        IO::K8s::Api::Apps::V1::Deployment
        IO::K8s::Api::Batch::V1::CronJob
        IO::K8s::Api::Networking::V1::Ingress
        IO::K8s::Api::Networking::V1::NetworkPolicy
        IO::K8s::Api::Rbac::V1::Role
        IO::K8s::Api::Storage::V1::StorageClass
        IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition
        IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService
        IO::K8s::Cilium::V2::CiliumNetworkPolicy
        IO::K8s::GatewayAPI::V1::HTTPRoute
        IO::K8s::Traefik::V1alpha1::Middleware
        IO::K8s::CertManager::V1::Certificate
        IO::K8s::K3s::V1::HelmChart
    );

    for my $class (@kinds) {
        eval "require $class; 1" or die $@;
        ok(Role::Tiny::does_role($class, 'IO::K8s::Role::SpecBuilder'),
            "$class does SpecBuilder");
        ok($class->can($_), "$class can $_")
            for qw( spec_get spec_set spec_array spec_hash
                    spec_push spec_merge spec_delete );
    }

    # A built-in-shaped class declared through the base class with no
    # api_version parameter -- the branch that used to skip SpecBuilder.
    {
        package T88::PlainKind;
        use IO::K8s::APIObject;
        k8s spec => { Str => 1 };
    }
    ok(Role::Tiny::does_role('T88::PlainKind', 'IO::K8s::Role::SpecBuilder'),
        'a non-CRD use IO::K8s::APIObject class does SpecBuilder');
    is(T88::PlainKind->new->spec_set('a', 'b')->spec_get('a'), 'b',
        'and its spec_* methods work');

    # AutoGen composes IO::K8s::Role::APIObject directly rather than going
    # through the base class import, so it is the other route in -- and the
    # one that used to miss out entirely, since the CRD branch that added
    # SpecBuilder lived in that import.
    ok(Role::Tiny::does_role('IO::K8s::Role::APIObject', 'IO::K8s::Role::SpecBuilder'),
        'the role itself composes SpecBuilder, which is what covers both routes');

    IO::K8s::AutoGen::clear_cache();
    my $gen = IO::K8s::AutoGen::get_or_generate(
        'com.example.t88.v1.Widget',
        {   type => 'object',
            'x-kubernetes-group-version-kind' =>
                [ { group => 't88.example.com', version => 'v1', kind => 'Widget' } ],
            properties => {
                apiVersion => { type => 'string' },
                kind       => { type => 'string' },
                spec       => { type => 'object',
                                properties => { domain => { type => 'string' } } },
            },
        },
        {},
        'IO::K8s::_AUTOGEN_t88',
    );
    ok(Role::Tiny::does_role($gen, 'IO::K8s::Role::SpecBuilder'),
        'an AutoGen-built class does SpecBuilder');
    is($gen->new->spec_set('domain', 'x.example.com')->spec_get('domain'),
        'x.example.com', 'and its spec_* methods reach the generated spec class');
};

subtest 'a Kind with no spec field says so, at the caller' => sub {
    # 32 shipped Kinds carry data/rules/subjects and no spec at all. They
    # have the methods now; what matters is that they fail intelligibly
    # rather than on a missing accessor deep inside SpecBuilder.
    for my $class (qw( IO::K8s::Api::Core::V1::ConfigMap
                       IO::K8s::Api::Rbac::V1::Role )) {
        ok(!$class->can('spec'), "$class really has no spec field");
        my $obj = $class->new;

        for my $call ( [ spec_get    => 'a.b'     ],
                       [ spec_set    => 'a.b', 1  ],
                       [ spec_array  => 'a'       ],
                       [ spec_hash   => 'a'       ],
                       [ spec_push   => 'a', 1    ],
                       [ spec_merge  => a => 1    ],
                       [ spec_delete => 'a'       ] ) {
            my ($method, @args) = @$call;
            throws_ok { $obj->$method(@args) }
                qr/\Q$class has no spec field\E/,
                "$class->$method croaks naming the class";
            unlike($@, qr/SpecBuilder\.pm line \d+/,
                "$class->$method leaks no internal file/line");
        }
    }
};

# --- the regression the composition change most endangers -----------------
# Both core Kinds keep working through their builder role, in both
# directions: built in Perl -> canonical JSON, and that JSON inflated back
# to an object that emits the identical structure.

subtest 'core NetworkPolicy still builds and round-trips' => sub {
    my $np = IO::K8s::Api::Networking::V1::NetworkPolicy->new(
        metadata => { name => 'web', namespace => 'prod' },
    );
    is($np->_netpol_format, 'core', 'the core branch is the one under test');

    $np->select_pods(app => 'web');
    $np->allow_ingress_from_pods({ app => 'gateway' }, ports => [ { port => 8080 } ]);
    $np->allow_egress_to_cidrs(['10.0.0.0/8']);

    my $expected = {
        apiVersion => 'networking.k8s.io/v1',
        kind       => 'NetworkPolicy',
        metadata   => { name => 'web', namespace => 'prod' },
        spec       => {
            podSelector => { matchLabels => { app => 'web' } },
            policyTypes => [ 'Ingress', 'Egress' ],
            ingress     => [ {
                from  => [ { podSelector => { matchLabels => { app => 'gateway' } } } ],
                ports => [ { port => 8080, protocol => 'TCP' } ],
            } ],
            egress      => [ {
                to => [ { ipBlock => { cidr => '10.0.0.0/8' } } ],
            } ],
        },
    };
    is_deeply($np->TO_JSON, $expected, 'Perl -> canonical JSON');

    # The typed intermediates really are objects, not the hashrefs the role
    # was handed -- an accessor-only assertion would not have caught that.
    isa_ok($np->spec, 'IO::K8s::Api::Networking::V1::NetworkPolicySpec');
    isa_ok($np->spec->podSelector,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($np->spec->ingress->[0],
        'IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule');

    my $back = IO::K8s->new->struct_to_object(
        'IO::K8s::Api::Networking::V1::NetworkPolicy', $expected);
    isa_ok($back, 'IO::K8s::Api::Networking::V1::NetworkPolicy');
    is_deeply($back->TO_JSON, $expected, 'canonical JSON -> Perl -> identical JSON');
};

subtest 'core Ingress still builds and round-trips' => sub {
    # add_hostname + add_backend only: add_path_match has no ingress mode
    # -- an HTTPIngressPath needs a backend this method cannot supply, so
    # it croaks by design (k117). t/17 covers that refusal.
    my $ing = IO::K8s::Api::Networking::V1::Ingress->new(
        metadata => { name => 'web', namespace => 'prod' },
    );
    is($ing->_route_format, 'ingress', 'the ingress branch is the one under test');

    $ing->add_hostname('example.com', 'api.example.com');
    $ing->add_backend('api', port => 8080);
    $ing->add_header_match('X-Env', 'production');   # documented no-op here

    my $expected = {
        apiVersion => 'networking.k8s.io/v1',
        kind       => 'Ingress',
        metadata   => { name => 'web', namespace => 'prod' },
        spec       => {
            defaultBackend => {
                service => { name => 'api', port => { number => 8080 } },
            },
            rules => [
                { host => 'example.com' },
                { host => 'api.example.com' },
            ],
        },
    };
    is_deeply($ing->TO_JSON, $expected, 'Perl -> canonical JSON');

    isa_ok($ing->spec, 'IO::K8s::Api::Networking::V1::IngressSpec');
    isa_ok($ing->spec->rules->[0], 'IO::K8s::Api::Networking::V1::IngressRule');

    my $back = IO::K8s->new->struct_to_object(
        'IO::K8s::Api::Networking::V1::Ingress', $expected);
    isa_ok($back, 'IO::K8s::Api::Networking::V1::Ingress');
    is_deeply($back->TO_JSON, $expected, 'canonical JSON -> Perl -> identical JSON');
};

done_testing;
