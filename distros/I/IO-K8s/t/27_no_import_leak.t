#!/usr/bin/env perl
# Import leaks, in both directions.
#
# 1. The import direction (original): `use`-ing an IO::K8s class from a
#    foreign package must not leak the k8s DSL or Moo sugar into that
#    package. IO::K8s::Resource::import is deliberately narrow.
#
# 2. The composition direction (k118): a role must not compose its own
#    imports onto its consumers. Role::Tiny snapshots the role package's
#    stash at `use Moo::Role` time; anything imported *after* that line
#    counts as a concrete method of the role and is installed on every
#    consumer. Before k118 that put blessed/croak/InstanceOf/Maybe (from
#    IO::K8s::Role::APIObject), use_module (from IO::K8s::Role::SpecBuilder,
#    composed onto every APIObject since k103), cidr_contains (from
#    IO::K8s::Role::NetworkPolicy) and HashRef/blessed (from
#    IO::K8s::Role::Resource, so on every shipped class) on the public
#    surface. The fix hoists every import above `use Moo::Role`.
#
#    k119 closed the same leak where it came from a class's own `use Moo`
#    file rather than from a role -- see 2b, where both are swept together.
#
# Part 1 alone could never catch part 2: it asserts what a *foreign*
# package does not receive, never what a Kind class itself can do.

use strict;
use warnings;
use Test::More;

use B ();
use File::Find;
use Moo::Role ();
use lib 'lib';

# ---------------------------------------------------------------------------
# 1. The import direction
# ---------------------------------------------------------------------------

{
    package My::App;
    use Moo;
    use IO::K8s::Api::Core::V1::Secret;

    has k8s => (is => 'ro');
}

ok(My::App->can('k8s'), 'My::App has k8s accessor');
ok(!My::App->does('IO::K8s::Role::Resource'),
    'My::App does NOT compose IO::K8s::Role::Resource');

my $app = My::App->new(k8s => 'hello');
is($app->k8s, 'hello', 'k8s accessor works normally');

# ---------------------------------------------------------------------------
# 2a. The composition direction, structurally.
#
# Apply each role to a throwaway package on its own and look at what landed.
# Every method a role composes must be defined in an IO::K8s::Role::*
# package -- its own, or another role it composes (Role::APIObject composes
# SpecBuilder on purpose, k103). Anything defined elsewhere is an import
# that slipped below `use Moo::Role`.
#
# The required methods are discovered from the composition failure rather
# than listed here, so the loop doubles as a check that the k103 `requires`
# declarations are live: a role whose `requires` broke would compose
# against an empty package without complaint and stub nothing.
# ---------------------------------------------------------------------------

my @role_files;
find(
    {
        wanted   => sub { push @role_files, $File::Find::name if /\.pm$/ },
        no_chdir => 1,
    },
    'lib/IO/K8s/Role',
);

my @roles = sort map {
    my $m = $_;
    $m =~ s{^lib/}{};
    $m =~ s{/}{::}g;
    $m =~ s{\.pm$}{};
    $m;
} @role_files;

cmp_ok(scalar @roles, '>=', 12, 'found the role mesh under lib/IO/K8s/Role');

require_ok($_) for @roles;

# Installed on every consumer by Role::Tiny / Moo itself, not by the role.
my %INFRA = map +($_ => 1), qw( does DOES meta );

my %requires_seen;
my $probe_n = 0;

for my $role (@roles) {
    my $pkg = 'IO::K8s::Test::Probe' . ++$probe_n;
    my %stub;
    my $applied = 0;

    # Role::Tiny checks requires before installing anything, so a failed
    # apply leaves $pkg untouched and the retry is clean.
    for (1 .. 10) {
        if (eval { Moo::Role->apply_roles_to_package($pkg, $role); 1 }) {
            $applied = 1;
            last;
        }
        my $err = $@;
        my ($missing) = $err =~ /\bmissing\s+([^\n]*?)\s+at\s/;
        if (!defined $missing) {
            fail("$role applies to a bare package");
            diag($err);
            last;
        }
        no strict 'refs';
        for my $m (split /\s*,\s*/, $missing) {
            next if $stub{$m}++;
            *{"${pkg}::${m}"} = sub { };
        }
    }
    next unless $applied;

    $requires_seen{$role} = [ sort keys %stub ];

    no strict 'refs';
    my @foreign;
    for my $name (sort grep { defined &{"${pkg}::$_"} } keys %{"${pkg}::"}) {
        next if $stub{$name} || $INFRA{$name};
        my $gv   = B::svref_2object(\&{"${pkg}::$name"})->GV;
        my $from = eval { $gv->STASH->NAME } // '?';
        push @foreign, $name.' (from '.$from.')'
            unless $from =~ /\AIO::K8s::Role::/;
    }

    is_deeply(\@foreign, [],
        $role.' composes only methods defined in the role mesh')
        or diag('leaked imports: '.join(', ', @foreign));
}

