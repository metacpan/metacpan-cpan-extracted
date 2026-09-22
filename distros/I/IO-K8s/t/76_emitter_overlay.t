#!/usr/bin/env perl
# A2 (step 4): the emitter learns provider-friendly output --
#
#  * short provider class names: a class under a known %_class_prefix entry
#    (exposed as IO::K8s::Resource::class_prefixes) renders the short way a
#    hand-written class would ('Traefik::V1alpha1::X', 'Meta::V1::X',
#    'Core::V1::X'); anything else still renders '+Full::Class::Name'.
#  * an emitter `overlay` (the per-Kind slice of a provider's
#    maint/crd-render/<Provider>.yaml -- this task only wires the emitter's
#    consumption of that hashref, not the YAML files themselves) supplies,
#    for the root Kind: the `with` roles line, verbatim `extra` lines right
#    after it, and a `names` map keyed by the LOGICAL class path
#    (IO::K8s::AutoGen::class_path's own return value, e.g. 'Spec',
#    'Spec::Limit') rather than the generated class's own Perl name.
use strict;
use warnings;
use Test::More;
use FindBin;

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;
use IO::K8s::Resource;

my ($crd) = @{ IO::K8s::CRD->load("$FindBin::Bin/data/crd-knob.yaml") };
my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_AUTOGEN_ov76');
my $root = $classes->{'opts.example.com/v1'};

