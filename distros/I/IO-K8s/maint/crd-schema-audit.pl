#!/usr/bin/env perl
# Per-field schema-fidelity audit for the CRD providers.
#
# The third question in this maint/ family, and the only one that looks at
# field OPTIONS rather than at coverage or at bytes:
#
#   spec-drift-check.pl   -- does lib/ cover the upstream Kubernetes API?
#   crd-drift-check.pl    -- does lib/ match what the emitter renders?
#   crd-schema-audit.pl   -- does each shipped class agree with its CRD on
#                            required-ness and the value constraints?
#
# Why it exists (k120). The obvious reason is hand-modelling: k113 wrote 57
# generators.external-secrets.io classes by hand and five disagreed with the
# CRD -- a `pattern` dropped (losing a construction-time check), a `required`
# dropped, a `required` invented, and twice a `default` read out of an
# English description sentence that the schema never declared. Nothing found
# those but a field-by-field walk.
#
# The less obvious reason is why crd-drift-check.pl --check cannot stand in
# for this even at 0 differ. An overlay maps several logical paths onto one
# bare class name, and where the schemas at those paths are NOT identical
# the render silently keeps whichever it wrote last (render_for's
# `$files{$_} = $rendered->{$_}`), so --check only ever compares the
# survivor. cert-manager v1.21.1 is the live example: `LocalObjectReference`
# is two different upstream types -- corev1's at six imagePullSecrets[]
# positions (`name` has `default: ""`, nothing required) and cert-manager's
# own at four venafi credentialsRef positions (no default, `required:
# [name]`) -- and maint/crd-render/CertManager.yaml names both the same, so
# one Perl class carries the corev1 shape and the four credentialsRef
# positions are modelled wrong. --check reports 0 differ throughout. This
# script is what sees it, which is exactly why it is a separate tool and not
# a --check flag.
#
# This is a report generator. It reads manifests and the shipped attribute
# registry, and writes nothing -- not to lib/, not to the karr board, not to
# the manifest cache. It never touches the network either: point it at a
# directory of CRD YAML, or let it read the cache maint/crd-drift-check.pl
# already populated under spec/crd/.
#
# Usage:
#   maint/crd-schema-audit.pl [--provider NAME]... [--dir path] [--lib path]
#                             [--cache-dir path] [--verbose]
#
# Examples:
#   maint/crd-schema-audit.pl
#     Audit every provider that has a cached manifest.
#
#   maint/crd-schema-audit.pl --provider ExternalSecrets --verbose
#     One provider, plus the per-keyword tally of what the k8s DSL cannot
#     express (see "Not expressible" below) and what was skipped.
#
#   maint/crd-schema-audit.pl --provider Cilium --dir /path/to/crds
#     Audit against a manifest directory instead of the cache.
#
# WHAT IS COMPARED
#
# Only the option keys the k8s DSL records, since only those can be right or
# wrong in a class: required, pattern, enum, minimum, maximum, default. Each
# is reported in both directions -- DROPPED (the CRD declares it, the class
# does not) and INVENTED (the class declares it, the CRD does not).
#
# NOT EXPRESSIBLE -- counted, never reported as a finding
#
# minLength, maxLength, minItems, maxItems, uniqueItems, multipleOf and
# format are NOT in %FIELD_OPTIONS in IO::K8s::Resource, so no class can
# carry them and their absence is a property of the DSL, not a defect. They
# are tallied separately and named under --verbose. This matters: a single
# provider can declare a couple of thousand of them, and a reader who sees
# that number in a findings column will reasonably conclude the tree is on
# fire. It is not.
#
# STOCK CLASSES ARE NOT WALKED
#
# A field whose schema matches a shipped core class is typed as that class
# (D5 reuse_core: Meta::V1::LabelSelector, Meta::V1::Condition,
# Core::V1::SecretReference, ...). Such a class models the core Kubernetes
# API, not this one CRD, so it legitimately carries none of the CRD's own
# narrowing -- a walk into it would flag every constraint the CRD declares
# there and drown the real findings. Anything outside the audited provider's
# own IO::K8s::<Provider>:: namespace is therefore skipped and counted under
# `stock_skipped`. That test is used rather than a list of core namespaces
# because there are four of them (IO::K8s::Api::, ::Apimachinery::,
# ::ApiextensionsApiserver::, ::KubeAggregator::) and missing one silently
# turns every shared Condition into a page of invented findings. Suspecting
# a reused core class of being the wrong shape for a field is a real
# question, but it is crd-drift-check.pl's, not this script's.
use strict;
use warnings;
use v5.10;
use FindBin;
use File::Spec;
use Getopt::Long qw( GetOptions );
use YAML::PP;
use Module::Runtime qw( use_module );

