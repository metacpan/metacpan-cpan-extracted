#!/usr/bin/env perl
# D2: SpecBuilder on typed specs -- inline structs, referenced classes,
# arrays of objects -- plus the k90 regression and the unchanged hash path.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s;

{
    package TestSB::Route;
    use IO::K8s::Resource;
    k8s match    => Str;
    k8s priority => Int;
}

{
    package TestSB::Guarded;
    use IO::K8s::Resource;
    k8s must => Str, 'required';
}

{
    package TestSB::Widget;
    use IO::K8s::APIObject
        api_version     => 'test.example.com/v1',
        resource_plural => 'widgets';
    with 'IO::K8s::Role::Namespaced';

    k8s spec => {
        replicas    => Int,
        tls         => { secretName => Str, options => { Str => 1 } },
        routes      => ['+TestSB::Route'],
        template    => 'Core::V1::PodTemplateSpec',
        labels      => { Str => 1 },
        guarded     => '+TestSB::Guarded',
        '$ref'      => Str,
        nums        => [Num],
        quantities  => [Quantity],
        times       => [Time],
        intOrStrs   => [IntOrStr],
    };
}

{
    # A genuinely opaque hash spec, kept local to this test rather than
    # borrowed from a real provider class: every bundled provider's Kinds
    # have gone to full-depth typed modeling (k95/D5) in turn -- Traefik's
    # IngressRoute, Cilium's CiliumNetworkPolicy, Gateway API's GatewayClass
    # and now K3s's HelmChart -- so there is no longer a shipped class this
    # subtest can rely on staying an opaque `{ Str => 1 }` spec.
    package TestSB::OpaqueThing;
    use IO::K8s::APIObject
        api_version     => 'test.example.com/v1',
        resource_plural => 'opaquethings';
    with 'IO::K8s::Role::Namespaced';

    k8s spec => { Str => 1 };
}

sub widget {
    my (%spec) = @_;
    return TestSB::Widget->FROM_HASH({
        metadata => { name => 'w' },
        (%spec ? (spec => \%spec) : ()),
    });
}

subtest 'k90: spec_set on a modeled spec keeps the spec' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $s = $k8s->new_object('Sandbox',
        metadata => { name => 'x', namespace => 'd' },
        spec     => { shutdownPolicy => 'Retain' },
    );
    is($s->spec_get('shutdownPolicy'), 'Retain', 'spec_get reads through the struct');
    $s->spec_set('shutdownPolicy', 'Delete');
    is($s->TO_JSON->{spec}{shutdownPolicy}, 'Delete', 'spec_set writes through the struct');
    # v1beta1 is now modeled to full depth (D5/D6, k95): spec is the named
    # SandboxSpec class, not an anonymous inline struct, and operatingMode
    # carries the real upstream enum (Running/Suspended) instead of a bare Str.
    isa_ok($s->spec, 'IO::K8s::AgentSandbox::V1beta1::SandboxSpec', 'spec is still the struct');
    $s->spec_merge(operatingMode => 'Suspended');
    is_deeply($s->TO_JSON->{spec}, { shutdownPolicy => 'Delete', operatingMode => 'Suspended' }, 'spec_merge keeps existing fields');
};

subtest 'spec_get walks structs, objects and arrays' => sub {
    my $w = widget(
        replicas => 2,
        tls      => { secretName => 's', options => { minVersion => '1.2' } },
        routes   => [ { match => 'a', priority => 1 }, { match => 'b', priority => 2 } ],
    );
    is($w->spec_get('replicas'), 2, 'scalar');
    is($w->spec_get('tls.secretName'), 's', 'inline struct field');
    is($w->spec_get('tls.options.minVersion'), '1.2', 'opaque map under a struct');
    is($w->spec_get('routes.1.match'), 'b', 'array index into objects');
    is($w->spec_get('routes.-1.priority'), 2, '-1 is the last element');
    isa_ok($w->spec_get('routes.0'), 'TestSB::Route', 'an object node is returned as is');
    is($w->spec_get('nope'), undef, 'undeclared, unset');
    is($w->spec_get('tls.nope'), undef, 'undeclared nested, unset');
    is($w->spec_get('replicas.deeper'), undef, 'cannot descend a scalar on read');
};

