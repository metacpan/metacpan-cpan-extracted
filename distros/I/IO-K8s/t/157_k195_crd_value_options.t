#!/usr/bin/env perl
# k195: to_crd must put the value options (enum, pattern, minimum, maximum)
# of a [X] array on the array's `items` schema and those of a typed map
# (HashRef[X]) on its `additionalProperties` schema. They used to land on the
# container schema, so the emitted CRD constrained the array / object itself
# (an `enum` on `type: array`, a `minimum` on `type: object`) instead of its
# values -- the API server then rejects or silently ignores the constraint.
#
# Claims, all read off the schema to_crd emits:
#   * [Str] enum / pattern -> items carries them, the array schema has none;
#   * [Int] minimum / maximum -> items carries them (as JSON numbers);
#   * HashRef[Str] enum / pattern, HashRef[Int] minimum / maximum ->
#     additionalProperties carries them, the object schema has none;
#   * control: a scalar field keeps its options on the field itself;
#   * the item / value type is still emitted next to the options.
#
# Local fixtures only, no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Deep;
use JSON::MaybeXS ();

{
    package Test::K195::Values;
    use IO::K8s::APIObject
        api_version     => 'k195.example.com/v1',
        resource_plural => 'valueses';
    with 'IO::K8s::Role::Namespaced';

    k8s modes      => [Str],         { enum    => [qw( fast slow )] };
    k8s names      => [Str],         { pattern => '^[a-z]+$' };
    k8s ports      => [Int],         { minimum => 1, maximum => 65535 };
    k8s labelEnum  => HashRef[Str],  { enum    => [qw( red green )] };
    k8s labelPat   => HashRef[Str],  { pattern => '^[a-z]+$' };
    k8s counts     => HashRef[Int],  { minimum => 0, maximum => 10 };
    k8s mode       => Str,           { enum    => [qw( fast slow )] };
    k8s replicas   => Int,           { minimum => 1, maximum => 5 };
    k8s slug       => Str,           { pattern => '^[a-z]+$' };

    1;
}

my $crd   = Test::K195::Values->to_crd;
my $json  = JSON::MaybeXS->new(canonical => 1)->decode($crd->to_json);
my $props = $json->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties};

my @OPTS = qw( enum pattern minimum maximum );

sub no_value_options {
    my ($schema, $name) = @_;
    my @bad = grep { exists $schema->{$_} } @OPTS;
    ok(!@bad, "$name: container schema carries no value option")
        or diag "found on the container: @bad";
}

# [X] arrays -> items
for my $case (
    [ modes => 'string',  { enum    => [qw( fast slow )] } ],
    [ names => 'string',  { pattern => '^[a-z]+$' } ],
    [ ports => 'integer', { minimum => 1, maximum => 65535 } ],
) {
    my ($field, $type, $want) = @$case;
    subtest "[X] $field: options on items" => sub {
        my $s = $props->{$field};
        is($s->{type}, 'array', 'type: array');
        no_value_options($s, $field);
        cmp_deeply($s->{items}, { type => $type, %$want }, 'items has the type and the options');
    };
}

# HashRef[X] -> additionalProperties
for my $case (
    [ labelEnum => 'string',  { enum    => [qw( red green )] } ],
    [ labelPat  => 'string',  { pattern => '^[a-z]+$' } ],
    [ counts    => 'integer', { minimum => 0, maximum => 10 } ],
) {
    my ($field, $type, $want) = @$case;
    subtest "HashRef[X] $field: options on additionalProperties" => sub {
        my $s = $props->{$field};
        is($s->{type}, 'object', 'type: object');
        no_value_options($s, $field);
        cmp_deeply($s->{additionalProperties}, { type => $type, %$want },
            'additionalProperties has the type and the options');
    };
}

# Control: scalars keep their options on the field.
subtest 'scalar fields keep their options' => sub {
    cmp_deeply($props->{mode},     { type => 'string',  enum    => [qw( fast slow )] }, 'Str enum');
    cmp_deeply($props->{replicas}, { type => 'integer', minimum => 1, maximum => 5 },   'Int minimum / maximum');
    cmp_deeply($props->{slug},     { type => 'string',  pattern => '^[a-z]+$' },        'Str pattern');
};

# Wire type: bounds are JSON numbers, not strings.
subtest 'bounds in items / additionalProperties are JSON numbers' => sub {
    my $text = $crd->to_json;
    like($text, qr/"maximum":65535[,}]/, 'ports maximum is a number');
    unlike($text, qr/"(?:minimum|maximum)":"/, 'no bound is a JSON string');
};

done_testing;
