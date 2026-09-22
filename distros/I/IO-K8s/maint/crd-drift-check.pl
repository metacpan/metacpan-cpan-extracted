#!/usr/bin/env perl
# Upstream CRD spec drift checker for the IO::K8s CRD providers.
#
# The CRD analog of maint/spec-drift-check.pl. Where that tool diffs the
# core Kubernetes swagger.json against the shipped IO::K8s::Api::* classes,
# this one diffs each CRD provider's upstream CustomResourceDefinition
# manifests -- at the exact upstream_version the provider pins -- against
# what that provider actually ships: its resource_map (Kind coverage) and,
# where a class models its spec as a typed inline struct rather than an
# opaque hash, the class's k8s() attribute registry (field coverage).
#
# The six providers are IO::K8s::{Cilium,GatewayAPI,AgentSandbox,Traefik,
# CertManager,K3s}. Each one grew a `sub crd_sources` alongside its existing
# `sub upstream_version`: a data-only hook returning the upstream CRD-manifest
# URLs (base + files) for its pinned version, plus a `status`. A provider
# whose upstream publishes no machine-readable openAPIV3Schema (K3s) returns
# status => 'unresolved' and is reported as such rather than diffed.
#
# This is a report generator. It never writes to lib/, never touches the
# karr board, and never modifies the exceptions file -- deciding what a
# reported gap is worth is a human/agent call, not the script's.
#
# Usage:
#   maint/crd-drift-check.pl [--provider NAME]... [options]
#   maint/crd-drift-check.pl --provider Cilium --dir path/to/crd/yamls
#
# Examples:
#   maint/crd-drift-check.pl
#     Drift report for all six providers (cached CRDs under spec/crd/).
#
#   maint/crd-drift-check.pl --provider GatewayAPI --verbose
#     One provider, including entries suppressed by the exceptions file.
#
# Network access: fetches each provider's CRD manifests over HTTPS via
# HTTP::Tiny (raw.githubusercontent.com and GitHub release assets), the
# same discipline as spec-drift-check.pl. Downloaded manifests are cached
# under --cache-dir (default: spec/crd/<Provider>/<upstream_version>/, already
# gitignored) so repeat runs against the same pin don't re-fetch. The cache is
# keyed on the provider's upstream_version, so bumping a pin re-fetches
# automatically; --no-cache forces a re-download regardless.
use strict;
use warnings;
use v5.10;
use FindBin;
use File::Spec;
use File::Find;
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP;
use Cwd qw(realpath);

# File::Spec->rel2abs makes a path absolute but, on Unix, never collapses a
# '..' segment already in it (that's deliberate upstream: collapsing one
# blindly can change what a path means across a symlink). $DIST_ROOT itself
# is built from FindBin::Bin + '..', so left at rel2abs alone it would read
# as ".../maint/.." forever -- harmless for open()/-d, which the OS resolves
# fine, but fatal for the --suggest-dir "not inside lib/" guard below, which
# is a plain string-prefix test: a literal '..' anywhere in either side
# defeats it silently instead of refusing. _canon_abs collapses '.'/'..'
# lexically after rel2abs, with no filesystem lookup -- unlike Cwd::abs_path,
# it works on a --suggest-dir that doesn't exist yet.
sub _canon_abs {
    my ($path) = @_;
    my ($vol, $dirs) = File::Spec->splitpath(File::Spec->rel2abs($path), 1);
    my @out;
    for my $seg (File::Spec->splitdir($dirs)) {
        next if $seg eq '' || $seg eq '.';
        if ($seg eq '..') { pop @out if @out; next; }
        push @out, $seg;
    }
    return File::Spec->catdir($vol, File::Spec->rootdir, @out);
}

# _canon_abs is lexical only -- it never touches the filesystem, so a
# symlink component (a --suggest-dir that is itself a symlink into lib/, or
# has one anywhere in its existing prefix) sails straight through it
# unresolved, and the "not inside lib/" guard below is a plain string-prefix
# test on that unresolved string. Cwd::realpath resolves symlinks but
# returns undef for a path that doesn't fully exist -- and a --suggest-dir
# legitimately doesn't exist yet, that's the option's whole point. So walk
# up from the full (lexically collapsed) path until an existing prefix is
# found, realpath just that prefix, and reattach whatever tail doesn't
# exist untouched -- a path component that isn't there cannot itself be a
# symlink, so the lexical form is already correct for it.
sub _resolve_path {
    my ($path) = @_;
    # A failed realpath() during the walk below leaves $! set (ENOENT) as a
    # side effect of the underlying stat -- localize it so a caller's own
    # die (e.g. the --suggest-dir guard) doesn't inherit that as its exit
    # status instead of the usual 255.
    local $!;
    my ($vol, $dirs) = File::Spec->splitpath(_canon_abs($path), 1);
    my @segs = grep { length } File::Spec->splitdir($dirs);
    my @tail;
    while (1) {
        my $candidate = @segs
            ? File::Spec->catdir($vol, File::Spec->rootdir, @segs)
            : File::Spec->catdir($vol, File::Spec->rootdir);
        my $real = realpath($candidate);
        if (defined $real) {
            return @tail ? File::Spec->catdir($real, @tail) : $real;
        }
        last unless @segs;
        unshift @tail, pop @segs;
    }
    # Not even the root resolved (shouldn't happen on a real filesystem) --
    # fall back to the lexical form rather than die.
    return _canon_abs($path);
}

my $DIST_ROOT = _canon_abs(File::Spec->catdir($FindBin::Bin, '..'));
my $UA_STRING = 'io-k8s-p5-crd-drift-check (+https://github.com/pplu/io-k8s-p5)';

# The provider modules this tool knows how to check, in report order. Each
# is a Moo class composing IO::K8s::Role::ResourceMap with an upstream_version
# and (as of k82) a crd_sources method.
my @ALL_PROVIDERS = qw(Cilium GatewayAPI AgentSandbox Traefik CertManager K3s
                       PrometheusOperator VolumeSnapshot ExternalSecrets);

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

