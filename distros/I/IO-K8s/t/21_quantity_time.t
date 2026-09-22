#!/usr/bin/env perl
# Tests for Quantity and Time type support
# Ensures proper type registration, validation, and schema comparison

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use JSON::MaybeXS;

my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1);

# ---- Type objects exist and are exported ----

subtest 'type objects' => sub {
    use_ok('IO::K8s::Types');

    my $q = IO::K8s::Types::Quantity();
    isa_ok($q, 'Type::Tiny', 'Quantity is Type::Tiny');
    is($q->name, 'Quantity', 'Quantity name');

    my $t = IO::K8s::Types::Time();
    isa_ok($t, 'Type::Tiny', 'Time is Type::Tiny');
    is($t->name, 'Time', 'Time name');
};

# ---- Quantity validation ----

subtest 'Quantity constraint' => sub {
    my $q = IO::K8s::Types::Quantity();

    # Valid quantities
    for my $valid (qw(100m 5Gi 1.5 0.001 12e6 12E3 1k 1M 1G 1T 1P 1E
                      1Ki 1Mi 1Ti 1Pi 1Ei 500m .5 3. +100m -1k 0)) {
        ok($q->check($valid), "valid: '$valid'");
    }

    # Invalid quantities
    for my $invalid ('abc', '1X', '1ki', '1mI', '100m%', '', '1 Gi') {
        ok(!$q->check($invalid), "invalid: '$invalid'");
    }
};

# ---- k52: decimal SI suffixes n (nano) and u (micro) ----
#
# Upstream apimachinery accepts nine decimal SI suffixes -- n u m "" k M G T P
# E (pkg/api/resource/suffix.go) -- but the suffix class in the Quantity
# regex used to be [mkMGTPE], omitting n and u. Real cluster data uses both:
# metrics-server reports CPU as e.g. "100n", and autoscaling/v2
# MetricTarget/MetricValueStatus carry averageValue in "500u"-style units.
subtest 'k52: n (nano) and u (micro) suffixes accepted' => sub {
    my $q = IO::K8s::Types::Quantity();
    ok($q->check('100n'), 'valid: 100n (nano)');
    ok($q->check('500u'), 'valid: 500u (micro)');

    # End-to-end, not just the bare type constraint: the ticket's own repro
    # was EmptyDirVolumeSource->new(sizeLimit => '100n') dying outright.
    use_ok('IO::K8s::Api::Core::V1::EmptyDirVolumeSource');
    my $ed = IO::K8s::Api::Core::V1::EmptyDirVolumeSource->new(sizeLimit => '100n');
    is($ed->sizeLimit, '100n', 'sizeLimit stores 100n verbatim');
    is($ed->TO_JSON->{sizeLimit}, '100n', 'TO_JSON keeps 100n as a Quantity string');

    use_ok('IO::K8s::Api::Autoscaling::V2::MetricValueStatus');
    my $mv = IO::K8s::Api::Autoscaling::V2::MetricValueStatus->new(averageValue => '500u');
    is($mv->averageValue, '500u', 'averageValue stores 500u verbatim');

    # The existing matrix stays green.
    ok($q->check('100m'), 'existing: 100m still valid');
    ok($q->check('1Ki'), 'existing: 1Ki still valid');
    ok($q->check('2e3'), 'existing: 2e3 still valid');
};

