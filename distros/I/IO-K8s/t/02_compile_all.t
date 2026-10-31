#!/usr/bin/env perl
# One process, one full load of lib/, many sweeps over the loaded tree.
#
# Loading all ~1900 modules costs ~40 s. Ten test files used to walk lib/
# and load it again each; every sweep that reads the SHIPPED state (the
# modules themselves and %IO::K8s::Resource::_attr_registry) now lives here
# as a named subtest and shares the single load below. Each subtest keeps the
# claim it made in its own file; the originating file and ticket are named on
# each one.
#
#   compile            every module under lib/ loads          (was t/02_compile_all.t)
#   registry guard     every k8s attribute target is loadable (was t/34_registry_guard.t)
#   registry synthesis synthesise + round-trip every class    (was t/42_registry_synthesis_roundtrip.t)
#   import leak 2b     no leaked import on a shipped class    (was t/27_no_import_leak.t, 2b)
#   k191               no legacy-map warning; string maps are map[string]string
#   k196               every scalar field has its upstream kind
#   k193               no { X => 1 } map spelling left in lib/
#   k110/k114          shipped patterns / Class->to_crd smoke (was t/79_to_crd.t)
#   plural coverage    resource_plural over the shipped API classes (was t/51_resource_plural.t)
#
# What deliberately does NOT live here: anything that declares a class of its
# own or builds one through AutoGen. `use IO::K8s::APIObject` registers the
# calling package in the attribute registry at COMPILE time, so a fixture
# class in this file would show up in the registry sweeps above. Those tests
# keep their own, cheap processes: t/27_no_import_leak.t, t/51_resource_plural.t,
# t/79_to_crd.t, t/153_k196_number_wire_type.t.
#
# Local fixtures only (lib/, spec/, t/25_real_world.t's manifests); no
# network, no cluster.

use strict;
use warnings;
use Test::More;

use FindBin;
use File::Find;
use JSON::MaybeXS ();
use Path::Tiny qw( path );
use re ();
use Role::Tiny ();
use lib "$FindBin::Bin/../lib";

# Every warning raised from here on -- the compile of this file, `use IO::K8s`
# and the whole load below -- is kept for the k191 "no legacy-map warning"
# claim, and still passed on to STDERR.
my @WARNINGS;
BEGIN {
    $SIG{__WARN__} = sub { push @WARNINGS, "@_"; warn @_ };
}

use IO::K8s;

my $ROOT = path($FindBin::Bin)->parent;
my $root = "$FindBin::Bin/..";
my $LIB  = "$root/lib";

# ---------------------------------------------------------------------------
# The one load
# ---------------------------------------------------------------------------

my (@MODULES, %PATH_OF, %LOAD_ERROR);
{
    my @paths;
    find({ wanted => sub { push @paths, $File::Find::name if /\.pm\z/ }, no_chdir => 1 }, $LIB);
    for my $path (@paths) {
        (my $mod = $path) =~ s{^\Q$LIB\E/}{};
        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm\z}{};
        $PATH_OF{$mod} = $path;
    }
    @MODULES = sort keys %PATH_OF;

    for my $mod (@MODULES) {
        eval "require $mod; 1" or $LOAD_ERROR{$mod} = $@;
    }
}
$SIG{__WARN__} = 'DEFAULT';

# The classes under lib/IO/K8s/ (everything but IO::K8s itself), as the
# registry-oriented files always walked them.
my @K8S_MODULES = grep { /\AIO::K8s::/ } @MODULES;

my $registry = \%IO::K8s::Resource::_attr_registry;

my $CORE = qr/^IO::K8s::(?:Api|Apimachinery|ApiextensionsApiserver|KubeAggregator)::/;

# ---------------------------------------------------------------------------
# helpers shared by the k191 and k196 static checks
# ---------------------------------------------------------------------------

sub defkey_to_perl_class {
    my ($key) = @_;
    return unless $key =~ /^io\.k8s\./;
    my @parts = split /\./, substr($key, length 'io.k8s.');
    my $kind  = pop @parts;
    return join '::', 'IO::K8s',
        ( map { join '', map { ucfirst } grep { length } split /-/, $_ } @parts ), $kind;
}

# ===========================================================================
# was t/02_compile_all.t: every module under lib/ compiles
# ===========================================================================

subtest 'compile: every module under lib/ loads' => sub {
    for my $mod (@MODULES) {
        ok(!defined $LOAD_ERROR{$mod}, "require $mod;")
            or diag($LOAD_ERROR{$mod});
    }
};

# ===========================================================================
# was t/34_registry_guard.t
#
# Catches missing or misrouted attribute target classes at build time, before
# they surface as "Can't locate ... in @INC" at inflate time. This is the
# test that would have caught k1 (apiextensions.k8s.io/v1 union types), k2
# (KubeAggregator prefix did not match) and k3 (StorageVersionSpec was never
# shipped) together, rather than one at a time on the consumer side.
#
# After every shipped class has been loaded, walk the global attribute
# registry and assert every referenced class is loadable. We do not care HOW
# it is loaded -- that is Resource.pm's job -- only that the symbol is
# findable. This catches:
#
#   * a declared class that was never shipped  (k3)
#   * a class shipped under one namespace but declared under another
#     because _expand_class fell through to the default expansion
#     (k2, before the prefix-match fix)
#   * a self-inflating union class that the attribute side still
#     references via the type spec (k1)
# ===========================================================================

subtest 'registry guard: every k8s-attribute target class is loadable' => sub {
    my %loadable = map { $_ => 1 } @K8S_MODULES;

    # Inline-generated structs (Resource.pm `_generate_inline_struct`) are not
    # shipped as .pm files -- they materialise as packages when the parent class
    # is loaded. We accept any target that is a materialised resource class
    # (it can TO_JSON, from the composed role), regardless of whether there's a
    # .pm on disk for it.
    my $available = sub {
        my ($target) = @_;
        return 1 if $loadable{$target};
        no strict 'refs';
        return $target->can("TO_JSON") ? 1 : 0;
    };

    my @missing;
    for my $class (sort keys %$registry) {
        for my $attr (sort keys %{$registry->{$class}}) {
            my $info = $registry->{$class}{$attr};
            my $target = $info->{class} or next;          # scalar / array-of-str
            next if $target =~ /^(Str|Int|Bool|Quantity|Time|IntOrStr)\b/;
            next if $available->($target);

            push @missing, sprintf("  %-70s  %s  -> %s", "$class->$attr",
                ($info->{is_array_of_objects} ? '[obj]'
                  : $info->{is_hash_of_objects}  ? '{obj}'
                  : $info->{is_object}           ? 'obj'
                  : '???'),
                $target);
        }
    }

    if (@missing) {
        diag("Attribute targets that are declared but not loadable:");
        diag($_) for @missing;
    }

    is(scalar @missing, 0,
        'every k8s-attribute target class is loadable (would have caught k1, k2, k3)')
        or BAIL_OUT(scalar(@missing) . " attribute target(s) not loadable");
};

