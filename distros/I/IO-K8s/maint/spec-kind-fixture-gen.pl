#!/usr/bin/env perl
# Distills a Kubernetes upstream swagger.json into a compact, checked-in
# fixture of every x-kubernetes-group-version-kind entry: apiVersion, Kind
# name, and namespace scope. Feeds t/43_spec_kind_dispatch.t, which walks
# every entry in the fixture and checks that IO::K8s can actually resolve
# and load it -- the repeatable version of the class of bug found by a
# pre-release manual sweep: StorageVersionMigration and LeaseCandidate
# shipped as classes but were completely absent from %DEFAULT_RESOURCE_MAP,
# so inflate() died with "Can't locate .../StorageVersionMigration.pm in
# @INC" (fixed under karr #11).
#
# This script is maint/-only tooling: it downloads or reads a swagger.json
# and writes t/data/spec-kinds.json. It is never run by the test suite --
# the test that consumes its output is 100% offline, per this dist's rule
# that tests never touch the network or a cluster.
#
# Scope (namespaced vs. cluster) is not in `definitions` -- swagger.json's
# x-kubernetes-group-version-kind extension on a *definition* only carries
# group/version/kind, not scope. It has to be read off the real REST
# `paths`: a namespaced resource's single-item GET/POST path contains a
# literal "/namespaces/{namespace}/" segment, a cluster-scoped one does not.
# This mirrors the manual verification done for the DRA v1.36 sync ("scope
# verified against the real swagger paths, not just pattern-matched from
# V1", see Changes) -- that was a one-off manual check, not encoded
# anywhere yet, so build_scope_maps()/resolve_scope() below are new, not a
# port of existing code. What IS ported (verbatim logic, see comments) is
# is_dropped_list_kind() from maint/spec-drift-check.pl, and the
# tag-resolve/download/cache helpers, which mirror that script's so the two
# maint tools behave the same way for the same --tag/--spec/--cache-dir
# options.
#
# Usage:
#   maint/spec-kind-fixture-gen.pl [--tag v1.36.3 | --spec path/to/swagger.json]
#                                   [--output t/data/spec-kinds.json]
#                                   [--cache-dir path] [--no-cache]
#
# Examples:
#   maint/spec-kind-fixture-gen.pl --spec spec/v1.36.3.json
#     Regenerate the checked-in fixture from an already-cached local spec
#     (no network access at all).
#
#   maint/spec-kind-fixture-gen.pl --tag v1.36.3
#     Regenerate from a pinned upstream tag, downloading + caching under
#     spec/ (gitignored) if not already present.
#
# Network access: only when --tag needs to download (or resolve "latest"
# via the GitHub tags API) and the tag isn't already cached under
# --cache-dir. --spec pointing at a local file never touches the network.
use strict;
use warnings;
use v5.10;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use Digest::SHA qw(sha256_hex);
use JSON::PP;

my $DIST_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $UA_STRING = 'io-k8s-p5-spec-kind-fixture-gen (+https://github.com/pplu/io-k8s-p5)';

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