my $emitter = IO::K8s::CRD::Emitter->new(
    base    => 'TestOv::V1',
    overlay => {
        with  => [ 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::SpecBuilder' ],
        extra => [ "sub _format { 'x' }" ],
        names => { 'Spec' => 'KnobSpec', 'Spec::Limit' => 'RateLimit' },
    },
);
my $files = $emitter->render($root);

subtest 'names: the overlay names map is keyed by logical path, not generated class name' => sub {
    is_deeply([ sort keys %$files ], [
        'TestOv/V1/Knob.pm',
        'TestOv/V1/KnobSpec.pm',
        'TestOv/V1/KnobSpecRoutesItem.pm',
        'TestOv/V1/KnobStatus.pm',
        'TestOv/V1/RateLimit.pm',
    ], 'root, nested (default-named), and the two overlay-named classes');
};

subtest 'with: the overlay roles render on one with line, in order, extra lines right after' => sub {
    my $src = $files->{'TestOv/V1/Knob.pm'};
    like($src,
        qr/^with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::SpecBuilder';\nsub _format \{ 'x' \}$/m,
        'with line (both roles, in order) immediately followed by the verbatim extra line');
};

subtest 'nested class references honour the overlay names map' => sub {
    my $spec_src = $files->{'TestOv/V1/KnobSpec.pm'};
    like($spec_src, qr/^k8s limit\s+=> '\+TestOv::V1::RateLimit';$/m,
        'limit refers to the overlay-named RateLimit package');
};

subtest 'known-prefix classes render short (Meta::V1) instead of +Full' => sub {
    # A schema whose spec.selector is shaped exactly like
    # Meta::V1::LabelSelector -- with reuse_core on (the default), AutoGen
    # types the field as that shipped class directly rather than a nested
    # one, so this exercises _class_ref's known-prefix path independent of
    # any names/overlay machinery.
    my $schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' =>
            [ { group => 'ov76.example.com', version => 'v1', kind => 'Selectable' } ],
        properties => {
            apiVersion => { type => 'string' }, kind => { type => 'string' }, metadata => { type => 'object' },
            spec => {
                type => 'object',
                properties => {
                    selector => {
                        type => 'object',
                        properties => {
                            matchLabels      => { type => 'object', additionalProperties => { type => 'string' } },
                            matchExpressions => {
                                type  => 'array',
                                items => {
                                    type => 'object',
                                    properties => {
                                        key      => { type => 'string' },
                                        operator => { type => 'string' },
                                        values   => { type => 'array', items => { type => 'string' } },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    };
    my $sel_root = IO::K8s::AutoGen::get_or_generate(
        'com.example.ov76.v1.Selectable', $schema, {}, 'IO::K8s::_AUTOGEN_ov76sel',
        api_version => 'ov76.example.com/v1', kind => 'Selectable',
        resource_plural => 'selectables', is_namespaced => 1,
    );
    my $sel_emitter = IO::K8s::CRD::Emitter->new(base => 'TestOvShort::V1');
    my $sel_files = $sel_emitter->render($sel_root);
    my $spec_src = $sel_files->{'TestOvShort/V1/SelectableSpec.pm'};
    ok(defined $spec_src, 'spec class rendered') or diag join("\n", sort keys %$sel_files);
    like($spec_src, qr/^k8s selector\s+=> 'Meta::V1::LabelSelector';$/m,
        'a reused core class under a known prefix renders short, not +Full');

    for my $path (sort keys %$sel_files) {
        ok(eval "$sel_files->{$path}\n1;", "compiles: $path") or diag "$path:\n" . $sel_files->{$path} . "\n$@";
    }
};

subtest 'the new provider prefixes are registered and do not shadow anything' => sub {
    my $prefixes = IO::K8s::Resource::class_prefixes();
    my %expected = (
        Cilium             => 'IO::K8s::Cilium',
        Traefik            => 'IO::K8s::Traefik',
        CertManager        => 'IO::K8s::CertManager',
        GatewayAPI         => 'IO::K8s::GatewayAPI',
        K3s                => 'IO::K8s::K3s',
        AgentSandbox       => 'IO::K8s::AgentSandbox',
        PrometheusOperator => 'IO::K8s::PrometheusOperator',
        VolumeSnapshot     => 'IO::K8s::VolumeSnapshot',
        ExternalSecrets    => 'IO::K8s::ExternalSecrets',
    );
    for my $prefix (sort keys %expected) {
        is($prefixes->{$prefix}, $expected{$prefix}, "class_prefixes has $prefix => $expected{$prefix}");
    }

    # The forward direction (_expand_class, the k8s DSL): a fresh throwaway
    # package declaring a field with the short provider form must record the
    # full IO::K8s::<Provider>::... class in the registry -- the same
    # observation technique t/35_expand_class.t uses.
    my $pkg = 'IO::K8s::Test::Ov76::CiliumRoundTrip';
    my $k8s_call = eval "package $pkg; use IO::K8s::Resource; sub { k8s(\@_) }"
        or die "could not import IO::K8s::Resource into $pkg: $@";
    $k8s_call->(x => 'Cilium::V2::CiliumNetworkPolicy');
    is($IO::K8s::Resource::_attr_registry{$pkg}{x}{class},
        'IO::K8s::Cilium::V2::CiliumNetworkPolicy',
        "expand_class('Cilium::V2::CiliumNetworkPolicy') round-trips to IO::K8s::Cilium::V2::CiliumNetworkPolicy");
};

subtest 'the rendered source compiles and round-trips the same document' => sub {
    for my $path (sort keys %$files) {
        my $src = $files->{$path};
        ok(eval "$src\n1;", "compiles: $path") or diag "$path:\n$src\n$@";
    }
    my $k8s = IO::K8s->new;
    $k8s->add({ Knob => '+TestOv::V1::Knob' });
    my $doc = {
        apiVersion => 'opts.example.com/v1', kind => 'Knob',
        metadata => { name => 'k', namespace => 'd' },
        spec => { mode => 'fast', replicas => 2, limit => { average => 1, period => '5s' },
                  routes => [ { match => 'a', weight => 1 } ], size => 3, extra => { x => 1 } },
    };
    my $hand = $k8s->inflate($doc);
    isa_ok($hand->spec->limit, 'TestOv::V1::RateLimit');
    my $gen = do { my $g = IO::K8s->new; $g->add({ Knob => "+$root" }); $g->inflate($doc) };
    is_deeply($hand->TO_JSON, $gen->TO_JSON, 'emitted classes and generated classes agree on the wire');
};

done_testing;
