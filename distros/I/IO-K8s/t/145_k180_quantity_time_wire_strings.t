#!/usr/bin/env perl
# k180: a Quantity or Time value went out as whatever JSON type its Perl
# scalar had. Since k167 each element of a [Quantity] / [Time] array is
# written as a JSON string, but a scalar Quantity / Time field and the
# values of a { Quantity => 1 } / { Time => 1 } map still fell through
# TO_JSON's generic copy: limits => { cpu => 1 } went out as {"cpu":1}.
# The API server accepts both, but the same value took two wire forms
# depending on where it sat, and neither was the one Kubernetes writes
# itself -- a quantity and a timestamp are always JSON strings in what the
# API server returns.
#
# Claims:
#   * a scalar Quantity / Time field, each value of a Quantity / Time map
#     and each element of a Quantity / Time array go out as a JSON string,
#     whatever Perl scalar holds it -- checked on the JSON text, for a
#     hand-declared class, the shipped ResourceRequirements and
#     EmptyDirVolumeSource, and an AutoGen class;
#   * a numeric value arriving on the wire comes back out as a string
#     (the visible wire change this makes);
#   * the object keeps the value it was given -- serializing does not
#     rewrite it -- and the map TO_JSON returns is a copy (k54);
#   * an undef or reference map value that got in past the constructor is
#     left alone, as the array branches leave such elements;
#   * YAML, the kubectl-apply path, carries the string too.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::Api::Core::V1::ResourceRequirements;
use IO::K8s::Api::Core::V1::EmptyDirVolumeSource;

my $json = JSON::MaybeXS->new(canonical => 1, utf8 => 1);

{
    package TestK180::All;
    use IO::K8s::Resource;
    k8s amount     => Quantity;
    k8s at         => Time;
    k8s amounts    => { Quantity => 1 };
    k8s ats        => { Time => 1 };
    k8s amountList => [Quantity];
    k8s atList     => [Time];
    k8s count      => Int;
    k8s flex       => IntOrStr;
}

subtest 'every Quantity and Time position is a JSON string' => sub {
    my $obj = TestK180::All->new(
        amount     => 2,
        at         => '2026-09-27T12:00:00Z',
        amounts    => { cpu => 1, memory => '1Gi', frac => 0.5 },
        ats        => { at => '2026-09-27T12:00:00Z' },
        amountList => [1, '500m'],
        atList     => ['2026-09-27T12:00:00Z'],
        count      => '3',
        flex       => '4',
    );
    is($obj->to_json,
        '{"amount":"2","amountList":["1","500m"],"amounts":{"cpu":"1","frac":"0.5","memory":"1Gi"},'
        . '"at":"2026-09-27T12:00:00Z","atList":["2026-09-27T12:00:00Z"],'
        . '"ats":{"at":"2026-09-27T12:00:00Z"},"count":3,"flex":4}',
        'scalar, map and array alike; Int and IntOrStr keep their own rules');

    is($obj->amount, 2, 'the object keeps the value it was given');
    is($obj->amounts->{cpu}, 1, '... in a map too');
    my $data = $obj->TO_JSON;
    $data->{amounts}{extra} = '9';
    ok(!exists $obj->amounts->{extra}, 'the map TO_JSON returns is a copy, not the object\'s own');

    # A value the constructor never saw (written through the accessor's
    # hashref) may be undef or a ref; it goes out as it is.
    $obj->amounts->{none} = undef;
    $obj->amounts->{deep} = [ 'x' ];
    my $again = $obj->TO_JSON;
    ok(exists $again->{amounts}{none} && !defined $again->{amounts}{none},
        'an undef map value is left alone');
    is_deeply($again->{amounts}{deep}, ['x'], 'a reference map value is left alone');
};

subtest 'the shipped classes: limits => { cpu => 1 } goes out as "1"' => sub {
    my $res = IO::K8s::Api::Core::V1::ResourceRequirements->new(
        limits   => { cpu => 1, memory => '512Mi' },
        requests => { cpu => 0.25 },
    );
    is($res->to_json, '{"limits":{"cpu":"1","memory":"512Mi"},"requests":{"cpu":"0.25"}}',
        'ResourceRequirements limits/requests');
    like($res->to_yaml, qr/^\s+cpu: '1'$/m, 'YAML quotes it as a string as well');

    my $ed = IO::K8s::Api::Core::V1::EmptyDirVolumeSource->new(sizeLimit => 1);
    is($ed->to_json, '{"sizeLimit":"1"}', 'a scalar Quantity field (EmptyDirVolumeSource.sizeLimit)');

    my $pod = IO::K8s->new->new_object('Pod',
        metadata => { name => 'q' },
        spec     => { containers => [{ name => 'app', image => 'nginx',
                                       resources => { limits => { cpu => 2 } } }] },
    );
    is($json->encode($pod->TO_JSON->{spec}{containers}[0]{resources}), '{"limits":{"cpu":"2"}}',
        'the same inside a Pod built through new_object');
};

subtest 'a number on the wire comes back out as a string' => sub {
    my $k8s = IO::K8s->new;
    my $pod = $k8s->inflate('{"apiVersion":"v1","kind":"Pod","metadata":{"name":"q"},'
        . '"spec":{"containers":[{"name":"app","image":"nginx",'
        . '"resources":{"limits":{"cpu":1},"requests":{"memory":1024}}}]}}');
    is($json->encode($pod->TO_JSON->{spec}{containers}[0]{resources}),
        '{"limits":{"cpu":"1"},"requests":{"memory":"1024"}}',
        'inflate {"cpu":1} -> TO_JSON {"cpu":"1"}');
};

subtest 'an AutoGen class writes its Quantity and Time values as strings' => sub {
    my $Q = '#/definitions/io.k8s.apimachinery.pkg.api.resource.Quantity';
    my $T = '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.Time';
    my $class = IO::K8s::AutoGen::get_or_generate('com.example.v1.K180Thing', {
        type       => 'object',
        properties => {
            capacity => { '$ref' => $Q },
            since    => { '$ref' => $T },
            usage    => { type => 'object', additionalProperties => { '$ref' => $Q } },
            stamps   => { type => 'array', items => { type => 'string', format => 'date-time' } },
        },
    }, {}, 'IO::K8s::_AUTOGEN_k180');
    # A generated Time accepts any string (k178), so a numeric one can reach
    # it; it still goes out as a string.
    my $obj = $class->new(capacity => 100, since => 20260927, usage => { cpu => 1 }, stamps => [1]);
    is($obj->to_json, '{"capacity":"100","since":"20260927","stamps":["1"],"usage":{"cpu":"1"}}',
        'scalar $ref Quantity / Time, a Quantity map and a date-time array');
};

done_testing;