sub usage {
    my ($exit_code) = @_;
    print <<"USAGE";
Usage:
  $0 [--provider NAME]... [options]

Options:
  --provider NAME     Provider to check (repeatable). One of:
                        @ALL_PROVIDERS
                       Default: all of them.
  --dir PATH          Local directory of CRD YAML manifests to diff instead
                       of fetching (implies a single --provider).
  --spec PATH         Alias for --dir.
  --exceptions PATH   Exceptions file (default: maint/crd-drift-exceptions.yaml)
  --lib PATH          lib/ directory to load providers from (default: DIST/lib)
  --cache-dir PATH    Downloaded-manifest cache root (default: DIST/spec/crd)
  --no-cache          Force re-download even if a cached copy exists
  --verbose           Also list items suppressed by the exceptions file
  --format text|json  Report format (default: text)
  --output PATH       Also write the report to this file
  --suggest           After the report, print the class source the emitter
                       renders for every OPAQUE SPEC and MISSING FIELD Kind
                       (never touches lib/). With --format json this goes to
                       stderr instead of stdout, so stdout stays a single
                       parseable JSON document.
  --suggest-dir PATH  Write those files under PATH instead of printing
                       (PATH must not be inside the distribution's lib/).
                       The "wrote N file(s)" confirmation follows the same
                       stdout/stderr rule as --suggest above.
  --names FILE        YAML map of generated-class path (relative to the
                       Kind, e.g. "Middleware::Spec::RateLimit") to the
                       package name to use (e.g. "RateLimit") -- the
                       upstream Go type names (D6).
  --render            Like --suggest, but for EVERY served GVK of the
                       provider (not only reported gaps) -- the full D5
                       render, always through the provider's overlay (see
                       --overlay) when one exists. Same stdout/stderr rule.
  --render-dir PATH   Write the --render output under PATH instead of
                       printing (PATH must not be inside lib/).
  --check             Render every served GVK to memory and compare each
                       rendered file against the checked-in
                       lib/IO/K8s/<Provider>/<Version>/<File>.pm: MATCH,
                       DIFFERS (a short hand-rolled diff), COSMETIC (a
                       DIFFERS whose file is listed in
                       ignore_cosmetic_differs AND whose k8s declarations
                       still match the render after whitespace normalisation
                       -- POD/ABSTRACT/whitespace only; suppressed, listed
                       under --verbose), ACCEPTED DIVERGENCE (a DIFFERS whose
                       file is listed in accept_structural_divergence -- a
                       genuine, documented, file-exact k8s-declaration
                       difference the maintainer chose to keep, NOT gated on
                       the cosmetic signature guard; suppressed, listed with
                       its diff under --verbose), MISSING IN LIB, or NOT
                       RENDERED (a file under the provider directory the
                       render does not produce -- see ignore_unrendered in the
                       exceptions file for a kept back-compat track). Exits 1
                       if anything but a MATCH, a suppressed COSMETIC or a
                       suppressed ACCEPTED DIVERGENCE remains.
  --overlay FILE      Overlay YAML for --render/--check (default:
                       maint/crd-render/<Provider>.yaml when it exists;
                       requires exactly one --provider).
  --help              This message

For each provider, fetches its upstream CustomResourceDefinition manifests at
the pinned upstream_version, parses each openAPIV3Schema, and reports missing
Kinds, missing/extra top-level spec fields, opaque specs (spec not modeled
field-by-field), and stale/perl-only GVKs (shipped with no upstream CRD).

This is a report only -- it never creates karr tickets or edits lib/.
USAGE
    exit($exit_code // 0);
}

sub parse_args {
    my %opt = (
        exceptions  => File::Spec->catfile($FindBin::Bin, 'crd-drift-exceptions.yaml'),
        lib         => File::Spec->catdir($DIST_ROOT, 'lib'),
        'cache-dir' => File::Spec->catdir($DIST_ROOT, 'spec', 'crd'),
        format      => 'text',
        provider    => [],
    );
    GetOptions(\%opt,
        'provider=s@', 'dir=s', 'spec=s',
        'exceptions=s', 'lib=s', 'cache-dir=s', 'no-cache',
        'verbose', 'output=s', 'format=s', 'help|h',
        'suggest' => \$opt{suggest}, 'suggest-dir=s' => \$opt{suggest_dir}, 'names=s' => \$opt{names},
        'render' => \$opt{render}, 'render-dir=s' => \$opt{render_dir},
        'check' => \$opt{check}, 'overlay=s' => \$opt{overlay},
    ) or usage(1);
    usage(0) if $opt{help};
    if ($opt{format} !~ /^(text|json)$/) {
        die "crd-drift-check: --format must be 'text' or 'json'\n";
    }
    $opt{dir} //= $opt{spec};
    my @providers = @{ $opt{provider} };
    @providers = @ALL_PROVIDERS unless @providers;
    my %known = map { $_ => 1 } @ALL_PROVIDERS;
    for my $p (@providers) {
        die "crd-drift-check: unknown provider '$p' (known: @ALL_PROVIDERS)\n"
            unless $known{$p};
    }
    if (defined $opt{dir} && @providers != 1) {
        die "crd-drift-check: --dir/--spec requires exactly one --provider\n";
    }
    if (defined $opt{overlay} && @providers != 1) {
        die "crd-drift-check: --overlay requires exactly one --provider\n";
    }
    if (defined $opt{overlay} && !-f $opt{overlay}) {
        die "crd-drift-check: --overlay file not found: $opt{overlay}\n";
    }
    if ($opt{suggest_dir}) {
        $opt{suggest_dir} = _canon_abs($opt{suggest_dir});
        _die_if_inside_lib($opt{suggest_dir}, $opt{lib}, '--suggest-dir');
    }
    if ($opt{render_dir}) {
        $opt{render_dir} = _canon_abs($opt{render_dir});
        _die_if_inside_lib($opt{render_dir}, $opt{lib}, '--render-dir');
    }
    $opt{provider} = \@providers;
    return \%opt;
}

# Shared by --suggest-dir and --render-dir: the write target stays the
# lexical form (either may not exist yet); the guard compares
# symlink-resolved forms so a symlink into lib/ can't sneak past a
# lexical-only check. See _resolve_path's own comment above for why.
sub _die_if_inside_lib {
    my ($path, $lib, $flag) = @_;
    my $real     = _resolve_path($path);
    my $lib_real = _resolve_path($lib);
    die "crd-drift-check: $flag must not point inside lib/\n"
        if $real eq $lib_real || index($real, "$lib_real/") == 0;
}

# ---------------------------------------------------------------------------
# Provider + registry loading (mirrors spec-drift-check.pl's lib loading)
# ---------------------------------------------------------------------------

sub load_lib {
    my ($lib_dir) = @_;
    die "crd-drift-check: lib dir not found: $lib_dir\n" unless -d $lib_dir;
    unshift @INC, $lib_dir unless grep { $_ eq $lib_dir } @INC;
    require IO::K8s;
    return;
}

# A resource_map value -> fully-qualified Perl class. Mirrors
# IO::K8s::Role::ResourceMap's rule: a '+' prefix is used verbatim, anything
# else is relative to IO::K8s::.
sub qualify_class {
    my ($path) = @_;
    return substr($path, 1) if $path =~ /^\+/;
    return "IO::K8s::$path";
}

# ---------------------------------------------------------------------------
# CRD manifest fetch + cache
# ---------------------------------------------------------------------------

sub http_get {
    my ($url) = @_;
    require HTTP::Tiny;
    require Encode;
    my $ua  = HTTP::Tiny->new(agent => $UA_STRING, timeout => 90);
    my $res = $ua->get($url);
    die sprintf("crd-drift-check: GET %s failed: %s %s\n",
        $url, $res->{status} // '?', $res->{reason} // '?')
        unless $res->{success};
    # HTTP::Tiny hands back raw response bytes, not a decoded character
    # string. Decoding once here -- before the caller both caches it (via
    # the '>:encoding(UTF-8)' write in load_manifests) and parses it --
    # means those bytes are only ever UTF-8-encoded once: writing an
    # UNdecoded byte string through an ':encoding(UTF-8)' filehandle
    # re-encodes each byte as if it were a Latin-1 codepoint, doubling the
    # encoding for any non-ASCII character (a manifest's 'µs' pattern, say)
    # and corrupting it on disk (k94 review).
    return Encode::decode('UTF-8', $res->{content});
}

# The byte shape a double-encoded character leaves behind, derived from
# UTF-8's own structure rather than listed case by case. Misreading a
# character's UTF-8 bytes as Latin-1 codepoints and re-encoding them maps
# every CONTINUATION byte (\x80-\xBF) to "\xC2" plus itself, and the LEAD
# byte to "\xC3" plus a byte that still says how long the original was:
#
#   original           lead     doubled lead   trailing "\xC2"+cont pairs
#   2-byte  U+0080+    C2-DF    C3 82-9F       1
#   3-byte  U+0800+    E0-EF    C3 A0-AF       2
#   4-byte  U+10000+   F0-F4    C3 B0-B4       3
#
# so a doubled run is one C3-led byte from one of those ranges followed by
# exactly as many pairs as its row implies. Two boundaries are deliberate:
#
#   * The 2-byte row stays narrowed to C2/C3 -- the Latin-1 Supplement, the
#     'µ'/'ü'/'é' a CRD manifest realistically carries. Widening it to the
#     full C2-DF would make the signature match plain, correct text: 'Ä«'
#     is C3 84 C2 AB, and since the repair below succeeds on it, it would
#     silently become 'ī'. A doubled 'Â'/'Ã' run has no such reading.
#   * Nothing above the 4-byte row: UTF-8 has no longer sequence, and F5-FF
#     is not a lead byte at all.
#
# Before k114 only the 2-byte row existed, so every character from U+0800 up
# -- an en dash, a curly quote, anything typographic an upstream description
# realistically carries -- went unrepaired. Cilium's CiliumPodIPPool
# description reached the emitter as "\xC3\xA2\xC2\x80\xC2\x93" and --check
# then reported a permanent false difference against a perfectly good
# checked-in class, which is the way a drift report stops being read.
my $DOUBLE_ENCODED_RUN = qr{
      \xC3[\x82\x83]   (?:\xC2[\x80-\xBF])
    | \xC3[\xA0-\xAF]  (?:\xC2[\x80-\xBF]){2}
    | \xC3[\xB0-\xB4]  (?:\xC2[\x80-\xBF]){3}
}x;

sub _slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path
        or die "crd-drift-check: cannot read $path: $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    require Encode;
    my $content = Encode::decode('UTF-8', $bytes);

    # A cache file written before the http_get fix above holds bytes that
    # were UTF-8-encoded twice: e.g. 'µ' (correctly, bytes C2 B5) written
    # through ':encoding(UTF-8)' without ever having been decoded first
    # becomes, on disk, the UTF-8 encoding of the two CHARACTERS U+00C2 and
    # U+00B5, i.e. C3 82 C2 B5. An earlier version of this check matched
    # any "\xC3" followed by a continuation byte -- but that signature is
    # NOT unique to double-encoded content: a single, correctly-encoded
    # Latin-1-Supplement character (C3 A9 = 'e-acute', C3 BC = 'u-umlaut',
    # ...) is EXACTLY that shape, since every codepoint from U+00C0-U+00FF
    # has UTF-8 lead byte C3 too. That false positive silently mangled a
    # legitimately cached 'Grüße'/'Délai' into U+FFFD replacement
    # characters on read alone (round-2 review finding).
    #
    # $DOUBLE_ENCODED_RUN above is that tighter signature: a C3-led byte in
    # one of the three doubled-lead ranges plus the exact number of "C2" +
    # continuation pairs its row implies -- four bytes for a doubled 'µ',
    # six for a doubled en dash, eight for a doubled emoji, never two. A
    # lone 'ü'/'é' never produces such a run on its own; it would need a
    # literal "C2" + continuation byte immediately afterward too, and for
    # the longer rows two or three of them in a row.
    #
    # Even with that tighter signature, only ACCEPT the repair if the
    # WHOLE text survives the reinterpret-as-Latin-1-then-decode-as-UTF-8
    # round trip strictly. FB_CROAK on both encode() and decode(): encode()
    # alone would otherwise silently substitute '?' for any codepoint above
    # U+00FF (a real emoji elsewhere in an otherwise-unrelated part of the
    # same cached file, say), which decode() would then just as silently
    # accept -- masking real data loss instead of tripping this fallback.
    # LEAVE_SRC on both: CHECK => FB_CROAK makes encode()/decode() consume
    # (empty out) their source argument as they convert it, which would
    # destroy $content -- the exact value this needs to fall back to --
    # even along the success path. A file that fails this check keeps its
    # own, already correctly single-decoded $content.
    if ($bytes =~ $DOUBLE_ENCODED_RUN) {
        my $check = Encode::FB_CROAK() | Encode::LEAVE_SRC();
        my $repaired = eval {
            Encode::decode('UTF-8', Encode::encode('iso-8859-1', $content, $check), $check);
        };
        $content = $repaired if defined $repaired;
    }
    return $content;
}

# A `files` entry ('v2/foo.yaml') maps to one cache file with path
# separators flattened to '_' ('v2_foo.yaml'). Nothing here is committed:
# the cache is per-version local scratch under spec/crd/<Provider>/<version>/
# (fully gitignored), keyed on the provider's upstream_version so a pin bump
# re-fetches automatically.
sub cache_name_for {
    my ($file) = @_;
    (my $name = $file) =~ s{/}{_}g;
    return $name;
}

# Returns a list of [source_label, yaml_text] for a provider, either from a
# local --dir or from crd_sources (fetching + caching as needed).
sub load_manifests {
    my ($opt, $provider, $sources, $version) = @_;
    my @out;
    if (defined $opt->{dir}) {
        opendir my $dh, $opt->{dir}
            or die "crd-drift-check: cannot open --dir $opt->{dir}: $!\n";
        my @files = sort grep { /\.ya?ml$/ } readdir $dh;
        closedir $dh;
        die "crd-drift-check: no *.yaml manifests in $opt->{dir}\n" unless @files;
        for my $f (@files) {
            my $path = File::Spec->catfile($opt->{dir}, $f);
            push @out, [$f, _slurp($path)];
        }
        return @out;
    }

    # Cache is keyed on upstream_version so a pin bump caches separately and a
    # stale older-version cache never serves the wrong manifests.
    (my $safe_version = defined $version ? $version : '(unknown)')
        =~ s/[^A-Za-z0-9._-]/_/g;
    my $cache_dir = File::Spec->catdir($opt->{'cache-dir'}, $provider, $safe_version);
    make_path($cache_dir) unless -d $cache_dir;
    for my $file (@{ $sources->{files} }) {
        my $cache_file = File::Spec->catfile($cache_dir, cache_name_for($file));
        if (!$opt->{'no-cache'} && -f $cache_file) {
            push @out, [$file, _slurp($cache_file)];
            next;
        }
        my $url = $sources->{base} . '/' . $file;
        print STDERR "crd-drift-check: downloading $url ...\n";
        my $content = http_get($url);
        open my $fh, '>:encoding(UTF-8)', $cache_file
            or die "crd-drift-check: cannot write $cache_file: $!\n";
        print $fh $content;
        close $fh;
        push @out, [$file, $content];
    }
    return @out;
}

# ---------------------------------------------------------------------------
# CRD manifest parsing
#
# From each CustomResourceDefinition document: spec.group, spec.names.kind,
# and per served version its name + the spec-object property set from
# openAPIV3Schema.properties.spec.properties. GVK = "group/version/Kind".
# The whole document rides along too (doc), so --suggest can hand a
# reported GVK's manifest straight to IO::K8s::CRD->generate without
# re-fetching or re-parsing it. Keep the root schema as well: a clearly
# closed root without `spec` is distinct from an opaque spec schema.
# ---------------------------------------------------------------------------

sub parse_crds {
    my (@manifests) = @_;
    require YAML::PP;
    my $yp = YAML::PP->new(boolean => 'JSON::PP');
    my %by_gvk;    # "group/version/Kind" -> { kind, group, version, doc, spec_props => {name=>1}, has_spec_schema }
    for my $m (@manifests) {
        my ($label, $text) = @$m;
        my @docs = eval { $yp->load_string($text) };
        if ($@) {
            warn "crd-drift-check: could not parse $label: $@";
            next;
        }
        for my $doc (@docs) {
            next unless ref $doc eq 'HASH';
            next unless ($doc->{kind} // '') eq 'CustomResourceDefinition';
            my $spec  = $doc->{spec} or next;
            my $group = $spec->{group} // next;
            my $kind  = $spec->{names}{kind} // next;
            for my $ver (@{ $spec->{versions} // [] }) {
                my $vname = $ver->{name} // next;
                my $gvk   = "$group/$vname/$kind";
                my $schema      = $ver->{schema}{openAPIV3Schema};
                my $spec_schema = $schema->{properties} && exists $schema->{properties}{spec}
                    ? $schema->{properties}{spec} : undef;
                my $spec_props  = $spec_schema ? $spec_schema->{properties} : undef;
                $by_gvk{$gvk} = {
                    kind            => $kind,
                    group           => $group,
                    version         => $vname,
                    label           => $label,
                    doc             => $doc,
                    root_schema     => $schema,
                    has_spec_schema => ($spec_props ? 1 : 0),
                    spec_props      => { map { $_ => 1 } keys %{ $spec_props // {} } },
                };
            }
        }
    }
    return \%by_gvk;
}

# A class without a registered `spec` can only be exempt from opaque-spec
# reporting when the upstream root is unambiguously a closed flat object.
# Keep every open, preserve-unknown, composite, or malformed shape visible:
# Tier 3 deliberately compares spec fields only, not arbitrary root fields.
sub has_closed_flat_root_without_spec {
    my ($upstream) = @_;
    my $schema = $upstream->{root_schema};
    return unless ref $schema eq 'HASH';
    return unless ($schema->{type} // '') eq 'object';
    if (exists $schema->{'x-kubernetes-preserve-unknown-fields'}) {
        my $preserve_unknown = $schema->{'x-kubernetes-preserve-unknown-fields'};
        return unless JSON::PP::is_bool($preserve_unknown);
        return if $preserve_unknown;
    }
    if (exists $schema->{additionalProperties}) {
        my $additional_properties = $schema->{additionalProperties};
        return unless JSON::PP::is_bool($additional_properties) && !$additional_properties;
    }
    for my $keyword (qw( allOf anyOf oneOf not $ref )) {
        return if exists $schema->{$keyword};
    }

    my $properties = $schema->{properties};
    return unless ref $properties eq 'HASH';
    return if exists $properties->{spec};
    for my $property (values %$properties) {
        return unless ref $property eq 'HASH';
    }
    return 1;
}

# ---------------------------------------------------------------------------
# Shipped-provider view: GVK -> class, from resource_map values.
#
# A mapped class's api_version() ("group/version") joined to its kind() is
# the exact GVK IO::K8s::add() would register it under -- the authoritative
# "what does this provider serve" set, independent of which resource_map
# keys (short or domain-qualified) happen to point at it.
# ---------------------------------------------------------------------------

sub shipped_view {
    my ($provider) = @_;
    my $pkg = "IO::K8s::$provider";
    my $map = $pkg->resource_map;
    my %gvk_class;    # gvk -> class
    my %classes;      # class -> 1 (unique)
    $classes{ qualify_class($_) } = 1 for values %$map;
    for my $class (sort keys %classes) {
        eval { require_class($class); 1 }
            or do { warn "crd-drift-check: failed to load $class: $@"; next };
        my $av   = eval { $class->api_version };
        my $kind = eval { $class->kind };
        next unless defined $av && defined $kind;
        $gvk_class{"$av/$kind"} = $class;
    }
    return \%gvk_class;
}

sub require_class {
    my ($class) = @_;
    (my $rel = $class) =~ s{::}{/}g;
    $rel .= '.pm';
    require $rel;
    return;
}

# shipped_view() above only requires the resource_map's Kind-root classes.
# For a D5/D7-style provider, a Kind's `spec` is a NAMED nested class in its
# own file (e.g. IngressRoute's spec => '+IO::K8s::Traefik::V1alpha1::
# IngressRouteSpec') that resource_map never lists -- so without this,
# shipped_spec_fields() reads %IO::K8s::Resource::_attr_registry for a class
# that was never require()d, its registry entry doesn't exist, and every
# field is falsely reported MISSING (k105). Mirrors t/34_registry_guard.t /
# spec-drift-check.pl's load_registry: walk + require every .pm, but scoped
# to this provider's own subtree so an unrelated provider's tree stays
# unloaded. A provider with no per-Kind subdirectory yet (nothing beyond the
# resource_map roots) is a silent no-op, not an error.
sub require_provider_tree {
    my ($lib_dir, $provider) = @_;
    my $provider_dir = File::Spec->catdir($lib_dir, 'IO', 'K8s', $provider);
    return unless -d $provider_dir;

    my @pm_paths;
    find(
        { wanted => sub { push @pm_paths, $File::Find::name if /\.pm$/ }, no_chdir => 1 },
        $provider_dir,
    );
    for my $path (sort @pm_paths) {
        my $rel = File::Spec->abs2rel($path, $lib_dir);
        $rel =~ s{\\}{/}g;    # require() wants forward slashes regardless of OS
        eval { require $rel; 1 }
            or warn "crd-drift-check: failed to load $rel: $@";
    }
    return;
}

# The shipped `spec` field set for a class, or undef when spec is modeled
# opaquely (a { Str => 1 } hash, a free-form object, or simply absent).
# Two shapes expose upstream-comparable field names, both read off the
# nested class's own registry entry using each attribute's wire json_key:
#
#   - an inline struct (is_inline_struct) -- the k93-era case, an anonymous
#     `{ field => TypeSpec, ... }` the k8s DSL generated a struct for; or
#   - (A3, D5/D7) a plain object reference (is_object, not an inline
#     struct) whose class lives under IO::K8s::<Provider>:: -- the emitter
#     output's own case, where `spec` is typed as a NAMED nested class
#     ('Traefik::V1alpha1::MiddlewareSpec') rather than an anonymous one.
#     Scoped to the provider's own namespace so a spec reusing a shipped
#     CORE class (Meta::V1::LabelSelector, say -- D5's reuse_core) is not
#     mistaken for that Kind's own field list.
sub shipped_spec_fields {
    my ($class, $provider) = @_;
    my $reg  = \%IO::K8s::Resource::_attr_registry;
    my $info = $reg->{$class}{spec} or return undef;
    return undef unless $info->{is_object};
    my $inner = $info->{class} or return undef;
    unless ($info->{is_inline_struct}) {
        return undef
            unless defined $provider && index($inner, "IO::K8s::$provider\::") == 0;
    }
    my $inner_attrs = $reg->{$inner} // {};
    my %fields;
    for my $aname (keys %$inner_attrs) {
        $fields{ $inner_attrs->{$aname}{json_key} // $aname } = 1;
    }
    return \%fields;
}

# ---------------------------------------------------------------------------
# Exceptions file
# ---------------------------------------------------------------------------

sub load_exceptions {
    my ($path) = @_;
    die "crd-drift-check: exceptions file not found: $path\n" unless -f $path;
    require YAML::PP;
    my ($data) = YAML::PP->new->load_string(_slurp($path));
    $data //= {};
    $data->{ignore_missing_kinds} //= [];
    $data->{ignore_stale_kinds}   //= [];
    $data->{ignore_missing_fields} //= [];
    $data->{ignore_extra_fields}   //= [];
    $data->{ignore_unrendered}     //= [];
    $data->{ignore_cosmetic_differs} //= [];
    $data->{accept_structural_divergence} //= [];
    return $data;
}

# GVK-level exceptions match on provider + exact gvk (a bare `gvk` with no
# `provider` matches in any provider).
sub gvk_excepted {
    my ($provider, $gvk, $entries) = @_;
    for my $e (@$entries) {
        next unless ref $e eq 'HASH';
        next unless ($e->{gvk} // '') eq $gvk;
        next if defined $e->{provider} && $e->{provider} ne $provider;
        return (1, $e->{reason});
    }
    return (0, undef);
}

# Field-level exceptions match on provider + gvk + field.
sub field_excepted {
    my ($provider, $gvk, $field, $entries) = @_;
    for my $e (@$entries) {
        next unless ref $e eq 'HASH';
        next unless ($e->{gvk} // '') eq $gvk && ($e->{field} // '') eq $field;
        next if defined $e->{provider} && $e->{provider} ne $provider;
        return (1, $e->{reason});
    }
    return (0, undef);
}

# --check's NOT RENDERED exceptions match on provider + path, where `path`
# is the same lib/-relative string --check itself reports and render_gvk's
# own file keys already use ("IO/K8s/<Provider>/<Version>/<File>.pm") --
# one canonical form throughout, nothing to translate between.
sub unrendered_excepted {
    my ($provider, $path, $entries) = @_;
    for my $e (@$entries) {
        next unless ref $e eq 'HASH';
        next unless ($e->{path} // '') eq $path;
        next if defined $e->{provider} && $e->{provider} ne $provider;
        return (1, $e->{reason});
    }
    return (0, undef);
}

# --check's COSMETIC reclassification (k132) matches on provider + path, the
# same lib/-relative form ("IO/K8s/<Provider>/<Version>/<File>.pm") that
# ignore_unrendered uses and that --check itself reports. Being *listed* is
# necessary but never sufficient: check_for only suppresses a listed file
# when _structural_signature() confirms its k8s declarations still match the
# render (see the guard there).
sub cosmetic_differ_excepted {
    my ($provider, $path, $entries) = @_;
    for my $e (@$entries) {
        next unless ref $e eq 'HASH';
        next unless ($e->{path} // '') eq $path;
        next if defined $e->{provider} && $e->{provider} ne $provider;
        return (1, $e->{reason});
    }
    return (0, undef);
}

# --check's ACCEPTED DIVERGENCE reclassification (k133, Weg 1) matches on
# provider + path, the same lib/-relative form ("IO/K8s/<Provider>/<Version>/
# <File>.pm") the other --check exceptions use. Deliberately SEPARATE from
# ignore_cosmetic_differs and its _structural_signature guard: this category
# accepts a GENUINE structural difference between the render and lib -- the
# k55/k120 typed-empty-vs-opaque-hash UUIDSpec case, where lib names the empty
# struct '+IO::K8s::ExternalSecrets::V1alpha1::UUIDSpec' and the emitter types
# it opaquely as { Str => 1 } -- so it cannot go through the cosmetic guard,
# which by design refuses anything whose k8s declarations drift. The scope
# limit here is exactness, not a signature: only the EXACT provider+path pairs
# listed are reclassified, so an unlisted file's structural drift is never
# masked (and a listed file's diff is still printed under --verbose).
sub accept_divergence_excepted {
    my ($provider, $path, $entries) = @_;
    for my $e (@$entries) {
        next unless ref $e eq 'HASH';
        next unless ($e->{path} // '') eq $path;
        next if defined $e->{provider} && $e->{provider} ne $provider;
        return (1, $e->{reason});
    }
    return (0, undef);
}

# ---------------------------------------------------------------------------
# Per-provider drift
# ---------------------------------------------------------------------------

sub check_provider {
    my ($opt, $provider, $exceptions) = @_;
    my $pkg = "IO::K8s::$provider";
    require_class($pkg);
    my $version = eval { $pkg->upstream_version } // '(unknown)';
    my $sources = eval { $pkg->crd_sources };
    die "crd-drift-check: $pkg has no crd_sources method\n" unless ref $sources eq 'HASH';

    # Populate the registry for every nested class under this provider (k105)
    # before shipped_view()/shipped_spec_fields() read it -- not just the
    # resource_map roots shipped_view() requires on its own.
    require_provider_tree($opt->{lib}, $provider);

    my $shipped = shipped_view($provider);
    my $result  = {
        provider      => $provider,
        upstream      => $version,
        status        => $sources->{status} // 'ok',
        shipped_gvks  => scalar keys %$shipped,
        missing_kind  => [],
        missing_field => [],
        extra_field   => [],
        opaque_spec   => [],
        stale_gvk     => [],
        suppressed    => [],
        note          => $sources->{note},
    };

    # Unresolved upstream source (K3s): report the shipped GVKs, diff nothing.
    if (($sources->{status} // 'ok') ne 'ok') {
        $result->{stale_gvk} = [ map { [$_, $shipped->{$_}] } sort keys %$shipped ];
        $result->{unresolved} = 1;
        $result->{crd_count}  = 0;
        return $result;
    }

    my @manifests = load_manifests($opt, $provider, $sources, $version);
    my $upstream  = parse_crds(@manifests);
    $result->{crd_count} = scalar keys %$upstream;

    # Tier 1: upstream GVK with no shipped class.
    for my $gvk (sort keys %$upstream) {
        next if $shipped->{$gvk};
        my ($ign, $reason) = gvk_excepted($provider, $gvk, $exceptions->{ignore_missing_kinds});
        if ($ign) {
            push @{ $result->{suppressed} }, ['ignore_missing_kinds', $gvk, $reason];
            next;
        }
        push @{ $result->{missing_kind} }, [$gvk, $upstream->{$gvk}{kind}];
    }

    # Info: shipped GVK with no upstream CRD (stale / perl-only).
    for my $gvk (sort keys %$shipped) {
        next if $upstream->{$gvk};
        my ($ign, $reason) = gvk_excepted($provider, $gvk, $exceptions->{ignore_stale_kinds});
        if ($ign) {
            push @{ $result->{suppressed} }, ['ignore_stale_kinds', $gvk, $reason];
            next;
        }
        push @{ $result->{stale_gvk} }, [$gvk, $shipped->{$gvk}];
    }

    # Field-level: GVKs present in both.
    for my $gvk (sort keys %$upstream) {
        my $class = $shipped->{$gvk} or next;
        my $u = $upstream->{$gvk};
        my $shipped_fields = shipped_spec_fields($class, $provider);
        my $has_shipped_spec = exists $IO::K8s::Resource::_attr_registry{$class}{spec};

        if (!defined $shipped_fields) {
            next if !$has_shipped_spec && has_closed_flat_root_without_spec($u);
            # No comparable spec fields: retain the uncertainty as info.
            push @{ $result->{opaque_spec} },
                [$gvk, $class, scalar keys %{ $u->{spec_props} }, $u->{has_spec_schema}];
            next;
        }
        if (!$u->{has_spec_schema}) {
            # class models spec fields but upstream has no spec schema to diff.
            push @{ $result->{opaque_spec} }, [$gvk, $class, 0, 0];
            next;
        }

        for my $f (sort keys %{ $u->{spec_props} }) {
            next if $shipped_fields->{$f};
            my ($ign, $reason) = field_excepted($provider, $gvk, $f, $exceptions->{ignore_missing_fields});
            if ($ign) {
                push @{ $result->{suppressed} }, ['ignore_missing_fields', "$gvk.$f", $reason];
                next;
            }
            push @{ $result->{missing_field} }, [$gvk, $class, $f];
        }
        for my $f (sort keys %$shipped_fields) {
            next if $u->{spec_props}{$f};
            my ($ign, $reason) = field_excepted($provider, $gvk, $f, $exceptions->{ignore_extra_fields});
            if ($ign) {
                push @{ $result->{suppressed} }, ['ignore_extra_fields', "$gvk.$f", $reason];
                next;
            }
            push @{ $result->{extra_field} }, [$gvk, $class, $f];
        }
    }
    $result->{_upstream} = $upstream;
    return $result;
}

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

sub render_provider {
    my ($r, $verbose) = @_;
    my @out;
    push @out, sprintf('########## %s (upstream %s) ##########', $r->{provider}, $r->{upstream});

    if ($r->{unresolved}) {
        push @out, 'status: SOURCE UNRESOLVED -- no upstream openAPIV3Schema to diff';
        push @out, "note:   $r->{note}" if $r->{note};
        push @out, "lib:    $r->{shipped_gvks} shipped GVK(s), not verified against upstream:";
        push @out, "  $_->[0]  ->  $_->[1]" for @{ $r->{stale_gvk} };
        push @out, '';
        return @out;
    }

    push @out, sprintf('spec:   %d upstream GVK(s) across the fetched CRD manifests', $r->{crd_count});
    push @out, sprintf('lib:    %d shipped GVK(s) from the resource_map', $r->{shipped_gvks});
    push @out, '';
    push @out, '--- SUMMARY ---';
    push @out, sprintf('  Tier 1  MISSING KIND    %4d  upstream GVK, no shipped class', scalar @{ $r->{missing_kind} });
    push @out, sprintf('  Tier 3  MISSING FIELD   %4d  upstream spec field a modeled class lacks', scalar @{ $r->{missing_field} });
    push @out, sprintf('  Info    EXTRA FIELD     %4d  modeled class declares a spec field upstream lacks', scalar @{ $r->{extra_field} });
    push @out, sprintf('  Info    OPAQUE SPEC     %4d  GVK whose spec is not modeled field-by-field', scalar @{ $r->{opaque_spec} });
    push @out, sprintf('  Info    STALE/PERL-ONLY %4d  shipped GVK, no matching upstream CRD', scalar @{ $r->{stale_gvk} });
    my %supp;
    $supp{ $_->[0] }++ for @{ $r->{suppressed} };
    push @out, sprintf('  Suppressed by exceptions: %d (%s)%s',
        scalar @{ $r->{suppressed} },
        join(', ', map { "$_: $supp{$_}" } sort keys %supp) || 'none',
        (@{ $r->{suppressed} } && !$verbose) ? ' -- rerun with --verbose to list them' : '');
    push @out, '';

    push @out, '--- Tier 1: MISSING KIND (upstream GVK, no shipped class) ---';
    push @out, "  $_->[0]" for @{ $r->{missing_kind} };
    push @out, '  (none)' unless @{ $r->{missing_kind} };
    push @out, '';

    push @out, '--- Tier 3: MISSING FIELD (upstream spec.<field>, class lacks it) ---';
    push @out, "  $_->[0]  spec.$_->[2]  ($_->[1])" for @{ $r->{missing_field} };
    push @out, '  (none)' unless @{ $r->{missing_field} };
    push @out, '';

    push @out, '--- Info: EXTRA FIELD (class has spec.<field>, upstream lacks it) ---';
    push @out, "  $_->[0]  spec.$_->[2]  ($_->[1])" for @{ $r->{extra_field} };
    push @out, '  (none)' unless @{ $r->{extra_field} };
    push @out, '';

    push @out, '--- Info: OPAQUE SPEC (spec not modeled field-by-field) ---';
    for my $e (@{ $r->{opaque_spec} }) {
        my ($gvk, $class, $n, $has_schema) = @$e;
        my $detail = $has_schema
            ? "upstream schema has $n spec field(s), class models spec opaquely"
            : 'upstream has no spec schema to compare';
        push @out, "  $gvk  ($class): $detail";
    }
    push @out, '  (none)' unless @{ $r->{opaque_spec} };
    push @out, '';

    push @out, '--- Info: STALE / PERL-ONLY (shipped GVK, no upstream CRD) ---';
    push @out, "  $_->[0]  ->  $_->[1]" for @{ $r->{stale_gvk} };
    push @out, '  (none)' unless @{ $r->{stale_gvk} };

    if ($verbose && @{ $r->{suppressed} }) {
        push @out, '';
        push @out, '--- Suppressed by exceptions (--verbose) ---';
        for my $s (@{ $r->{suppressed} }) {
            my ($cat, $subject, $reason) = @$s;
            push @out, sprintf('  [%s] %s%s', $cat, $subject,
                (defined $reason ? "  -- $reason" : ''));
        }
    }
    push @out, '';
    return @out;
}

sub render_report {
    my ($results, $verbose) = @_;
    my @out;
    push @out, '=== IO::K8s crd-drift-check ===';
    push @out, 'providers: ' . join(', ', map { $_->{provider} } @$results);
    push @out, '';
    push @out, render_provider($_, $verbose) for @$results;
    return join("\n", @out) . "\n";
}

# ---------------------------------------------------------------------------
# --suggest: the classes the emitter would write for a reported Kind.
#
# Report-only stays report-only: the source goes to stdout or to a directory
# the caller names, never into lib/. One throwaway AutoGen namespace per
# GVK keeps the generated classes apart from anything the providers loaded.
# ---------------------------------------------------------------------------

sub load_names {
    my ($path) = @_;
    return {} unless $path;
    require YAML::PP;
    my $map = YAML::PP->new->load_file($path);
    die "crd-drift-check: --names file must be a YAML map\n" unless ref $map eq 'HASH';
    return $map;
}

# The per-Kind overlay slice for one provider (A2's shape: `base:`, `kinds:`
# with per-Kind `with`/`extra`/`names`), from --overlay when given or from
# maint/crd-render/<Provider>.yaml otherwise. A missing default file is the
# normal case until a provider's Phase B task writes one -- returns {}, not
# an error; a missing --overlay is already fatal in parse_args, so reaching
# here with one set means the file exists.
sub load_overlay {
    my ($opt, $provider) = @_;
    my $path = defined $opt->{overlay}
        ? $opt->{overlay}
        : File::Spec->catfile($DIST_ROOT, 'maint', 'crd-render', "$provider.yaml");
    return {} unless -f $path;
    require YAML::PP;
    my $data = YAML::PP->new->load_file($path);
    die "crd-drift-check: overlay file $path must be a YAML map\n" unless ref $data eq 'HASH';
    $data->{kinds} //= {};
    return $data;
}

# One served GVK, rendered through the emitter -- the shared core of
# --suggest (a reported gap only) and --render (every GVK): generate the
# AutoGen classes for $u->{doc} into a fresh throwaway namespace, then
# render $root with $overlay (the Kind's own `kinds.<Kind>` slice, already
# sliced out by the caller) and any --names D6 override.
sub render_gvk {
    my ($opt, $provider, $u, $overlay) = @_;
    require IO::K8s::CRD;
    require IO::K8s::CRD::Emitter;
    state $ns_counter = 0;
    my $ns = 'IO::K8s::_CRDRENDER_' . ++$ns_counter;
    # reuse_core on (D5, and IO::K8s::CRD->generate's own default) -- a
    # nested schema shaped exactly like a shipped core class is typed as
    # that class rather than a per-provider copy. A provider overlay may name
    # logical nested-class paths under `no_reuse_core` (k120) where that
    # reuse is suppressed so the provider's own named type is generated
    # instead (then given its Go name via `names`) -- PrometheusOperator's
    # Argument, whose {name,value} shape would otherwise reuse
    # Core::V1::HTTPHeader.
    my %reuse_core_except = map { $_ => 1 } @{ $overlay->{no_reuse_core} // [] };
    my $classes = IO::K8s::CRD->generate($u->{doc}, $ns, reuse_core => 1,
        reuse_core_except => \%reuse_core_except);
    my $root = $classes->{"$u->{group}/$u->{version}"} or return {};

    # A --names key is written relative to the Kind (the Kind's own
    # generated class IS $root, e.g. '...::Middleware'), so a key of
    # 'Middleware::Spec::RateLimit' names the nested class
    # '$root::Spec::RateLimit' -- the leading 'Middleware::' names the
    # Kind, it is not repeated inside $root. Strip it before joining.
    my $names = $opt->{_names_map} // {};
    my %class_names;
    for my $key (grep { $_ ne $u->{kind} } keys %$names) {
        (my $suffix = $key) =~ s/^\Q$u->{kind}\E:://;
        $class_names{"$root\::$suffix"} = $names->{$key};
    }
    my $emitter = IO::K8s::CRD::Emitter->new(
        base    => "IO::K8s::$provider\::" . ucfirst($u->{version}),
        names   => \%class_names,
        overlay => $overlay // {},
    );
    return $emitter->render($root);
}

sub _merge_rendered_files {
    my ($files, $functional, $origins, $rendered, $gvk) = @_;
    for my $path (sort keys %$rendered) {
        my $source = $rendered->{$path};
        my $signature = IO::K8s::CRD::Emitter->_functional_source($source);
        if (exists $files->{$path}) {
            die 'crd-drift-check: target ' . $path
                . ' has non-identical GVK sources ' . $origins->{$path}
                . ' and ' . $gvk . "\n"
                if $functional->{$path} ne $signature;
        }
        # Deliberately retain the last equivalent source, matching the
        # overwrite selection render_for/suggest_for made before collision
        # detection.
        $files->{$path} = $source;
        $functional->{$path} = $signature;
        $origins->{$path} = $gvk;
    }
    return;
}

sub suggest_for {
    my ($opt, $result, $upstream) = @_;
    my @gvks = map { $_->[0] } @{ $result->{opaque_spec} }, @{ $result->{missing_field} };
    my %seen;
    my %files;
    my %functional;
    my %origins;
    my $overlay = load_overlay($opt, $result->{provider});
    for my $gvk (grep { !$seen{$_}++ } @gvks) {
        my $u = $upstream->{$gvk} or next;
        my $kind_overlay = $overlay->{kinds}{$u->{kind}} // {};
        my $rendered = render_gvk($opt, $result->{provider}, $u, $kind_overlay);
        _merge_rendered_files(\%files, \%functional, \%origins, $rendered, $gvk);
    }
    return \%files;
}

# --render's own GVK set: every served GVK the manifests describe, not only
# a reported gap.
sub render_for {
    my ($opt, $provider, $upstream) = @_;
    my $overlay = load_overlay($opt, $provider);
    my %files;
    my %functional;
    my %origins;
    for my $gvk (sort keys %$upstream) {
        my $u = $upstream->{$gvk};
        my $kind_overlay = $overlay->{kinds}{$u->{kind}} // {};
        my $rendered = render_gvk($opt, $provider, $u, $kind_overlay);
        _merge_rendered_files(\%files, \%functional, \%origins, $rendered, $gvk);
    }
    return \%files;
}

sub _report_out {
    my ($opt) = @_;
    # --format json keeps stdout a parseable JSON document (see main below,
    # which prints the report there); everything --suggest/--render/--check
    # would otherwise print goes to stderr instead when that format is
    # active, and to stdout the same as ever otherwise. See usage().
    return $opt->{format} eq 'json' ? \*STDERR : \*STDOUT;
}

sub emit_files {
    my ($opt, $files, $dir, $label) = @_;
    return unless %$files;
    my $out = _report_out($opt);
    if ($dir) {
        require File::Path;
        require File::Basename;
        for my $rel (sort keys %$files) {
            my $path = "$dir/$rel";
            File::Path::make_path(File::Basename::dirname($path));
            open my $fh, '>:encoding(UTF-8)', $path or die "crd-drift-check: cannot write $path: $!\n";
            print $fh $files->{$rel};
            close $fh;
        }
        print $out "\n--- $label: wrote " . scalar(keys %$files) . " file(s) under $dir\n";
        return;
    }
    for my $rel (sort keys %$files) {
        print $out "\n#### $rel\n", $files->{$rel};
    }
}

# ---------------------------------------------------------------------------
# --check: rendered output vs. the checked-in lib/ tree.
# ---------------------------------------------------------------------------

# A hand-rolled "first differing line and context" report -- not a real
# diff algorithm, just the common prefix/suffix trimmed off both sides so
# the interesting middle is what's left, formatted unified-ish ('-'/'+')
# and capped to 40 lines. Sufficient for a maint loop; Text::Diff is not a
# dependency of this distribution and this doesn't need one.
sub _diff_lines {
    my ($have, $want) = @_;
    my @a = split /\n/, $have, -1;
    my @b = split /\n/, $want, -1;
    my $pre = 0;
    $pre++ while $pre < @a && $pre < @b && $a[$pre] eq $b[$pre];
    my $suf = 0;
    $suf++ while $suf < (@a - $pre) && $suf < (@b - $pre)
        && $a[$#a - $suf] eq $b[$#b - $suf];
    my @out = (sprintf('@@ first difference at line %d @@', $pre + 1));
    push @out, "-$_" for @a[$pre .. $#a - $suf];
    push @out, "+$_" for @b[$pre .. $#b - $suf];
    my $total = @out;
    if ($total > 40) {
        @out = @out[0 .. 39];
        push @out, sprintf('... (%d more line(s) omitted)', $total - 40);
    }
    return @out;
}

# The guard behind ignore_cosmetic_differs (k132). A file may be suppressed
# as a cosmetic differ ONLY when its STRUCTURAL content is byte-identical
# between the rendered source and the checked-in lib source after whitespace
# is normalised away -- so that a listed exception can never hide a real
# change (house rule: a red test is a claim before it is a failure). The
# structural content is exactly the statements the k8s DSL and the identity
# import carry: every `k8s <name> => <type>[, <opts>];` declaration
# (name/type/required/enum) plus the `use IO::K8s::APIObject|Resource ...;`
# and any `with '...';` (api_version/scope/roles). Everything else in the
# file -- the `# ABSTRACT:` line, POD (=attr/=description/=seealso ...),
# ordinary comments, blank lines, =>-alignment and where the k8s lines sit
# relative to their POD -- is cosmetic and never enters the signature.
#
# This is textual, not a Perl parse, and that is sufficient here: both sides
# are emitter-shaped source whose only load-bearing lines are those three
# statement kinds, each terminated by `;`. The normalisation collapses every
# whitespace run to one space and drops the spaces just inside brackets, so a
# qw() enum wrapped across several lines in lib compares equal to the same
# enum on one line from the emitter, while a changed member, type or
# required-ness does not.
sub _structural_signature {
    my ($src) = @_;
    my @code;
    my $in_pod = 0;
    for my $line (split /\n/, $src, -1) {
        if (!$in_pod && $line =~ /^=\w/) { $in_pod = 1; next; }
        if ($in_pod) { $in_pod = 0 if $line =~ /^=cut\b/; next; }
        next if $line =~ /^\s*#/;      # comment-only line (incl. # ABSTRACT:)
        next unless $line =~ /\S/;     # blank
        push @code, $line;
    }
    my @stmts;
    my $buf;
    for my $line (@code) {
        if (!defined $buf) {
            next unless $line =~ /^\s*(?:use\s+IO::K8s::(?:APIObject|Resource)\b|with\b|k8s\b)/;
            $buf = $line;
        }
        else {
            $buf .= "\n" . $line;
        }
        if ($buf =~ /;\s*\z/) { push @stmts, $buf; undef $buf; }
    }
    push @stmts, $buf if defined $buf;    # unterminated -- keep it, so it shows
    for my $stmt (@stmts) {
        $stmt =~ s/\s+/ /g;               # collapse every whitespace run
        $stmt =~ s/([(\[{])\s+/$1/g;      # no space just inside an opening bracket
        $stmt =~ s/\s+([)\]}])/$1/g;      # ... nor just inside a closing one
        $stmt =~ s/\A\s+//;
        $stmt =~ s/\s+\z//;
    }
    return join("\n", @stmts);
}

# Renders every served GVK of $provider (already computed in $rendered, a
# provider->file map from render_for) and diffs each file against
# lib/IO/K8s/<Provider>/. Returns { provider, rows => [...], bad => 0|1 }.
sub check_for {
    my ($opt, $provider, $rendered, $exceptions) = @_;

    my $provider_dir = File::Spec->catdir($opt->{lib}, 'IO', 'K8s', $provider);
    my %shipped;
    if (-d $provider_dir) {
        require File::Find;
        File::Find::find({ no_chdir => 1, wanted => sub {
            return unless -f $File::Find::name && /\.pm\z/;
            (my $rel = $File::Find::name) =~ s{^\Q$opt->{lib}\E/}{};
            $shipped{$rel} = 1;
        } }, $provider_dir);
    }

    my @rows;
    my $bad = 0;
    for my $rel (sort keys %$rendered) {
        delete $shipped{$rel};
        my $lib_path = File::Spec->catfile($opt->{lib}, split m{/}, $rel);
        if (!-f $lib_path) {
            push @rows, { status => 'MISSING IN LIB', path => $rel };
            $bad = 1;
            next;
        }
        my $have = _slurp($lib_path);
        my $want = $rendered->{$rel};
        if ($have eq $want) {
            push @rows, { status => 'MATCH', path => $rel };
            next;
        }
        my ($ign, $reason) = cosmetic_differ_excepted($provider, $rel, $exceptions->{ignore_cosmetic_differs});
        if ($ign && _structural_signature($have) eq _structural_signature($want)) {
            # Listed AND the k8s declarations still match the render: the
            # difference is POD/ABSTRACT/whitespace only. Suppress it -- not a
            # failing differ, does not set $bad.
            push @rows, { status => 'COSMETIC', path => $rel, excepted => 1, reason => $reason };
            next;
        }
        # A genuine structural difference the maintainer chose to keep as a
        # documented, file-exact divergence (k133 Weg 1) -- distinct from a
        # cosmetic differ: it is NOT gated on _structural_signature (the whole
        # point is that the k8s declarations DO differ). Not a failing differ;
        # does not set $bad. The diff rides along so --verbose shows exactly
        # what is being accepted, and matching stays strictly provider+path so
        # no other file's drift can hide behind it.
        my ($accept, $accept_reason) =
            accept_divergence_excepted($provider, $rel, $exceptions->{accept_structural_divergence});
        if ($accept) {
            push @rows, { status => 'ACCEPTED DIVERGENCE', path => $rel,
                          excepted => 1, reason => $accept_reason,
                          diff => [ _diff_lines($have, $want) ] };
            next;
        }
        # A real DIFFERS. If it was listed as cosmetic yet the structural
        # content deviates, the guard refused it: flag the stale/wrong entry
        # loudly rather than swallowing the change (k132).
        my $row = { status => 'DIFFERS', path => $rel, diff => [ _diff_lines($have, $want) ] };
        $row->{guard_tripped} = 1 if $ign;
        push @rows, $row;
        $bad = 1;
    }
    for my $rel (sort keys %shipped) {
        my ($ign, $reason) = unrendered_excepted($provider, $rel, $exceptions->{ignore_unrendered});
        push @rows, { status => 'NOT RENDERED', path => $rel, excepted => $ign, reason => $reason };
        $bad = 1 unless $ign;
    }
    return { provider => $provider, rows => \@rows, bad => $bad };
}

sub render_check_report {
    my ($c, $verbose) = @_;
    my @out;
    push @out, sprintf('########## %s --check (rendered vs lib/IO/K8s/%s) ##########', $c->{provider}, $c->{provider});
    my %count;
    for my $row (@{ $c->{rows} }) {
        $count{ $row->{status} }++;
        # Cosmetic and accepted-divergence (both suppressed) rows are listed
        # only under --verbose -- the same discipline render_provider uses for
        # exception-suppressed drift (k132/k133), so a routine --check stays
        # structurally readable.
        next if ($row->{status} eq 'COSMETIC'
                 || $row->{status} eq 'ACCEPTED DIVERGENCE') && !$verbose;
        my $line = sprintf('  %-16s %s', $row->{status}, $row->{path});
        $line .= '  -- ' . $row->{reason} if $row->{excepted} && defined $row->{reason};
        $line .= '  -- LISTED cosmetic but structural content deviates; guard kept it as a real DIFFERS'
            if $row->{guard_tripped};
        push @out, $line;
        push @out, "    $_" for @{ $row->{diff} // [] };
    }
    my $cosmetic = $count{COSMETIC} // 0;
    my $accepted = $count{'ACCEPTED DIVERGENCE'} // 0;
    push @out, sprintf(
        '--- SUMMARY: %d match, %d differ, %d cosmetic (suppressed), %d accepted divergence (suppressed), %d missing in lib, %d not rendered ---',
        $count{MATCH} // 0, $count{DIFFERS} // 0, $cosmetic, $accepted,
        $count{'MISSING IN LIB'} // 0, $count{'NOT RENDERED'} // 0,
    );
    push @out, '  (cosmetic differs suppressed by ignore_cosmetic_differs -- rerun with --verbose to list them)'
        if $cosmetic && !$verbose;
    push @out, '  (accepted divergences suppressed by accept_structural_divergence -- rerun with --verbose to list them)'
        if $accepted && !$verbose;
    push @out, '';
    return join("\n", @out) . "\n";
}

sub render_check_unresolved {
    my ($provider) = @_;
    return "########## $provider --check ##########\n"
        . "  skipped: upstream source unresolved -- no openAPIV3Schema to render against\n\n";
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

my $opt = parse_args();
load_lib($opt->{lib});
my $exceptions = load_exceptions($opt->{exceptions});
# Loaded once, up front: render_gvk reads it for every --suggest/--render
# GVK regardless of which of those flags (or neither) is actually set.
$opt->{_names_map} = load_names($opt->{names});

my @results = map { check_provider($opt, $_, $exceptions) } @{ $opt->{provider} };

# check_provider embeds the parsed upstream view as _upstream purely to get
# it out to --suggest below. Pull it into its own map and strip it off
# @results right away, unconditionally -- not only for --format json -- so
# neither render_report nor the JSON encode ever has to know it was there,
# and so --suggest still has it regardless of --format.
my %upstream_by_provider;
for my $r (@results) {
    $upstream_by_provider{ $r->{provider} } = delete $r->{_upstream} if $r->{_upstream};
}

my $report;
if ($opt->{format} eq 'json') {
    $report = JSON::PP->new->canonical->pretty->encode({ providers => \@results });
} else {
    $report = render_report(\@results, $opt->{verbose});
}

print $report;
if ($opt->{output}) {
    open my $fh, '>:encoding(UTF-8)', $opt->{output}
        or die "crd-drift-check: cannot write $opt->{output}: $!\n";
    print $fh $report;
    close $fh;
}

if ($opt->{suggest} || $opt->{suggest_dir}) {
    my %files;
    for my $r (@results) {
        my $upstream = $upstream_by_provider{ $r->{provider} } or next;
        my $f = suggest_for($opt, $r, $upstream);
        $files{$_} = $f->{$_} for keys %$f;
    }
    emit_files($opt, \%files, $opt->{suggest_dir}, 'suggest');
}

# --render and --check both need the full render (every served GVK, not
# only a reported gap) -- computed once per provider here and reused by
# whichever of the two flags is set, rather than rendering twice.
my %rendered_by_provider;
if ($opt->{render} || $opt->{render_dir} || $opt->{check}) {
    for my $r (@results) {
        my $upstream = $upstream_by_provider{ $r->{provider} } or next;
        $rendered_by_provider{ $r->{provider} } = render_for($opt, $r->{provider}, $upstream);
    }
}

if ($opt->{render} || $opt->{render_dir}) {
    my %files;
    for my $provider (keys %rendered_by_provider) {
        my $f = $rendered_by_provider{$provider};
        $files{$_} = $f->{$_} for keys %$f;
    }
    emit_files($opt, \%files, $opt->{render_dir}, 'render');
}

my $check_failed = 0;
if ($opt->{check}) {
    my $out = _report_out($opt);
    for my $r (@results) {
        if (!$upstream_by_provider{ $r->{provider} }) {
            print $out render_check_unresolved($r->{provider});
            next;
        }
        my $c = check_for($opt, $r->{provider}, $rendered_by_provider{ $r->{provider} }, $exceptions);
        $check_failed = 1 if $c->{bad};
        print $out render_check_report($c, $opt->{verbose});
    }
}

exit(1) if $check_failed;
