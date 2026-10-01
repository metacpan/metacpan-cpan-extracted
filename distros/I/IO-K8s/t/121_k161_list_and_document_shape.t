#!/usr/bin/env perl
# k161: the wrong shape reaching IO::K8s::List->FROM_STRUCT, and a
# non-hash document reaching inflate.
#
# FROM_STRUCT dereferenced `items` without looking, so
#     inflate({ kind => 'PodList', apiVersion => 'v1', items => 'x' })
# died with Perl's own "Can't use string ("x") as an ARRAY ref" (or "Not an
# ARRAY reference" for {}), naming neither the List nor the field. A struct
# that was no hash at all died with "Not a HASH reference" inside
# FROM_STRUCT, and inflate('[]') died the same way inside inflate; an
# arrayref, undef or an object handed to inflate came back as a JSON parse
# error about "malformed JSON string".
#
# Approved contract, in the k146/k153/k154 message form:
#   * `items` that is defined but no array dies naming the List class, the
#     field, the expected array (of the derived item class, when there is
#     one) and the received shape;
#   * an element of `items` that is no hash dies naming the item class, the
#     received shape and the List field and element index it sits at;
#     `metadata` that is no hash names the List field the same way;
#   * a struct that is no hash dies naming the List class;
#   * inflate with a document that is no hash -- '[]', a JSON scalar, an
#     arrayref, undef, an object -- dies "Cannot inflate: expected a hash
#     (a JSON object), got ...";
#   * on every entry point that reaches a List: inflate (hash and JSON),
#     json_to_object and struct_to_object (one argument, and with the List
#     class), FROM_STRUCT directly, from_json;
#   * `items` missing or undef stays an empty list.
#
# Messages are matched on class names, field names and shapes, never on
# exact wording. Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();
use lib 'lib';

use IO::K8s;
use IO::K8s::List;

my $LIST = 'IO::K8s::List';
my $POD  = 'IO::K8s::Api::Core::V1::Pod';
my $META = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta';

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

sub dies_naming {
    my ($label, $code, @res) = @_;
    for my $re (@res) {
        throws_ok { $code->() } $re, "$label dies matching $re";
    }
    eval { $code->() };
    unlike($@, qr/Can't use (?:string|an undefined value)|Not an? (?:ARRAY|HASH) reference|malformed JSON/,
        "$label: not a bare Perl dereference or JSON parse error");
}

# Every way a List payload reaches FROM_STRUCT, as name => code.
sub entry_points {
    my ($struct) = @_;
    my $text = $json->encode($struct);
    return (
        'inflate(hash)'                => sub { $k8s->inflate($struct) },
        'inflate(JSON)'                => sub { $k8s->inflate($text) },
        'json_to_object(JSON)'         => sub { $k8s->json_to_object($text) },
        'struct_to_object(hash)'       => sub { $k8s->struct_to_object($struct) },
        'json_to_object(+List, JSON)'  => sub { $k8s->json_to_object('+'.$LIST, $text) },
        'struct_to_object(+List, hash)'=> sub { $k8s->struct_to_object('+'.$LIST, $struct) },
        'FROM_STRUCT($struct, $k8s)'   => sub { $LIST->FROM_STRUCT($struct, $k8s) },
        'FROM_STRUCT($struct)'         => sub { $LIST->FROM_STRUCT($struct) },
        'from_json'                    => sub { $LIST->from_json($text, $k8s) },
    );
}

sub pod_list { return { apiVersion => 'v1', kind => 'PodList', @_ } }

my $good_pod = { metadata => { name => 'p' }, spec => { containers => [ { name => 'c', image => 'nginx' } ] } };

# ===========================================================================
# RED: items is not an array
# ===========================================================================

# Claim: a string where the items array belongs names the List class, the
# field, the expected array of the derived item class and the plain scalar
# received -- on every entry point.
subtest 'items => "x" dies in the k154 form on every entry point' => sub {
    my %entry = entry_points(pod_list(items => 'x'));
    for my $name (sort keys %entry) {
        dies_naming($name, $entry{$name},
            qr/\Q$LIST\E field items/, qr/array/i, qr/\Q$POD\E/, qr/plain scalar/);
    }
};

