#!/usr/bin/env perl
# Registry-driven synthesis + round-trip test.
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

use strict;
use warnings;
use Test::More;
use File::Find;
use JSON::MaybeXS;
use lib 'lib';
use IO::K8s;

# Load every shipped class, exactly like t/34, so the registry is fully
# populated (including inline-struct classes, which materialise only
# when their parent .pm is required).
my @pm_paths;
find(
    {
        wanted   => sub { push @pm_paths, $File::Find::name if /\.pm$/ },
        no_chdir => 1,
    },
    'lib/IO/K8s',
);

for my $path (sort @pm_paths) {
    (my $mod = $path) =~ s|^lib/||;
    $mod =~ s|/|::|g;
    $mod =~ s|\.pm$||;
    require_ok($mod);
}

my $registry = \%IO::K8s::Resource::_attr_registry;

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

cmp_ok(scalar(@classes), '>', 800, 'registry has the expected order of magnitude of classes')
    or diag("only " . scalar(@classes) . " classes in the registry - did the load loop above run?");

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
    return { 'sample-key' => 'sample-value' } if $info->{is_hash_of_str};
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
                elsif ($info->{is_array_of_int}) {
                    my @encoded = map { $json_iso->encode($_) } @{ $out1->{$key} };
                    ok((@encoded && !grep { !/^-?\d+\z/ } @encoded),
                        "$class ($mode) .$key elements serialize as unquoted numbers")
                        or diag("encoded: @encoded");
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

done_testing;
