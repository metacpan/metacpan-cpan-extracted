#!/usr/bin/env perl
# Derives the Kind -> plural resource-name tables from a Kubernetes upstream
# swagger.json and rewrites the generated blocks inside
# lib/IO/K8s/Role/APIObject.pm, which is what
# IO::K8s::Role::APIObject::resource_plural() looks up.
#
# Why generated and not hand-written: the plural is NOT derivable from the
# Kind. Endpoints -> endpoints, NetworkPolicy -> networkpolicies, Ingress ->
# ingresses, PriorityClass -> priorityclasses, CSIStorageCapacity ->
# csistoragecapacities. It IS authoritative in the spec's REST paths, which
# is where this reads it from -- guessing is the exact failure mode karr #33
# exists to remove (a wrong plural is indistinguishable from a denied
# permission at the RBAC layer).
#
# Extraction rule
#   For every operation in `paths` that carries an
#   x-kubernetes-group-version-kind AND an x-kubernetes-action of 'list' or
#   'post' -- i.e. the collection endpoints, the only ones whose final path
#   segment is the resource's own plural -- take the last non-parameterised
#   path segment. 'get'/'put'/'patch'/'delete' are deliberately NOT used:
#   their paths end in "{name}" (parameterised, so skipped) or, worse, in a
#   subresource segment.
#
#   Subresource segments are filtered by name (status, scale, log, exec,
#   proxy, binding, approval, token, eviction). They reach this point via
#   the handful of subresources that are themselves a POSTable Kind --
#   pods/{name}/eviction (Eviction), deployments/{name}/scale (Scale),
#   serviceaccounts/{name}/token (TokenRequest). Those Kinds are NOT
#   top-level resources and correctly end up with no plural at all; RBAC
#   addresses them as "pods/eviction", not as a resource of their own.
#
#   Note the filter is on the trailing segment, not on the Kind: the core
#   group's Binding IS a top-level resource (POST /api/v1/namespaces/
#   {namespace}/bindings -> "bindings") and keeps its plural; only the
#   pods/{name}/binding path is dropped.
#
# Two tables come out of the one run, both written into their own delimited
# generated block in the target module:
#
#   %RESOURCE_PLURAL           keyed "$api_version/$Kind"
#   %RESOURCE_PLURAL_BY_GROUP  keyed "$group|$Kind"  ($group is '' for core)
#
# The first is the same domain-qualified key shape as %DEFAULT_RESOURCE_MAP's
# qualified keys in lib/IO/K8s.pm, and exactly what
# IO::K8s::Role::APIObject::api_version() returns joined to kind(). Group is
# folded into the api_version, so core/v1 Event and events.k8s.io/v1 Event
# stay distinct entries. It is consulted first because an exact GVK is the
# most specific fact the spec has.
#
# The second exists because the plural is a property of the GroupResource,
# not of the version: RBAC addresses resources by apiGroups + resources with
# no version in the rule at all, and that is the consumer karr #33 was
# written for. It gives the shipped classes that sit on API tracks upstream
# has since dropped (resource.k8s.io/v1alpha3, flowcontrol/v1beta3,
# storage.k8s.io/v1alpha1, ...) the plural their served siblings already
# have, without inventing anything: every value in it is still read off a
# real collection path in this spec. Core stays a group of its own (the
# empty group), so core Event and events.k8s.io Event remain distinct here
# too -- this is group+Kind, never a bare Kind.
#
# This script never guesses and never merges. It dies rather than pick a
# winner when two paths claim different plurals for one GVK, and dies the
# same way when two versions of one group claim different plurals for one
# Kind -- upstream varying a plural across versions of a group is a signal
# to a human, not something to resolve silently.
#
# Like maint/spec-kind-fixture-gen.pl this is maint/-only tooling. It is
# never run by the test suite; the tests consume the checked-in table.
#
# Usage:
#   maint/spec-resource-plural-gen.pl [--tag v1.36.3 | --spec path/to/swagger.json]
#                                     [--output lib/IO/K8s/Role/APIObject.pm]
#                                     [--cache-dir path] [--no-cache]
#
# Examples:
#   maint/spec-resource-plural-gen.pl --spec spec/v1.36.3.json
#     Rewrite the table in the role module from an already-cached local spec
#     (no network access at all).
#
#   maint/spec-resource-plural-gen.pl --tag v1.37.0
#     Rewrite from a pinned upstream tag, downloading + caching under spec/
#     (gitignored) if not already present. This is the next-upstream-sync
#     invocation: run it, then `git diff lib/IO/K8s/Role/APIObject.pm` to
#     see exactly which plurals upstream added, dropped or moved.
#
#   maint/spec-resource-plural-gen.pl --spec spec/v1.36.3.json --output -
#     Print the generated block to stdout and touch nothing.
#
# Network access: only when --tag needs to download (or resolve "latest" via
# the GitHub tags API) and the tag isn't already cached under --cache-dir.
# --spec pointing at a local file never touches the network.
use strict;
use warnings;
use v5.10;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP;

