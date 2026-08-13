#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use YAML::PP;
use lib 'lib';
use IO::K8s;

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot open $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $content;
}

my $json = JSON::MaybeXS->new;
my $fixture = $json->decode(slurp('t/data/spec-kinds.json'));
my $short_name_compat = $json->decode(slurp('t/data/short-name-compat.json'));
my ($exceptions) = YAML::PP::Load(slurp('maint/spec-drift-exceptions.yaml'));
my $io = IO::K8s->new;

{
    package Test::SpecKindDispatch::First::DuplicateKind;
    use IO::K8s::APIObject
        api_version     => 'duplicate.example.com/v1',
        resource_plural => 'duplicatekinds';
    1;
}

{
    package Test::SpecKindDispatch::Second::DuplicateKind;
    use IO::K8s::APIObject
        api_version     => 'duplicate.example.com/v1',
        resource_plural => 'duplicatekinds';
    1;
}

{
    package Test::SpecKindDispatch::FirstProvider;
    use Moo;
    with 'IO::K8s::Role::ResourceMap';

    sub resource_map {
        return {
            DuplicateKind => '+Test::SpecKindDispatch::First::DuplicateKind',
        };
    }
    1;
}

{
    package Test::SpecKindDispatch::SecondProvider;
    use Moo;
    with 'IO::K8s::Role::ResourceMap';

    sub resource_map {
        return {
            DuplicateKind => '+Test::SpecKindDispatch::Second::DuplicateKind',
        };
    }
    1;
}

package main;

subtest 'fixture provenance and count' => sub {
    is($fixture->{generated_from}, 'v1.36.3',
        'fixture identifies the pinned Kubernetes release');
    is(scalar @{ $fixture->{entries} }, 311,
        'fixture contains every expected GVK entry');
    is($fixture->{gvk_total_in_spec}, 311,
        'fixture records the complete source GVK count');
    is($fixture->{source_sha256},
        'dcede2063da1d7ad62ecb5af8adb6d7fabd0b52385a7fa0048afb491dac90450',
        'fixture pins the exact source snapshot digest');
};

# Keep this conversion independent from IO::K8s's resource map. It is copied
# from maint/spec-drift-check.pl, which maps upstream definition identities to
# the checked-in Perl namespace convention.
sub seg_to_perl {
    my ($seg) = @_;
    return join '', map { ucfirst $_ } grep { length } split /-/, $seg;
}

sub defkey_to_perl_class {
    my ($key) = @_;
    return undef unless $key =~ /^io\.k8s\./;
    my $rest      = substr($key, length('io.k8s.'));
    my @parts     = split /\./, $rest;
    my $kind_part = pop @parts;
    my @path      = map { seg_to_perl($_) } @parts;
    return join('::', 'IO::K8s', @path, $kind_part);
}

subtest 'hyphenated upstream namespaces use the independent contractions' => sub {
    is(defkey_to_perl_class(
            'io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinition'),
        'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
        'apiextensions-apiserver contracts to ApiextensionsApiserver');
    is(defkey_to_perl_class(
            'io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIService'),
        'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService',
        'kube-aggregator contracts to KubeAggregator');
};