subtest 'spec_set vivifies typed intermediates' => sub {
    my $w = widget();
    ok(!$w->spec, 'starts without spec');
    $w->spec_set('tls.secretName', 'x');
    isa_ok($w->spec, 'TestSB::Widget::_Spec', 'spec vivified as the declared struct');
    isa_ok($w->spec->tls, 'TestSB::Widget::_Spec::_Tls', 'tls vivified as its struct');
    is($w->TO_JSON->{spec}{tls}{secretName}, 'x', 'and the value is on the wire');

    $w->spec_set('template.metadata.labels.app', 'web');
    isa_ok($w->spec->template, 'IO::K8s::Api::Core::V1::PodTemplateSpec', 'referenced class vivified');
    isa_ok($w->spec->template->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta', 'nested referenced class vivified');
    is($w->spec_get('template.metadata.labels.app'), 'web', 'deep write through referenced classes reads back');

    $w->spec_set('labels.app', 'web');
    is_deeply($w->spec->labels, { app => 'web' }, 'opaque map vivified as a hash');

    $w->spec_set('$ref', 'r');
    is($w->TO_JSON->{spec}{'$ref'}, 'r', 'a sanitized JSON key is addressed by its JSON name');
};

subtest 'spec_set through typed slots validates and inflates' => sub {
    my $w = widget();
    throws_ok { $w->spec_set('replicas', 'abc') } qr/replicas|Int/, 'type constraint of the declared field applies';
    $w->spec_set('tls', { secretName => 'y' });
    isa_ok($w->spec->tls, 'TestSB::Widget::_Spec::_Tls', 'a hashref handed to a struct slot is inflated');
    $w->spec_set('routes', [ { match => 'm', priority => 3 } ]);
    isa_ok($w->spec->routes->[0], 'TestSB::Route', 'hashrefs handed to an array-of-objects slot are inflated');
    throws_ok { $w->spec_set('replicas.deeper', 1) } qr/cannot descend through scalar field 'replicas'/, 'descending a scalar on write croaks';
};

subtest 'spec_push onto arrays of objects' => sub {
    my $w = widget();
    $w->spec_push('routes', { match => 'a', priority => 1 }, TestSB::Route->new(match => 'b', priority => 2));
    isa_ok($w->spec->routes->[0], 'TestSB::Route', 'hashref element inflated');
    isa_ok($w->spec->routes->[1], 'TestSB::Route', 'object element kept');
    is($w->spec_get('routes.-1.match'), 'b', 'pushed in order');
    $w->spec_set('routes.-1.priority', 9);
    is($w->spec->routes->[1]->priority, 9, '-1 writes the last element');
};

subtest '-1 on an empty array creates the element' => sub {
    my $w = widget();
    $w->spec_set('routes.-1.match', 'first');
    is(scalar @{ $w->spec->routes }, 1, 'one element created');
    isa_ok($w->spec->routes->[0], 'TestSB::Route', 'as the element class');
    is($w->spec_get('routes.0.match'), 'first', 'with the value');
    throws_ok { $w->spec_set('routes.-3.match', 'x') } qr/index -3/, 'other negative indices are out of range';
};

subtest 'undeclared keys on a struct land in the bag (D1)' => sub {
    my $w = widget(replicas => 1);
    $w->spec_set('bogus.deep', 1);
    is($w->TO_JSON->{spec}{bogus}{deep}, 1, 'written through the bag and emitted');
    is($w->spec_get('bogus.deep'), 1, 'and readable');
    $w->spec_delete('bogus');
    ok(!exists $w->TO_JSON->{spec}{bogus}, 'spec_delete removes a bag entry');
};

subtest 'spec_delete on structs and arrays' => sub {
    my $w = widget(replicas => 1, tls => { secretName => 's' }, routes => [ { match => 'a' }, { match => 'b' } ]);
    $w->spec_delete('tls.secretName');
    is($w->spec->tls->secretName, undef, 'declared field cleared');
    $w->spec_delete('routes.0');
    is($w->spec_get('routes.0.match'), 'b', 'array element spliced');
    $w->spec_delete('nothing.here');
    pass('missing path is a no-op');
};

subtest 'spec_merge on a struct: declared and undeclared' => sub {
    my $w = widget(replicas => 1);
    $w->spec_merge(replicas => 5, extra => 'e');
    is($w->spec->replicas, 5, 'declared field set through the accessor');
    is($w->TO_JSON->{spec}{extra}, 'e', 'undeclared field preserved');
};

subtest 'spec_array and spec_hash vivify and return the container' => sub {
    my $w = widget();
    my $routes = $w->spec_array('routes');
    is(ref $routes, 'ARRAY', 'array vivified');
    is($routes, $w->spec->routes, 'and it is the attribute value itself');
    my $labels = $w->spec_hash('labels');
    $labels->{a} = 'b';
    is($w->TO_JSON->{spec}{labels}{a}, 'b', 'in-place edits of the returned hash reach the wire');
    isa_ok($w->spec_hash('tls'), 'TestSB::Widget::_Spec::_Tls', 'spec_hash on a struct slot returns the struct');
    throws_ok { $w->spec_array('replicas') } qr/holds a non-array value|replicas/, 'spec_array on a scalar slot croaks';
};

subtest 'plain hash specs behave as before' => sub {
    my $gc = TestSB::OpaqueThing->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'r'),
    );
    $gc->spec_set('rules.-1.match', 'Host(`a`)');
    $gc->spec_push('rules.-1.services', { name => 'svc', port => 80 });
    is_deeply($gc->spec, { rules => [ { match => 'Host(`a`)', services => [ { name => 'svc', port => 80 } ] } ] }, 'hash path with -1 vivification');
    is_deeply($gc->spec_array('entryPoints'), [], 'spec_array on a hash spec');
};

