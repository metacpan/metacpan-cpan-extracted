#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use IO::K8s::Api::Core::V1::ResourceRequirements;

# k63: the { Str => 1 } DSL form maps to a bare HashRef with no inner
# constraint, so the most-used quantity-carrying fields validated nothing --
# ResourceRequirements->new(limits => { cpu => "banana" }) constructed happily
# and only failed at the API server (fail-open, which the house line rejects).
# This adds a hash-of-scalar-type form, { Quantity => 1 }, and retypes the
# fields upstream declares as map[ResourceName]Quantity.

# A bogus quantity is now rejected at construction.
throws_ok { IO::K8s::Api::Core::V1::ResourceRequirements->new(limits => { cpu => 'banana' }) }
    qr/[Qq]uantity|did not pass|constraint/,
    'limits => { cpu => banana } is rejected -- the value map is type-checked now';

# Valid quantities still construct and round-trip unchanged.
my $rr = IO::K8s::Api::Core::V1::ResourceRequirements->new(
    limits   => { cpu => '2',    memory => '1Gi' },
    requests => { cpu => '100m', memory => '256Mi' },
);
cmp_deeply($rr->TO_JSON->{limits},   { cpu => '2',    memory => '1Gi' },
           'valid limits round-trip as strings');
cmp_deeply($rr->TO_JSON->{requests}, { cpu => '100m', memory => '256Mi' },
           'valid requests round-trip as strings');

# The generic hash-of-scalar-type form, exercised directly for a couple of
# value types.
{
    package Test::Karr63::Thing;
    use IO::K8s::Resource;
    k8s scores => { Int => 1 };       # map of integers
    k8s ratios => { Num => 1 };       # map of numbers
    k8s labels => { Str => 1 };       # opaque map -- must stay unconstrained
}

my $t = Test::Karr63::Thing->new(
    scores => { a => 3, b => 4 },
    ratios => { a => 1.5 },
    labels => { any => 'value', nested => 'ok' },
);
like($t->to_json, qr/"a":3\b/,   'hash-of-Int serializes values unquoted');
like($t->to_json, qr/"a":1\.5/,  'hash-of-Num serializes values unquoted');

# The opaque { Str => 1 } form is unchanged: it still accepts anything, because
# labels/annotations/fieldsV1 are genuinely opaque string maps.
lives_ok { Test::Karr63::Thing->new(labels => { x => 'whatever' }) }
    'opaque { Str => 1 } map still accepts arbitrary string values';

done_testing;