# Claim: a hash where the array belongs says HASH.
subtest 'items => {} dies naming the HASH received' => sub {
    my %entry = entry_points(pod_list(items => {}));
    for my $name (sort keys %entry) {
        dies_naming($name, $entry{$name}, qr/\Q$LIST\E field items/, qr/array/i, qr/HASH/);
    }
};

# Claim: a JSON boolean is an object of its class, not an empty list.
subtest 'items => true dies naming the boolean class' => sub {
    my %entry = entry_points(pod_list(items => JSON::MaybeXS::true()));
    for my $name (sort keys %entry) {
        dies_naming($name, $entry{$name}, qr/\Q$LIST\E field items/, qr/an object of class \S*Boolean/);
    }
};

# Claim: a bare `kind: List` has no item class to name, and the message says
# the array is expected without inventing one.
subtest 'bare kind: List with items => "x"' => sub {
    dies_naming('kind List', sub { $k8s->inflate({ apiVersion => 'v1', kind => 'List', items => 'x' }) },
        qr/\Q$LIST\E field items: expected an array \(a JSON array\), got a plain scalar/);
};

# ===========================================================================
# RED: an element or the metadata is not a hash
# ===========================================================================

# Claim: an element that is no hash names the item class, the shape and the
# List field and index it sits at.
subtest 'an element that is no hash names its index' => sub {
    my %entry = entry_points(pod_list(items => [ $good_pod, 'x' ]));
    for my $name (sort keys %entry) {
        dies_naming($name, $entry{$name},
            qr/Cannot inflate \Q$POD\E: expected a hash/, qr/plain scalar/,
            qr/while inflating \Q$LIST\E field items at element 1/);
    }
    dies_naming('array element', sub { $k8s->inflate(pod_list(items => [ [] ])) },
        qr/reference of type ARRAY/, qr/\Q$LIST\E field items at element 0/);
};

# Claim: metadata that is no hash names the List field it sits at.
subtest 'metadata that is no hash names the List field' => sub {
    my %entry = entry_points(pod_list(metadata => [], items => []));
    for my $name (sort keys %entry) {
        dies_naming($name, $entry{$name},
            qr/Cannot inflate \Q$META\E: expected a hash/, qr/reference of type ARRAY/,
            qr/while inflating \Q$LIST\E field metadata/);
    }
};

# ===========================================================================
# RED: the List struct itself is not a hash
# ===========================================================================

# Claim: FROM_STRUCT on something that is no hash names the List class and
# the shape, directly and through the explicit-class entry points.
subtest 'a List struct that is no hash names the List class' => sub {
    for my $case (
        [ 'arrayref',  [],                         qr/reference of type ARRAY/ ],
        [ 'string',    'PodList',                  qr/plain scalar/ ],
        [ 'code ref',  sub { 1 },                  qr/reference of type CODE/ ],
        [ 'boolean',   JSON::MaybeXS::true(),      qr/an object of class \S*Boolean/ ],
    ) {
        my ($label, $value, $shape) = @$case;
        dies_naming("FROM_STRUCT($label)", sub { $LIST->FROM_STRUCT($value, $k8s) },
            qr/Cannot inflate \Q$LIST\E: expected a hash \(a JSON object\)/, $shape);
        dies_naming("struct_to_object(+List, $label)", sub { $k8s->struct_to_object('+'.$LIST, $value) },
            qr/Cannot inflate \Q$LIST\E: expected a hash/, $shape);
    }
    dies_naming('json_to_object(+List, "[]")', sub { $k8s->json_to_object('+'.$LIST, '[]') },
        qr/Cannot inflate \Q$LIST\E: expected a hash/, qr/reference of type ARRAY/);
    dies_naming('from_json("[]")', sub { $LIST->from_json('[]', $k8s) },
        qr/Cannot inflate \Q$LIST\E: expected a hash/, qr/reference of type ARRAY/);
};

# ===========================================================================
# RED: inflate with a document that is not a hash
# ===========================================================================

