#!/usr/bin/env perl
# k35: close the residual shadow window left by k34 (GH
# pplu/io-k8s-p5#7 + #8), and stop new_object()/json_to_object() re-expanding a
# class name they already resolved.
#
# Two defects, in the order they have to be fixed:
#
# 1. RE-EXPANSION (the enabler)
#    new_object() called expand_class(), then handed the resolved class to
#    struct_to_object(), which called expand_class() on it AGAIN. The second
#    pass re-enters the whole search order, so a name that the first pass
#    resolved exactly gets re-interpreted. Observable today:
#
#        $k8s->new_object('+Secret', {...})   # '+' means "this exact class"
#
#    returns IO::K8s::Api::Core::V1::Secret, not the caller's Secret class:
#    expand_class('+Secret') strips the '+' to 'Secret', and the second pass
#    finds 'Secret' in the resource_map. The '+' guarantee is lost.
#
# 2. SHADOW WINDOW
#    A Kind that is not in the resource_map still reached the "is there a
#    loadable class of exactly this name?" probe before the IO::K8s:: relative
#    path and before AutoGen. So with an openapi_spec defining kind 'Widget'
#    and a top-level Widget.pm installed, expand_class('Widget') returned the
#    foreign CPAN module instead of the generated class -- the same class of
#    bug as GH #7/#8, one step further out.
#
#    The probe could not be tightened while (1) existed, because the
#    re-expansion of an already-resolved single-segment name depended on it.
#
# The fix: internal callers go through a private pre-expanded entry point, and
# the probe is restricted to multi-segment names ('My::StaticWebSite' -- the
# documented CRD case). A single-segment bare name is a Kubernetes Kind and
# resolves to IO::K8s::<Kind> / AutoGen, never to a same-named distribution.
# '+Name' still forces an exact class, including a single-segment one.
#
# Pure local fixtures -- no network, no cluster, no installed CPAN dist.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util ();
use File::Temp ();
use Path::Tiny;
use lib 'lib';
use IO::K8s;
use IO::K8s::AutoGen ();

# ----------------------------------------------------------------------------
# Fixture library: a temp dir unshifted onto @INC, holding the shadowing and
# the legitimately-full-named classes. Nothing here is loaded up front.
# ----------------------------------------------------------------------------

my $shadow_dir = File::Temp->newdir();
my $shadow_lib = "$shadow_dir";