my $DIST_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $UA_STRING = 'io-k8s-p5-spec-resource-plural-gen (+https://github.com/pplu/io-k8s-p5)';

# Two independently delimited regions, one per table. The markers are
# prefix-matched at column 0, and "group resource plural table" is not a
# prefix of "resource plural table", so the two regions never capture each
# other.
my $BEGIN_MARKER = '# --- BEGIN GENERATED resource plural table';
my $END_MARKER   = '# --- END GENERATED resource plural table ---';

my $GROUP_BEGIN_MARKER = '# --- BEGIN GENERATED group resource plural table';
my $GROUP_END_MARKER   = '# --- END GENERATED group resource plural table ---';

# Trailing path segments that name a subresource rather than a resource.
# See the header comment: only reachable for the few subresources that are
# themselves a POSTable Kind.
my %SUBRESOURCE_SEGMENT = map { $_ => 1 } qw(
    status scale log exec proxy binding approval token eviction
);

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

sub usage {
    my ($exit_code) = @_;
    print <<"USAGE";
Usage:
  $0 [--tag TAG | --spec PATH] [options]

Options:
  --tag TAG             Upstream Kubernetes tag, e.g. v1.36.3 (default: latest
                        stable release from the kubernetes/kubernetes tag list)
  --spec PATH           Local swagger.json instead of downloading
  --output PATH         Module whose generated blocks are rewritten (default:
                        DIST/lib/IO/K8s/Role/APIObject.pm). "-" prints the
                        generated blocks to stdout and writes nothing.
  --cache-dir PATH      Downloaded-spec cache directory (default: DIST/spec)
  --no-cache            Force re-download even if a cached copy exists
  --help                This message

Rewrites two delimited regions of the target module with the Kind -> plural
tables read off the spec's REST paths (collection endpoints of the list/post
actions):

  "$BEGIN_MARKER ... $END_MARKER"
      keys "\$api_version/\$Kind" -- the exact-GVK table, consulted first

  "$GROUP_BEGIN_MARKER ... $GROUP_END_MARKER"
      keys "\$group|\$Kind" -- the GroupResource fallback, emitted only where
      every version of the group agrees on the plural

Subresource-only Kinds (Eviction, Scale, TokenRequest) are absent from both
on purpose and keep returning undef.
USAGE
    exit($exit_code // 0);
}

sub parse_args {
    my %opt = (
        'cache-dir' => File::Spec->catdir($DIST_ROOT, 'spec'),
        output      => File::Spec->catfile($DIST_ROOT, 'lib', 'IO', 'K8s', 'Role', 'APIObject.pm'),
    );
    GetOptions(\%opt,
        'tag=s', 'spec=s', 'output=s', 'cache-dir=s', 'no-cache',
        'help|h',
    ) or usage(1);
    usage(0) if $opt{help};
    return \%opt;
}

# ---------------------------------------------------------------------------
# HTTP + spec loading -- mirrors maint/spec-kind-fixture-gen.pl's fetch/cache
# path (same tag resolution, same on-disk cache under spec/, same UA string
# convention) so all three maint tools behave identically for the same
# --tag/--spec/--cache-dir/--no-cache options.
# ---------------------------------------------------------------------------