# ===========================================================================
# was t/42_registry_synthesis_roundtrip.t
#
# (t/34_registry_guard.t, referred to below, is the "registry guard" subtest above.)
#
# t/34_registry_guard.t proved every k8s-attribute target class is
# *loadable*. It never builds an object and never checks serialization, so
# it structurally cannot see a class of bug that has now shown up twice on
# the consumer side against a real cluster:
#
#   * ArrayRef[Bool] (DeviceAttribute.bools in the Resource V1/V1beta1/
#     V1beta2 DRA APIs) serialized as [1,0,1] instead of [true,false,true],
#     and died on the way back in because JSON::PP::Boolean (what a real
#     cluster response decodes booleans as) doesn't satisfy Types::Standard
#     Bool without the array-element coercion that fixed it. See
#     t/37_dra_v1beta1_v1beta2.t for the narrow regression test.
#   * Attribute target classes that were never shipped at all (the
#     apiextensions union types, StorageVersionSpec) - t/34 now catches the
#     "is it loadable" half of this, but not "can I build one and does it
#     serialize correctly".
#
# This file is the general net: for every class in the k8s DSL's attribute
# registry (the same %IO::K8s::Resource::_attr_registry t/34 reads), build
# a synthetic instance straight from the registry's own type-flags, run it
# through inflate -> TO_JSON -> real JSON encode/decode -> re-inflate ->
# TO_JSON again, and check the two encodings are byte-identical *and* that
# bool/int fields actually carry the JSON types they claim to. A bug that
# quietly turns a bool array into 0/1 integers would still round-trip
# "stably" (1/0 encodes to 1/0 both times) - byte-equality alone cannot see
# it, which is why the type checks below inspect JSON::PP::Boolean-ness and
# the unquoted-number encoding directly, not just idempotence.
#
# ============================================================================
# Depth
# ============================================================================
# Object-typed fields recurse into a real, synthetically-filled child (not
# an empty hash) up to MAX_DEPTH levels below the class currently on test.
# This is *not* a coverage limit: every class that can appear as a nested
# field is itself a key in the registry and gets its own independent
# top-level pass at depth 0, where its own fields are fully populated
# again. Depth-limiting only bounds how large a single class's own object
# graph gets before we stop adding further optional nesting - it does not
# reduce which fields get exercised across the suite as a whole.
#
# MAX_DEPTH exists to terminate real cycles in the type graph:
# JSONSchemaProps references itself (allOf/anyOf/not/properties/
# definitions/patternProperties/items/...), and every one of those edges is
# optional, so capping optional-field recursion is enough to break the
# cycle outright. Required object fields always recurse regardless of
# depth (a required field must get *something* or Moo's constructor
# rejects the object) - see the %building cycle guard below for what
# happens if a required chain ever does cycle back on itself.
#
# ============================================================================
# Special cases
# ============================================================================
# * The four apiextensions.k8s.io/v1 union types (JSON,
#   JSONSchemaPropsOrArray, JSONSchemaPropsOrBool,
#   JSONSchemaPropsOrStringArray) have their own FROM_STRUCT/TO_JSON and
#   serialize as a bare value, not as a hash of attributes - the generic
#   "build a struct of this class's registered fields" machinery does not
#   apply to them. They never appear as *top-level* targets in this test
#   because they don't call the k8s DSL at all (no `use IO::K8s::Resource`),
#   so they're simply never registry keys. They DO appear as *nested*
#   field targets (e.g. JSONSchemaProps.items/additionalProperties/
#   dependencies/default/example/enum) - those are detected via
#   ->can('FROM_STRUCT') and given a bare value matching the arm they
#   represent, instead of a hash. All four already have exhaustive,
#   dedicated coverage in t/31_apiextensions_unions.t.
# * IO::K8s::List is hand-written Moo with its own TO_JSON and never calls
#   the k8s DSL, so it likewise never becomes a registry key and is out of
#   scope for a test whose entire mechanism is "read the k8s attribute
#   registry".
#
# ============================================================================
# Required vs. full
# ============================================================================
# Two synthetic structs per class: 'required' (only fields the registry's
# Moo constructor spec marks required - often empty, which is itself a
# valid minimal case) and 'full' (every registered field, required or
# not). The registry doesn't carry a required flag on its own info hash
# (only Moo's constructor spec does), so required-ness is read from
# Moo->_constructor_maker_for($class)->all_attribute_specs directly - the
# same introspection Moo itself uses to enforce it.

# ===========================================================================

