#!/usr/bin/env perl
# k34 / GitHub pplu/io-k8s-p5#7 + #8: a bare Kind must resolve through the
# resource_map, never to a same-named top-level CPAN module that happens to be
# installed.
#
# Reported from CPAN smokers that had the Event or Role distributions
# installed. expand_class() checked "is there a class of this name?" BEFORE the
# resource_map, and that check does not merely test — it require_module()s the
# name. So expand_class('Event') loaded CPAN's Event.pm and returned "Event";
# the model then died downstream in _k8s_attr_info, differently per stub:
#
#   Role   (plain package)    Can't locate object method "_k8s_attr_info" via package "Role"
#   Event  (has an AUTOLOAD)  Can't locate Event/_k8s_attr_info.pm in @INC
#
# This test creates the shadowing condition itself — stub modules written to a
# temp dir that it puts on @INC, plus one package installed straight into the
# symbol table — so it reproduces without anything from the environment.
#
# What is asserted, beyond name resolution: that objects still BUILD and
# SERIALIZE as the right class under shadowing (the failure the smokers
# actually saw), and that the behaviour the moved check exists for — a CRD
# class named in full and not yet loaded — still resolves, by loading it.
#
# Pure local fixtures — no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util ();
use File::Temp ();
use Path::Tiny;
use lib 'lib';
use IO::K8s;

# ----------------------------------------------------------------------------
# Build the shadowing condition.
#
# Kind short names that really do collide with top-level CPAN distributions.
# Each gets a stub module in a temp dir which is then unshifted onto @INC, so
# the name is loadable but NOT loaded — exactly the smoker's situation.
# 'Node' is deliberately left off disk: it is installed into the symbol table
# instead, to cover _class_exists()'s other branch ($class->can('new')).
# ----------------------------------------------------------------------------

my %EXPECTED = (
    Event   => 'IO::K8s::Api::Core::V1::Event',
    Role    => 'IO::K8s::Api::Rbac::V1::Role',
    Job     => 'IO::K8s::Api::Batch::V1::Job',
    Node    => 'IO::K8s::Api::Core::V1::Node',
    Binding => 'IO::K8s::Api::Core::V1::Binding',
    Scale   => 'IO::K8s::Api::Autoscaling::V1::Scale',
    Secret  => 'IO::K8s::Api::Core::V1::Secret',
    Service => 'IO::K8s::Api::Core::V1::Service',
);

my @ON_DISK = qw(Event Role Job Binding Scale Secret Service);

my $shadow_dir = File::Temp->newdir();
my $shadow_lib = "$shadow_dir";

# Guard for the post-construction assertions: without the fix the object is
# undef or a foreign package, and calling into it dies mid-file.
sub _is_a {
    my ($obj, $class) = @_;
    return Scalar::Util::blessed($obj) && $obj->isa($class);
}

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

for my $name (@ON_DISK) {
    next if $name eq 'Event';
    # Plain stub: the 'Role' flavour. can('new') is true once loaded, and
    # calling anything the model needs blows up with a plain method error.
    _write_module($name, <<"PLAIN");
package $name;
our \$VERSION = '0.01';
sub new { die "shadow stub $name\::new() must never be called\\n" }
1;
PLAIN
}

# The 'Event' flavour: an AUTOLOAD, which turns the missing-method death into
# the confusing "Can't locate Event/_k8s_attr_info.pm in \@INC" of GH #7.
_write_module('Event', <<'AUTOLOADED');
package Event;
our $VERSION = '0.01';
our $AUTOLOAD;
sub AUTOLOAD {
    my $n = $AUTOLOAD;
    $n =~ s/.*:://;
    return if $n eq 'DESTROY';
    die "Can't locate Event/$n.pm in \@INC (shadow stub AUTOLOAD)\n";
}
1;
AUTOLOADED

# Not a Kubernetes Kind: the positive control. Proves the temp dir really is
# reachable through @INC, and pins the behaviour the moved check exists for —
# a loadable class named in full still passes through expand_class untouched.
#
# Multi-segment on purpose. This control used to be the single-segment
# 'NotAKubernetesKind'; k35 took single-segment names off the
# loadable-class check entirely (a one-word bare name is a Kind, never a
# distribution), so only a namespaced name still demonstrates the check.
# The single-segment half of the old claim is now asserted the other way
# round, below and in t/52_expand_class_shadow_window.t.
_write_module('Not::AKubernetesKind', <<'PROBE');
package Not::AKubernetesKind;
our $VERSION = '0.01';
sub new { bless {}, shift }
1;
PROBE

