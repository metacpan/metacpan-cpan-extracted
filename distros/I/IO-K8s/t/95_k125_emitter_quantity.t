#!/usr/bin/env perl
# k125: the CRD emitter recognizes the exact apimachinery Quantity shape.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";

use JSON::MaybeXS;
use re ();
use IO::K8s::AutoGen;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;
use IO::K8s::PrometheusOperator::V1::EmptyDirVolumeSource;
use IO::K8s::PrometheusOperator::V1::PodMonitorSpec;
use IO::K8s::PrometheusOperator::V1::ProbeSpec;
use IO::K8s::PrometheusOperator::V1::ServiceMonitorSpec;
use IO::K8s::PrometheusOperator::V1::TSDBSpec;
use IO::K8s::PrometheusOperator::V1::TracingConfig;
use IO::K8s::PrometheusOperator::V1alpha1::ScrapeConfigSpec;
use IO::K8s::VolumeSnapshot::V1::VolumeSnapshotStatus;

# Copied verbatim from the checked-in Prometheus Operator v0.93.1 and
# VolumeSnapshot v8.6.0 CRD fixtures. This has to stay an exact match: a
# near-enough pattern could be a different API contract.
my $QUANTITY_PATTERN = q{^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$};
my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1);

{
    package Test::K125::RegexRegistry;
    use IO::K8s::Resource;

    k8s flagged   => IntOrStr, { pattern => qr/$QUANTITY_PATTERN/i };
    k8s unflagged => IntOrStr, { pattern => qr/$QUANTITY_PATTERN/ };
}

package main;

my $schema = {
    type => 'object',
    'x-kubernetes-group-version-kind' => [{
        group   => 'quantity.example.test',
        version => 'v1',
        kind    => 'QuantityFixture',
    }],
    properties => {
        spec => {
            type       => 'object',
            properties => {
                canonicalString => {
                    type                         => 'string',
                    'x-kubernetes-int-or-string' => JSON::MaybeXS::true,
                    pattern                      => $QUANTITY_PATTERN,
                    default                      => '1Gi',
                    nullable                     => JSON::MaybeXS::true,
                    description                  => 'Quantity expressed as a string.',
                },
                canonicalUnion => {
                    anyOf => [
                        { type => 'integer' },
                        { type => 'string' },
                    ],
                    'x-kubernetes-int-or-string' => JSON::MaybeXS::true,
                    pattern                      => $QUANTITY_PATTERN,
                    default                      => '1Gi',
                    nullable                     => JSON::MaybeXS::true,
                    description                  => 'Quantity expressed as a string.',
                },
                noPattern => {
                    type                         => 'string',
                    'x-kubernetes-int-or-string' => JSON::MaybeXS::true,
                },
                otherPattern => {
                    type                         => 'string',
                    'x-kubernetes-int-or-string' => JSON::MaybeXS::true,
                    pattern                      => '^only-this$',
                },
                flaggedPattern => {
                    type                         => 'string',
                    'x-kubernetes-int-or-string' => JSON::MaybeXS::true,
                    pattern                      => '^(?i)(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$',
                },
                plainString => {
                    type    => 'string',
                    pattern => $QUANTITY_PATTERN,
                },
            },
        },
    },
};

my $generated = IO::K8s::AutoGen::get_or_generate(
    'quantity.example.test.v1.QuantityFixture',
    $schema,
    {},
    'IO::K8s::_AUTOGEN_k125_quantity',
    api_version     => 'quantity.example.test/v1',
    kind            => 'QuantityFixture',
    resource_plural => 'quantityfixtures',
    is_namespaced   => 1,
);
my $generated_spec = $generated->_k8s_attr_info->{spec}{class};
my $generated_info = $generated_spec->_k8s_attr_info;