my $DIST_ROOT = File::Spec->catdir($FindBin::Bin, '..');

# Same provider list, in the same order, as maint/crd-drift-check.pl.
my @ALL_PROVIDERS = qw(Cilium GatewayAPI AgentSandbox Traefik CertManager K3s
                       PrometheusOperator VolumeSnapshot ExternalSecrets);

# The option keys a class can carry, hence the only ones that can disagree.
my @COMPARABLE = qw( pattern enum minimum maximum );

# Declared upstream, unrepresentable in the DSL. See the header.
my @NOT_EXPRESSIBLE = qw( minLength maxLength minItems maxItems uniqueItems
                          multipleOf format );

sub usage {
    my ($exit_code) = @_;
    print <<"USAGE";
Usage:
  $0 [--provider NAME]... [options]

Options:
  --provider NAME     Provider to audit (repeatable). One of:
                        @ALL_PROVIDERS
                      Default: every provider with a cached manifest.
  --dir PATH          Read *.yaml CRD manifests from PATH instead of the
                      cache. Requires exactly one --provider.
  --cache-dir PATH    Manifest cache root (default: DIST/spec/crd), as
                      populated by maint/crd-drift-check.pl.
  --lib PATH          lib/ directory to audit (default: DIST/lib)
  --verbose           Also list the not-expressible tally and what was
                      skipped.
  --help              This message.

Reads manifests and lib/; writes nothing, and never uses the network. Run
maint/crd-drift-check.pl first if the manifest cache is empty.
USAGE
    exit $exit_code;
}

my %opt = (
    'cache-dir' => File::Spec->catdir($DIST_ROOT, 'spec', 'crd'),
    lib         => File::Spec->catdir($DIST_ROOT, 'lib'),
);
my @providers;
GetOptions(
    'provider=s'  => \@providers,
    'dir=s'       => \$opt{dir},
    'cache-dir=s' => \$opt{'cache-dir'},
    'lib=s'       => \$opt{lib},
    'verbose'     => \$opt{verbose},
    'help'        => \$opt{help},
) or usage(2);
usage(0) if $opt{help};

@providers = @ALL_PROVIDERS unless @providers;
my %known = map { $_ => 1 } @ALL_PROVIDERS;
for my $p (@providers) {
    die "crd-schema-audit: unknown provider '$p' (known: @ALL_PROVIDERS)\n"
        unless $known{$p};
}
die "crd-schema-audit: --dir requires exactly one --provider\n"
    if $opt{dir} && @providers != 1;

unshift @INC, $opt{lib};
require IO::K8s;

# ---------------------------------------------------------------------------
# Manifests
# ---------------------------------------------------------------------------

# Every *.yaml under the provider's cache (or --dir), newest pin wins by
# virtue of being the only one crd-drift-check.pl wrote for this version.
sub manifest_files {
    my ($provider) = @_;
    return sort glob File::Spec->catfile($opt{dir}, '*.yaml') if $opt{dir};
    my $root = File::Spec->catdir($opt{'cache-dir'}, $provider);
    return () unless -d $root;
    return sort glob File::Spec->catfile($root, '*', '*.yaml');
}