# The seven builder roles k103 gave `requires`, plus the two format hooks
# and ResourceMap. Discovered above, asserted here: if an import hoist ever
# swallowed a `requires` line the probe would have stubbed nothing.
is_deeply($requires_seen{'IO::K8s::Role::CertManaged'},
    [qw( spec_push spec_set )], 'CertManaged still requires its spec_* methods');
is_deeply($requires_seen{'IO::K8s::Role::HelmManaged'},
    [qw( spec_hash spec_set )], 'HelmManaged still requires its spec_* methods');
is_deeply($requires_seen{'IO::K8s::Role::Loadbalanced'},
    [qw( spec_array spec_get spec_push spec_set )],
    'Loadbalanced still requires its spec_* methods');
is_deeply($requires_seen{'IO::K8s::Role::MiddlewareBuilder'},
    [qw( spec_hash spec_set )], 'MiddlewareBuilder still requires its spec_* methods');
is_deeply($requires_seen{'IO::K8s::Role::MiddlewareTCPBuilder'},
    [qw( spec_set )], 'MiddlewareTCPBuilder still requires spec_set');
is_deeply($requires_seen{'IO::K8s::Role::NetworkPolicy'},
    [qw( _netpol_format spec_push spec_set )],
    'NetworkPolicy still requires _netpol_format and its spec_* methods');
is_deeply($requires_seen{'IO::K8s::Role::Routable'},
    [qw( _route_format spec_get spec_push spec_set )],
    'Routable still requires _route_format and its spec_* methods');
is_deeply($requires_seen{'IO::K8s::Role::ResourceMap'},
    [qw( resource_map )], 'ResourceMap still requires resource_map');

# ---------------------------------------------------------------------------
# 2b. The composition direction, on the shipped classes.
#
# The names k118 and k119 removed, swept over every class that composes
# IO::K8s::Role::Resource -- so both the ~213 top-level Kinds and the
# nested resource classes.
#
# k118 removed the role-composed ones (croak / use_module / HashRef /
# cidr_contains) by hoisting each role's imports above `use Moo::Role`.
# k119 removed the rest: blessed / reftype / InstanceOf / Maybe / ArrayRef /
# require_module reached four classes -- IO::K8s::List and the three
# Apiextensions JSONSchemaPropsOr* union types -- from their OWN `use Moo`
# file, where hoisting cannot help because a Moo class has no `not_methods`.
# Those four now load Scalar::Util / Types::Standard / Module::Runtime with
# an empty import list and call through fully-qualified names instead, so
# there is nothing left to compose and no exception list here.
#
# Str / Bool / Int are deliberately absent from this list: IO::K8s::Resource
# imports them into every class it is used from, so they are on ~1850
# classes by design and are not a leak.
# ---------------------------------------------------------------------------

# Imported by no shipped resource class on its own account, so any hit here
# is a leak -- from a role (k118) or from the class's own file (k119).
my @LEAKED = qw(
    croak use_module require_module HashRef cidr_contains
    blessed reftype InstanceOf Maybe ArrayRef
);

my @modules;
find(
    {
        wanted => sub {
            return unless /\.pm$/;
            my $m = $File::Find::name;
            $m =~ s{^lib/}{};
            $m =~ s{/}{::}g;
            $m =~ s{\.pm$}{};
            push @modules, $m;
        },
        no_chdir => 1,
    },
    'lib',
);
@modules = sort @modules;
eval "require $_" for @modules;

my @resource_classes = grep {
    $_->can('does') && eval { $_->does('IO::K8s::Role::Resource') }
} @modules;

cmp_ok(scalar @resource_classes, '>=', 800,
    'swept every shipped class composing IO::K8s::Role::Resource');

for my $name (@LEAKED) {
    my @carriers = grep { $_->can($name) } @resource_classes;
    is_deeply(\@carriers, [],
        "no shipped resource class carries '$name' as a method")
        or diag('carried by: '.join(', ', @carriers));
}