subtest 'only the emitter upgrades exact IntOrStr Quantity registry entries' => sub {
    ok($generated_info->{canonicalString}{is_int_or_string},
        'type:string plus extension remains IntOrStr in the dynamic registry');
    ok($generated_info->{canonicalUnion}{is_int_or_string},
        'anyOf(integer,string) plus extension reaches the same IntOrStr registry form');
    is_deeply($generated_info->{canonicalString}, $generated_info->{canonicalUnion},
        'the registry retains no provenance that could distinguish the two schema forms');

    my $dynamic = $generated_spec->new(
        canonicalString => '42',
        canonicalUnion  => '42',
    );
    like($json->encode($dynamic->TO_JSON), qr/"canonicalString":42\b/,
        'dynamic AutoGen remains IntOrStr and sends a numeric-looking string as a JSON number');
    like($json->encode($dynamic->TO_JSON), qr/"canonicalUnion":42\b/,
        'the anyOf form remains the same unchanged dynamic path');

    my $canonical_pattern = $generated_info->{canonicalString}{options}{pattern};
    my %canonical_options = %{ $generated_info->{canonicalString}{options} };

    my $files = IO::K8s::CRD::Emitter->new(base => 'TestK125::V1')->render($generated);
    my $source = $files->{'TestK125/V1/QuantityFixtureSpec.pm'};

    like($source,
        qr/^k8s canonicalString\s+=> Quantity, \{ default => '1Gi', nullable => 1 \};$/m,
        'the string form emits Quantity, drops only its redundant pattern, and retains other options');
    like($source,
        qr/^k8s canonicalUnion\s+=> Quantity, \{ default => '1Gi', nullable => 1 \};$/m,
        'the anyOf form emits the same Quantity declaration without provenance-dependent handling');
    is($generated_info->{canonicalString}{options}{pattern}, $canonical_pattern,
        'rendering does not remove the canonical pattern from the source registry');
    is_deeply($generated_info->{canonicalString}{options}, \%canonical_options,
        'rendering leaves every source registry option unchanged');

    like($source, qr/^k8s noPattern\s+=> IntOrStr;$/m,
        'an IntOrStr without a pattern remains IntOrStr');
    like($source, qr/^k8s otherPattern\s+=> IntOrStr,/m,
        'an IntOrStr with a different pattern remains IntOrStr');
    like($source, qr/^k8s flaggedPattern\s+=> IntOrStr,/m,
        'an IntOrStr with a semantically modified regex remains IntOrStr');
    like($source, qr/^k8s plainString\s+=> Str,/m,
        'a plain string field with the same pattern remains Str');

    for my $path (sort keys %$files) {
        ok(eval "$files->{$path}\n1;", "compiles: $path") or diag $@;
    }

    my $emitted = TestK125::V1::QuantityFixtureSpec->new(
        canonicalString => '42',
        canonicalUnion  => '1Gi',
    );
    my $wire = $emitted->TO_JSON;
    like($json->encode($wire), qr/"canonicalString":"42"/,
        'emitted Quantity sends a numeric-looking Quantity as a JSON string');
    like($json->encode($wire), qr/"canonicalUnion":"1Gi"/,
        'emitted Quantity sends a binary Quantity as a JSON string');
    is_deeply(TestK125::V1::QuantityFixtureSpec->FROM_HASH($wire)->TO_JSON, $wire,
        'the emitted Quantity class round-trips its wire structure');
    throws_ok {
        TestK125::V1::QuantityFixtureSpec->new(canonicalString => 'not-a-quantity')
    } qr/not a valid Kubernetes Quantity/,
        'the emitted Quantity class rejects an invalid Quantity';
};