# Kind -> CRD document, for every CustomResourceDefinition in those files.
sub load_crds {
    my (@files) = @_;
    my $yp = YAML::PP->new(boolean => 'JSON::PP');
    my %crd;
    for my $file (@files) {
        my @docs = eval { $yp->load_file($file) };
        if ($@) { warn "crd-schema-audit: cannot parse $file: $@"; next }
        for my $d (@docs) {
            next unless ref $d eq 'HASH' && ($d->{kind} // '') eq 'CustomResourceDefinition';
            $crd{ $d->{spec}{names}{kind} } = $d;
        }
    }
    return \%crd;
}

# The CRD version whose schema this Perl class actually models. A CRD can
# serve several versions from one document (ExternalSecret is v1 + v1beta1)
# while the class lives in exactly one of them, so picking versions[0]
# blindly compares a V1 class against a v1beta1 schema and invents findings
# wholesale -- the bug this function exists to not have.
sub version_for {
    my ($crd, $class) = @_;
    my @versions = @{ $crd->{spec}{versions} || [] } or return;
    if (my ($seg) = $class =~ /::(V\d+(?:alpha|beta)?\d*)::/) {
        my $want = lc $seg;
        for my $v (@versions) {
            return $v if lc($v->{name}) eq $want;
        }
    }
    return $versions[0];
}

# ---------------------------------------------------------------------------
# The walk
# ---------------------------------------------------------------------------

my $registry = \%IO::K8s::Resource::_attr_registry;

# apiVersion and kind are declared by every CRD schema but are never k8s
# attributes -- IO::K8s::Role::APIObject derives them from the class name
# and Role::Resource::TO_JSON writes them. Their absence from the registry
# is correct, so they are not a MISSING FIELD. `metadata` IS an attribute,
# but it comes from the same role rather than from the CRD, so a manifest
# that lists it in the root `required` (cert-manager's Challenge and Order
# do) is not saying anything a provider class could act on. All three are
# skipped at the ROOT object only -- a CRD is free to declare a field of
# its own called `kind` further down, and that one is audited normally.
my %ENVELOPE = (apiVersion => 1, kind => 1, metadata => 1);

sub audit_provider {
    my ($provider) = @_;
    my $pkg = "IO::K8s::$provider";
    eval { use_module($pkg); 1 }
        or return { provider => $provider, error => "cannot load $pkg: $@" };

    my @files = manifest_files($provider);
    return { provider => $provider, error => 'no cached manifest -- run maint/crd-drift-check.pl first' }
        unless @files;

    my $crds = load_crds(@files);
    my $k8s  = IO::K8s->new(with => [$pkg]);

    my (@findings, %stat, %seen);

    my $own_ns = "IO::K8s::$provider\::";

    my $walk;
    $walk = sub {
        my ($schema, $class, $where, $is_root) = @_;
        return unless ref $schema eq 'HASH' && $class;
        # A reused core class models the core API, not this CRD -- see the
        # header. Counted so the report says it happened.
        if (index($class, $own_ns) != 0) {
            $stat{stock_skipped}++;
            return;
        }
        return if $seen{"$where|$class"}++;
        eval { use_module($class); 1 } or do {
            $stat{unloadable}++;
            return;
        };
        my $attrs = $registry->{$class} or return;

        my %by_key;
        for my $a (keys %$attrs) {
            my $i = $attrs->{$a};
            $by_key{ $i->{json_key} // $a } = $i;
        }

        my $props = $schema->{properties} || {};
        my %req   = map { $_ => 1 } @{ $schema->{required} || [] };

        for my $key (sort keys %$props) {
            my $p = $props->{$key};
            my $i = $by_key{$key};
            next if $is_root && $ENVELOPE{$key};
            unless ($i) {
                push @findings, ["$where.$key", 'MISSING FIELD', 'declared in the CRD, no k8s attribute'];
                next;
            }
            my $o = $i->{options} || {};

            # required lives on the PARENT object, not on the field
            if ($req{$key} && !$i->{required}) {
                push @findings, ["$where.$key", 'REQUIRED DROPPED', 'the CRD requires it, the class does not'];
            }
            elsif (!$req{$key} && $i->{required}) {
                push @findings, ["$where.$key", 'REQUIRED INVENTED', 'the class requires it, the CRD does not'];
            }

            # a constraint on an array applies to its items
            my $c = (($p->{type} // '') eq 'array' && ref $p->{items} eq 'HASH')
                  ? $p->{items} : $p;
            for my $k (@COMPARABLE) {
                my $crd_has   = exists $c->{$k};
                my $class_has = exists $o->{$k};
                # A Quantity field needs no `pattern` option: the Quantity
                # type itself enforces the apimachinery quantity grammar,
                # and more tightly than the CRD's regex does. Same value,
                # carried by the type instead of by an option.
                if ($k eq 'pattern' && $crd_has && !$class_has && $i->{is_quantity}) {
                    $stat{quantity_pattern}++;
                    next;
                }
                push @findings, ["$where.$key", uc($k) . ' DROPPED',  'the CRD declares it, the class does not']
                    if $crd_has && !$class_has;
                push @findings, ["$where.$key", uc($k) . ' INVENTED', 'the class declares it, the CRD does not']
                    if !$crd_has && $class_has;
            }
            # `default` is a property of the field, never of an array's items
            if (exists $p->{default} && !exists $o->{default}) {
                push @findings, ["$where.$key", 'DEFAULT DROPPED', 'the CRD declares it, the class does not'];
            }
            elsif (!exists $p->{default} && exists $o->{default}) {
                my $d = $o->{default};
                push @findings, ["$where.$key", 'DEFAULT INVENTED',
                    "the class says default => '" . (ref $d ? '...' : ($d // '')) . "', the CRD declares none"];
            }

            $stat{"na_$_"}++ for grep { exists $c->{$_} } @NOT_EXPRESSIBLE;

            my $target = $i->{class} or next;
            my $child = (($p->{type} // '') eq 'array') ? $p->{items}
                      : $i->{is_hash}                   ? $p->{additionalProperties}
                      :                                   $p;
            $walk->($child, $target, "$where.$key");
        }
    };

    for my $kind (sort keys %$crds) {
        my $class = eval { $k8s->expand_class($kind) } or next;
        my $version = version_for($crds->{$kind}, $class) or next;
        my $root = $version->{schema}{openAPIV3Schema} or next;
        $walk->($root, $class, "$kind($version->{name})", 1);
    }

    return { provider => $provider, findings => \@findings, stat => \%stat };
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

my $bad = 0;
for my $provider (@providers) {
    my $r = audit_provider($provider);
    printf "########## %s ##########\n", $provider;
    if ($r->{error}) {
        print "  skipped: $r->{error}\n\n";
        next;
    }
    my $f = $r->{findings};
    if (@$f) {
        $bad = 1;
        printf "  %-64s  %-18s  %s\n", 'PATH', 'FINDING', 'DETAIL';
        printf "  %-64s  %-18s  %s\n", $_->[0], $_->[1], $_->[2]
            for sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @$f;
    }
    else {
        print "  no disagreement between the shipped classes and the CRD\n";
    }
    my $stat = $r->{stat};
    my $na = 0;
    $na += $stat->{"na_$_"} // 0 for @NOT_EXPRESSIBLE;
    printf "  --- %d finding(s); %d upstream keyword(s) the k8s DSL cannot express (not a defect)\n",
        scalar @$f, $na;
    if ($opt{verbose}) {
        printf "      not expressible: %s\n",
            join(', ', map { "$_=" . $stat->{"na_$_"} }
                       grep { $stat->{"na_$_"} } @NOT_EXPRESSIBLE) || '(none)';
        printf "      stock classes not walked (reuse_core): %d\n", $stat->{stock_skipped} // 0;
        printf "      Quantity fields whose grammar the type carries: %d\n", $stat->{quantity_pattern}
            if $stat->{quantity_pattern};
        printf "      classes that failed to load: %d\n", $stat->{unloadable} // 0
            if $stat->{unloadable};
    }
    print "\n";
}

exit($bad ? 1 : 0);