# The four k119 classes are in that sweep rather than exempted from it --
# asserted, not assumed, because they only reach @resource_classes by
# composing IO::K8s::Role::Resource, which each of them does at the BOTTOM
# of its file (List.pm being the exception, at the top). A `with` line lost
# in a refactor would drop them out of the sweep silently.
my %swept = map +($_ => 1), @resource_classes;
for my $class (qw(
    IO::K8s::List
    IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrArray
    IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool
    IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrStringArray
)) {
    ok($swept{$class}, "$class is covered by the leak sweep");
}

# ---------------------------------------------------------------------------
# 2c. The real role methods are still there.
#
# The point of 2a/2b is a removal, so this is the other half of the claim:
# every behaviour the role mesh is supposed to provide survived the hoist.
# ---------------------------------------------------------------------------

my %EXPECTED = (
    # nested resource -- IO::K8s::Role::Resource only
    'IO::K8s::Api::Core::V1::PodSpec' =>
        [qw( TO_JSON FROM_HASH to_json to_yaml compare_to_schema )],
    'IO::K8s::Api::Core::V1::Container' =>
        [qw( TO_JSON FROM_HASH to_json )],
    # core top-level Kind -- + Role::APIObject + Role::SpecBuilder (k103)
    'IO::K8s::Api::Core::V1::Pod' =>
        [qw( api_version kind metadata add_label match_labels conditions
             is_ready set_owner to_yaml save spec_get spec_set spec_push )],
    'IO::K8s::Api::Apps::V1::Deployment' =>
        [qw( api_version kind add_annotation owner_refs spec_set spec_merge )],
    # core Kind carrying a behaviour mixin
    'IO::K8s::Api::Networking::V1::NetworkPolicy' =>
        [qw( select_pods deny_all_ingress allow_egress_to_dns
             allow_ingress_from_cidrs )],
    'IO::K8s::Api::Networking::V1::Ingress' =>
        [qw( add_hostname add_backend )],
    # CRD Kinds, one per provider family that ships a mixin
    'IO::K8s::Cilium::V2::CiliumNetworkPolicy' =>
        [qw( select_pods allow_egress_to_dns spec_set )],
    'IO::K8s::Traefik::V1alpha1::Middleware' =>
        [qw( rate_limit basic_auth strip_prefix redirect_https )],
    'IO::K8s::CertManager::V1::Certificate' =>
        [qw( for_domains with_issuer letsencrypt store_in_secret )],
    'IO::K8s::K3s::V1::HelmChart' =>
        [qw( from_repo set_version set_values )],
    'IO::K8s::GatewayAPI::V1::HTTPRoute' =>
        [qw( add_hostname add_backend add_header_match )],
);

for my $class (sort keys %EXPECTED) {
    require_ok($class);
    my @missing = grep { !$class->can($_) } @{ $EXPECTED{$class} };
    is_deeply(\@missing, [], "$class kept its role methods")
        or diag('missing: '.join(', ', @missing));
}

# The leaked names, spot-checked as method calls on the same classes.
for my $class (sort keys %EXPECTED) {
    my @leaked = grep { $class->can($_) }
        @LEAKED;
    is_deeply(\@leaked, [], "$class carries no leaked import")
        or diag('leaked: '.join(', ', @leaked));
}

# ---------------------------------------------------------------------------
# 2d. Classes IO::K8s::AutoGen builds at runtime go through
# Moo::Role->apply_roles_to_package with the same roles, so they inherit the
# fix rather than needing one of their own.
# ---------------------------------------------------------------------------

{
    require IO::K8s;
    my $k8s = IO::K8s->new(
        openapi_spec => {
            definitions => {
                'com.example.v1.Widget' => {
                    properties => {
                        apiVersion => { type => 'string' },
                        kind       => { type => 'string' },
                        metadata   => { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' },
                        spec       => { type => 'object' },
                    },
                    'x-kubernetes-group-version-kind' => [
                        { group => 'example.com', version => 'v1', kind => 'Widget' },
                    ],
                },
            },
        },
    );
    my $widget = eval { $k8s->new_object('Widget', metadata => { name => 'w' }) };
    if ($widget) {
        my $class = ref $widget;
        my @leaked = grep { $class->can($_) }
            @LEAKED;
        is_deeply(\@leaked, [], 'AutoGen-built class carries no leaked import')
            or diag('leaked: '.join(', ', @leaked));
        ok($class->can('TO_JSON'), 'AutoGen-built class kept TO_JSON');
        ok($class->can('spec_set'), 'AutoGen-built class kept spec_set');
    }
    else {
        note('AutoGen probe skipped: '.$@);
    }
}

done_testing;
