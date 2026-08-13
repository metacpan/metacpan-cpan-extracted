#!/usr/bin/env perl
# Upstream Kubernetes OpenAPI spec drift checker for IO::K8s.
#
# Ports the manual coverage sweep done for the v1.36 sync (karr #4-#8) into a
# repeatable tool. Two modes:
#
#   Coverage mode (default): diffs one upstream swagger.json against what
#   lib/IO/K8s/ actually ships (the k8s() DSL attribute registry), kind by
#   kind, field by field.
#
#   Compare mode (--from/--to): diffs two upstream swagger.json specs
#   directly against each other, with no reference to this dist's lib/ at
#   all -- the "is upgrading worth it" question.
#
# This is a report generator. It never writes to lib/, never touches the
# karr board, and never modifies the exceptions file -- filtering settled
# decisions out of the noise is a judgement call left to a maintainer or
# agent reading the report, not something this script should do for them.
#
# Usage:
#   maint/spec-drift-check.pl [--tag v1.36.3 | --spec path/to/swagger.json]
#                              [--exceptions path] [--lib path]
#                              [--cache-dir path] [--no-cache]
#                              [--verbose] [--format text|json] [--output path]
#
#   maint/spec-drift-check.pl --from v1.31.0 --to v1.36.3
#     (--from/--to each take a tag or a local file path; --to defaults to
#     the latest stable release the same way coverage mode's --tag does)
#
# Examples:
#   maint/spec-drift-check.pl
#     Coverage report against the latest stable Kubernetes release.
#
#   maint/spec-drift-check.pl --tag v1.36.3 --verbose
#     Coverage report against a pinned tag, including suppressed entries
#     and the exception that suppressed each one.
#
#   maint/spec-drift-check.pl --from v1.31.0 --to v1.36.3
#     "Is upgrading from v1.31 to v1.36 worth it" report: new Kinds, new
#     required/optional fields, removals, description-only churn.
#
# Network access: talks to api.github.com (tag listing) and
# raw.githubusercontent.com (spec download) over HTTPS via HTTP::Tiny.
# Downloaded specs are cached under --cache-dir (default: spec/, already
# gitignored) so repeat runs against the same tag don't re-fetch.
use strict;
use warnings;
use v5.10;
use FindBin;
use File::Spec;
use File::Find;
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP;

my $DIST_ROOT  = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $UA_STRING  = 'io-k8s-p5-spec-drift-check (+https://github.com/pplu/io-k8s-p5)';

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