sub _write_module {
    my ($module, $body) = @_;
    my @parts = split /::/, $module;
    my $file = path($shadow_lib, @parts) . '.pm';
    path($shadow_lib, @parts[0 .. $#parts - 1])->mkpath if @parts > 1;
    open my $fh, '>', $file or die "cannot write $file: $!";
    print $fh $body;
    close $fh or die "cannot close $file: $!";
    return $file;
}

# The shadow: a top-level distribution whose name happens to equal a Kind in
# the openapi_spec. Calling into it is the failure we are preventing.
_write_module('Widget', <<'SHADOW');
package Widget;
our $VERSION = '0.01';
sub new { die "shadow stub Widget::new() must never be called\n" }
1;
SHADOW

# A user CRD class whose package name collides with a SHIPPED Kind. Only
# reachable as '+Secret' -- the bare name belongs to core v1 and must keep
# belonging to it.
_write_module('Secret', <<'CRD_COLLIDING');
package Secret;
our $VERSION = '0.01';
use IO::K8s::APIObject
    api_version     => 'vendor.example.com/v1',
    resource_plural => 'secrets';
k8s spec => { Str => 1 };
1;
CRD_COLLIDING

# A single-segment CRD class that is NOT a shipped Kind and NOT in the
# openapi_spec: reachable only via '+Gadget' or a resource_map '+Gadget'
# value. Its 'spec' is declared as another single-segment class, so it also
# pins that _inflate_struct() resolves the attribute registry's class names
# without sending them back through expand_class().
_write_module('Gadgetspec', <<'INNER');
package Gadgetspec;
our $VERSION = '0.01';
use IO::K8s::Resource;
k8s size  => 'Str';
k8s count => 'Int';
1;
INNER

_write_module('Gadget', <<'CRD_PLAIN');
package Gadget;
our $VERSION = '0.01';
use IO::K8s::APIObject
    api_version     => 'vendor.example.com/v1',
    resource_plural => 'gadgets';
k8s spec => '+Gadgetspec';
1;
CRD_PLAIN

# The documented CRD case: a class named in full. Multi-segment names keep the
# loadable-class probe, and it still has to LOAD rather than merely test --
# a resource_map '+' value comes back from _resolve_mapped() unloaded.
_write_module('My::CustomSite', <<'CRD_FULL');
package My::CustomSite;
our $VERSION = '0.01';
use IO::K8s::APIObject
    api_version     => 'homelab.example.com/v1',
    resource_plural => 'customsites';
k8s spec => { Str => 1 };
1;
CRD_FULL

unshift @INC, $shadow_lib;

# The other _class_exists() branch: a package that exists in this process and
# was never written to disk. 'Gizmo' is also a Kind in the spec below.
{
    no strict 'refs';
    *{'Gizmo::new'} = sub { die "shadow package Gizmo::new() must never be called\n" };
}

# ----------------------------------------------------------------------------
# An openapi_spec that defines both shadowed Kinds.
# ----------------------------------------------------------------------------

my %SPEC = (
    definitions => {
        'com.example.v1.Widget' => {
            type => 'object',
            'x-kubernetes-group-version-kind' =>
                [ { group => 'example.com', version => 'v1', kind => 'Widget' } ],
            properties => {
                apiVersion => { type => 'string' },
                kind       => { type => 'string' },
                size       => { type => 'string' },
                replicas   => { type => 'integer' },
            },
        },
        'com.example.v1.Gizmo' => {
            type => 'object',
            'x-kubernetes-group-version-kind' =>
                [ { group => 'example.com', version => 'v1', kind => 'Gizmo' } ],
            properties => {
                apiVersion => { type => 'string' },
                kind       => { type => 'string' },
                colour     => { type => 'string' },
            },
        },
    },
);

sub _spec_k8s { IO::K8s->new(openapi_spec => { %SPEC }) }

sub _is_a {
    my ($obj, $class) = @_;
    return Scalar::Util::blessed($obj) && $obj->isa($class);
}

# ----------------------------------------------------------------------------

subtest 'harness: the fixture lib is on @INC and the shadows are real' => sub {
    ok(path($shadow_lib, 'Widget.pm')->exists, 'Widget.pm exists on disk');
    ok(!exists $INC{'Widget.pm'}, 'Widget.pm is loadable but not yet loaded');
    ok(Gizmo->can('new'), 'Gizmo exists in the symbol table only');

    # Positive control for @INC reachability, and the behaviour the probe is
    # kept for: a class named in full loads and comes back verbatim.
    my $io = IO::K8s->new;
    is($io->expand_class('My::CustomSite'), 'My::CustomSite',
        'a multi-segment class name still resolves to itself');
    ok(exists $INC{'My/CustomSite.pm'},
        'and expand_class loaded it from the fixture lib');
};

# ---- part 2: no re-expansion of an already-resolved class -------------------

subtest "k35/2: '+Name' survives new_object, even when Name is a Kind" => sub {
    my $io = IO::K8s->new;

    is($io->expand_class('+Secret'), 'Secret',
        "expand_class('+Secret') is the exact class");

    # THE BUG: struct_to_object() re-expanded 'Secret', the resource_map
    # answered, and the caller got a core v1 Secret instead of their own class.
    my $obj;
    lives_ok {
        $obj = $io->new_object('+Secret', { spec => { token => 'abc' } });
    } "new_object('+Secret') does not die";
    isa_ok($obj, 'Secret', "new_object('+Secret')");
    ok(!_is_a($obj, 'IO::K8s::Api::Core::V1::Secret'),
        'and it is NOT the shipped core v1 Secret');

    # Same defect through the JSON entry point.
    my $from_json;
    lives_ok {
        $from_json = $io->json_to_object('+Secret', '{"spec":{"token":"abc"}}');
    } "json_to_object('+Secret', \$json) does not die";
    isa_ok($from_json, 'Secret', "json_to_object('+Secret')");

    # struct_to_object() called directly only ever expanded once, so this held
    # before the fix too -- it pins that the public entry point still expands.
    isa_ok($io->struct_to_object('+Secret', { spec => { token => 'abc' } }),
        'Secret', "struct_to_object('+Secret')");

    SKIP: {
        skip 'the +Secret object is not the CRD class', 3 unless _is_a($obj, 'Secret');
        my $wire = $io->object_to_struct($obj);
        is($wire->{apiVersion}, 'vendor.example.com/v1',
            'the CRD serializes its own apiVersion');
        # k38: kind() falls back to the bare class name when there is no
        # '::' to split on, so a single-segment package -- the shape this
        # subtest makes reachable -- serializes a manifest the cluster accepts
        # rather than one with no kind: at all. Details in t/54.
        is($wire->{kind}, 'Secret', 'and its kind, from the bare package name');
        is($wire->{spec}{token}, 'abc', 'and the spec payload');
    }

    # The bare name is untouched: it is a shipped Kind and stays one.
    is($io->expand_class('Secret'), 'IO::K8s::Api::Core::V1::Secret',
        "expand_class('Secret') is still the core v1 Kind");
};

subtest 'k35/2: a single-segment class reached only through +' => sub {
    my $io = IO::K8s->new;

    ok(!exists $INC{'Gadget.pm'}, 'Gadget.pm starts out unloaded');

    my $obj;
    lives_ok {
        $obj = $io->new_object('+Gadget', { spec => { size => 'l', count => 3 } });
    } "new_object('+Gadget') constructs a class that is not in the map";
    isa_ok($obj, 'Gadget', "new_object('+Gadget')");

    SKIP: {
        skip 'Gadget did not construct', 3 unless _is_a($obj, 'Gadget');
        # _inflate_struct() routes the attribute registry's class names
        # ('Gadgetspec' here) without re-expanding them.
        isa_ok($obj->spec, 'Gadgetspec', 'inner k8s attribute class');
        my $wire = $io->object_to_struct($obj);
        is($wire->{spec}{size}, 'l', 'inner struct survives serialization');
        is($wire->{spec}{count}, 3, 'and its Int field');
    }
};

subtest "k35/2: a resource_map '+Single' value resolves and loads" => sub {
    # The exact path the ticket names: a map entry whose value is a
    # '+'-prefixed SINGLE-SEGMENT class. _resolve_mapped() returns it
    # unloaded, so nothing may send it back through expand_class().
    my $io = IO::K8s->new(resource_map => {
        %{ IO::K8s->default_resource_map },
        Doohickey => '+Gadget',
    });

    is($io->expand_class('Doohickey'), 'Gadget',
        'the mapped short name resolves to the exact class');

    my $obj;
    lives_ok {
        $obj = $io->new_object('Doohickey', { spec => { size => 'xl', count => 1 } });
    } "new_object through a '+Single' map value works";
    isa_ok($obj, 'Gadget', 'mapped object');

    SKIP: {
        skip 'Doohickey did not construct as Gadget', 1 unless _is_a($obj, 'Gadget');
        is($io->object_to_struct($obj)->{apiVersion}, 'vendor.example.com/v1',
            'and serializes its own apiVersion');
    }
};

# ---- part 1: the shadow window is closed -----------------------------------

subtest 'k35/1: an openapi_spec Kind beats a same-named distribution' => sub {
    my $io = _spec_k8s();

    my $class = $io->expand_class('Widget');
    isnt($class, 'Widget', "expand_class('Widget') is not the shadowing package");
    ok(IO::K8s::AutoGen::is_autogen($class),
        "expand_class('Widget') generated a class from the spec")
        or diag "got: $class";
    ok(!exists $INC{'Widget.pm'}, 'the shadowing Widget.pm was never loaded');

    my $obj;
    lives_ok { $obj = $io->new_object('Widget', { size => 'small', replicas => 2 }) }
        "new_object('Widget') does not die under a shadowing Widget package";
    isa_ok($obj, $class, 'constructed Widget');

    SKIP: {
        skip 'Widget did not construct as the generated class', 2
            unless _is_a($obj, $class);
        my $wire = $io->object_to_struct($obj);
        is($wire->{size}, 'small', 'generated attributes round-trip');
        is($wire->{replicas}, 2, 'including the Int one');
    }

    # And the wire direction, apiVersion supplied.
    my $inflated;
    lives_ok {
        $inflated = $io->inflate({
            apiVersion => 'example.com/v1',
            kind       => 'Widget',
            size       => 'large',
        });
    } 'inflate() of a Widget manifest does not die under shadowing';
    ok(IO::K8s::AutoGen::is_autogen(ref($inflated) || ''),
        'inflate() produced the generated class');

    ok(!exists $INC{'Widget.pm'}, 'still never loaded Widget.pm');
};

subtest 'k35/1: same for a shadow that is only in the symbol table' => sub {
    my $io = _spec_k8s();

    my $class = $io->expand_class('Gizmo');
    isnt($class, 'Gizmo', "expand_class('Gizmo') ignores the in-memory package");
    ok(IO::K8s::AutoGen::is_autogen($class), 'and generated from the spec')
        or diag "got: $class";

    my $obj;
    lives_ok { $obj = $io->new_object('Gizmo', { colour => 'red' }) }
        "new_object('Gizmo') does not die under an in-memory Gizmo package";
    isa_ok($obj, $class, 'constructed Gizmo');
};

subtest 'k35/1: without a spec, a bare Kind falls back to IO::K8s::' => sub {
    my $io = IO::K8s->new;   # no openapi_spec

    is($io->expand_class('Widget'), 'IO::K8s::Widget',
        'the documented IO::K8s:: fallback, not the shadowing package');
    is(IO::K8s->expand_class('Widget'), 'IO::K8s::Widget',
        'class-method path agrees');
    ok(!exists $INC{'Widget.pm'}, 'and nothing loaded the shadowing package');

    throws_ok { $io->new_object('Widget', {}) } qr{IO/K8s/Widget\.pm},
        'new_object fails on the IO::K8s:: name rather than building a foreign class';

    # '+' is the documented escape hatch and still forces the exact class.
    is($io->expand_class('+Widget'), 'Widget', "'+Widget' still forces the package");
};

subtest 'k35/1: multi-segment names keep the loadable-class probe' => sub {
    my $io = IO::K8s->new;

    is($io->expand_class('My::CustomSite'), 'My::CustomSite',
        'a CRD class named in full resolves to itself');

    my $site;
    lives_ok {
        $site = $io->new_object('My::CustomSite', { spec => { domain => 'blog' } });
    } 'and constructs';
    isa_ok($site, 'My::CustomSite', 'full-name CRD object');

    # Through a resource_map '+' value, which _resolve_mapped returns unloaded.
    my $mapped = IO::K8s->new(resource_map => {
        %{ IO::K8s->default_resource_map },
        CustomSite => '+My::CustomSite',
    });
    isa_ok($mapped->new_object('CustomSite', { spec => { domain => 'blog' } }),
        'My::CustomSite', "mapped '+My::CustomSite' object");

    # class_namespaces stays a working route for single-segment names.
    my $ns_io = IO::K8s->new(class_namespaces => ['My']);
    is($ns_io->expand_class('CustomSite'), 'My::CustomSite',
        'class_namespaces still resolves a bare name to a user class');
};

done_testing;