sub usage {
    my ($exit_code) = @_;
    print <<"USAGE";
Usage:
  $0 [--tag TAG | --spec PATH] [options]

Options:
  --tag TAG            Upstream Kubernetes tag, e.g. v1.36.3 (default: latest
                        stable release from the kubernetes/kubernetes tag list)
  --spec PATH           Local swagger.json instead of downloading
  --output PATH         Fixture to write (default: DIST/t/data/spec-kinds.json)
  --cache-dir PATH       Downloaded-spec cache directory (default: DIST/spec)
  --no-cache             Force re-download even if a cached copy exists
  --help                 This message

Writes one JSON object per x-kubernetes-group-version-kind entry found in
the spec's definitions: def_key (the upstream io.k8s.* identity), api_version
(group/version, or bare version for the core group), kind, whether the spec's
own \`items\`-shaped generic list-kind pattern applies (list_kind), and
namespace scope read off the real REST paths (namespaced: true/false/null --
null when no path in the spec addresses this exact GVK at all, e.g. the
generic per-group DeleteOptions/WatchEvent request/response wrapper types).
USAGE
    exit($exit_code // 0);
}

sub parse_args {
    my %opt = (
        'cache-dir' => File::Spec->catdir($DIST_ROOT, 'spec'),
        output      => File::Spec->catfile($DIST_ROOT, 't', 'data', 'spec-kinds.json'),
    );
    GetOptions(\%opt,
        'tag=s', 'spec=s', 'output=s', 'cache-dir=s', 'no-cache',
        'help|h',
    ) or usage(1);
    usage(0) if $opt{help};
    return \%opt;
}

# ---------------------------------------------------------------------------
# HTTP + spec loading -- mirrors maint/spec-drift-check.pl's fetch/cache path
# (same tag resolution, same on-disk cache under spec/, same UA string
# convention) so both maint tools behave identically for the same options.
# ---------------------------------------------------------------------------

sub http_get_json {
    my ($url) = @_;
    require HTTP::Tiny;
    my $ua  = HTTP::Tiny->new(agent => $UA_STRING, timeout => 30);
    my $res = $ua->get($url);
    die sprintf("spec-kind-fixture-gen: GET %s failed: %s %s\n",
        $url, $res->{status} // '?', $res->{reason} // '?')
        unless $res->{success};
    my $data = eval { JSON::PP->new->decode($res->{content}) };
    die "spec-kind-fixture-gen: could not parse JSON from $url: $@\n" if $@;
    return $data;
}

sub _tag_sort_key {
    my ($tag) = @_;
    return undef unless $tag =~ /^v(\d+)\.(\d+)\.(\d+)$/;
    return [ $1 + 0, $2 + 0, $3 + 0 ];
}

sub latest_stable_tag {
    my @names;
    for my $page (1 .. 3) {
        my $data = http_get_json(
            "https://api.github.com/repos/kubernetes/kubernetes/tags?per_page=100&page=$page");
        last unless ref $data eq 'ARRAY' && @$data;
        push @names, map { $_->{name} } @$data;
        last if @$data < 100;
    }
    my @stable = grep { defined _tag_sort_key($_) } @names;
    die "spec-kind-fixture-gen: no stable vX.Y.Z tags found in the kubernetes/kubernetes tag list\n"
        unless @stable;
    my ($best) = sort {
        my ($ka, $kb) = (_tag_sort_key($a), _tag_sort_key($b));
        $kb->[0] <=> $ka->[0] || $kb->[1] <=> $ka->[1] || $kb->[2] <=> $ka->[2];
    } @stable;
    return $best;
}

sub _slurp_json {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "spec-kind-fixture-gen: cannot read $path: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh;
    my $source_sha256 = sha256_hex($content);
    my $data = eval { JSON::PP->new->decode($content) };
    die "spec-kind-fixture-gen: could not parse JSON from $path: $@\n" if $@;
    return ($data, $source_sha256);
}

sub fetch_spec_for_tag {
    my ($tag, $cache_dir, $no_cache) = @_;
    make_path($cache_dir) unless -d $cache_dir;
    my $cache_file = File::Spec->catfile($cache_dir, "$tag.json");
    if (!$no_cache && -f $cache_file) {
        return _slurp_json($cache_file);
    }
    my $url = "https://raw.githubusercontent.com/kubernetes/kubernetes/$tag/api/openapi-spec/swagger.json";
    print STDERR "spec-kind-fixture-gen: downloading $url ...\n";
    require HTTP::Tiny;
    my $ua  = HTTP::Tiny->new(agent => $UA_STRING, timeout => 90);
    my $res = $ua->get($url);
    die sprintf("spec-kind-fixture-gen: GET %s failed: %s %s\n",
        $url, $res->{status} // '?', $res->{reason} // '?')
        unless $res->{success};
    my $source_sha256 = sha256_hex($res->{content});
    my $data = eval { JSON::PP->new->decode($res->{content}) };
    die "spec-kind-fixture-gen: could not parse JSON from $url: $@\n" if $@;
    open my $fh, '>:raw', $cache_file or die "spec-kind-fixture-gen: cannot write $cache_file: $!\n";
    print $fh $res->{content};
    close $fh;
    return ($data, $source_sha256);
}

sub load_spec_arg {
    my ($value, $cache_dir, $no_cache) = @_;
    if (defined $value && -f $value) {
        my ($data, $source_sha256) = _slurp_json($value);
        return ($data, $value, $source_sha256);
    }
    my $tag = $value // latest_stable_tag();
    my ($data, $source_sha256) = fetch_spec_for_tag($tag, $cache_dir, $no_cache);
    return ($data, $tag, $source_sha256);
}

# ---------------------------------------------------------------------------
# Structural helpers
# ---------------------------------------------------------------------------

# Verbatim port of is_dropped_list_kind() from maint/spec-drift-check.pl:
# the generic Kubernetes list wrapper (a Kind with just `items` + `metadata`)
# that this dist dropped project-wide in 1.105. Structural, not name-based:
# a definition key ending in "List" whose properties include `items`.
# (spec-drift-check.pl also requires has_gvk($def), which is always true
# here since we only ever call this for definitions we're already iterating
# because they have a GVK entry.)
sub is_dropped_list_kind {
    my ($key, $def) = @_;
    return 0 unless $key =~ /List$/;
    return 0 unless exists(($def->{properties} // {})->{items});
    return 1;
}

# Read namespace scope for every x-kubernetes-group-version-kind straight
# off the spec's `paths`. Two independent tables, keyed by "group\x1eversion\
# x1ekind":
#
#   %get  -- the single-item "get by name" path (x-kubernetes-action eq
#            'get'). Unambiguous: a namespaced resource's get-by-name path
#            always has literal "/namespaces/{namespace}/" in it, a
#            cluster-scoped one never does. This is the primary source.
#
#   %post -- the "create" path (x-kubernetes-action eq 'post'). Fallback for
#            action-style Kinds that have no individual GET at all (Binding,
#            Eviction, TokenReview, *SubjectAccessReview, ...) -- you POST
#            them, you never GET them by name.
#
# Deliberately NOT using the collection "list" action: the cross-namespace
# "list this Kind across all namespaces" convenience path exists for every
# namespaced resource too (e.g. GET /api/v1/pods alongside GET
# /api/v1/namespaces/{namespace}/pods) and reports the same GVK without a
# namespace segment -- folding it in produces a same-key true/false
# conflict for nearly every namespaced core/apps/... Kind. get+post are each
# unambiguous on their own (verified against spec/v1.36.3.json: zero
# same-key conflicts in either table).
sub build_scope_maps {
    my ($spec) = @_;
    my (%get, %post);
    my $paths = $spec->{paths} // {};
    for my $path (sort keys %$paths) {
        my $item = $paths->{$path};
        for my $method (qw(get post)) {
            my $op = $item->{$method} or next;
            next unless ($op->{'x-kubernetes-action'} // '') eq $method;
            my $gvk = $op->{'x-kubernetes-group-version-kind'} or next;
            my $key = join("\x1e", $gvk->{group} // '', $gvk->{version} // '', $gvk->{kind} // '');
            my $namespaced = ($path =~ m{/namespaces/\{namespace\}/}) ? 1 : 0;
            my $tbl = $method eq 'get' ? \%get : \%post;
            if (exists $tbl->{$key} && $tbl->{$key} != $namespaced) {
                warn "spec-kind-fixture-gen: scope conflict for '$key' ($method): $path disagrees with an earlier path for the same GVK\n";
            }
            $tbl->{$key} = $namespaced;
        }
    }
    return (\%get, \%post);
}

# undef when neither table has direct path evidence for this exact GVK --
# true for the ~85 dropped-list-kind entries (a "list" operation's GVK
# names the item Kind, e.g. Pod, never "PodList", so a List kind's own GVK
# never appears as any operation's x-kubernetes-group-version-kind) and for
# generic non-per-item types like DeleteOptions/WatchEvent/Status/APIGroup.
sub resolve_scope {
    my ($gvk, $get, $post) = @_;
    my $key = join("\x1e", $gvk->{group} // '', $gvk->{version} // '', $gvk->{kind} // '');
    return $get->{$key}  if exists $get->{$key};
    return $post->{$key} if exists $post->{$key};
    return undef;
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

my $opt = parse_args();
my $source = $opt->{spec} // $opt->{tag};
my ($spec, $label, $source_sha256) =
    load_spec_arg($source, $opt->{'cache-dir'}, $opt->{'no-cache'});
my $defs = $spec->{definitions}
    or die "spec-kind-fixture-gen: no 'definitions' key in spec ($label)\n";

# $label is whatever load_spec_arg() was given to resolve the spec: a bare
# tag ('v1.36.3') when --tag/latest-stable was used, or a file path
# ('spec/v1.36.3.json') when --spec pointed at a local file. Prefer the
# clean vX.Y.Z tag for the fixture header when one is embedded in the path,
# so "regenerated from a local cache" and "regenerated via --tag" produce
# the same header for the same spec.
my ($generated_from) = $label =~ /(v\d+\.\d+\.\d+)/ ? $1 : $label;

my ($scope_get, $scope_post) = build_scope_maps($spec);

my @entries;
for my $key (sort keys %$defs) {
    my $def  = $defs->{$key};
    my $gvks = $def->{'x-kubernetes-group-version-kind'} or next;
    my $list_kind = is_dropped_list_kind($key, $def) ? 1 : 0;

    for my $gvk (@$gvks) {
        my $group   = $gvk->{group}   // '';
        my $version = $gvk->{version} // '';
        my $kind    = $gvk->{kind}    // '';
        my $api_version = length($group) ? "$group/$version" : $version;
        my $ns = resolve_scope($gvk, $scope_get, $scope_post);

        push @entries, {
            def_key     => $key,
            api_version => $api_version,
            kind        => $kind,
            list_kind   => $list_kind ? JSON::PP::true : JSON::PP::false,
            namespaced  => defined($ns) ? ($ns ? JSON::PP::true : JSON::PP::false) : undef,
        };
    }
}

# Stable sort for a readable diff on regeneration: by Kind name (what a
# human scans for first), then api_version, then the upstream def_key as a
# final tiebreaker (only matters for DeleteOptions/WatchEvent, which repeat
# the same kind+api_version pattern across many groups... no, actually
# def_key differs per group there too since each group gets its own
# x-kubernetes-group-version-kind list entry from the SAME def_key -- the
# def_key alone does not disambiguate those; group is already folded into
# api_version, so api_version does).
@entries = sort {
    $a->{kind} cmp $b->{kind}
        || $a->{api_version} cmp $b->{api_version}
        || $a->{def_key} cmp $b->{def_key}
} @entries;

my $enc = JSON::PP->new->canonical->utf8(0);
my @lines = map { my $l = $enc->encode($_); chomp $l; $l } @entries;

make_path(File::Spec->catpath((File::Spec->splitpath($opt->{output}))[0,1], ''));
open my $fh, '>:encoding(UTF-8)', $opt->{output}
    or die "spec-kind-fixture-gen: cannot write $opt->{output}: $!\n";
print $fh "{\n";
print $fh qq{   "generator" : "maint/spec-kind-fixture-gen.pl",\n};
print $fh qq{   "generated_from" : "$generated_from",\n};
print $fh qq{   "source_sha256" : "$source_sha256",\n};
print $fh qq{   "gvk_total_in_spec" : } . scalar(@entries) . qq{,\n};
print $fh qq{   "entries" : [\n};
print $fh join(",\n", map { "      $_" } @lines);
print $fh "\n   ]\n";
print $fh "}\n";
close $fh;

print STDERR "spec-kind-fixture-gen: wrote $opt->{output} (" . scalar(@entries) . " entries from $label)\n";