# Single-segment counterpart, same shape, to show the difference directly.
_write_module('NotAKubernetesKind', <<'PROBE');
package NotAKubernetesKind;
our $VERSION = '0.01';
sub new { bless {}, shift }
1;
PROBE

# A real CRD class, on disk and unloaded, reachable only as a resource_map
# '+' value. _resolve_mapped() returns that value without loading it, so
# struct_to_object()'s re-expansion has to load it — the reason the moved
# check must keep its require_module() semantics rather than becoming a
# pure "is it already loaded?" test.
_write_module('My::Shadow::Widget', <<'CRD');
package My::Shadow::Widget;
our $VERSION = '0.01';
use IO::K8s::APIObject
    api_version     => 'shadow.example.com/v1',
    resource_plural => 'widgets';
k8s spec => { Str => 1 };
1;
CRD

unshift @INC, $shadow_lib;

# The symbol-table flavour: no file anywhere, the package simply exists in
# this process. _class_exists() short-circuits on can('new') before it ever
# reaches require_module.
{
    no strict 'refs';
    *{'Node::new'} = sub { die "shadow package Node::new() must never be called\n" };
}

# ----------------------------------------------------------------------------

subtest 'harness: the shadows are real and a non-Kind class still passes through'
=> sub {
    my $io = IO::K8s->new;

    ok(!exists $INC{'Role.pm'}, 'Role.pm is loadable but not yet loaded');
    ok(Node->can('new'), 'Node exists in the symbol table');

    # Positive control: this name is NOT in the resource_map, so it reaches the
    # loadable-class check, loads from the temp dir and is returned verbatim.
    # If this fails the shadow lib is not on @INC and the rest proves nothing.
    is($io->expand_class('Not::AKubernetesKind'), 'Not::AKubernetesKind',
        'a loadable multi-segment class name still resolves to itself');
    ok(exists $INC{'Not/AKubernetesKind.pm'},
        'and it was actually loaded from the shadow lib');

    # k35: the same module under a single-segment name does NOT. A bare
    # one-word name is read as a Kind, so it goes to IO::K8s::<Kind> (and on
    # to AutoGen when a spec is configured) and never touches @INC.
    is($io->expand_class('NotAKubernetesKind'), 'IO::K8s::NotAKubernetesKind',
        'a single-segment name is a Kind, not a distribution');
    ok(!exists $INC{'NotAKubernetesKind.pm'},
        'and resolving it never loaded the same-named module');
};

subtest 'plain shadow stub: Role resolves and builds as the RBAC class' => sub {
    my $io = IO::K8s->new;

    is($io->expand_class('Role'), 'IO::K8s::Api::Rbac::V1::Role',
        "expand_class('Role') is the RBAC Kind, not the installed Role package");

    # The t/26_build_verify.t failure: construction died in _k8s_attr_info.
    my $role;
    lives_ok {
        $role = $io->new_object('Role', {
            metadata => { name => 'secret-reader', namespace => 'app' },
            rules    => [{
                apiGroups => [''],
                resources => ['secrets'],
                verbs     => [qw(get list watch)],
            }],
        });
    } 'new_object("Role") does not die under a shadowing Role package';
    isa_ok($role, 'IO::K8s::Api::Rbac::V1::Role', 'constructed Role');

    # SKIP so that a regression reports as failures here instead of dying
    # mid-file and taking the Event subtest below with it.
    SKIP: {
        skip 'Role did not construct as the RBAC class', 4
            unless _is_a($role, 'IO::K8s::Api::Rbac::V1::Role');

        my $wire = $io->object_to_struct($role);
        is($wire->{kind}, 'Role', 'serializes kind Role');
        is($wire->{apiVersion}, 'rbac.authorization.k8s.io/v1',
            'serializes the RBAC apiVersion');
        is($wire->{rules}[0]{verbs}[2], 'watch', 'rules survive the round trip');

        # A RoleBinding referencing a Role: 'Role' as a plain roleRef.kind
        # string must stay a string and must not drag the shadowed package in.
        my $binding = $io->new_object('RoleBinding', {
            metadata => { name => 'read-secrets', namespace => 'app' },
            roleRef  => {
                kind     => 'Role',
                name     => 'secret-reader',
                apiGroup => 'rbac.authorization.k8s.io',
            },
            subjects => [{ kind => 'ServiceAccount', name => 'app-sa', namespace => 'app' }],
        });
        is($io->object_to_struct($binding)->{roleRef}{kind}, 'Role',
            'RoleBinding roleRef.kind round-trips');
    }

    # The point of the fix: a Kind in the resource_map is answered from the
    # map, so the foreign module is never even looked for.
    ok(!exists $INC{'Role.pm'},
        'resolving the Kind never loaded the shadowing Role.pm');
};