my @non_dispatchable = @{ $exceptions->{non_dispatchable_kinds} // [] };
my %non_dispatchable_by_key = map { $_->{key} => $_ } @non_dispatchable;
my %fixture_def_keys = map { $_->{def_key} => 1 } @{ $fixture->{entries} };
my %used_exception;
my %dispatchable_by_kind;
my ($accounted, $generic_lists, $exception_entries, $dispatchable_entries) = (0, 0, 0, 0);

subtest 'every official dispatchable GVK resolves to its independently derived class' => sub {
    for my $entry (@{ $fixture->{entries} }) {
        $accounted++;

        if ($entry->{list_kind}) {
            $generic_lists++;
            next;
        }

        if ($non_dispatchable_by_key{ $entry->{def_key} }) {
            $exception_entries++;
            $used_exception{ $entry->{def_key} }++;
            next;
        }

        $dispatchable_entries++;
        my $kind        = $entry->{kind};
        my $api_version = $entry->{api_version};
        my $gvk         = "$api_version/$kind";
        my $expected    = defkey_to_perl_class($entry->{def_key});

        push @{ $dispatchable_by_kind{$kind} }, {
            api_version => $api_version,
            class       => $expected,
        };

        is($io->expand_class($gvk), $expected,
            "$gvk qualified dispatch resolves to $expected");
        is($io->expand_class($kind, $api_version), $expected,
            "$gvk split dispatch resolves to $expected");

        my $loaded = eval { $io->load_class($expected); 1 };
        ok($loaded, "$gvk expected class $expected loads")
            or diag($@);

        if (defined $entry->{namespaced}) {
            my $actual = $loaded && $expected->DOES('IO::K8s::Role::Namespaced') ? 1 : 0;
            is($actual, $entry->{namespaced} ? 1 : 0,
                "$gvk namespaced role matches the upstream path scope");
        }
    }

    is($accounted, 311, 'all 311 fixture entries are accounted for');
    is($generic_lists, 88, '88 dropped generic List GVK entries are skipped structurally');
    is($exception_entries, 125,
        '125 non-addressable shared/discovery GVK entries are skipped by exact definition key');
    is($dispatchable_entries, 98, '98 addressable GVK entries are checked exhaustively');
    is($generic_lists + $exception_entries + $dispatchable_entries, $accounted,
        'every entry belongs to exactly one accounting category');
};

subtest 'non-dispatchable exceptions are justified, present, and used' => sub {
    is(scalar @non_dispatchable, 7,
        'the maintained non-dispatchable exception set has seven entries');

    for my $exception (@non_dispatchable) {
        my $key = $exception->{key} // '<missing key>';
        ok(defined($exception->{reason}) && length($exception->{reason}),
            "$key has a reason");
        ok($fixture_def_keys{$key}, "$key exists in the GVK fixture");
        ok($used_exception{$key}, "$key was used while accounting fixture entries");
    }
};

my @expected_collision_kinds = qw(
    ClusterTrustBundle
    DeviceClass
    DeviceTaintRule
    Event
    HorizontalPodAutoscaler
    IPAddress
    LeaseCandidate
    MutatingAdmissionPolicy
    MutatingAdmissionPolicyBinding
    ResourceClaim
    ResourceClaimTemplate
    ResourceSlice
    ServiceCIDR
    VolumeAttributesClass
);

subtest 'all fourteen multi-version collision Kinds are explicit and loadable' => sub {
    my @collision_kinds = sort grep {
        my %versions = map { $_->{api_version} => 1 } @{ $dispatchable_by_kind{$_} };
        my %classes  = map { $_->{class}       => 1 } @{ $dispatchable_by_kind{$_} };
        keys(%versions) > 1 && keys(%classes) > 1;
    } keys %dispatchable_by_kind;

    is(scalar @collision_kinds, 14, 'exactly fourteen Kinds have multiple official class versions');
    is_deeply(\@collision_kinds, \@expected_collision_kinds,
        'the complete multi-version collision Kind set is named');

    for my $kind (@collision_kinds) {
        my %seen_class;
        for my $candidate (sort { $a->{api_version} cmp $b->{api_version} }
                @{ $dispatchable_by_kind{$kind} }) {
            next if $seen_class{ $candidate->{class} }++;
            my $loaded = eval { $io->load_class($candidate->{class}); 1 };
            ok($loaded,
                "$kind $candidate->{api_version} collision class $candidate->{class} loads")
                or diag($@);
        }
    }
};

subtest 'bare Kind compatibility map is pinned exactly' => sub {
    my $default_map = IO::K8s->default_resource_map;
    my %bare_map = map { $_ => $default_map->{$_} }
        grep { index($_, '/') < 0 } keys %$default_map;

    is(scalar(keys %$short_name_compat), 78,
        'compatibility snapshot contains all 78 approved bare aliases');
    is(scalar(keys %bare_map), 78,
        'live default map contains exactly 78 bare aliases');
    is_deeply(\%bare_map, $short_name_compat,
        'every live bare alias and target exactly matches the compatibility snapshot');
};

subtest 'representative real objects cover every multi-version collision Kind' => sub {
    my @cases = (
        {
            api_version => 'certificates.k8s.io/v1beta1',
            kind        => 'ClusterTrustBundle',
            class       => 'IO::K8s::Api::Certificates::V1beta1::ClusterTrustBundle',
            body        => {
                metadata => { name => 'example.com:foo:v1' },
                spec     => {
                    signerName => 'example.com/foo',
                    trustBundle => "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n",
                },
            },
        },
        {
            api_version => 'resource.k8s.io/v1beta1',
            kind        => 'DeviceClass',
            class       => 'IO::K8s::Api::Resource::V1beta1::DeviceClass',
            body        => {
                metadata => { name => 'gpu.example.com' },
                spec     => {
                    selectors => [
                        { cel => { expression => q{device.driver == "gpu.example.com"} } },
                    ],
                },
            },
        },
        {
            api_version => 'resource.k8s.io/v1beta2',
            kind        => 'DeviceTaintRule',
            class       => 'IO::K8s::Api::Resource::V1beta2::DeviceTaintRule',
            body        => {
                metadata => { name => 'gpu-taint' },
                spec     => {
                    deviceSelector => { cel => { expression => q{true} } },
                    taint => {
                        key => 'example.com/gpu', value => 'true', effect => 'NoSchedule',
                    },
                },
            },
        },
        {
            # The plan's Events v1 example plus the schema-required eventTime.
            api_version => 'events.k8s.io/v1',
            kind        => 'Event',
            class       => 'IO::K8s::Api::Events::V1::Event',
            body        => {
                metadata => { name => 'event' },
                eventTime => '2026-08-10T12:00:00Z',
            },
        },
        {
            api_version => 'autoscaling/v1',
            kind        => 'HorizontalPodAutoscaler',
            class       => 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
            body        => {
                metadata => { name => 'hpa' },
                spec     => {
                    maxReplicas => 2,
                    minReplicas => 1,
                    scaleTargetRef => {
                        apiVersion => 'apps/v1', kind => 'Deployment', name => 'app',
                    },
                    targetCPUUtilizationPercentage => 70,
                },
            },
        },
        {
            api_version => 'networking.k8s.io/v1',
            kind        => 'IPAddress',
            class       => 'IO::K8s::Api::Networking::V1::IPAddress',
            body        => {
                metadata => { name => '192.0.2.10' },
                spec     => {
                    parentRef => {
                        group => '', resource => 'services', name => 'web', namespace => 'default',
                    },
                },
            },
        },
        {
            api_version => 'coordination.k8s.io/v1alpha2',
            kind        => 'LeaseCandidate',
            class       => 'IO::K8s::Api::Coordination::V1alpha2::LeaseCandidate',
            body        => {
                metadata => { name => 'candidate-1', namespace => 'kube-system' },
                spec     => {
                    binaryVersion => '1.36.0',
                    leaseName     => 'my-controller',
                    strategy      => 'OldestEmulationVersion',
                },
            },
        },
        {
            api_version => 'admissionregistration.k8s.io/v1',
            kind        => 'MutatingAdmissionPolicy',
            class       => 'IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicy',
            body        => {
                metadata => { name => 'my-policy' },
                spec     => {
                    failurePolicy     => 'Fail',
                    reinvocationPolicy => 'Never',
                    matchConstraints => {
                        resourceRules => [
                            {
                                apiGroups => [''], apiVersions => ['v1'],
                                resources => ['pods'], operations => ['CREATE'],
                            },
                        ],
                    },
                    mutations => [
                        {
                            patchType => 'ApplyConfiguration',
                            applyConfiguration => { expression => 'Object{}' },
                        },
                    ],
                },
            },
        },
        {
            api_version => 'admissionregistration.k8s.io/v1',
            kind        => 'MutatingAdmissionPolicyBinding',
            class       => 'IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicyBinding',
            body        => {
                metadata => { name => 'my-binding' },
                spec     => { policyName => 'my-policy' },
            },
        },
        {
            api_version => 'resource.k8s.io/v1beta1',
            kind        => 'ResourceClaim',
            class       => 'IO::K8s::Api::Resource::V1beta1::ResourceClaim',
            body        => {
                metadata => { name => 'my-claim', namespace => 'default' },
                spec     => {
                    devices => {
                        requests => [
                            { name => 'req-1', deviceClassName => 'gpu.example.com' },
                        ],
                    },
                },
            },
        },
        {
            api_version => 'resource.k8s.io/v1beta1',
            kind        => 'ResourceClaimTemplate',
            class       => 'IO::K8s::Api::Resource::V1beta1::ResourceClaimTemplate',
            body        => {
                metadata => { name => 'my-template', namespace => 'default' },
                spec     => {
                    metadata => { labels => { app => 'demo' } },
                    spec     => {
                        devices => {
                            requests => [
                                { name => 'req-1', deviceClassName => 'gpu.example.com' },
                            ],
                        },
                    },
                },
            },
        },
        {
            api_version => 'resource.k8s.io/v1beta1',
            kind        => 'ResourceSlice',
            class       => 'IO::K8s::Api::Resource::V1beta1::ResourceSlice',
            body        => {
                metadata => { name => 'gpu-pool-1' },
                spec     => {
                    allNodes => JSON::MaybeXS::true(),
                    devices  => [],
                    driver   => 'gpu.example.com',
                    pool     => {
                        generation => 1, name => 'gpu-pool', resourceSliceCount => 1,
                    },
                },
            },
        },
        {
            api_version => 'networking.k8s.io/v1',
            kind        => 'ServiceCIDR',
            class       => 'IO::K8s::Api::Networking::V1::ServiceCIDR',
            body        => {
                metadata => { name => 'primary' },
                spec     => { cidrs => ['10.96.0.0/16'] },
            },
        },
        {
            api_version => 'storage.k8s.io/v1',
            kind        => 'VolumeAttributesClass',
            class       => 'IO::K8s::Api::Storage::V1::VolumeAttributesClass',
            body        => {
                metadata   => { name => 'fast' },
                driverName => 'csi.example.com',
                parameters => { tier => 'fast' },
            },
        },
    );

    my %constructed_kind;
    for my $case (@cases) {
        my $gvk = "$case->{api_version}/$case->{kind}";
        my $obj = eval {
            $io->inflate({
                apiVersion => $case->{api_version},
                kind       => $case->{kind},
                %{ $case->{body} },
            });
        };
        is($@, '', "$gvk valid literal inflates without error") or next;
        isa_ok($obj, $case->{class}, "$gvk inflates as its exact class");

        my $wire = $io->object_to_struct($obj);
        is($wire->{apiVersion}, $case->{api_version}, "$gvk serializes its exact apiVersion");
        is($wire->{kind}, $case->{kind}, "$gvk serializes its exact kind");
        $constructed_kind{ $case->{kind} } = 1;
    }

    is_deeply([sort keys %constructed_kind], \@expected_collision_kinds,
        'every multi-version collision Kind has valid real construction data');
};

subtest 'bare Event and HPA retain their pinned compatibility classes' => sub {
    my $event = $io->new_object('Event', {
        metadata        => { name => 'legacy-event' },
        involvedObject  => { kind => 'Pod', name => 'pod-1', namespace => 'default' },
    });
    isa_ok($event, 'IO::K8s::Api::Core::V1::Event',
        'bare Event remains the Core v1 compatibility class');

    my $hpa = $io->new_object('HorizontalPodAutoscaler', {
        metadata => { name => 'legacy-hpa' },
        spec     => {
            maxReplicas => 10,
            minReplicas => 2,
            scaleTargetRef => {
                apiVersion => 'apps/v1', kind => 'Deployment', name => 'web',
            },
            metrics => [
                {
                    type     => 'Resource',
                    resource => {
                        name   => 'cpu',
                        target => { type => 'Utilization', averageUtilization => 70 },
                    },
                },
            ],
        },
    });
    isa_ok($hpa, 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler',
        'bare HPA remains the Autoscaling v2 compatibility class');

    my $pod = $io->new_object('Pod', metadata => { name => 'core-pod' });
    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod',
        'representative core new_object construction remains available');
};