subtest 'spec_set croaks with the spec path when vivifying a required-attribute class (k101)' => sub {
    my $w = widget();
    throws_ok { $w->spec_set('guarded.must', 'x') }
        qr/^spec path 'guarded\.must': cannot create TestSB::Guarded for 'guarded': Missing required arguments: must/,
        'vivifying a class with a required attribute croaks naming the path and the class';
    unlike($@, qr/SpecBuilder\.pm line \d+/, 'no internal file/line leaks');
    $w->spec_set('guarded', TestSB::Guarded->new(must => 'x'));
    is($w->spec_get('guarded.must'), 'x', 'building the object first and assigning it works');
};

subtest 'spec_set re-raises a type-constraint failure with the spec path (k101)' => sub {
    my $w = widget();
    throws_ok { $w->spec_set('replicas', 'abc') }
        qr/^spec path 'replicas': cannot set 'replicas':.*Int/s,
        'the accessor failure is prefixed with the path and keeps the original Type::Tiny text';
    unlike($@, qr/SpecBuilder\.pm line \d+/, 'no internal file/line leaks');
};

subtest 'spec_delete re-raises a clear failure with the spec path (k101)' => sub {
    my $w = widget();
    $w->spec_set('guarded', TestSB::Guarded->new(must => 'x'));
    throws_ok { $w->spec_delete('guarded.must') }
        qr/^spec path 'guarded\.must': cannot clear 'must':/,
        'clearing a required attribute croaks naming the path';
    unlike($@, qr/SpecBuilder\.pm line \d+/, 'no internal file/line leaks');
};

subtest 'k111: -1 vivification of [Num]/[Quantity]/[Time]/[IntOrStr] fields' => sub {
    # _sb_fresh only reaches its array-shape grep when a segment must be
    # vivified so the walk can descend PAST it -- which for a scalar-element
    # array only happens when addressing an index into it while it is still
    # unset, e.g. the 'routes.-1...' idiom the object-array test above uses.
    # spec_push/spec_array never hit this: both always build [] directly for
    # the FINAL segment of their own path, with no call into _sb_fresh, so a
    # bare spec_push/spec_array on a freshly-unset top-level field already
    # worked before this fix. Before the fix, _sb_fresh's array-shape grep
    # list knew only is_array_of_objects/str/int/bool/hash/array, so
    # '-1' addressed into an unset [Num]/[Quantity]/[Time]/[IntOrStr] field
    # -- the four flags k96 added -- fell through to the "cannot descend
    # through scalar field" croak even though the field is a genuine array.
    my $w = widget();
    is($w->spec_get('quantities'), undef, 'unset before vivification');
    $w->spec_set('quantities.-1', '500m');
    is_deeply($w->spec->quantities, ['500m'], "'-1' vivifies [Quantity] as an array and sets the new element");
    is($w->TO_JSON->{spec}{quantities}[0], '500m', 'round-trips onto the wire');

    $w->spec_set('nums.-1', 3.14);
    is_deeply($w->spec->nums, [3.14], "'-1' vivifies [Num]");

    $w->spec_set('times.-1', '2026-09-04T00:00:00Z');
    is_deeply($w->spec->times, ['2026-09-04T00:00:00Z'], "'-1' vivifies [Time]");

    $w->spec_set('intOrStrs.-1', '25%');
    is_deeply($w->spec->intOrStrs, ['25%'], "'-1' vivifies [IntOrStr]");

    # spec_push/spec_array on a still-unset field were never affected by the
    # bug (see comment above), but are exercised here too since they are the
    # ticket's named entry points -- on a second, independent field so this
    # does not depend on the vivification above.
    my $w2 = widget();
    is_deeply($w2->spec_array('quantities'), [], 'spec_array on a fresh [Quantity] field returns []');
    $w2->spec_push('quantities', '250m');
    is_deeply($w2->spec->quantities, ['250m'], 'spec_push onto it appends');
};

done_testing;