sub http_get_json {
    my ($url) = @_;
    require HTTP::Tiny;
    my $ua  = HTTP::Tiny->new(agent => $UA_STRING, timeout => 30);
    my $res = $ua->get($url);
    die sprintf("spec-resource-plural-gen: GET %s failed: %s %s\n",
        $url, $res->{status} // '?', $res->{reason} // '?')
        unless $res->{success};
    my $data = eval { JSON::PP->new->decode($res->{content}) };
    die "spec-resource-plural-gen: could not parse JSON from $url: $@\n" if $@;
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
    die "spec-resource-plural-gen: no stable vX.Y.Z tags found in the kubernetes/kubernetes tag list\n"
        unless @stable;
    my ($best) = sort {
        my ($ka, $kb) = (_tag_sort_key($a), _tag_sort_key($b));
        $kb->[0] <=> $ka->[0] || $kb->[1] <=> $ka->[1] || $kb->[2] <=> $ka->[2];
    } @stable;
    return $best;
}

sub _slurp_json {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "spec-resource-plural-gen: cannot read $path: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh;
    my $data = eval { JSON::PP->new->decode($content) };
    die "spec-resource-plural-gen: could not parse JSON from $path: $@\n" if $@;
    return $data;
}

sub fetch_spec_for_tag {
    my ($tag, $cache_dir, $no_cache) = @_;
    make_path($cache_dir) unless -d $cache_dir;
    my $cache_file = File::Spec->catfile($cache_dir, "$tag.json");
    return _slurp_json($cache_file) if !$no_cache && -f $cache_file;

    my $url = "https://raw.githubusercontent.com/kubernetes/kubernetes/$tag/api/openapi-spec/swagger.json";
    print STDERR "spec-resource-plural-gen: downloading $url ...\n";
    require HTTP::Tiny;
    my $ua  = HTTP::Tiny->new(agent => $UA_STRING, timeout => 90);
    my $res = $ua->get($url);
    die sprintf("spec-resource-plural-gen: GET %s failed: %s %s\n",
        $url, $res->{status} // '?', $res->{reason} // '?')
        unless $res->{success};
    my $data = eval { JSON::PP->new->decode($res->{content}) };
    die "spec-resource-plural-gen: could not parse JSON from $url: $@\n" if $@;
    open my $fh, '>:raw', $cache_file or die "spec-resource-plural-gen: cannot write $cache_file: $!\n";
    print $fh $res->{content};
    close $fh;
    return $data;
}

sub load_spec_arg {
    my ($value, $cache_dir, $no_cache) = @_;
    return (_slurp_json($value), $value) if defined $value && -f $value;
    my $tag = $value // latest_stable_tag();
    return (fetch_spec_for_tag($tag, $cache_dir, $no_cache), $tag);
}

# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------

# Both tables in one pass over the collection REST paths:
#
#   "$api_version/$Kind" => plural   (exact GVK)
#   "$group|$Kind"       => plural   (GroupResource, '' group for core)
#
# Dies on a same-key conflict in either table rather than picking a winner.
# For the group table that means: two versions of one group claiming
# different plurals for one Kind is a hard stop, not something to average.
# Every pair that survives is a pair every version of the spec agrees on,
# which is the only condition under which a group-keyed entry is emitted.
sub build_plural_table {
    my ($spec) = @_;
    my $paths = $spec->{paths}
        or die "spec-resource-plural-gen: no 'paths' key in spec\n";

    my (%plural, %source, %group_plural, %group_source);
    for my $path (sort keys %$paths) {
        my $item = $paths->{$path};
        next unless ref $item eq 'HASH';
        for my $method (sort keys %$item) {
            my $op = $item->{$method};
            next unless ref $op eq 'HASH';
            my $gvk = $op->{'x-kubernetes-group-version-kind'} or next;
            my $action = $op->{'x-kubernetes-action'} // '';
            next unless $action eq 'list' || $action eq 'post';

            # Last literal (non-"{param}") segment of the path.
            my @segments = grep { length && !/\A\{/ } split m{/}, $path;
            next unless @segments;
            my $last = $segments[-1];
            next if $SUBRESOURCE_SEGMENT{$last};

            my $group   = $gvk->{group}   // '';
            my $version = $gvk->{version} // '';
            my $kind    = $gvk->{kind}    // '';
            next unless length $version && length $kind;
            my $api_version = length($group) ? "$group/$version" : $version;
            my $key = "$api_version/$kind";

            if (exists $plural{$key} && $plural{$key} ne $last) {
                die sprintf(
                    "spec-resource-plural-gen: conflicting plurals for '%s': '%s' (%s) vs '%s' (%s)\n",
                    $key, $plural{$key}, $source{$key}, $last, $path);
            }
            $plural{$key} = $last;
            $source{$key} = $path;

            my $group_key = "$group|$kind";
            if (exists $group_plural{$group_key} && $group_plural{$group_key} ne $last) {
                die sprintf(
                    "spec-resource-plural-gen: upstream disagrees across versions of one group "
                  . "for '%s': '%s' (%s) vs '%s' (%s from %s). The plural is supposed to be a "
                  . "property of the GroupResource; a human has to decide what this means before "
                  . "the group-keyed table can be regenerated.\n",
                    $group_key, $group_plural{$group_key}, $group_source{$group_key},
                    $last, $api_version, $path);
            }
            $group_plural{$group_key} = $last;
            $group_source{$group_key} = "$api_version from $path";
        }
    }
    return (\%plural, \%group_plural);
}

# Sort key: group first (core first -- its keys carry no group at all), then
# the rest of the key. Stable across regenerations so an upstream sync
# produces a readable diff.
sub _group_of {
    my ($key) = @_;
    return $key =~ m{\A([^/]+)/[^/]+/[^/]+\z} ? $1 : '';
}

# Same idea for the "$group|$Kind" keys: everything before the '|', which is
# the empty string for the core group.
sub _group_of_pair {
    my ($key) = @_;
    return $key =~ m{\A([^|]*)\|} ? $1 : '';
}

sub render_block {
    my ($table, $label, $spec) = @_;
    my $group_of = $spec->{group_of};

    my @keys = sort {
        $group_of->($a) cmp $group_of->($b) || $a cmp $b
    } keys %$table;

    # Aligned per group block, not across the whole table: one long
    # flowcontrol.apiserver.k8s.io key would otherwise pad every core entry
    # out by 50 columns.
    my %width;
    for my $k (@keys) {
        my $group = $group_of->($k);
        my $len   = length($k) + 2;    # quotes
        $width{$group} = $len if $len > ($width{$group} // 0);
    }

    my @lines;
    push @lines, "$spec->{begin} ($label) ---";
    push @lines, '# Regenerate with: maint/spec-resource-plural-gen.pl --spec spec/' . $label . '.json';
    push @lines, "my \%$spec->{var} = (";
    my $prev_group;
    for my $k (@keys) {
        my $group = $group_of->($k);
        if (!defined $prev_group || $group ne $prev_group) {
            push @lines, '' if defined $prev_group;
            push @lines, sprintf('    # %s', length($group) ? $group : 'core');
            $prev_group = $group;
        }
        push @lines, sprintf(q{    %-*s => '%s',}, $width{$group}, "'$k'", $table->{$k});
    }
    push @lines, ');';
    push @lines, $spec->{end};
    return join("\n", @lines) . "\n";
}

# Each region is [ $begin_marker, $end_marker, $block ]. Regions are spliced
# back as real lines, not as one fat string, so a later region's marker scan
# sees the same line array shape as the first one did.
sub rewrite_module {
    my ($path, @regions) = @_;
    open my $in, '<:encoding(UTF-8)', $path
        or die "spec-resource-plural-gen: cannot read $path: $!\n";
    my @lines = <$in>;
    close $in;

    for my $region (@regions) {
        my ($begin_marker, $end_marker, $block) = @$region;

        my ($begin, $end);
        for my $i (0 .. $#lines) {
            $begin = $i if !defined $begin && index($lines[$i], $begin_marker) == 0;
            $end   = $i if defined $begin && index($lines[$i], $end_marker) == 0;
            last if defined $end;
        }
        die "spec-resource-plural-gen: no '$begin_marker ... ---' / '$end_marker' region in $path\n"
            unless defined $begin && defined $end;

        splice @lines, $begin, $end - $begin + 1, map { "$_\n" } split /\n/, $block;
    }

    open my $out, '>:encoding(UTF-8)', $path
        or die "spec-resource-plural-gen: cannot write $path: $!\n";
    print $out @lines;
    close $out;
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

my $opt = parse_args();
my ($spec, $label) = load_spec_arg($opt->{spec} // $opt->{tag},
    $opt->{'cache-dir'}, $opt->{'no-cache'});

# $label is either a bare tag ('v1.36.3') or the file path --spec named;
# prefer the embedded vX.Y.Z so both routes to the same spec produce the
# same generated header.
my ($generated_from) = $label =~ /(v\d+\.\d+\.\d+)/ ? $1 : $label;

my ($plural, $group_plural) = build_plural_table($spec);

my $block = render_block($plural, $generated_from, {
    var      => 'RESOURCE_PLURAL',
    begin    => $BEGIN_MARKER,
    end      => $END_MARKER,
    group_of => \&_group_of,
});
my $group_block = render_block($group_plural, $generated_from, {
    var      => 'RESOURCE_PLURAL_BY_GROUP',
    begin    => $GROUP_BEGIN_MARKER,
    end      => $GROUP_END_MARKER,
    group_of => \&_group_of_pair,
});

if ($opt->{output} eq '-') {
    print $block, "\n", $group_block;
}
else {
    rewrite_module($opt->{output},
        [ $BEGIN_MARKER,       $END_MARKER,       $block ],
        [ $GROUP_BEGIN_MARKER, $GROUP_END_MARKER, $group_block ],
    );
    print STDERR "spec-resource-plural-gen: wrote $opt->{output} ("
        . scalar(keys %$plural) . " plurals, "
        . scalar(keys %$group_plural) . " group plurals from $label)\n";
}