# ---- k52: the deliberate boundary -- what stays rejected ----
#
# Widening [mkMGTPE] to [numkMGTPE] must not go further than the fix sketch
# called for. Two families of rejection here are intentional, not
# incidental:
#
#  1. A mantissa-less quantity -- a bare suffix like "Ki" or "n", a bare
#     exponent like "e3", or a bare "." -- with an optional sign. Upstream's
#     parseQuantityString treats a missing numeric run before the suffix as
#     an implicit "0" and accepts it. The Quantity regex requires at least
#     one digit on one side of an optional decimal point
#     (\d+\.?\d*|\d*\.\d+) and has no such special case, so these are
#     rejected. This is a deliberate stricter-than-upstream stance, not a
#     bug: nothing in this distribution's own use needs a bare-suffix
#     quantity, and accepting one is far more likely to be a caller's typo
#     (a stray suffix with no number) than an intentional zero.
#  2. A malformed suffix -- "1mi" (the decimal 'm' suffix with a bogus
#     trailing 'i'), "1KI" (wrong case for the binary 'Ki' suffix), "100nn"
#     (a doubled decimal suffix) -- which upstream rejects too. These pin
#     that widening the suffix class to include n/u did not also loosen the
#     alternation into accepting near-misses of the binary suffixes or
#     doubled-up decimal ones.
subtest 'k52: the intended boundary stays rejected' => sub {
    my $q = IO::K8s::Types::Quantity();

    for my $bare (qw(Ki m n e3 .)) {
        ok(!$q->check($bare),
            "mantissa-less '$bare' stays rejected (upstream parses it as 0; deliberate strictness)");
    }

    for my $bad ('1mi', '1KI', '100nn') {
        ok(!$q->check($bad), "malformed suffix '$bad' stays rejected");
    }
};

# ---- Time validation ----

subtest 'Time constraint' => sub {
    my $t = IO::K8s::Types::Time();

    # Valid RFC3339 timestamps
    for my $valid (
        '2024-01-15T10:30:45Z',
        '2026-02-28T00:00:00Z',
        '2024-01-15T10:30:45+01:00',
        '2024-01-15T10:30:45-05:00',
        '2024-01-15T10:30:45.123Z',
        '2024-01-15T10:30:45.123456Z',
    ) {
        ok($t->check($valid), "valid: '$valid'");
    }

    # Invalid timestamps
    for my $invalid ('not-a-date', '2024-01-15', '2024-01-15 10:30:45',
                     '2024-01-15T10:30:45', '10:30:45Z', '') {
        ok(!$t->check($invalid), "invalid: '$invalid'");
    }
};

# ---- Classes using Time ----

subtest 'ObjectMeta Time fields' => sub {
    use_ok('IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');

    my $info = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->_k8s_attr_info;
    ok($info->{creationTimestamp}{is_time}, 'creationTimestamp has is_time flag');
    ok($info->{deletionTimestamp}{is_time}, 'deletionTimestamp has is_time flag');
    ok(!$info->{creationTimestamp}{is_str}, 'creationTimestamp is NOT is_str');
    ok($info->{name}{is_str}, 'name is still is_str');

    my $meta = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
        name              => 'test-pod',
        creationTimestamp => '2024-01-15T10:30:45Z',
    );
    my $data = $meta->TO_JSON;
    is($data->{creationTimestamp}, '2024-01-15T10:30:45Z', 'Time serializes as string');
    is($data->{name}, 'test-pod', 'Str still works');

    my $encoded = $json->encode($data);
    like($encoded, qr/"creationTimestamp":"2024-01-15T10:30:45Z"/,
        'Time is JSON string');
};

subtest 'PodCondition Time fields' => sub {
    use_ok('IO::K8s::Api::Core::V1::PodCondition');

    my $cond = IO::K8s::Api::Core::V1::PodCondition->new(
        lastTransitionTime => '2026-02-28T12:00:00Z',
        status             => 'True',
        type               => 'Ready',
    );
    my $encoded = $json->encode($cond->TO_JSON);
    like($encoded, qr/"lastTransitionTime":"2026-02-28T12:00:00Z"/,
        'PodCondition lastTransitionTime JSON string');
};

subtest 'Required Time field' => sub {
    use_ok('IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition');

    my $cond = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition->new(
        lastTransitionTime => '2024-01-15T10:30:45Z',
        message            => 'ok',
        reason             => 'Ready',
        status             => 'True',
        type               => 'Available',
    );
    my $info = $cond->_k8s_attr_info;
    ok($info->{lastTransitionTime}{is_time}, 'required Time field has is_time');
};