subtest 'duplicate provider GVK registration remains deterministic first-wins' => sub {
    my $provider_io = IO::K8s->new;
    $provider_io->add(
        Test::SpecKindDispatch::FirstProvider->new,
        Test::SpecKindDispatch::SecondProvider->new,
    );

    my $first  = 'Test::SpecKindDispatch::First::DuplicateKind';
    my $second = 'Test::SpecKindDispatch::Second::DuplicateKind';

    is($provider_io->expand_class('DuplicateKind'), $first,
        'first provider keeps the bare short alias');
    is($provider_io->expand_class('duplicate.example.com/v1/DuplicateKind'), $first,
        'first provider keeps the exact qualified GVK');
    is($provider_io->expand_class('DuplicateKind', 'duplicate.example.com/v1'), $first,
        'first provider keeps the exact split GVK');

    is($provider_io->expand_class("+$second"), $second,
        'later duplicate remains reachable through +Full::Class');
    my $later = $provider_io->new_object("+$second", {
        metadata => { name => 'later-provider-object' },
    });
    isa_ok($later, $second,
        'explicit +Full::Class constructs the later provider class');
};

subtest 'explicit invalid Pod GVKs fail closed without bare fallback' => sub {
    my @invalid_api_versions = (
        'example.invalid/v9',
        'apps/v1',
        'apps//v1',
        '',
    );

    for my $api_version (@invalid_api_versions) {
        my $display = length($api_version) ? $api_version : '<empty>';

        is($io->expand_class("$api_version/Pod"), undef,
            "qualified $display/Pod does not fall back to the bare Pod alias");
        is($io->expand_class('Pod', $api_version), undef,
            "split Pod + $display does not fall back to the bare Pod alias");

        my $inflate_error = '';
        eval {
            $io->inflate({
                apiVersion => $api_version,
                kind       => 'Pod',
                metadata   => { name => 'bad' },
            });
            1;
        } or $inflate_error = $@;
        like($inflate_error,
            qr/(?=.*\bPod\b)(?=.*\Q$display\E)/s,
            "inflate rejects Pod + $display and names the exact requested GVK");

        my $new_object_error = '';
        eval {
            $io->new_object('Pod', { metadata => { name => 'bad' } }, $api_version);
            1;
        } or $new_object_error = $@;
        like($new_object_error,
            qr/(?=.*\bPod\b)(?=.*\Q$display\E)/s,
            "new_object rejects Pod + $display and names the exact requested GVK");

        my $qualified_new_object_error = '';
        eval {
            $io->new_object("$api_version/Pod", {
                metadata => { name => 'bad' },
            });
            1;
        } or $qualified_new_object_error = $@;
        like($qualified_new_object_error,
            qr/(?=.*\bPod\b)(?=.*\Q$display\E)/s,
            "qualified new_object rejects $display/Pod with the requested GVK");
    }

    is($io->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'omitted apiVersion still resolves through the pinned bare Pod alias');
    my $bare_pod = $io->inflate({ kind => 'Pod', metadata => { name => 'good' } });
    isa_ok($bare_pod, 'IO::K8s::Api::Core::V1::Pod',
        'inflate with omitted apiVersion still uses the pinned bare Pod class');
};

done_testing;
