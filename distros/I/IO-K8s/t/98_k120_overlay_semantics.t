#!/usr/bin/env perl
# k120: two overlay-semantic extensions that neither the pre-k120
# names/with/extra vocabulary nor package_for's always-prefix-with-base rule
# could express, needed for the PrometheusOperator and ExternalSecrets render
# overlays. Both are exercised here on a self-contained inline schema, with no
# network and no spec/crd/ cache.
#
#   1. reuse_core_except (IO::K8s::AutoGen, generation time): with reuse_core
#      on, suppress D5 core-reuse at named logical nested-class paths so a
#      provider's OWN named type is generated even where its shape matches a
#      shipped core class -- PrometheusOperator's {name,value} Argument, which
#      would otherwise fold into Core::V1::HTTPHeader.
#
#   2. an absolute overlay `names` value (IO::K8s::CRD::Emitter, render time):
#      a value carrying '::' names a fully-qualified package this render
#      references but does NOT emit a file for -- a cross-version provider
#      type (kept in the '+IO::K8s::...' form) or a core class the reuse
#      heuristic will not fold on its own (referenced by its short prefix,
#      Core::V1::X).
use strict;
use warnings;
use Test::More;

use IO::K8s::AutoGen;
use IO::K8s::CRD::Emitter;
use IO::K8s::Resource;

# spec.args items are {name,value} -- the exact shape D5 reuse folds into
# Core::V1::HTTPHeader. spec.auth {token} and spec.pullSecret {name} are
# single-key objects the reuse heuristic will NOT fold (it needs two keys),
# so each is generated as its own nested class the overlay can then redirect.
sub thing_schema {
    return {
        type => 'object',
        'x-kubernetes-group-version-kind' =>
            [ { group => 'k120.example.com', version => 'v1', kind => 'Thing' } ],
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            metadata   => { type => 'object' },
            spec => {
                type => 'object',
                properties => {
                    args => {
                        type  => 'array',
                        items => {
                            type => 'object',
                            properties => {
                                name  => { type => 'string' },
                                value => { type => 'string' },
                            },
                        },
                    },
                    auth       => { type => 'object', properties => { token => { type => 'string' } } },
                    pullSecret => { type => 'object', properties => { name  => { type => 'string' } } },
                },
            },
        },
    };
}

my $reg = \%IO::K8s::Resource::_attr_registry;
my $ns  = 0;

sub gen_thing {
    my (%opts) = @_;
    my $root = IO::K8s::AutoGen::get_or_generate(
        'k120.example.com.v1.Thing', thing_schema(), {},
        'IO::K8s::_AUTOGEN_k120_' . ++$ns,
        api_version => 'k120.example.com/v1', kind => 'Thing',
        resource_plural => 'things', is_namespaced => 1, %opts,
    );
    return $root;
}

subtest 'reuse_core_except is gated: default still folds {name,value} into core' => sub {
    my $root = gen_thing();
    my $spec = $reg->{$root}{spec}{class};
    is($reg->{$spec}{args}{class}, 'IO::K8s::Api::Core::V1::HTTPHeader',
        'with reuse_core on and no except set, args items reuse Core::V1::HTTPHeader');
};

subtest 'reuse_core_except suppresses reuse at the named path only' => sub {
    my $root = gen_thing(reuse_core_except => { 'Spec::ArgsItem' => 1 });
    my $spec = $reg->{$root}{spec}{class};
    my $item = $reg->{$spec}{args}{class};

    is(IO::K8s::AutoGen::class_path($item), 'Spec::ArgsItem',
        'args items now generate a nested provider class at the suppressed path');
    isnt($item, 'IO::K8s::Api::Core::V1::HTTPHeader',
        'and it is no longer the core class');

    my $item_fields = $reg->{$item};
    is($item_fields->{name}{is_str},  1, 'the generated class keeps the name field');
    is($item_fields->{value}{is_str}, 1, 'the generated class keeps the value field');

    # A path NOT in the except set is unaffected: auth/pullSecret are still
    # generated (single-key, never reused), so suppression changed nothing but
    # the one path.
    ok(IO::K8s::AutoGen::class_path($reg->{$spec}{auth}{class}),
        'an unlisted single-key object is still its own nested class');
};

subtest 'absolute overlay names: cross-version (+full) and core (short), no file emitted' => sub {
    my $root = gen_thing(reuse_core_except => { 'Spec::ArgsItem' => 1 });

    my $emitter = IO::K8s::CRD::Emitter->new(
        base    => 'K120Test::V1',
        overlay => {
            names => {
                'Spec'             => 'ThingSpec',
                'Spec::ArgsItem'   => 'Argument',
                # a same-provider cross-version target: kept in full '+' form
                'Spec::Auth'       => 'IO::K8s::Otherprov::V2::AuthConfig',
                # a core class the reuse heuristic would not fold: short prefix
                'Spec::PullSecret' => 'IO::K8s::Api::Core::V1::LocalObjectReference',
            },
        },
    );
    my $files = $emitter->render($root);
    my $spec_src = $files->{'K120Test/V1/ThingSpec.pm'};
    ok(defined $spec_src, 'the spec class rendered') or diag join "\n", sort keys %$files;

    like($spec_src, qr/^k8s args\s+=> \['\+K120Test::V1::Argument'\];$/m,
        'the suppressed-and-renamed args items reference the provider Argument class');
    like($spec_src, qr/^k8s auth\s+=> '\+IO::K8s::Otherprov::V2::AuthConfig';$/m,
        'a cross-version absolute target keeps the full +IO::K8s:: form');
    like($spec_src, qr/^k8s pullSecret\s+=> 'Core::V1::LocalObjectReference';$/m,
        'an absolute core target renders by its short prefix, as a hand-written class would');

    # The Argument class (locally generated) IS emitted; the two absolute
    # targets are references this render does not own, so no file is written
    # for them under K120Test/V1/.
    ok(exists $files->{'K120Test/V1/Argument.pm'}, 'the locally generated Argument class is emitted');
    ok(!grep({ /Auth/ } keys %$files),
        'no file is emitted for the cross-version Auth target') or diag join "\n", sort keys %$files;
    ok(!grep({ /PullSecret|LocalObjectReference/ } keys %$files),
        'no file is emitted for the core PullSecret target');

    for my $path (sort keys %$files) {
        ok(eval "$files->{$path}\n1;", "compiles: $path") or diag "$path:\n$files->{$path}\n$@";
    }
};

done_testing;