# Claim: a JSON document that is no object -- and a Perl value that is
# neither a hashref nor JSON text -- dies in the same form, without a class
# (the Kind that would pick one is inside the missing hash).
subtest 'inflate with a non-hash document' => sub {
    my $ns = $k8s->new_object('Namespace', metadata => { name => 'n' });
    for my $case (
        [ q{'[]'},          '[]',        qr/reference of type ARRAY/ ],
        [ q{'[{...}]'},     '[{"kind":"Pod"}]', qr/reference of type ARRAY/ ],
        [ 'arrayref',       [],          qr/reference of type ARRAY/ ],
        [ 'scalar ref',     \'x',        qr/reference of type SCALAR/ ],
        [ 'code ref',       sub { 1 },   qr/reference of type CODE/ ],
        [ 'undef',          undef,       qr/got undef/ ],
        [ 'an object',      $ns,         qr/an object of class IO::K8s::Api::Core::V1::Namespace/ ],
        [ 'a boolean',      JSON::MaybeXS::true(), qr/an object of class \S*Boolean/ ],
    ) {
        my ($label, $value, $shape) = @$case;
        dies_naming("inflate($label)", sub { $k8s->inflate($value) },
            qr/Cannot inflate: expected a hash \(a JSON object\)/, $shape);
    }
    dies_naming(q{json_to_object('[]')}, sub { $k8s->json_to_object('[]') },
        qr/Cannot inflate: expected a hash \(a JSON object\)/, qr/reference of type ARRAY/);
};

# Claim: a JSON scalar document -- where the backend decodes one at all --
# is refused the same way.
subtest 'inflate with a JSON scalar document' => sub {
    plan skip_all => 'JSON backend does not decode non-reference documents'
        unless eval { $k8s->json->decode('"x"'); 1 };
    for my $case ([ q{'"x"'}, '"x"', qr/plain scalar/ ], [ q{'42'}, '42', qr/plain scalar/ ],
                  [ q{'null'}, 'null', qr/got undef/ ], [ q{'true'}, 'true', qr/an object of class/ ]) {
        my ($label, $value, $shape) = @$case;
        dies_naming("inflate($label)", sub { $k8s->inflate($value) },
            qr/Cannot inflate: expected a hash \(a JSON object\)/, $shape);
    }
};

# Claim: strict governs undeclared keys, not shape -- same messages there.
subtest 'the same under strict' => sub {
    my $strict = IO::K8s->new(strict => 1);
    dies_naming('strict items', sub { $strict->inflate(pod_list(items => 'x')) },
        qr/\Q$LIST\E field items/, qr/plain scalar/);
    dies_naming('strict document', sub { $strict->inflate('[]') },
        qr/Cannot inflate: expected a hash/, qr/ARRAY/);
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: items missing or undef is an empty list, as before -- on every
# entry point.
subtest 'GUARD: items missing or undef is an empty list' => sub {
    for my $struct (pod_list(), pod_list(items => undef), pod_list(items => [])) {
        my %entry = entry_points($struct);
        for my $name (sort keys %entry) {
            my $list = $entry{$name}->();
            isa_ok($list, $LIST, $name);
            is_deeply($list->items, [], "$name: no items");
        }
    }
    my $list = $LIST->FROM_STRUCT(undef, $k8s);
    is_deeply($list->items, [], 'FROM_STRUCT(undef) is still an empty list');
};

# Claim: a well-formed list still inflates, typed, on every entry point.
subtest 'GUARD: a well-formed PodList inflates' => sub {
    my %entry = entry_points(pod_list(metadata => { resourceVersion => '7' }, items => [ $good_pod, $good_pod ]));
    for my $name (sort keys %entry) {
        my $list = $entry{$name}->();
        is(scalar @{ $list->items }, 2, "$name: two items");
        isa_ok($list->items->[1], $POD, "$name: item");
        is($list->metadata->resourceVersion, '7', "$name: metadata");
        is($list->kind, 'PodList', "$name: kind");
    }
};

# Claim: a hash document and JSON text for one still inflate.
subtest 'GUARD: a hash and JSON text still inflate' => sub {
    my $doc = { apiVersion => 'v1', kind => 'Namespace', metadata => { name => 'n1' } };
    is($k8s->inflate($doc)->metadata->name, 'n1', 'hashref');
    is($k8s->inflate($json->encode($doc))->metadata->name, 'n1', 'JSON text');
};

done_testing;