subtest 'AUTOLOAD shadow stub: Event resolves and inflates as Core v1' => sub {
    my $io = IO::K8s->new;

    is($io->expand_class('Event'), 'IO::K8s::Api::Core::V1::Event',
        "expand_class('Event') is the Core v1 Kind, not the installed Event package");

    # The t/43_spec_kind_dispatch.t failure: bare Event, no apiVersion.
    my $event;
    lives_ok {
        $event = $io->new_object('Event', {
            metadata       => { name => 'legacy-event' },
            involvedObject => { kind => 'Pod', name => 'pod-1', namespace => 'default' },
        });
    } 'new_object("Event") does not die under a shadowing Event package';
    isa_ok($event, 'IO::K8s::Api::Core::V1::Event', 'constructed Event');

    # And the inflate direction, apiVersion supplied.
    my $inflated;
    lives_ok {
        $inflated = $io->inflate({
            apiVersion     => 'v1',
            kind           => 'Event',
            metadata       => { name => 'from-wire' },
            involvedObject => { kind => 'Pod', name => 'pod-1' },
        });
    } 'inflate() of an Event manifest does not die under shadowing';
    isa_ok($inflated, 'IO::K8s::Api::Core::V1::Event', 'inflated Event');

    SKIP: {
        skip 'Event did not inflate as the Core v1 class', 1
            unless _is_a($inflated, 'IO::K8s::Api::Core::V1::Event');
        is($io->object_to_struct($inflated)->{involvedObject}{name}, 'pod-1',
            'involvedObject survives the round trip');
    }

    ok(!exists $INC{'Event.pm'},
        'resolving the Kind never loaded the shadowing Event.pm');
};

subtest 'shadow already in the symbol table: Node still resolves' => sub {
    my $io = IO::K8s->new;

    # Node was never written to disk — can('new') is true, so _class_exists
    # short-circuits without touching @INC. The map still has to win.
    is($io->expand_class('Node'), 'IO::K8s::Api::Core::V1::Node',
        "expand_class('Node') ignores the in-memory Node package");
    my $node;
    lives_ok { $node = $io->new_object('Node', { metadata => { name => 'worker-1' } }) }
        'new_object("Node") does not die under a shadowing Node package';
    isa_ok($node, 'IO::K8s::Api::Core::V1::Node', 'constructed Node');

    # Same again for a stub that IS loaded, not just loadable: load Role for
    # real, then re-resolve. Pre-fix this was the other half of the bug.
    require Role;
    ok(exists $INC{'Role.pm'}, 'Role.pm is now genuinely loaded');
    is($io->expand_class('Role'), 'IO::K8s::Api::Rbac::V1::Role',
        'a loaded shadow package still loses to the resource_map');
};

subtest 'every realistic collision short name resolves to its Kind' => sub {
    my $io = IO::K8s->new;
    for my $kind (sort keys %EXPECTED) {
        is($io->expand_class($kind), $EXPECTED{$kind},
            "expand_class('$kind') resolves to $EXPECTED{$kind}");
        # Class-method call path too — it uses %DEFAULT_RESOURCE_MAP directly.
        is(IO::K8s->expand_class($kind), $EXPECTED{$kind},
            "IO::K8s->expand_class('$kind') resolves to $EXPECTED{$kind}");
    }
};

subtest 'a full CRD class name that is loadable but unloaded still resolves' => sub {
    # Registered as a bare '+' value straight on resource_map, so nothing
    # loads it up front (add()/with() would, via _qualify_class_path).
    my $io = IO::K8s->new(resource_map => {
        %{ IO::K8s->default_resource_map },
        Widget => '+My::Shadow::Widget',
    });

    ok(!exists $INC{'My/Shadow/Widget.pm'},
        'the CRD class starts out unloaded');

    is($io->expand_class('My::Shadow::Widget'), 'My::Shadow::Widget',
        'a full class name resolves to itself');
    ok(exists $INC{'My/Shadow/Widget.pm'},
        'and expand_class loaded it — the check tests loadable, not loaded');

    my $widget;
    lives_ok {
        $widget = $io->new_object('Widget', { spec => { size => 'large' } });
    } 'new_object through the mapped short name works';
    isa_ok($widget, 'My::Shadow::Widget', 'constructed CRD object');

    SKIP: {
        skip 'Widget did not construct as the CRD class', 1
            unless _is_a($widget, 'My::Shadow::Widget');
        is($io->object_to_struct($widget)->{apiVersion}, 'shadow.example.com/v1',
            'CRD serializes its own apiVersion');
    }
};

done_testing;