subtest 'external regexp flags keep IntOrStr semantics while an unflagged regexp becomes Quantity' => sub {
    my $class = 'Test::K125::RegexRegistry';
    my $info = $class->_k8s_attr_info;
    my $flagged_pattern = $info->{flagged}{options}{pattern};
    my %flagged_options = %{ $info->{flagged}{options} };
    my ($body, $flags) = re::regexp_pattern($flagged_pattern);
    is($body, $QUANTITY_PATTERN, 'the externally flagged regexp has the exact canonical Quantity body');
    like($flags, qr/i/, 'the externally flagged regexp carries a semantic /i flag');

    my $files = IO::K8s::CRD::Emitter->new(base => 'TestK125::Regex')->render($class);
    my $source = $files->{'TestK125/Regex/RegexRegistry.pm'};

    like($source, qr/^k8s flagged\s+=> IntOrStr, \{ pattern => /m,
        'an exact Quantity body with an external /i flag remains IntOrStr');
    like($source, qr/^k8s flagged.*\(\?i\)/m,
        'the external /i flag is folded into the emitted pattern text');
    like($source, qr/^k8s unflagged\s+=> Quantity;$/m,
        'the same exact body without semantic flags emits Quantity');
    is($info->{flagged}{options}{pattern}, $flagged_pattern,
        'rendering does not replace the externally flagged regexp in the registry');
    is_deeply($info->{flagged}{options}, \%flagged_options,
        'rendering leaves the externally flagged registry options unchanged');

    ok(eval "$source\n1;", 'the flagged/unflagged rendered source compiles') or diag $@;
    my $flagged_lived = eval { TestK125::Regex::RegexRegistry->new(flagged => '1KI'); 1 };
    ok($flagged_lived, 'the emitted IntOrStr pattern preserves the original /i semantics') or diag $@;
    for my $value ('1Ki', '1KI', '1Gi', 'not-a-quantity') {
        my $original_lives = eval { $class->new(flagged => $value); 1 };
        my $emitted_lives = eval { TestK125::Regex::RegexRegistry->new(flagged => $value); 1 };
        is(!!$emitted_lives, !!$original_lives,
            "the emitted flagged pattern keeps the original acceptance for '$value'");
    }

    my $quantity = TestK125::Regex::RegexRegistry->new(unflagged => '42');
    like($json->encode($quantity->TO_JSON), qr/"unflagged":"42"/,
        'the unflagged regexp-derived Quantity sends numeric-looking text as a JSON string');
};

subtest 'all seven curated Prometheus Operator fields are Quantity strings on the wire' => sub {
    my @fields = (
        [ 'IO::K8s::PrometheusOperator::V1::EmptyDirVolumeSource', 'sizeLimit' ],
        [ 'IO::K8s::PrometheusOperator::V1::PodMonitorSpec', 'nativeHistogramMinBucketFactor' ],
        [ 'IO::K8s::PrometheusOperator::V1::ProbeSpec', 'nativeHistogramMinBucketFactor' ],
        [ 'IO::K8s::PrometheusOperator::V1::ServiceMonitorSpec', 'nativeHistogramMinBucketFactor' ],
        [ 'IO::K8s::PrometheusOperator::V1::TSDBSpec', 'staleSeriesCompactionThreshold' ],
        [ 'IO::K8s::PrometheusOperator::V1::TracingConfig', 'samplingFraction' ],
        [ 'IO::K8s::PrometheusOperator::V1alpha1::ScrapeConfigSpec', 'nativeHistogramMinBucketFactor' ],
    );

    for my $entry (@fields) {
        my ($class, $field) = @$entry;
        my $info = $class->_k8s_attr_info->{$field};
        ok($info->{is_quantity}, "$class\::$field is registered as Quantity");

        my $object = $class->new($field => '42');
        my $wire = $object->TO_JSON;
        like($json->encode($wire), qr/"\Q$field\E":"42"/,
            "$class\::$field serializes numeric-looking Quantity text as a JSON string");
        is_deeply($class->FROM_HASH($wire)->TO_JSON, $wire,
            "$class\::$field round-trips its Quantity wire value");
    }
};

subtest 'VolumeSnapshot restoreSize and its lossy CRD export stay unchanged' => sub {
    my $class = 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotStatus';
    ok($class->_k8s_attr_info->{restoreSize}{is_quantity},
        'VolumeSnapshot restoreSize remains Quantity');

    my $status = $class->new(restoreSize => '42');
    like($json->encode($status->TO_JSON), qr/"restoreSize":"42"/,
        'VolumeSnapshot restoreSize remains a JSON Quantity string');
    is_deeply(
        IO::K8s::CRD::_schema_for_class($class)->{properties}{restoreSize},
        { type => 'string' },
        'the intentionally lossy Quantity CRD export remains a plain string schema',
    );
};

done_testing;