{
    # k108 (fixed in 1.108): IO::K8s::Cilium::V2alpha1::AccessLogs used to be
    # excluded here -- it is the one class in the whole registry with a real
    # upstream field literally named `json`, which collided with
    # Role::Resource's own internal JSON-encoder attribute (also named `json`
    # at the time). Now that the role's encoder attribute is private
    # (`_json_encoder`), AccessLogs and its only referrer (Telemetry.accessLogs)
    # need no special-casing and are covered by the generic sweep below like
    # every other class.
    my %SKIP_CLASS  = ();
    my %SKIP_FIELD  = ();

    my @classes = sort grep { !$SKIP_CLASS{$_} } keys %$registry;


    use constant MAX_DEPTH => 2;

    my $io       = IO::K8s->new;
    my $json_iso = JSON::MaybeXS->new(utf8 => 0, canonical => 1, allow_nonref => 1);

    # Toggles so both arms of a binary choice (true/false, numeric/string form
    # of IntOrStr, single-schema/tuple arm of JSONSchemaPropsOrArray) get
    # exercised somewhere across the sweep, instead of always picking one.
    my $bool_toggle = 0;
    my $ios_toggle  = 0;
    my $arr_toggle  = 0;

    # ============================================================================
    # Moo introspection helpers
    # ============================================================================

    my %specs_cache;
    sub moo_specs_for {
        my ($class) = @_;
        return $specs_cache{$class} //= Moo->_constructor_maker_for($class)->all_attribute_specs;
    }

    sub required_flags_for {
        my ($class) = @_;
        my $specs = moo_specs_for($class);
        my %flags = map { $_ => ($specs->{$_}{required} ? 1 : 0) } keys %$specs;
        return \%flags;
    }

    # Before k96 task-2's review fix, a few ArrayRef[X] combinations (X =
    # Quantity, at least - IO::K8s::Api::Resource::V1::CapacityRequestPolicy's
    # validValues => [Quantity]) registered with NO is_array_of_* flag at all:
    # _k8s's Type::Tiny branch only recognised Str/Int/Bool as array element
    # types. That gap is closed (Resource.pm's array branch now also flags
    # Num/IntOrStr/Quantity/Time; synth_value below has explicit cases for all
    # four), so every currently-shipped shape reaches synth_value with a real
    # flag and never falls into this block. Left in place as a defensive
    # fallback for a hypothetical future scalar kind the DSL grows without a
    # matching case being added here: ask the real Moo `isa` constraint what it
    # is - the actual source of truth - rather than silently minting an invalid
    # "synthetic-$attr" string that fails its own type check.
    sub isa_text_for {
        my ($class, $attr) = @_;
        my $isa = moo_specs_for($class)->{$attr}{isa} or return undef;
        return "$isa";
    }

    # ============================================================================
    # Bare-value synthesis for the four self-inflating union types
    # ============================================================================

    sub union_bare_value {
        my ($target_class) = @_;
        return JSON::MaybeXS::true() if $target_class =~ /JSONSchemaPropsOrBool$/;
        return ['depends-on-me']     if $target_class =~ /JSONSchemaPropsOrStringArray$/;
        if ($target_class =~ /JSONSchemaPropsOrArray$/) {
            # Alternate arms across the run so both the single-schema and the
            # tuple arm of this union get exercised somewhere in the sweep.
            return ($arr_toggle++ % 2)
                ? [ { type => 'string' }, { type => 'integer' } ]
                : { type => 'string' };
        }
        return 'synthetic-json-value' if $target_class =~ /::JSON$/;
        die "unhandled FROM_STRUCT class $target_class - add a bare-value case above";
    }

    # ============================================================================
    # Synthetic scalar values, one per registry type flag
    # ============================================================================

    # Shared candidate pool for every 'pattern'-constrained scalar shape a
    # shipped D3 field has turned out to need: HTTP-status-code-shaped
    # (100/404/500/8080), DNS-label-shaped (a/b), Go-duration-shaped (1h),
    # IPv4/IPv6-address-shaped (10.0.0.1, Cilium's peerAddress/ip fields, k95),
    # CIDR-shaped (10.0.0.0/24, Cilium's destinationCIDRs/excludedCIDRs),
    # BGP-community-triple-shaped (65000:1:1, Cilium's BGPCommunities.large),
    # absolute-URL-shaped (https://example.com, Gateway API's
    # SubjectAltName.uri and HTTPCORSFilter.allowOrigins, k95),
    # cron/@keyword-shaped (@daily, ExternalSecrets'
    # ExternalSecretSyncWindowEntry.schedule, which also accepts a 5-field cron
    # string or "@every <duration>"), GCP-service-account-email-shaped
    # (test@project.iam.gserviceaccount.com, ExternalSecrets'
    # GCPWorkloadIdentityFederation.gcpServiceAccountEmail), Nebius
    # service-account-id-shaped (serviceaccount-abc, ExternalSecrets'
    # NebiusWorkloadIdentity.iamServiceAccountID), byte-size-shaped (512MB,
    # PrometheusOperator's AlertmanagerLimitsSpec.maxPerSilenceBytes and the
    # several *.bodySizeLimit fields, all sharing one "trailing B, optional
    # K/M/G/T/E/P(i) prefix" pattern), abort|warn-enum-shaped (abort,
    # PrometheusOperator's RuleGroup.partial_response_strategy), and
    # filename-shaped (config.yaml, PrometheusOperator's
    # V1alpha1::FileSDConfig.files, which requires a .json/.yml/.yaml suffix).
    # Every call site below greps this same pool for the first entry that
    # satisfies the field's own pattern rather than assuming one fixed shape --
    # a value the field's own constraint rejects isn't a valid instance of it.
    my @PATTERN_CANDIDATES = (
        '100', '404', '500', '8080', 'a', 'b', '1h', '10.0.0.1', '10.0.0.0/24', '65000:1:1', 'https://example.com',
        '@daily', 'test@project.iam.gserviceaccount.com', 'serviceaccount-abc', '512MB', 'abort', 'config.yaml',
    );

    sub synth_scalar {
        my ($info, $attr) = @_;
        my $opts = $info->{options} // {};
        if ($info->{is_bool}) {
            return ($bool_toggle++ % 2) ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
        }
        # D3 value constraints (k8s DSL per-field option hash, k95 CRD full-depth
        # providers are the first shipped classes to actually declare them):
        # enum/minimum/maximum are enforced client-side (Types::Standard), so a
        # synthetic value that ignores them isn't a valid instance of the field
        # and struct_to_object rightly rejects it -- that is the constraint
        # working, not a bug in the class under test. enum wins over the
        # type-based synthesis below regardless of scalar kind.
        return $opts->{enum}[0] if $opts->{enum};
        if ($info->{is_int}) {
            my $v = 7;
            $v = $opts->{minimum} if defined $opts->{minimum} && $v < $opts->{minimum};
            $v = $opts->{maximum} if defined $opts->{maximum} && $v > $opts->{maximum};
            return $v;
        }
        if ($info->{is_num}) {
            # A numeric string on purpose (k196): the way a quoted YAML value
            # arrives, and TO_JSON must still put it out as a JSON number.
            my $v = '1.5';
            $v = $opts->{minimum} if defined $opts->{minimum} && $v < $opts->{minimum};
            $v = $opts->{maximum} if defined $opts->{maximum} && $v > $opts->{maximum};
            return $v;
        }
        if ($info->{is_int_or_string}) {
            # IntOrStr must survive whichever form the caller gave it - toggle
            # between a numeric-looking string and a real string so both forms
            # get exercised across the sweep. A 'pattern' constraint (Traefik's
            # duration/percentage-shaped IntOrStr fields, Cilium's ICMPField.type
            # which accepts either a 0-255 code or a named ICMP type, k95) is
            # arbitrary and not guaranteed to accept free text OR the unchecked
            # '8080' this used to hardcode regardless of whether it matched --
            # search the same candidate pool as the plain-Str branch below and
            # fall back to the toggle only when nothing in it satisfies the
            # pattern.
            if ($opts->{pattern}) {
                my @ok = grep { $_ =~ $opts->{pattern} } @PATTERN_CANDIDATES;
                return $ok[0] if @ok;
            }
            return ($ios_toggle++ % 2) ? '8080' : 'http';
        }
        return '100m'                  if $info->{is_quantity};
        return '2024-01-01T00:00:00Z'  if $info->{is_time};
        # A plain (non-array, non-IntOrStr) Str field can carry its own
        # 'pattern' too -- cert-manager's embedded Gateway API ParentReference
        # (group/kind/namespace/sectionName, all DNS-label-shaped),
        # CertificateRenewalWindows.windowDuration (a Go-duration-shaped
        # string), and Cilium's IP/CIDR/BGP-community-shaped fields (k95:
        # CiliumBGPPeer.peerAddress, Frontend.ip, CiliumEgressGatewayPolicySpec
        # .destinationCIDRs, BGPCommunities.large) are the shipped fields of
        # this exact shape. Same reasoning as the is_array_of_str candidate-list
        # below: an unconstrained "synthetic-$attr" isn't a valid instance of
        # the field.
        if ($opts->{pattern}) {
            my @ok = grep { $_ =~ $opts->{pattern} } @PATTERN_CANDIDATES;
            return $ok[0] if @ok;
        }
        return "synthetic-$attr";      # is_str, and the generic fallback
    }

    # ============================================================================
    # Recursive struct construction
    # ============================================================================

    # Only populated along *required* edges - see object_field_value.
    my %building;

    sub object_field_value {
        my ($target_class, $mode, $depth, $required) = @_;

        return union_bare_value($target_class) if $target_class->can('FROM_STRUCT');

        if (!$required) {
            # Optional edge: MAX_DEPTH alone guarantees termination (this is
            # what breaks JSONSchemaProps's self-reference), so there's no
            # need to track it on the cycle stack - and doing so would
            # misfire, since the same class legitimately gets revisited via
            # different optional paths within the depth bound.
            return undef if $depth >= MAX_DEPTH;
            return build_struct($target_class, $mode, $depth + 1);
        }

        # Required edge: must always produce a value, so depth doesn't apply.
        # Guard against a genuine required-field cycle (which would mean the
        # schema is impossible to instantiate at all) so a future regression
        # fails loudly here instead of recursing forever. No shipped class
        # currently triggers this.
        if ($building{$target_class}) {
            die "cycle detected while building a REQUIRED chain into $target_class (depth $depth) - "
              . "this class's required fields form a loop that can never be satisfied";
        }
        local $building{$target_class} = 1;
        return build_struct($target_class, $mode, $depth + 1);
    }

    sub synth_value {
        my ($info, $attr, $mode, $depth, $class) = @_;
        my $opts = $info->{options} // {};

        # Per-element D3 constraints on an array of scalars (k8s tags => [Str],
        # { enum => [...] } / { pattern => ... }) -- same reasoning as
        # synth_scalar's enum/minimum/maximum handling: a value the field's own
        # constraint rejects isn't a valid instance, so pick one that satisfies
        # it instead of the unconstrained default.
        if ($info->{is_array_of_str}) {
            return [ @{ $opts->{enum} }[ 0, $#{ $opts->{enum} } ? 1 : 0 ] ] if $opts->{enum};
            if ($opts->{pattern}) {
                my @ok = grep { $_ =~ $opts->{pattern} } @PATTERN_CANDIDATES;
                return [ @ok[ 0, $#ok ? 1 : 0 ] ] if @ok;
            }
            return [ 'a', 'b' ];
        }
        if ($info->{is_array_of_int}) {
            my @vals = (1, 2, 3);
            @vals = map {
                my $v = $_;
                $v = $opts->{minimum} if defined $opts->{minimum} && $v < $opts->{minimum};
                $v = $opts->{maximum} if defined $opts->{maximum} && $v > $opts->{maximum};
                $v;
            } @vals if defined $opts->{minimum} || defined $opts->{maximum};
            return \@vals;
        }
        return [ 1, 0, 1 ]  if $info->{is_array_of_bool};    # the exact DeviceAttribute.bools shape
        # k96 task-2 review: these four used to register with no flag at all
        # (see the block comment above isa_text_for) and fell through to the
        # isa-text fallback in synth_value below, which produced these same
        # values by sniffing the real Moo ArrayRef[X] constraint. Now that the
        # registry carries the flag directly, match those values here instead
        # -- same synthetic data, sourced from the registry like every other
        # case in this function rather than the isa-text side channel.
        return [ 1.5, 2.5 ]                               if $info->{is_array_of_num};
        return [ '8080', 'http' ]                         if $info->{is_array_of_int_or_string};
        return [ '100m', '1Gi' ]                          if $info->{is_array_of_quantity};
        return [ '2024-01-01T00:00:00Z' ]                 if $info->{is_array_of_time};
        return { 'sample-key' => 'sample-value' } if $info->{is_hash_of_str} || $info->{is_hash_opaque};
        # map[string][]string (k194)
        return { 'sample-key' => [ 'sample-a', 'sample-b' ] } if $info->{is_hash_of_str_arrays};
        # Typed value maps -- the { TypeName => 1 } DSL form (k63). Each value
        # must satisfy the scalar constraint the map carries.
        return { 'sample-key' => '100m' }                 if $info->{is_hash_of_quantity};
        return { 'sample-key' => 5 }                       if $info->{is_hash_of_int};
        return { 'sample-key' => 1.5 }                     if $info->{is_hash_of_num};
        return { 'sample-key' => 1 }                       if $info->{is_hash_of_bool};
        return { 'sample-key' => '2024-01-01T00:00:00Z' }  if $info->{is_hash_of_time};
        return { 'sample-key' => '8080' }                  if $info->{is_hash_of_int_or_string};
        # Opaque array-of-hash / array-of-array forms (k66).
        return [ { 'sample-key' => 'sample-value' } ]      if $info->{is_array_of_hash};
        return [ [ 'sample-a', 'sample-b' ] ]              if $info->{is_array_of_array};

        if ($info->{is_hash_of_objects}) {
            my $child = object_field_value($info->{class}, $mode, $depth, $info->{required});
            return defined $child ? { 'sample-key' => $child } : undef;
        }
        if ($info->{is_hash_of_object_arrays}) {    # map[string][]Object (k194)
            my $child = object_field_value($info->{class}, $mode, $depth, $info->{required});
            return defined $child ? { 'sample-key' => [$child] } : undef;
        }
        if ($info->{is_array_of_objects}) {
            my $child = object_field_value($info->{class}, $mode, $depth, $info->{required});
            return defined $child ? [$child] : undef;
        }
        if ($info->{is_object}) {    # covers is_inline_struct too - it's always is_object as well
            return object_field_value($info->{class}, $mode, $depth, $info->{required});
        }

        # Nothing matched - the isa-text fallback described above isa_text_for.
        if (!%$info || (keys %$info == 1 && exists $info->{required})) {
            my $isa_text = isa_text_for($class, $attr);
            if (defined $isa_text && $isa_text =~ /ArrayRef/) {
                return [ '100m', '1Gi' ]          if $isa_text =~ /Quantity/;
                return [ '8080', 'http' ]         if $isa_text =~ /IntOrStr/;
                return ['2024-01-01T00:00:00Z']   if $isa_text =~ /Time/;
                return [ "synthetic-$attr-a", "synthetic-$attr-b" ];
            }
        }

        return synth_scalar($info, $attr);
    }

    sub build_struct {
        my ($class, $mode, $depth) = @_;
        my $reg = $registry->{$class} // {};
        my $req = required_flags_for($class);
        my $skip = $SKIP_FIELD{$class};
        my %struct;
        for my $attr (sort keys %$reg) {
            next if $skip && $skip->{$attr};
            my $info = { %{ $reg->{$attr} }, required => ($req->{$attr} // 0) };
            next if $mode eq 'required' && !$info->{required};
            my $key = $info->{json_key} // $attr;
            my $val = synth_value($info, $attr, $mode, $depth, $class);
            next unless defined $val;
            $struct{$key} = $val;
        }
        return \%struct;
    }

    # ============================================================================
    # The sweep
    # ============================================================================

    my $classes_tested = 0;

    subtest 'registry synthesis: every registry class inflates, serializes and round-trips' => sub {
        cmp_ok(scalar(@classes), '>', 800, 'registry has the expected order of magnitude of classes')
            or diag("only " . scalar(@classes) . " classes in the registry - did the load loop above run?");

        for my $class (@classes) {
            $classes_tested++;

            subtest $class => sub {
                for my $mode (qw(required full)) {
                    %building = ();

                    my $struct = eval { build_struct($class, $mode, 0) };
                    if (my $err = $@) {
                        fail("$class ($mode): build_struct did not die");
                        diag($err);
                        next;
                    }

                    my $obj1 = eval { $io->struct_to_object($class, $struct) };
                    if (my $err = $@) {
                        fail("$class ($mode): struct_to_object($class, ...) did not die");
                        diag("struct: " . $json_iso->encode($struct));
                        diag($err);
                        next;
                    }
                    isa_ok($obj1, $class, "$class ($mode) inflated object");

                    # Type checks on this class's OWN fields (not recursed into
                    # children - every child class gets its own top-level pass at
                    # depth 0, where this same block checks its own fields).
                    my $out1 = $obj1->TO_JSON;
                    my $reg  = $registry->{$class} // {};
                    for my $attr (sort keys %$reg) {
                        my $info = $reg->{$attr};
                        my $key  = $info->{json_key} // $attr;
                        next unless exists $out1->{$key};

                        if ($info->{is_bool}) {
                            is(ref($out1->{$key}), 'JSON::PP::Boolean',
                                "$class ($mode) .$key is a real JSON boolean, not a plain 1/0");
                        }
                        elsif ($info->{is_array_of_bool}) {
                            my @refs = map { ref($_) } @{ $out1->{$key} };
                            ok((@refs && !grep { $_ ne 'JSON::PP::Boolean' } @refs),
                                "$class ($mode) .$key elements are real JSON booleans, not 1/0 (the DeviceAttribute.bools bug shape)")
                                or diag("refs: @refs");
                        }
                        elsif ($info->{is_int}) {
                            like($json_iso->encode($out1->{$key}), qr/^-?\d+\z/,
                                "$class ($mode) .$key serializes as an unquoted number");
                        }
                        elsif ($info->{is_num}) {
                            like($json_iso->encode($out1->{$key}), qr/^-?[\d.]+(?:[eE][-+]?\d+)?\z/,
                                "$class ($mode) .$key serializes as an unquoted number");
                        }
                        elsif ($info->{is_array_of_int}) {
                            my @encoded = map { $json_iso->encode($_) } @{ $out1->{$key} };
                            ok((@encoded && !grep { !/^-?\d+\z/ } @encoded),
                                "$class ($mode) .$key elements serialize as unquoted numbers")
                                or diag("encoded: @encoded");
                        }
                        elsif ($info->{is_hash_of_str_arrays}) {
                            # map[string][]string: every element must hit the wire as a JSON string
                            my @encoded = map { $json_iso->encode($_) } map { @$_ } values %{ $out1->{$key} };
                            ok((@encoded && !grep { !/^"/ } @encoded),
                                "$class ($mode) .$key elements serialize as JSON strings")
                                or diag("encoded: @encoded");
                        }
                        elsif ($info->{is_hash_of_str}) {
                            # map[string]string: every value must hit the wire as a JSON string
                            my %encoded = map { $_ => $json_iso->encode($out1->{$key}{$_}) } keys %{ $out1->{$key} };
                            ok((%encoded && !grep { !/^"/ } values %encoded),
                                "$class ($mode) .$key values serialize as JSON strings")
                                or diag("encoded: " . join(', ', map { "$_=$encoded{$_}" } sort keys %encoded));
                        }
                    }

                    my $json1 = eval { $obj1->to_json };
                    if (my $err = $@) {
                        fail("$class ($mode): to_json did not die");
                        diag($err);
                        next;
                    }

                    # The round trip that matters: decode through a *real* JSON
                    # string (producing JSON::PP::Boolean objects for any bool,
                    # exactly like a real cluster response) and re-inflate. This is
                    # the step that died for DeviceAttribute.bools before the Bool
                    # array-element coercion existed.
                    my $decoded = $io->json->decode($json1);
                    my $obj2    = eval { $io->struct_to_object($class, $decoded) };
                    if (my $err = $@) {
                        fail("$class ($mode): re-inflating $class from its own real-JSON output did not die");
                        diag("json1: $json1");
                        diag($err);
                        next;
                    }

                    my $json2 = eval { $obj2->to_json };
                    if (my $err = $@) {
                        fail("$class ($mode): to_json (second pass) did not die");
                        diag($err);
                        next;
                    }

                    is($json2, $json1, "$class ($mode): inflate/TO_JSON/decode/re-inflate is byte-stable");
                }
            };
        }

        is($classes_tested, scalar(@classes), 'every registry class was exercised');
    };
}

# ===========================================================================
# was t/27_no_import_leak.t, part 2b: the composition direction, on the
# shipped classes.
#
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
# The same list lives in t/27_no_import_leak.t (2c-2e, which need fixture
# classes and so cannot run in this process); keep the two in step.
my @LEAKED = qw(
    croak use_module require_module HashRef cidr_contains
    blessed reftype InstanceOf Maybe ArrayRef
);

subtest 'import leak 2b: no shipped resource class carries a leaked import' => sub {
    my @resource_classes = grep {
        $_->can('does') && eval { $_->does('IO::K8s::Role::Resource') }
    } @MODULES;

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

};

# ===========================================================================
# was t/152_k191_no_legacy_ref_warning.t, subtests 1 and 3
#
# k191 spec test 8: loading and serializing the SHIPPED classes must never
# trigger the legacy-{ Str => 1 } deprecation warning ("declare it as Opaque or
# HashRef[...]"), and every shipped core field that is a string map must be a
# real map[string]string upstream.
#
# The static check (subtest 3) does not depend on some fixture happening to
# carry a ref value: for every core class field whose registry entry says
# is_hash_of_str it looks the property up in spec/v1.37.0.json (falling back
# to v1.36.3.json for classes only older clusters know) and demands
# additionalProperties { type: string }. A field that upstream types as
# map[string][]string, a ResourceList, a RawExtension, ... and that is still
# declared { Str => 1 } fails here.
# ===========================================================================

my $LEGACY = qr/Opaque|HashRef\[|deprecat/i;

sub legacy_warnings { grep { /$LEGACY/ } @WARNINGS }

subtest 'k191: loading every shipped class raises no legacy-map warning' => sub {
    cmp_ok(scalar @MODULES, '>', 800, 'walked the whole tree (' . scalar(@MODULES) . ' modules)');
    my @failed = map { "$_: $LOAD_ERROR{$_}" } grep { defined $LOAD_ERROR{$_} } @MODULES;
    is(scalar @failed, 0, 'every module loads') or diag explain \@failed;
    is(scalar(legacy_warnings()), 0, 'no legacy-map warning while loading')
        or diag explain [ legacy_warnings() ];
};

subtest 'k191: every core is_hash_of_str field is additionalProperties {type: string} upstream' => sub {
    # v1.37.0 first; classes it no longer knows (kept as a superset for older
    # clusters) fall back to v1.36.3. A class in neither is reported, not skipped.
    # spec/ is not shipped in the built dist: without v1.37.0 there is nothing
    # to check, without v1.36.3 only the fallback classes cannot be checked.
    my @have = grep { $ROOT->child('spec', $_)->is_file } qw( v1.37.0.json v1.36.3.json );
    plan skip_all => 'spec/v1.37.0.json not available (spec/ is not shipped in the dist)'
        unless grep { $_ eq 'v1.37.0.json' } @have;
    my $have_fallback = grep { $_ eq 'v1.36.3.json' } @have;

    my @specs = map {
        my $d = JSON::MaybeXS->new->decode($ROOT->child('spec', $_)->slurp_raw)->{definitions};
        ok($d, "$_ has definitions");
        my %for_class;
        for my $key (keys %$d) {
            my $class = defkey_to_perl_class($key) or next;
            $for_class{$class} = $key;
        }
        { name => $_, defs => $d, for_class => \%for_class };
    } @have;

    my ($checked, $mapped_classes, $fallback, @wrong, @unmatched, @no_upstream, @fallback_skipped) = (0, 0, 0);

    # Deliberately skipped: kept as a superset for older clusters, but neither
    # v1.37.0 nor v1.36.3 carries the definition, so there is nothing to check
    # against. Anything else that lands in @no_upstream is a failure.
    my %SKIPPED = ( 'IO::K8s::Api::Storage::V1alpha1::VolumeAttributesClass.parameters' => 1 );

    for my $class (sort grep { /$CORE/ } keys %$registry) {
        my @fields = grep { $registry->{$class}{$_}{is_hash_of_str} } sort keys %{ $registry->{$class} };
        my ($spec) = grep { $_->{for_class}{$class} } @specs;
        unless ($spec) {
            # Without the v1.36.3 fallback these cannot be told apart from a
            # real gap, so they are reported as skipped instead.
            my @gone = grep { !$SKIPPED{$_} } map { "$class.$_" } @fields;
            if ($have_fallback) { push @no_upstream, @gone } else { push @fallback_skipped, @gone }
            next;
        }
        $mapped_classes++;
        $fallback += @fields if $spec != $specs[0];
        my $defs  = $spec->{defs};
        my $props = $defs->{ $spec->{for_class}{$class} }{properties} // {};
        for my $attr (@fields) {
            my $prop = $props->{$attr} // $props->{ '$' . substr($attr, 1) };
            unless ($prop) {
                push @unmatched, "$class.$attr";
                next;
            }
            $prop = $defs->{ ($prop->{'$ref'} =~ s{^#/definitions/}{}r) } // $prop if $prop->{'$ref'};
            my $ap = $prop->{additionalProperties};
            $checked++;
            my $ok = ref $ap eq 'HASH' && ($ap->{type} // '') eq 'string' && !$ap->{'$ref'};
            push @wrong, "$class.$attr" unless $ok;
        }
    }

    diag 'v1.36.3.json missing, skipped ' . scalar(@fallback_skipped) . ' fields of classes v1.37.0 no longer knows'
        if @fallback_skipped;
    cmp_ok($mapped_classes, '>', 300, "mapped $mapped_classes core classes to upstream definitions");
    # Lower bound only proves the loop is not vacuous (at time of writing 25
    # core fields carry is_hash_of_str); it is deliberately loose so that
    # retyping a field to Opaque/HashRef[...] does not break this test.
    cmp_ok($checked, '>=', 20, "checked $checked string-map fields against the schema ($fallback via the v1.36.3 fallback)");
    is_deeply(\@no_upstream, [], 'every string-map field belongs to a class known to v1.37.0 or v1.36.3')
        or diag "in neither spec: @no_upstream";
    is_deeply(\@unmatched, [], 'every string-map field has an upstream property of that name')
        or diag "no upstream property: @unmatched";
    is_deeply(\@wrong, [], 'no string-map field is anything but map[string]string upstream')
        or diag "not map[string]string upstream:\n  " . join("\n  ", @wrong);
};

# ===========================================================================
# was t/153_k196_number_wire_type.t, last subtest (the static one; the wire
# claims stay in t/153 because they declare a fixture class of their own)
#
# Statically: every scalar field of a shipped core class has the kind its
# upstream property declares (Str <-> string, Int <-> integer, Num <-> number,
# Bool <-> boolean), so a class that types a number as Str again fails here,
# not at the API server -- and compare_to_schema describes a Num field as
# number.
# ===========================================================================

my $PROPS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';

subtest 'k196: every core scalar field has the kind its upstream property declares' => sub {
    my @have = grep { $ROOT->child('spec', $_)->is_file } qw( v1.37.0.json v1.36.3.json );
    plan skip_all => 'spec/v1.37.0.json not available (spec/ is not shipped in the dist)'
        unless grep { $_ eq 'v1.37.0.json' } @have;

    # The shared load already required every module under lib/IO/K8s; a
    # failure is reported here as the standalone test did.
    for my $mod (@K8S_MODULES) { fail("load $mod: $LOAD_ERROR{$mod}") if defined $LOAD_ERROR{$mod} }

    my @specs = map {
        my $d = JSON::MaybeXS->new->decode($ROOT->child('spec', $_)->slurp_raw)->{definitions};
        my %for_class;
        for my $key (keys %$d) {
            my $class = defkey_to_perl_class($key) or next;
            $for_class{$class} = $key;
        }
        { defs => $d, for_class => \%for_class };
    } @have;

    # Scalar kind flag -> the OpenAPI type it stands for. Quantity, Time
    # and IntOrStr are $refs or formats upstream and are not scalar kinds here.
    my %WANT = ( is_str => 'string', is_int => 'integer', is_num => 'number', is_bool => 'boolean' );
    my ($checked, $numbers, @wrong) = (0, 0);

    for my $class (sort grep { /$CORE/ } keys %$registry) {
        my ($spec) = grep { $_->{for_class}{$class} } @specs or next;
        my $props = $spec->{defs}{ $spec->{for_class}{$class} }{properties} // {};
        for my $attr (sort keys %{ $registry->{$class} }) {
            my $entry = $registry->{$class}{$attr};
            next if $entry->{is_quantity} || $entry->{is_time} || $entry->{is_int_or_string};
            my ($flag) = grep { $entry->{$_} } sort keys %WANT or next;
            my $prop = $props->{ $entry->{json_key} // $attr } or next;
            next if $prop->{'$ref'};
            $checked++;
            $numbers++ if ($prop->{type} // '') eq 'number';
            push @wrong, "$class.$attr: declared " . ($flag =~ s/^is_//r)
                . ", upstream type " . ($prop->{type} // '(none)')
                unless ($prop->{type} // '') eq $WANT{$flag};
        }
    }

    # compare_to_schema, the per-class form of this check, reads Num as
    # number (it had no arm for it and reported 'unknown').
    my $props_def = $specs[0]{defs}{ $specs[0]{for_class}{$PROPS} };
    my @num_mismatch = grep { $_->{attr} =~ /^(?:minimum|maximum|multipleOf)\z/ }
        @{ $PROPS->compare_to_schema($props_def)->{type_mismatch} };
    is_deeply(\@num_mismatch, [], 'compare_to_schema: the number fields match upstream')
        or diag explain \@num_mismatch;

    cmp_ok($checked, '>', 1000, "checked $checked scalar fields against the schema");
    cmp_ok($numbers, '>=', 3, "$numbers of them are upstream type: number");
    is_deeply(\@wrong, [], 'every scalar field matches its upstream type')
        or diag join "\n", @wrong;
};
# ===========================================================================
# was t/159_k193_no_legacy_map_declarations.t
#
# k193: the legacy `{ X => 1 }` map spelling is gone from the shipped tree; maps
# are declared HashRef[X] (typed) or HashRef[Str] (strict string map).
#
#  1. Registry: after loading every shipped class no field carries
#     is_hash_of_str_lenient, the flag only the legacy `{ Str => 1 }` sets
#     (lib/IO/K8s/Resource.pm). This catches a field that went through the
#     legacy form at load time, in any shipped class.
#  2. Source scan: the lenient flag exists only for Str; `{ Quantity => 1 }`
#     and the object-map forms leave no trace in the registry, so every lib
#     file is scanned for a `k8s name => { X => 1 }` statement. Option hashes
#     (`Int, { minimum => 1 }`) follow a comma and never match.
#  3. maint/crd-drift-check.pl: _structural_signature must no longer equate
#     HashRef[X] with `{ X => 1 }` -- the normalisation existed only because
#     lib still carried the legacy form.
# ===========================================================================

my @K193_FILES = sort map { $PATH_OF{$_} } @K8S_MODULES;
subtest 'k193: found the shipped classes' => sub {
    cmp_ok(scalar @K193_FILES, '>', 500, 'found the shipped classes')
        or BAIL_OUT('lib walk failed');
};

# (the registry check below needs no load of its own: the shared load above
# is the "require every shipped class" step the standalone test did first.)
subtest 'k193: no shipped field carries the legacy lenient string-map flag' => sub {
    my @lenient;
    my $classes = 0;
    for my $class (sort keys %IO::K8s::Resource::_attr_registry) {
        next unless $class =~ /^IO::K8s::/;
        $classes++;
        my $attrs = $IO::K8s::Resource::_attr_registry{$class};
        for my $attr (sort keys %$attrs) {
            push @lenient, "$class->$attr" if $attrs->{$attr}{is_hash_of_str_lenient};
        }
    }
    cmp_ok($classes, '>', 500, 'registry is populated');
    is_deeply(\@lenient, [], 'no is_hash_of_str_lenient field')
        or diag scalar(@lenient) . ' fields, first: '
            . join ', ', @lenient[0 .. ($#lenient > 9 ? 9 : $#lenient)];
};

# ---- 2. source scan -------------------------------------------------------
my $legacy_re = qr/^\s*k8s\s+(?:\w+|'[^']+'|"[^"]+")\s*=>\s*\{\s*\w+\s*=>\s*1\s*\}/;

subtest 'k193: scan pattern sanity (it must bite, and spare option hashes)' => sub {
    like('k8s labels => { Str => 1 };', $legacy_re, 'legacy Str map matches');
    like('k8s   requests   =>   {Quantity=>1};', $legacy_re, 'legacy Quantity map matches');
    unlike('k8s size => Int, { minimum => 1 };', $legacy_re, 'option hash does not match');
    unlike('k8s labels => HashRef[Str];', $legacy_re, 'new spelling does not match');
};

subtest 'k193: no lib file declares a map as { X => 1 }' => sub {
    my @hits;
    for my $path (@K193_FILES) {
        open my $fh, '<:raw', $path or die "cannot read $path: $!";
        my $src = do { local $/; <$fh> };
        close $fh;
        my $in_pod = 0;
        my $n      = 0;
        for my $line (split /\n/, $src, -1) {
            $n++;
            if ($line =~ /^=cut\b/) { $in_pod = 0; next }
            if ($line =~ /^=\w/)    { $in_pod = 1; next }
            next if $in_pod || $line =~ /^\s*#/;
            if ($line =~ $legacy_re) {
                (my $rel = $path) =~ s{^\Q$root\E/}{};
                push @hits, "$rel:$n";
            }
        }
    }
    is_deeply(\@hits, [], 'no legacy map declaration')
        or diag scalar(@hits) . ' hits, first: '
            . join ', ', @hits[0 .. ($#hits > 9 ? 9 : $#hits)];
};

# ---- 3. crd-drift-check _structural_signature -----------------------------
my $script = "$root/maint/crd-drift-check.pl";
my $source = do {
    open my $fh, '<:raw', $script or die "cannot read $script: $!";
    local $/;
    <$fh>;
};
my ($sig_sub) = $source =~ /^(sub _structural_signature \{.*?^\})$/ms;
ok($sig_sub, 'found sub _structural_signature') or BAIL_OUT('sub _structural_signature gone');
{
    package T159;
    use strict;
    use warnings;
    ## no critic
    eval "$sig_sub\n1;" or die "cannot eval _structural_signature: $@";
}

sub sig { T159::_structural_signature(@_) }

subtest 'k193: _structural_signature no longer equates HashRef[X] with { X => 1 }' => sub {
    isnt(sig("k8s labels => HashRef[Str];\n"), sig("k8s labels => { Str => 1 };\n"),
        'HashRef[Str] differs from { Str => 1 }');
    isnt(sig("k8s requests => HashRef[Quantity];\n"), sig("k8s requests => { Quantity => 1 };\n"),
        'HashRef[Quantity] differs from { Quantity => 1 }');
    isnt(sig("k8s weights => HashRef[Foo];\n"), sig("k8s weights => { Foo => 1 };\n"),
        'object-map spellings differ too');
    is(sig("k8s labels => HashRef[Str];\n"), sig("k8s labels   =>   HashRef[Str];\n"),
        'whitespace-only change still equal');
    isnt(sig("k8s labels => HashRef[Str];\n"), sig("k8s labels => HashRef[Int];\n"),
        'different value types still differ');
};

# ===========================================================================
# was t/79_to_crd.t: the sweeps over the shipped classes (k96 smoke, k110,
# k114). The fixture-bearing subtests stay in t/79_to_crd.t.
# ===========================================================================

require Module::Runtime;

subtest 'to_crd smoke: every shipped, resource_plural-bearing Kind survives to_crd' => sub {
    require File::Find;
    require Module::Runtime;
    (my $lib = $INC{'IO/K8s.pm'}) =~ s{/IO/K8s\.pm\z}{};
    my @classes;
    File::Find::find(sub {
        return unless /\.pm\z/;
        (my $c = $File::Find::name) =~ s{^\Q$lib\E/}{};
        $c =~ s{/}{::}g;
        $c =~ s/\.pm\z//;
        push @classes, $c;
    }, "$lib/IO/K8s/Api", "$lib/IO/K8s/Apimachinery", "$lib/IO/K8s/ApiextensionsApiserver",
       "$lib/IO/K8s/KubeAggregator", "$lib/IO/K8s/Cilium", "$lib/IO/K8s/Traefik",
       "$lib/IO/K8s/CertManager", "$lib/IO/K8s/GatewayAPI", "$lib/IO/K8s/K3s",
       "$lib/IO/K8s/AgentSandbox", "$lib/IO/K8s/PrometheusOperator",
       "$lib/IO/K8s/VolumeSnapshot", "$lib/IO/K8s/ExternalSecrets");

    my @failed;
    my $checked = 0;
    for my $class (sort @classes) {
        eval { Module::Runtime::use_module($class); 1 } or next;
        next unless $class->can('_is_resource');
        next unless $class->can('resource_plural') && defined eval { $class->resource_plural };
        $checked++;
        eval { $class->to_crd; 1 } or push @failed, "$class: $@";
    }
    ok($checked > 100, "checked a real number of Kinds ($checked)");
    is_deeply(\@failed, [], 'no shipped Kind fails Class->to_crd');
};

# (k110 and k114 below used to run after the smoke subtest on purpose, because
# that one had loaded every shipped class; the shared load above now does.)
subtest 'to_crd k110: no shipped qr// pattern croaks or changes on emit' => sub {
    my ($checked, @drifted) = (0);
    for my $class (sort grep { /\AIO::K8s::/ } keys %IO::K8s::Resource::_attr_registry) {
        my $info = $IO::K8s::Resource::_attr_registry{$class};
        for my $attr (sort keys %$info) {
            my $opts = $info->{$attr}{options} or next;
            my $p    = $opts->{pattern};
            next unless defined $p && ref $p eq 'Regexp';
            $checked++;
            # The pre-k110 emission: re::regexp_pattern's raw text. Every
            # shipped pattern must translate to exactly that, so a rule
            # that starts rejecting or rewriting real provider patterns
            # fails here rather than in a consumer's cluster.
            my $before = (re::regexp_pattern($p))[0];
            my $after  = eval { IO::K8s::CRD::_pattern_to_ecma262($p, "$class.$attr") };
            if ($@) { push @drifted, "$class.$attr croaks: $@"; next }
            push @drifted, "$class.$attr: '$before' -> '$after'" if $after ne $before;
        }
    }
    ok($checked > 100, "checked a real number of shipped qr// patterns ($checked)");
    is_deeply(\@drifted, [], 'the shipped patterns are all already ECMA262');
};

sub _crd_pattern {
    my ($p, $where) = @_;
    return ref $p eq 'Regexp' ? IO::K8s::CRD::_pattern_to_ecma262($p, $where) : $p;
}

subtest 'to_crd k114: the emitter is a fixed point on every shipped pattern' => sub {
    my ($checked, @drifted) = (0);
    for my $class (sort grep { /\AIO::K8s::/ } keys %IO::K8s::Resource::_attr_registry) {
        my $info = $IO::K8s::Resource::_attr_registry{$class};
        for my $attr (sort keys %$info) {
            my $opts = $info->{$attr}{options} or next;
            next unless exists $opts->{pattern};
            $checked++;
            my $p     = $opts->{pattern};
            my $where = "$class.$attr";

            my $want = eval { _crd_pattern($p, $where) };
            if ($@) { push @drifted, "$where croaks on emit: $@"; next }

            my $literal = eval { IO::K8s::CRD::Emitter::_pattern_literal($p) };
            if ($@) { push @drifted, "$where croaks in the emitter: $@"; next }

            my $back = eval $literal;
            my $got  = eval { _crd_pattern($back, $where) };
            push @drifted,
                "$where: emits '$want', renders as $literal, which emits "
                . (defined $got ? "'$got'" : "nothing ($@)")
                if !defined $got || $got ne $want;
        }
    }
    ok($checked > 300, "checked every shipped pattern field ($checked)");
    is_deeply(\@drifted, [], 'rendering a shipped pattern and reading it back changes nothing');

    # The fixed-point check above cannot see an artifact that is ALREADY
    # baked into a shipped class -- '\@' is an escaped unit, so re-rendering
    # it reproduces it and the fixed point holds. These two spellings are
    # what an artifact looks like once it is in: '\@' is an invalid identity
    # escape in ECMA262's unicode mode and '\x{...}' is not ECMA262 at all,
    # so no CRD author writes either -- in an openAPIV3Schema.pattern they
    # mean IO::K8s' own qr// rendering put them there (k114). '\$' is left
    # out on purpose: it is a legal ECMA262 escape an author may really have
    # written, so its presence proves nothing.
    my @artifacts;
    for my $class (sort grep { /\AIO::K8s::/ } keys %IO::K8s::Resource::_attr_registry) {
        my $info = $IO::K8s::Resource::_attr_registry{$class};
        for my $attr (sort keys %$info) {
            my $opts = $info->{$attr}{options} or next;
            next unless exists $opts->{pattern};
            my $text = eval { _crd_pattern($opts->{pattern}, "$class.$attr") };
            next unless defined $text;
            push @artifacts, "$class.$attr: '$text'" if $text =~ /\\\@|\\x\{/;
        }
    }
    is_deeply(\@artifacts, [],
        q{no shipped pattern reaches a CRD carrying a '\@' or '\x{...}' escape});
};

# ===========================================================================
# was t/51_resource_plural.t: the two coverage subtests over the shipped
# classes. The plural-resolution subtests, which need fixture classes of their
# own, stay in t/51_resource_plural.t.
# ===========================================================================

subtest 'plural: coverage over the default resource map' => sub {
    # Regression guard for a bad regeneration: every short name in the
    # built-in map must resolve to a plural except the three subresources.
    # Unchanged by k36 -- the short names all point at served versions,
    # so they were already answered by tier 1.
    my $map = IO::K8s->default_resource_map;
    my @short = grep { !m{/} } sort keys %$map;

    my @without;
    for my $kind (@short) {
        my $class = IO::K8s->expand_class($kind);
        IO::K8s->load_class($class);
        push @without, $kind unless defined $class->resource_plural;
    }

    is_deeply(\@without, [qw(Eviction Scale TokenRequest)],
        'exactly the three subresources have no plural');
    is(scalar(@short) - scalar(@without), 77,
        '77 of the 80 short names carry an upstream plural');
};

subtest 'plural: coverage over every shipped upstream API class' => sub {
    # The guard k36 is actually about: the whole shipped surface the
    # generated tables are supposed to cover, not just the short names in
    # the default resource map. Anything in one of the three namespaces
    # _api_version_from_class() understands, composing Role::APIObject.
    #
    # k45: the seven embedded template types (PodTemplateSpec,
    # JobTemplateSpec, PersistentVolumeClaimTemplate, and the four
    # ResourceClaimTemplateSpec versions) now compose IO::K8s::Resource
    # instead of Role::APIObject -- upstream's schema for them carries no
    # apiVersion/kind -- so they no longer satisfy does('...Role::APIObject')
    # and drop out of @api entirely, rather than landing in @without.
    my @classes = @MODULES;

    my @api;
    for my $class (sort @classes) {
        next unless $class =~ /\AIO::K8s::(?:Api|ApiextensionsApiserver|KubeAggregator)::/;
        IO::K8s->load_class($class);
        next if Role::Tiny->is_role($class);
        next unless $class->can('does') && $class->does('IO::K8s::Role::APIObject');
        push @api, $class;
    }

    my @without = grep { !defined $_->resource_plural } @api;

    is(scalar @api, 124, '124 shipped upstream API object classes (113 before the v1.37 sync, karr k72)');
    is(scalar(@api) - scalar(@without), 121,
        '121 of them carry an upstream plural (110 before the v1.37 sync, karr k72)');

    # The exact miss list: just the 3 subresources now. The 7 embedded
    # template types are no longer Role::APIObject classes at all, so they
    # never reach @api to be filtered into @without.
    is_deeply(\@without, [qw(
        IO::K8s::Api::Authentication::V1::TokenRequest
        IO::K8s::Api::Autoscaling::V1::Scale
        IO::K8s::Api::Policy::V1::Eviction
    )], 'exactly the subresources stay undef');
};

# ===========================================================================
# was t/152_k191_no_legacy_ref_warning.t, subtest 2
#
# Inflating and serializing real manifests (t/25's own heredocs) and a built
# one must not raise the legacy-map warning either. Last in the file on
# purpose: it creates objects, the sweeps above only read the loaded state.
# ===========================================================================

subtest 'k191: real-world manifests inflate and serialize without a legacy-map warning' => sub {
    eval { require YAML::PP; 1 }
        or plan skip_all => 'YAML::PP required for the real-world manifests';

    my $src = $ROOT->child('t', '25_real_world.t')->slurp_utf8;
    my @docs;
    while ($src =~ /<<'(END_YAML)';\n(.*?)\n\1\n/sg) {
        push @docs, YAML::PP->new->load_string($2);
    }
    cmp_ok(scalar @docs, '>=', 10, 'picked up the t/25 manifests (' . scalar(@docs) . ')');

    my $k8s = IO::K8s->new;
    my @objects;
    local $SIG{__WARN__} = sub { push @WARNINGS, "@_" };
    my $before = @WARNINGS;

    for my $doc (@docs) {
        next unless ref $doc eq 'HASH' && $doc->{kind};
        my $obj = eval { $k8s->inflate($doc) };
        ok($obj, 'inflate ' . $doc->{kind}) or diag $@;
        push @objects, $obj if $obj;
    }

    # the t/26 shape: built in Perl, labels/annotations/data carrying numbers
    push @objects, $k8s->new_object('ConfigMap',
        metadata => { name => 'cm', labels => { v => 5 + 0 }, annotations => { a => 1.5 } },
        data     => { port => 8080 });
    push @objects, $k8s->new_object('Deployment',
        metadata => { name => 'd', labels => { app => 'x' } },
        spec     => {
            replicas => 2,
            selector => { matchLabels => { app => 'x' } },
            template => {
                metadata => { labels => { app => 'x' } },
                spec     => {
                    nodeSelector => { disk => 'ssd' },
                    overhead     => { cpu => '250m', memory => '120Mi' },
                    containers   => [ { name => 'c', image => 'nginx',
                        resources => { limits => { cpu => '1' }, requests => { cpu => '100m' } } } ],
                },
            },
        });

    for my $obj (@objects) {
        eval { $obj->to_json; $obj->TO_JSON; $obj->to_yaml; 1 } or fail('serialize ' . ref($obj) . ": $@");
    }
    ok(scalar(@objects) > 10, 'serialized ' . scalar(@objects) . ' objects');

    my @mine = @WARNINGS[ $before .. $#WARNINGS ];
    is(scalar(grep { /$LEGACY/ } @mine), 0, 'no legacy-map warning while inflating/serializing')
        or diag explain \@mine;
};

done_testing;