subtest 'Event Time fields' => sub {
    use_ok('IO::K8s::Api::Core::V1::Event');

    my $info = IO::K8s::Api::Core::V1::Event->_k8s_attr_info;
    ok($info->{eventTime}{is_time}, 'eventTime is_time');
    ok($info->{firstTimestamp}{is_time}, 'firstTimestamp is_time');
    ok($info->{lastTimestamp}{is_time}, 'lastTimestamp is_time');
};

# ---- Classes using Quantity ----

subtest 'MetricTarget Quantity fields' => sub {
    use_ok('IO::K8s::Api::Autoscaling::V2::MetricTarget');

    my $info = IO::K8s::Api::Autoscaling::V2::MetricTarget->_k8s_attr_info;
    ok($info->{value}{is_quantity}, 'value has is_quantity flag');
    ok($info->{averageValue}{is_quantity}, 'averageValue has is_quantity flag');
    ok(!$info->{value}{is_str}, 'value is NOT is_str');

    my $target = IO::K8s::Api::Autoscaling::V2::MetricTarget->new(
        type         => 'AverageValue',
        averageValue => '500m',
    );
    my $encoded = $json->encode($target->TO_JSON);
    like($encoded, qr/"averageValue":"500m"/, 'Quantity serializes as JSON string');
};

subtest 'CSIStorageCapacity Quantity fields' => sub {
    use_ok('IO::K8s::Api::Storage::V1::CSIStorageCapacity');

    my $info = IO::K8s::Api::Storage::V1::CSIStorageCapacity->_k8s_attr_info;
    ok($info->{capacity}{is_quantity}, 'capacity has is_quantity');
    ok($info->{maximumVolumeSize}{is_quantity}, 'maximumVolumeSize has is_quantity');

    my $cap = IO::K8s::Api::Storage::V1::CSIStorageCapacity->new(
        storageClassName => 'standard',
        capacity         => '100Gi',
        maximumVolumeSize => '10Ti',
    );
    my $encoded = $json->encode($cap->TO_JSON);
    like($encoded, qr/"capacity":"100Gi"/, 'capacity as Quantity JSON string');
    like($encoded, qr/"maximumVolumeSize":"10Ti"/, 'maximumVolumeSize as Quantity JSON string');
};

subtest 'EmptyDirVolumeSource sizeLimit' => sub {
    use_ok('IO::K8s::Api::Core::V1::EmptyDirVolumeSource');

    my $info = IO::K8s::Api::Core::V1::EmptyDirVolumeSource->_k8s_attr_info;
    ok($info->{sizeLimit}{is_quantity}, 'sizeLimit has is_quantity');
};

subtest 'ResourceFieldSelector divisor' => sub {
    use_ok('IO::K8s::Api::Core::V1::ResourceFieldSelector');

    my $info = IO::K8s::Api::Core::V1::ResourceFieldSelector->_k8s_attr_info;
    ok($info->{divisor}{is_quantity}, 'divisor has is_quantity');
};

# ---- Schema comparison ----

subtest 'schema comparison matches Quantity and Time' => sub {
    use IO::K8s::Resource;

    # Simulate a schema with Quantity $ref and Time $ref
    my $schema = {
        properties => {
            capacity => {
                '$ref' => '#/definitions/io.k8s.apimachinery.pkg.api.resource.Quantity',
            },
            creationTimestamp => {
                '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.Time',
            },
            eventTime => {
                '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime',
            },
            lastUpdate => {
                type   => 'string',
                format => 'date-time',
            },
        },
    };

    # Build a test class with matching types
    {
        package TestSchemaMatch;
        use IO::K8s::Resource;
        k8s capacity          => Quantity;
        k8s creationTimestamp  => Time;
        k8s eventTime          => Time;
        k8s lastUpdate         => Time;
    }

    my $diff = TestSchemaMatch->compare_to_schema($schema);
    is_deeply($diff->{type_mismatch}, [], 'no type mismatches for Quantity/Time');
    is_deeply($diff->{missing_locally}, [], 'no missing locally');
    is_deeply($diff->{missing_in_schema}, [], 'no missing in schema');
};

done_testing;