sub usage {
    my ($exit_code) = @_;
    print <<"USAGE";
Usage:
  $0 [--tag TAG | --spec PATH] [options]      # coverage mode (default)
  $0 --from TAG_OR_PATH --to TAG_OR_PATH       # compare mode

Coverage mode options:
  --tag TAG           Upstream Kubernetes tag, e.g. v1.36.3 (default: latest
                       stable release from the kubernetes/kubernetes tag list)
  --spec PATH         Local swagger.json instead of downloading

Compare mode options:
  --from TAG_OR_PATH  Baseline spec (required to enable compare mode)
  --to TAG_OR_PATH    Target spec (default: latest stable release)

Common options:
  --exceptions PATH   Exceptions file (default: maint/spec-drift-exceptions.yaml)
  --lib PATH          lib/ directory to load classes from (default: DIST/lib)
  --cache-dir PATH    Downloaded-spec cache directory (default: DIST/spec)
  --no-cache          Force re-download even if a cached copy exists
  --verbose           Also list items suppressed by the exceptions file
  --format text|json  Report format (default: text)
  --output PATH       Also write the report to this file
  --help              This message

This is a report only -- it never creates karr tickets or edits lib/.
USAGE
    exit($exit_code // 0);
}

sub parse_args {
    my %opt = (
        exceptions => File::Spec->catfile($FindBin::Bin, 'spec-drift-exceptions.yaml'),
        lib        => File::Spec->catdir($DIST_ROOT, 'lib'),
        'cache-dir'=> File::Spec->catdir($DIST_ROOT, 'spec'),
        format     => 'text',
    );
    GetOptions(\%opt,
        'tag=s', 'spec=s', 'from=s', 'to=s',
        'exceptions=s', 'lib=s', 'cache-dir=s', 'no-cache',
        'verbose', 'output=s', 'format=s', 'help|h',
    ) or usage(1);
    usage(0) if $opt{help};
    if ($opt{format} !~ /^(text|json)$/) {
        die "spec-drift-check: --format must be 'text' or 'json'\n";
    }
    return \%opt;
}

# ---------------------------------------------------------------------------
# HTTP + spec loading
# ---------------------------------------------------------------------------

sub http_get_json {
    my ($url) = @_;
    require HTTP::Tiny;
    my $ua  = HTTP::Tiny->new(agent => $UA_STRING, timeout => 30);
    my $res = $ua->get($url);
    die sprintf("spec-drift-check: GET %s failed: %s %s\n",
        $url, $res->{status} // '?', $res->{reason} // '?')
        unless $res->{success};
    my $data = eval { JSON::PP->new->decode($res->{content}) };
    die "spec-drift-check: could not parse JSON from $url: $@\n" if $@;
    return $data;
}

sub _tag_sort_key {
    my ($tag) = @_;
    return undef unless $tag =~ /^v(\d+)\.(\d+)\.(\d+)$/;
    return [ $1 + 0, $2 + 0, $3 + 0 ];
}

# Latest stable (non-alpha/beta/rc) release tag, per the GitHub tags API.
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
    die "spec-drift-check: no stable vX.Y.Z tags found in the kubernetes/kubernetes tag list\n"
        unless @stable;
    my ($best) = sort {
        my ($ka, $kb) = (_tag_sort_key($a), _tag_sort_key($b));
        $kb->[0] <=> $ka->[0] || $kb->[1] <=> $ka->[1] || $kb->[2] <=> $ka->[2];
    } @stable;
    return $best;
}

sub _slurp_json {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "spec-drift-check: cannot read $path: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh;
    my $data = eval { JSON::PP->new->decode($content) };
    die "spec-drift-check: could not parse JSON from $path: $@\n" if $@;
    return $data;
}

sub fetch_spec_for_tag {
    my ($tag, $cache_dir, $no_cache) = @_;
    make_path($cache_dir) unless -d $cache_dir;
    my $cache_file = File::Spec->catfile($cache_dir, "$tag.json");
    if (!$no_cache && -f $cache_file) {
        return _slurp_json($cache_file);
    }
    my $url = "https://raw.githubusercontent.com/kubernetes/kubernetes/$tag/api/openapi-spec/swagger.json";
    print STDERR "spec-drift-check: downloading $url ...\n";
    require HTTP::Tiny;
    my $ua  = HTTP::Tiny->new(agent => $UA_STRING, timeout => 90);
    my $res = $ua->get($url);
    die sprintf("spec-drift-check: GET %s failed: %s %s\n",
        $url, $res->{status} // '?', $res->{reason} // '?')
        unless $res->{success};
    my $data = eval { JSON::PP->new->decode($res->{content}) };
    die "spec-drift-check: could not parse JSON from $url: $@\n" if $@;
    open my $fh, '>:raw', $cache_file or die "spec-drift-check: cannot write $cache_file: $!\n";
    print $fh $res->{content};
    close $fh;
    return $data;
}

# Resolve a --tag/--spec/--from/--to value (or undef) to a loaded spec plus
# a human-readable label. A value that exists as a file is loaded directly
# (no caching -- it's already local); anything else is treated as a tag.
sub load_spec_arg {
    my ($value, $cache_dir, $no_cache) = @_;
    if (defined $value && -f $value) {
        return (_slurp_json($value), $value);
    }
    my $tag = $value // latest_stable_tag();
    return (fetch_spec_for_tag($tag, $cache_dir, $no_cache), $tag);
}

# ---------------------------------------------------------------------------
# lib/IO/K8s registry loading (mirrors t/34_registry_guard.t)
# ---------------------------------------------------------------------------

sub load_registry {
    my ($lib_dir) = @_;
    die "spec-drift-check: lib dir not found: $lib_dir\n" unless -d $lib_dir;
    unshift @INC, $lib_dir unless grep { $_ eq $lib_dir } @INC;

    my @pm_paths;
    find(
        { wanted => sub { push @pm_paths, $File::Find::name if /\.pm$/ }, no_chdir => 1 },
        File::Spec->catdir($lib_dir, 'IO', 'K8s'),
    );

    my %shipped;
    for my $path (sort @pm_paths) {
        my $rel = File::Spec->abs2rel($path, $lib_dir);
        (my $mod = $rel) =~ s{[\\/]}{::}g;
        $mod =~ s/\.pm$//;
        $shipped{$mod} = 1;
        $rel =~ s{\\}{/}g;    # require() wants forward slashes regardless of OS
        eval { require $rel; 1 }
            or warn "spec-drift-check: failed to load $mod ($rel): $@";
    }
    return (\%shipped, \%IO::K8s::Resource::_attr_registry);
}

# ---------------------------------------------------------------------------
# Upstream definition key <-> Perl class name mapping
#
# "io.k8s.<group...>.<version>.<Kind>" -> "IO::K8s::<Group...>::<Version>::<Kind>"
# with hyphenated segments contracted to CamelCase (apiextensions-apiserver
# -> ApiextensionsApiserver, kube-aggregator -> KubeAggregator), matching
# Resource.pm's %_class_prefix / AutoGen.pm's _schema_to_type_spec naming.
# ---------------------------------------------------------------------------

sub seg_to_perl {
    my ($seg) = @_;
    return join '', map { ucfirst $_ } grep { length } split /-/, $seg;
}

sub defkey_to_perl_class {
    my ($key) = @_;
    return undef unless $key =~ /^io\.k8s\./;
    my $rest      = substr($key, length('io.k8s.'));
    my @parts     = split /\./, $rest;
    my $kind_part = pop @parts;
    my @path      = map { seg_to_perl($_) } @parts;
    return join('::', 'IO::K8s', @path, $kind_part);
}

sub has_gvk { return exists $_[0]->{'x-kubernetes-group-version-kind'} }

sub _strip_ref { my ($ref) = @_; $ref =~ s{^#/definitions/}{}; return $ref }

# The definition key a property's schema points at, if any: a direct $ref,
# an array of $ref, or a map (additionalProperties) of $ref. Scalar/array-
# of-scalar/inline-object properties return undef -- they never reference
# a class.
sub prop_ref_key {
    my ($prop) = @_;
    return _strip_ref($prop->{'$ref'}) if $prop->{'$ref'};
    my $type = $prop->{type} // '';
    if ($type eq 'array') {
        my $items = $prop->{items} // {};
        return _strip_ref($items->{'$ref'}) if $items->{'$ref'};
    }
    elsif ($type eq 'object') {
        my $ap = $prop->{additionalProperties};
        if (ref $ap eq 'HASH' && $ap->{'$ref'}) {
            return _strip_ref($ap->{'$ref'});
        }
    }
    return undef;
}

# The generic Kubernetes list wrapper (Items + ListMeta) that this dist
# dropped project-wide in 1.105. Structural, not name-based: a Kind whose
# key ends in "List" and which has an `items` property.
sub is_dropped_list_kind {
    my ($key, $def) = @_;
    return 0 unless $key =~ /List$/;
    return 0 unless has_gvk($def);
    return 0 unless exists(($def->{properties} // {})->{items});
    return 1;
}

# ---------------------------------------------------------------------------
# Exceptions file
# ---------------------------------------------------------------------------

sub load_exceptions {
    my ($path) = @_;
    die "spec-drift-check: exceptions file not found: $path\n" unless -f $path;
    open my $fh, '<:encoding(UTF-8)', $path or die "spec-drift-check: cannot read $path: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh;
    require YAML::PP;
    my ($data) = YAML::PP::Load($content);
    $data //= {};
    $data->{list_kinds_dropped}     = 1  unless exists $data->{list_kinds_dropped};
    $data->{scalar_types}         //= {};
    $data->{opaque_types}         //= [];
    $data->{perl_only}             //= [];
    $data->{ignore_missing_classes} //= [];
    $data->{ignore_missing_fields}  //= [];
    $data->{ignore_extra_fields}     //= [];
    return $data;
}

# Every entry is matched as a literal prefix of $name (a full match is just
# a prefix of itself). Entries may be a bare string or a {prefix=>,reason=>}.
sub prefix_match {
    my ($name, $entries) = @_;
    for my $e (@$entries) {
        my $prefix = ref($e) eq 'HASH' ? $e->{prefix} : $e;
        next unless defined $prefix && length $prefix;
        if (substr($name, 0, length $prefix) eq $prefix) {
            return (1, ref($e) eq 'HASH' ? $e->{reason} : undef);
        }
    }
    return (0, undef);
}

sub field_ignored {
    my ($class, $field, $entries) = @_;
    for my $e (@$entries) {
        next unless ref $e eq 'HASH';
        next unless ($e->{class} // '') eq $class && ($e->{field} // '') eq $field;
        return (1, $e->{reason});
    }
    return (0, undef);
}

# ---------------------------------------------------------------------------
# Coverage mode: one spec vs. the shipped registry
# ---------------------------------------------------------------------------

sub run_coverage_mode {
    my ($opt) = @_;
    my $source = $opt->{spec} // $opt->{tag};
    my ($spec, $label) = load_spec_arg($source, $opt->{'cache-dir'}, $opt->{'no-cache'});
    my $defs = $spec->{definitions}
        or die "spec-drift-check: no 'definitions' key in spec ($label)\n";
    my $exceptions = load_exceptions($opt->{exceptions});
    my ($shipped, $registry) = load_registry($opt->{lib});

    my %scalarish;
    $scalarish{$_} = 1 for keys %{ $exceptions->{scalar_types} };
    $scalarish{$_} = 1 for @{ $exceptions->{opaque_types} };

    my (@missing_kind, @missing_type, @field_tier2, @field_tier3, @extra_fields, @perl_only);
    my @suppressed;    # [category, subject, context, reason]

    # Pass 1: classes missing entirely.
    my %mapped_class;    # def key -> perl class, for every non-scalarish definition
    for my $key (sort keys %$defs) {
        next if $scalarish{$key};
        my $pc = defkey_to_perl_class($key) or next;
        $mapped_class{$key} = $pc;
        next if $shipped->{$pc};

        if (is_dropped_list_kind($key, $defs->{$key}) && $exceptions->{list_kinds_dropped}) {
            push @suppressed, ['list_kinds_dropped', $key, $pc, '1.105 generic list-kind removal'];
            next;
        }
        my ($ignored, $reason) = prefix_match($pc, $exceptions->{ignore_missing_classes});
        if ($ignored) {
            push @suppressed, ['ignore_missing_classes', $key, $pc, $reason];
            next;
        }
        if (has_gvk($defs->{$key})) {
            push @missing_kind, [$key, $pc];
        } else {
            push @missing_type, [$key, $pc];
        }
    }

    # Pass 2: field-level gaps on classes that ARE shipped.
    for my $key (sort keys %$defs) {
        next if $scalarish{$key};
        my $pc = $mapped_class{$key} or next;
        next unless $shipped->{$pc};

        my $def      = $defs->{$key};
        my $props    = $def->{properties} // {};
        my $required = { map { $_ => 1 } @{ $def->{required} // [] } };
        my $attrs    = $registry->{$pc} // {};
        my %attr_json_keys;
        for my $aname (keys %$attrs) {
            $attr_json_keys{ $attrs->{$aname}{json_key} // $aname } = 1;
        }

        my @prop_names = keys %$props;
        @prop_names = grep { $_ ne 'apiVersion' && $_ ne 'kind' } @prop_names if has_gvk($def);

        for my $pname (sort @prop_names) {
            next if $attr_json_keys{$pname};
            my ($ignored, $reason) = field_ignored($pc, $pname, $exceptions->{ignore_missing_fields});
            if ($ignored) {
                push @suppressed, ['ignore_missing_fields', "$pc.$pname", $key, $reason];
                next;
            }
            my $req_note = $required->{$pname} ? ' (required)' : '';
            my $ref_key  = prop_ref_key($props->{$pname});
            if (defined $ref_key && !$scalarish{$ref_key}) {
                my $target = $mapped_class{$ref_key} // defkey_to_perl_class($ref_key);
                if (defined $target && !$shipped->{$target}) {
                    push @field_tier2, [$pc, $key, $pname, $target, $req_note];
                    next;
                }
            }
            push @field_tier3, [$pc, $key, $pname, $req_note];
        }

        my @extra = sort grep { !exists $props->{$_} } keys %attr_json_keys;
        @extra = grep { $_ ne 'apiVersion' && $_ ne 'kind' } @extra if has_gvk($def);
        for my $fname (@extra) {
            my ($ignored, $reason) = field_ignored($pc, $fname, $exceptions->{ignore_extra_fields});
            if ($ignored) {
                push @suppressed, ['ignore_extra_fields', "$pc.$fname", $key, $reason];
                next;
            }
            push @extra_fields, [$pc, $key, $fname];
        }
    }

    # Pass 3: shipped classes under an upstream root with no matching def at all.
    my %mapped_values = map { $_ => 1 } values %mapped_class;
    for my $pc (sort keys %$shipped) {
        next unless $pc =~ /^IO::K8s::(?:Api|Apimachinery|ApiextensionsApiserver|KubeAggregator)::/;
        next if $mapped_values{$pc};
        my ($ignored, $reason) = prefix_match($pc, $exceptions->{perl_only});
        if ($ignored) {
            push @suppressed, ['perl_only', $pc, undef, $reason];
            next;
        }
        push @perl_only, $pc;
    }

    my %result = (
        mode         => 'coverage',
        label        => $label,
        defs_total   => scalar(keys %$defs),
        classes_total=> scalar(keys %$shipped),
        missing_kind => \@missing_kind,
        missing_type => \@missing_type,
        field_tier2  => \@field_tier2,
        field_tier3  => \@field_tier3,
        extra_fields => \@extra_fields,
        perl_only    => \@perl_only,
        suppressed   => \@suppressed,
    );
    return \%result;
}

sub render_coverage_report {
    my ($r, $verbose) = @_;
    my @out;
    push @out, "=== IO::K8s spec-drift-check :: coverage ===";
    push @out, "spec:  $r->{label}  ($r->{defs_total} definitions)";
    push @out, "lib:   IO::K8s ($r->{classes_total} classes loaded)";
    push @out, "";
    push @out, "--- SUMMARY ---";
    push @out, sprintf("  Tier 1  MISSING KIND    %4d  upstream Kind, no shipped class at all", scalar @{ $r->{missing_kind} });
    push @out, sprintf("  Tier 2  MISSING TYPE    %4d  new type unshipped (standalone, or behind a missing field)", scalar @{ $r->{missing_type} } + scalar @{ $r->{field_tier2} });
    push @out, sprintf("  Tier 3  MISSING FIELD   %4d  field missing on a shipped class, target type already shipped", scalar @{ $r->{field_tier3} });
    push @out, sprintf("  Info    EXTRA FIELD     %4d  Perl declares a field the current spec no longer has", scalar @{ $r->{extra_fields} });
    push @out, sprintf("  Info    STALE/PERL-ONLY %4d  shipped class, no matching definition key in this spec", scalar @{ $r->{perl_only} });
    my %supp_by_cat;
    $supp_by_cat{ $_->[0] }++ for @{ $r->{suppressed} };
    push @out, sprintf("  Suppressed by exceptions: %d (%s)%s",
        scalar @{ $r->{suppressed} },
        join(', ', map { "$_: $supp_by_cat{$_}" } sort keys %supp_by_cat),
        $verbose ? '' : ' -- rerun with --verbose to list them');
    push @out, "";

    push @out, "--- Tier 1: MISSING KIND (upstream Kind, no shipped class) ---";
    for my $e (@{ $r->{missing_kind} }) {
        push @out, "  $e->[0]  ->  $e->[1]";
    }
    push @out, "  (none)" unless @{ $r->{missing_kind} };
    push @out, "";

    push @out, "--- Tier 2: MISSING TYPE (new type unshipped) ---";
    for my $e (@{ $r->{missing_type} }) {
        push @out, "  [standalone] $e->[0]  ->  $e->[1]";
    }
    for my $e (@{ $r->{field_tier2} }) {
        my ($pc, $key, $pname, $target, $req_note) = @$e;
        push @out, "  [coupled]    $pc.$pname$req_note  ($key)";
        push @out, "                   -> new type $target, itself unshipped";
    }
    push @out, "  (none)" unless @{ $r->{missing_type} } || @{ $r->{field_tier2} };
    push @out, "";

    push @out, "--- Tier 3: MISSING FIELD (target type already shipped) ---";
    for my $e (@{ $r->{field_tier3} }) {
        my ($pc, $key, $pname, $req_note) = @$e;
        push @out, "  $pc.$pname$req_note  ($key)";
    }
    push @out, "  (none)" unless @{ $r->{field_tier3} };
    push @out, "";

    push @out, "--- Info: EXTRA FIELD (Perl has it, upstream no longer does) ---";
    for my $e (@{ $r->{extra_fields} }) {
        my ($pc, $key, $fname) = @$e;
        push @out, "  $pc.$fname  ($key)";
    }
    push @out, "  (none)" unless @{ $r->{extra_fields} };
    push @out, "";

    push @out, "--- Info: STALE / PERL-ONLY (no matching upstream definition) ---";
    for my $pc (@{ $r->{perl_only} }) {
        push @out, "  $pc";
    }
    push @out, "  (none)" unless @{ $r->{perl_only} };

    if ($verbose && @{ $r->{suppressed} }) {
        push @out, "";
        push @out, "--- Suppressed by exceptions (--verbose) ---";
        for my $s (@{ $r->{suppressed} }) {
            my ($cat, $subject, $ctx, $reason) = @$s;
            push @out, sprintf("  [%s] %s%s%s", $cat, $subject,
                (defined $ctx ? "  ($ctx)" : ''),
                (defined $reason ? "  -- $reason" : ''));
        }
    }
    return join("\n", @out) . "\n";
}

# ---------------------------------------------------------------------------
# Compare mode: two specs against each other, weighted by upgrade significance
# ---------------------------------------------------------------------------

sub run_compare_mode {
    my ($opt) = @_;
    my ($specA, $labelA) = load_spec_arg($opt->{from}, $opt->{'cache-dir'}, $opt->{'no-cache'});
    my ($specB, $labelB) = load_spec_arg($opt->{to},   $opt->{'cache-dir'}, $opt->{'no-cache'});
    my $defsA = $specA->{definitions} // {};
    my $defsB = $specB->{definitions} // {};

    my (@new_kind, @new_type, @removed_kind, @removed_type,
        @new_required_field, @new_optional_field, @removed_field, @description_change);

    for my $key (sort keys %$defsB) {
        next if exists $defsA->{$key};
        my $pc = defkey_to_perl_class($key);
        push @{ has_gvk($defsB->{$key}) ? \@new_kind : \@new_type }, [$key, $pc];
    }
    for my $key (sort keys %$defsA) {
        next if exists $defsB->{$key};
        my $pc = defkey_to_perl_class($key);
        push @{ has_gvk($defsA->{$key}) ? \@removed_kind : \@removed_type }, [$key, $pc];
    }

    for my $key (sort keys %$defsA) {
        next unless exists $defsB->{$key};
        my ($defA, $defB) = ($defsA->{$key}, $defsB->{$key});
        my $propsA = $defA->{properties} // {};
        my $propsB = $defB->{properties} // {};
        my $reqA = { map { $_ => 1 } @{ $defA->{required} // [] } };
        my $reqB = { map { $_ => 1 } @{ $defB->{required} // [] } };

        for my $pname (sort keys %$propsB) {
            next if exists $propsA->{$pname};
            push @{ $reqB->{$pname} ? \@new_required_field : \@new_optional_field }, [$key, $pname];
        }
        for my $pname (sort keys %$propsA) {
            next if exists $propsB->{$pname};
            push @removed_field, [$key, $pname];
        }
        for my $pname (sort keys %$propsB) {
            next unless exists $propsA->{$pname};
            if ($reqB->{$pname} && !$reqA->{$pname}) {
                push @new_required_field, [$key, "$pname (was optional)"];
                next;
            }
            my $da = $propsA->{$pname}{description} // '';
            my $db = $propsB->{$pname}{description} // '';
            push @description_change, [$key, $pname] if $da ne $db;
        }
    }

    return {
        mode                => 'compare',
        from                => $labelA,
        to                  => $labelB,
        new_kind            => \@new_kind,
        removed_kind        => \@removed_kind,
        new_type            => \@new_type,
        removed_type        => \@removed_type,
        new_required_field  => \@new_required_field,
        removed_field       => \@removed_field,
        new_optional_field  => \@new_optional_field,
        description_change  => \@description_change,
    };
}

sub render_compare_report {
    my ($r) = @_;
    my @out;
    push @out, "=== IO::K8s spec-drift-check :: compare ===";
    push @out, "from:  $r->{from}";
    push @out, "to:    $r->{to}";
    push @out, "";
    push @out, "Weighted by upgrade significance (highest first). new Kind / removed Kind";
    push @out, "carry the same weight -- both are structural. The final two 'removed' tiers";
    push @out, "and both 'removed' sections are not in karr #9's literal four-tier list but";
    push @out, "come essentially free from the same diff and matter just as much for an";
    push @out, "upgrade decision (a field silently disappearing upstream breaks round-trips).";
    push @out, "";

    # kind: 'class' rows are [def_key, perl_class]; 'field' rows are [def_key, field_name].
    my @sections = (
        ['NEW KIND (new top-level resource)'      => $r->{new_kind},           'class'],
        ['REMOVED KIND (top-level resource gone)'  => $r->{removed_kind},       'class'],
        ['NEW TYPE (new non-Kind definition)'      => $r->{new_type},          'class'],
        ['REMOVED TYPE (non-Kind definition gone)' => $r->{removed_type},      'class'],
        ['NEW REQUIRED FIELD'                      => $r->{new_required_field}, 'field'],
        ['REMOVED FIELD'                           => $r->{removed_field},      'field'],
        ['NEW OPTIONAL FIELD'                      => $r->{new_optional_field}, 'field'],
        ['DESCRIPTION CHANGE ONLY'                 => $r->{description_change}, 'field'],
    );

    push @out, "--- SUMMARY ---";
    for my $s (@sections) {
        push @out, sprintf("  %-40s %4d", $s->[0], scalar @{ $s->[1] });
    }
    push @out, "";

    for my $s (@sections) {
        my ($title, $items, $kind) = @$s;
        push @out, "--- $title ---";
        if ($kind eq 'class') {
            push @out, "  $_->[0]  ->  " . ($_->[1] // '(unmapped key)') for @$items;
        } else {
            push @out, "  $_->[0] :: $_->[1]" for @$items;
        }
        push @out, "  (none)" unless @$items;
        push @out, "";
    }
    return join("\n", @out) . "\n";
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

my $opt = parse_args();
my $result =
    defined $opt->{from} ? run_compare_mode($opt)
                          : run_coverage_mode($opt);

my $report;
if ($opt->{format} eq 'json') {
    $report = JSON::PP->new->canonical->pretty->encode($result);
} else {
    $report = $result->{mode} eq 'compare'
        ? render_compare_report($result)
        : render_coverage_report($result, $opt->{verbose});
}

print $report;
if ($opt->{output}) {
    open my $fh, '>:encoding(UTF-8)', $opt->{output}
        or die "spec-drift-check: cannot write $opt->{output}: $!\n";
    print $fh $report;
    close $fh;
}
