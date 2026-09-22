package IO::K8s::CRD;
# ABSTRACT: Turn CustomResourceDefinition manifests into IO::K8s classes
our $VERSION = '1.108';
use v5.10;
use strict;
use warnings;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use Module::Runtime qw( require_module );
use JSON::MaybeXS ();
use re ();
use IO::K8s::AutoGen ();
use IO::K8s::Resource ();

# The typed class crd_for_class() and new() build and return (D9). Kept as
# a constant rather than spelled out at each call site -- the brief's own
# shorthand ('IO::K8s::Apiextensions::Pkg::...') drops the
# 'ApiextensionsApiserver' segment the shipped classes actually use; this
# is the real, checked-in name (see lib/IO/K8s/ApiextensionsApiserver/).
my $CRD_CLASS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition';



sub load {
    my ($class, $input) = @_;
    croak 'IO::K8s::CRD->load needs a CustomResourceDefinition object, a hashref, YAML/JSON text or a file path'
        unless defined $input;

    my @docs;
    if (ref $input eq 'ARRAY') {
        return [ map { @{ $class->load($_) } } @$input ];
    }
    elsif (blessed($input) && $input->can('TO_JSON')) {
        @docs = ($input->TO_JSON);
    }
    elsif (ref $input eq 'HASH') {
        @docs = ($input);
    }
    elsif (!ref $input) {
        my $text = $input;
        if ($input !~ /\n/ && -f $input) {
            open my $fh, '<:encoding(UTF-8)', $input
                or croak "IO::K8s::CRD->load: cannot open $input: $!";
            $text = do { local $/; <$fh> };
            close $fh;
        }
        require YAML::PP;
        my $yp = YAML::PP->new(boolean => 'JSON::PP');
        @docs = grep { ref $_ eq 'HASH' } $yp->load_string($text);
    }
    else {
        croak 'IO::K8s::CRD->load: unsupported input ' . ref($input);
    }

    for my $i (0 .. $#docs) {
        my $doc = $docs[$i];
        my $kind = $doc->{kind} // '';
        croak 'IO::K8s::CRD->load: document ' . ($i + 1) . " is a '$kind', not a CustomResourceDefinition"
            unless $kind eq 'CustomResourceDefinition';
        croak 'IO::K8s::CRD->load: CustomResourceDefinition without spec.group / spec.names.kind / spec.versions'
            unless ref $doc->{spec} eq 'HASH'
                && defined $doc->{spec}{group}
                && ref $doc->{spec}{names} eq 'HASH' && defined $doc->{spec}{names}{kind}
                && ref $doc->{spec}{versions} eq 'ARRAY' && @{ $doc->{spec}{versions} };
    }
    return \@docs;
}

# served / storage arrive as JSON booleans, plain 0/1, or the strings a
# hand-written YAML may carry; the DSL's one boolean normalization decides.
# A missing field is a legitimate "not set" and stays 0/false; a field that
# IS present but cannot mean true or false (an arrayref, say) must not be
# swallowed into the same "not set" answer -- croak instead, naming the
# version index and field so the manifest is easy to find.
sub _flag {
    my ($value, $field, $index) = @_;
    return 0 unless defined $value;
    my $bool = eval { IO::K8s::Resource::_normalize_bool($value) };
    croak "IO::K8s::CRD: spec.versions[$index].$field is not a boolean" if $@;
    return $bool ? 1 : 0;
}


sub served_versions {
    my ($class, $crd) = @_;
    my $group = $crd->{spec}{group};
    my $versions = $crd->{spec}{versions};
    my @out;
    for my $i (0 .. $#$versions) {
        my $v = $versions->[$i];
        next unless _flag($v->{served}, 'served', $i);
        push @out, {
            name        => $v->{name},
            api_version => "$group/$v->{name}",
            storage     => _flag($v->{storage}, 'storage', $i),
            # A plain '$v->{schema}{openAPIV3Schema}' would autovivify
            # $v->{schema} into {} on a version that has none, silently
            # mutating the caller's manifest hashref -- ref() first, so a
            # missing/undef 'schema' is read without creating it.
            schema      => (ref $v->{schema} eq 'HASH' ? $v->{schema}{openAPIV3Schema} : undef) // { type => 'object' },
        };
    }
    croak "IO::K8s::CRD: no served version in the CRD for $crd->{spec}{names}{kind}" unless @out;
    return \@out;
}


sub generate {
    my ($class, $crd, $namespace, %opts) = @_;
    my $spec  = $crd->{spec};
    my $group = $spec->{group};
    my $kind  = $spec->{names}{kind};
    my $namespaced = ($spec->{scope} // 'Namespaced') eq 'Namespaced' ? 1 : 0;

    # See the POD above: a sub-namespace of our own so a CRD-derived class
    # can never alias with one AutoGen would build straight from an
    # openapi_spec definition of the same GVK under the caller's namespace.
    my $crd_namespace = "$namespace\::_CRD";

    my %out;
    my $fallback;
    for my $v (@{ $class->served_versions($crd) }) {
        my $def_name = join '.', $group, $v->{name}, $kind;
        my $schema = {
            %{ $v->{schema} },
            'x-kubernetes-group-version-kind' => [ { group => $group, version => $v->{name}, kind => $kind } ],
        };
        $out{ $v->{api_version} } = IO::K8s::AutoGen::get_or_generate(
            $def_name, $schema, {}, $crd_namespace,
            api_version     => $v->{api_version},
            kind            => $kind,
            resource_plural => $spec->{names}{plural},
            is_namespaced   => $namespaced,
            %opts,
        );
        # Track every served version as the fallback so the LAST one wins
        # when none is marked storage -- matching the POD above. An explicit
        # storage:true always overrides it, regardless of position.
        $fallback = $v->{api_version};
        $out{storage} = $v->{api_version} if $v->{storage};
    }
    $out{storage} //= $fallback;
    return \%out;
}


sub crd_for_class {
    my ($class) = @_;
    croak 'IO::K8s::CRD::crd_for_class needs a class name' unless defined $class && length $class;

    my $id = _identity_for_class($class);
    return __PACKAGE__->new(classes => [$class], storage => $id->{version});
}


sub new {
    my ($invocant, %args) = @_;

    my $classes = $args{classes};
    croak "IO::K8s::CRD->new needs a non-empty 'classes' arrayref"
        unless ref $classes eq 'ARRAY' && @$classes;

    my @ids = map {
        _ensure_class_loaded($_);
        _identity_for_class($_);
    } @$classes;

    for my $field (qw(group kind plural scope)) {
        my %by_value;
        push @{ $by_value{ $ids[$_]{$field} } }, $classes->[$_] for 0 .. $#ids;
        next if keys %by_value <= 1;
        croak "IO::K8s::CRD->new: classes disagree on $field ("
            . join(', ', map { "$_: " . join(',', @{ $by_value{$_} }) } sort keys %by_value)
            . ") -- classes passed to ->new must all be versions of the same CRD";
    }

    my %seen_version;
    my @dupes = grep { $seen_version{$_}++ } map { $_->{version} } @ids;
    croak "IO::K8s::CRD->new: duplicate version name(s) (@dupes) across classes; "
        . "each class must be a distinct served version"
        if @dupes;

    my $storage = $args{storage};
    croak "IO::K8s::CRD->new needs a 'storage' version name" unless defined $storage && length $storage;
    my ($storage_index) = grep { $ids[$_]{version} eq $storage } 0 .. $#ids;
    croak "IO::K8s::CRD->new: storage '$storage' does not name any of the given classes' versions ("
        . join(', ', map { $_->{version} } @ids) . ")"
        unless defined $storage_index;

    my $id0 = $ids[0];
    my @versions = map {
        my $i = $_;
        {
            name    => $ids[$i]{version},
            served  => JSON::MaybeXS::true,
            storage => ($i == $storage_index) ? JSON::MaybeXS::true : JSON::MaybeXS::false,
            schema  => { openAPIV3Schema => _schema_for_class($classes->[$i]) },
        };
    } 0 .. $#ids;

    my $manifest = {
        metadata => { name => "$id0->{plural}.$id0->{group}" },
        spec     => {
            group => $id0->{group},
            scope => $id0->{scope},
            names => {
                plural   => $id0->{plural},
                kind     => $id0->{kind},
                singular => lc($id0->{kind}),
                listKind => "$id0->{kind}List",
            },
            versions => \@versions,
        },
    };

    require IO::K8s;
    my $k8s = IO::K8s->new;
    return $k8s->_struct_to_object_expanded($CRD_CLASS, $manifest);
}

# Shared by crd_for_class and new(): $class's group/version (split out of
# api_version), kind, resource_plural and Namespaced-or-Cluster scope --
# everything both need to know about $class besides its schema. Does not
# call _ensure_class_loaded itself (callers that need it call that first;
# crd_for_class historically didn't, and to_crd's caller is always already
# loaded), so this keeps crd_for_class's pre-existing behaviour unchanged
# for an unloaded class: a plain "Can't locate object method" from Perl,
# not a custom message.
sub _identity_for_class {
    my ($class) = @_;

    my $api_version = $class->api_version;
    my ($group, $version) = $api_version =~ m{\A(?:(.*)/)?([^/]+)\z};
    croak "IO::K8s::CRD: cannot read a version out of "
        . "'$api_version' (from ${class}->api_version)"
        unless defined $version && length $version;
    $group = '' unless defined $group;

    my $kind   = $class->kind;
    my $plural = $class->resource_plural;
    croak "IO::K8s::CRD: $class has no resource_plural"
        unless defined $plural && length $plural;

    my $scope = $class->DOES('IO::K8s::Role::Namespaced') ? 'Namespaced' : 'Cluster';

    return { group => $group, version => $version, kind => $kind, plural => $plural, scope => $scope };
}


sub _schema_for_class {
    my ($class, $seen) = @_;
    $seen ||= {};
    return _opaque_object() if $seen->{$class};

    _ensure_class_loaded($class);
    my $info   = $class->_k8s_attr_info;
    my $is_top = $class->can('_is_resource') ? 1 : 0;
    my %next_seen = (%$seen, $class => 1);

    my (%properties, @required);
    for my $attr (sort keys %$info) {
        next if $is_top && $attr eq 'metadata';
        my $entry    = $info->{$attr};
        my $json_key = $entry->{json_key} // $attr;
        $properties{$json_key} = _property_schema($entry, \%next_seen, $class . '.' . $json_key);
        push @required, $json_key if $entry->{required};
    }

    if ($is_top) {
        $properties{apiVersion} = { type => 'string' };
        $properties{kind}       = { type => 'string' };
        $properties{metadata}   = { type => 'object' };
    }

    my %schema = (type => 'object', properties => \%properties);
    $schema{required} = [ sort @required ] if @required;
    return \%schema;
}

# $class already loaded as a file (require_module needed) vs. already
# usable in memory (an inline-struct class the k8s DSL built synchronously
# when its parent's own `k8s foo => { ... }` line ran, or $class itself,
# already loaded by the caller of to_crd/crd_for_class). The inline-struct
# case has no .pm file at all -- require_module would fail "Can't locate
# ... in @INC" for exactly the classes _schema_for_class most needs to
# recurse into. can('_k8s_attr_info') is true the moment
# IO::K8s::Role::Resource is composed onto a package, which happens
# synchronously either way (_generate_inline_struct, or a real file's own
# `use IO::K8s::Resource;` at compile time), so it is the right question
# for both.
sub _ensure_class_loaded {
    my ($class) = @_;
    return if $class->can('_k8s_attr_info');
    require_module($class);
}

sub _property_schema {
    my ($entry, $seen, $where) = @_;
    my $schema = _type_schema($entry, $seen);
    _apply_options($schema, $entry->{options}, $where, $entry->{is_bool}) if $entry->{options};
    return $schema;
}

# The registry's one classifying is_* flag, turned into its schema shape --
# the reverse of IO::K8s::AutoGen::_schema_to_type_spec's dispatch (and
# IO::K8s::CRD::Emitter::_type_source's DSL-source mirror of the same
# flags, read alongside this while writing it).
#
# is_quantity has no format upstream ever puts on a plain `type: string`
# schema: AutoGen only ever reaches Quantity through a $ref to
# resource.Quantity, never through a format string, so there is nothing to
# emit here that would read back as Quantity. A Quantity field therefore
# round-trips through add_crd as a plain Str -- documented in the task-2
# report, not worked around here. is_hash_of_quantity shares the same gap
# for the same reason (AutoGen's additionalProperties dispatch collapses
# every typed map -- int/num/bool/quantity/time/int-or-string alike -- to
# the opaque { Str => 1 } shape rather than a typed additionalProperties
# schema, so none of is_hash_of_{int,num,bool,quantity,time,int_or_string}
# has a schema shape that reads back as itself; only the standalone scalar
# is_time is lossless via `format: date-time`, which AutoGen's own dispatch
# explicitly reads back into Time). is_array_of_quantity has the identical
# gap to the scalar is_quantity, one level down.
sub _type_schema {
    my ($entry, $seen) = @_;

    return { type => 'string' }  if $entry->{is_str};
    return { type => 'integer' } if $entry->{is_int};
    return { type => 'number' }  if $entry->{is_num};
    return { type => 'boolean' } if $entry->{is_bool};
    return { 'x-kubernetes-int-or-string' => JSON::MaybeXS::true } if $entry->{is_int_or_string};
    return { type => 'string' }  if $entry->{is_quantity};
    return { type => 'string', format => 'date-time' } if $entry->{is_time};

    return _schema_for_class($entry->{class}, $seen) if $entry->{is_object};

    return { type => 'array', items => _schema_for_class($entry->{class}, $seen) }
        if $entry->{is_array_of_objects};
    return { type => 'array', items => { type => 'string' } }  if $entry->{is_array_of_str};
    return { type => 'array', items => { type => 'integer' } } if $entry->{is_array_of_int};
    return { type => 'array', items => { type => 'boolean' } } if $entry->{is_array_of_bool};
    return { type => 'array', items => { type => 'number' } }  if $entry->{is_array_of_num};
    return { type => 'array', items => { 'x-kubernetes-int-or-string' => JSON::MaybeXS::true } }
        if $entry->{is_array_of_int_or_string};
    return { type => 'array', items => { type => 'string' } }  if $entry->{is_array_of_quantity};
    return { type => 'array', items => { type => 'string', format => 'date-time' } }
        if $entry->{is_array_of_time};
    return { type => 'array', items => _opaque_object() } if $entry->{is_array_of_hash};
    return { type => 'array', items => { type => 'array' } }   if $entry->{is_array_of_array};
    # Belt-and-suspenders (k96 task-2 review, Critical): every is_array_of_*
    # flag Resource.pm can currently set is handled above. A future one that
    # is not degrades to an untyped array items schema rather than falling
    # through to the croak below -- a class this function cannot describe
    # precisely should still produce a *valid*, merely permissive,
    # openAPIV3Schema, not block to_crd outright the way the unhandled
    # is_array_of_num/quantity/time/int_or_string case did before this fix
    # (found via IO::K8s::Api::Resource::V1::ResourceSlice's
    # DeviceCapacity.validValues, an [Quantity] field).
    return { type => 'array', items => {} }
        if grep { /^is_array_of_/ && $entry->{$_} } keys %$entry;

    return { type => 'object', additionalProperties => _schema_for_class($entry->{class}, $seen) }
        if $entry->{is_hash_of_objects};
    # is_hash_of_str is the opaque { Str => 1 } marker itself (see
    # Resource.pm: "the genuinely opaque string map that labels,
    # annotations and fieldsV1 need") -- never a typed additionalProperties
    # schema, unlike every other is_hash_of_* flag below.
    return _opaque_object() if $entry->{is_hash_of_str};
    return { type => 'object', additionalProperties => { type => 'integer' } } if $entry->{is_hash_of_int};
    return { type => 'object', additionalProperties => { type => 'number' } }  if $entry->{is_hash_of_num};
    return { type => 'object', additionalProperties => { type => 'boolean' } } if $entry->{is_hash_of_bool};
    return { type => 'object', additionalProperties => { type => 'string' } }  if $entry->{is_hash_of_quantity};
    return { type => 'object', additionalProperties => { type => 'string', format => 'date-time' } }
        if $entry->{is_hash_of_time};
    return { type => 'object', additionalProperties => { 'x-kubernetes-int-or-string' => JSON::MaybeXS::true } }
        if $entry->{is_hash_of_int_or_string};

    croak 'IO::K8s::CRD::_schema_for_class: registry entry with no recognizable is_* flag';
}

sub _opaque_object {
    return { type => 'object', 'x-kubernetes-preserve-unknown-fields' => JSON::MaybeXS::true };
}

# D3 -> openAPIV3Schema: every option version 1 of D3 carries is emitted
# ("All of them are emitted into the CRD schema (D9)" -- the design spec's
# own words). 'required' is excluded here on purpose -- it is not a
# per-property key, it joins the ENCLOSING object's own 'required' array,
# handled by _schema_for_class's caller loop above.
sub _apply_options {
    my ($schema, $opts, $where, $is_bool) = @_;
    $schema->{enum} = [ @{ $opts->{enum} } ] if exists $opts->{enum};
    $schema->{minimum} = $opts->{minimum} if exists $opts->{minimum};
    $schema->{maximum} = $opts->{maximum} if exists $opts->{maximum};
    if (exists $opts->{pattern}) {
        my $p = $opts->{pattern};
        $schema->{pattern} = (ref $p eq 'Regexp') ? _pattern_to_ecma262($p, $where) : $p;
    }
    $schema->{description} = $opts->{description} if exists $opts->{description};
    if (exists $opts->{default}) {
        my $default = _copy_one_level($opts->{default});
        $schema->{default} = $is_bool
            ? (IO::K8s::Resource::_normalize_bool($default)
                ? JSON::MaybeXS::true
                : JSON::MaybeXS::false)
            : $default;
    }
    $schema->{nullable} = $opts->{nullable} ? JSON::MaybeXS::true : JSON::MaybeXS::false
        if exists $opts->{nullable};
    $schema->{'x-kubernetes-preserve-unknown-fields'} = $opts->{preserve_unknown} ? JSON::MaybeXS::true : JSON::MaybeXS::false
        if exists $opts->{preserve_unknown};
    return;
}

#### qr// -> ECMA262, for openAPIV3Schema.pattern (k110)
#
# A CRD's openAPIV3Schema.pattern is an ECMA262 regex -- that is what JSON
# Schema specifies and what the apiserver validates against. A Perl qr// is
# not one, and the two flavors overlap enough that emitting the qr// text
# verbatim fails SILENTLY: the apiserver either rejects the whole CRD, or
# accepts a pattern that matches something other than what the Perl class
# itself validates with (relevant to Kubernetes::REST's ensure_crd).
#
# The rule is translate-on-emit, bounded:
#
#   * Only a qr// is translated. A pattern given as a plain string is
#     passed through untouched by _apply_options above -- that string is
#     already meant to be the wire pattern (it is also exactly what
#     IO::K8s::AutoGen hands back out of a real CRD's own schema), and
#     re-parsing someone else's ECMA262 text as if it were Perl would be
#     the opposite of bounded.
#   * A qr// is translated where the translation is lossless, and croaks
#     everywhere else. Nothing is emitted on a guess.
#
# What is translated:
#
#   \A -> ^ and \z -> $. Both hold only because /m is rejected below:
#   with no /m, ECMA262 '^' and '$' anchor the whole input, which is
#   precisely what Perl's \A and \z mean. \Z is NOT '$' -- Perl's \Z also
#   matches before a final newline -- so it croaks instead of being quietly
#   equated with it.
#
# Everything ECMA262 spells identically -- literals, character classes,
# (?:...), lookaround, backreferences, lazy quantifiers, \d \w \s \b,
# {n,m} -- is copied verbatim.
#
# The scan is textual and conservative rather than a real regex parser, but
# it tracks the escape level and character-class nesting, so an escaped
# construct (a literal \\K, or a ']' inside a class) is not mistaken for
# the real thing, and it errs towards croaking.
#
# What it deliberately does NOT reject are the constructs Perl and the
# apiserver's own engine agree on even though strict ECMA262 does not:
# \p{...}/\P{...}/\pC and \x{...}. Rejecting them would break checked-in
# classes to satisfy a rule the validator on the other end does not
# implement -- Cilium's LogConfig.value is qr/^\PC*$/ straight out of the
# upstream CRD, so a shipped class really does carry one.
#
# That upstream \PC is the whole of the case now (k114). Until then this
# also rested on IO::K8s::CRD::Emitter rendering a non-ASCII pattern as
# \x{HEX}, which made a shipped \x{...} something this distribution
# produced by itself -- and that is exactly what k114 stopped doing: such a
# pattern is emitted as a plain string carrying the codepoint, so the
# escape no longer reaches a registry from that direction. A \x{...} here
# can now only come from a hand-written class, and it is still let through
# for the same reason \PC is: Go/RE2 takes it.

# Regex flags that change what the pattern MEANS and have no carrier in a
# bare pattern string. The charset flags (a/d/l/u) and /p are absent on
# purpose: they do not change the meaning of the ASCII-oriented text a CRD
# pattern carries, and a plain qr// picks 'u' up on its own from a feature
# bundle (qr/^\PC*$/ in Cilium's LogConfig already reports flags 'u'), so
# croaking on those would reject patterns that were never given a flag.
# /n is here -- it silently turns every (...) into a non-capturing group.
my %_PATTERN_BAD_FLAG = (
    i => 'case-insensitive matching (/i)',
    m => 'multiline anchors (/m)',
    s => 'dot-matches-newline (/s)',
    x => 'extended, whitespace-insensitive syntax (/x)',
    n => 'non-capturing groups (/n)',
);

# Backslash escapes that are Perl-only or -- worse -- mean something
# DIFFERENT in ECMA262. \v is the trap: vertical whitespace in Perl, a
# plain vertical tab (\x0B) there. Keyed by the character after the
# backslash; the scan only consults this after establishing that the
# backslash is not itself escaped.
my %_PATTERN_BAD_ESCAPE = (
    'Z' => '\Z (Perl end-of-string-or-before-final-newline; ECMA262 $ is not the same)',
    'K' => '\K (keep, Perl-only)',
    'G' => '\G (pos() anchor, Perl-only)',
    'h' => '\h (horizontal whitespace, Perl-only)',
    'H' => '\H (non-horizontal-whitespace, Perl-only)',
    'v' => '\v (vertical whitespace in Perl, a vertical TAB in ECMA262)',
    'V' => '\V (non-vertical-whitespace, Perl-only)',
    'R' => '\R (linebreak, Perl-only)',
    'N' => '\N (non-newline, or \N{NAME}, Perl-only)',
    'X' => '\X (extended grapheme cluster, Perl-only)',
    'C' => '\C (single byte, Perl-only)',
    'o' => '\o{...} (octal escape, Perl-only)',
    'g' => '\g backreference (Perl-only; ECMA262 has \1 and \k<name>)',
);

sub _pattern_croak {
    my ($where, $text, $what) = @_;
    croak 'IO::K8s::CRD: pattern for '
        . (defined $where && length $where ? $where : 'an unnamed field')
        . " cannot be emitted as ECMA262: it uses $what."
        . ' openAPIV3Schema.pattern is an ECMA262 regex -- rewrite the field'
        . ' pattern, or give it as a plain string to emit it verbatim.'
        . ' Pattern: qr/' . $text . '/';
}

sub _pattern_to_ecma262 {
    my ($re, $where) = @_;

    # LIST context gives ($raw_text, $flags): the text a qr// was built
    # from, with no '(?^u:...)' wrapper around it (which is what plain
    # stringification would produce), plus the flags as their own string.
    my ($text, $flags) = re::regexp_pattern($re);
    $flags = '' unless defined $flags;

    my @bad_flags = grep { exists $_PATTERN_BAD_FLAG{$_} } split //, $flags;
    _pattern_croak($where, $text, join(' and ', map { $_PATTERN_BAD_FLAG{$_} } @bad_flags))
        if @bad_flags;

    my $out      = '';
    my $len      = length $text;
    my $i        = 0;
    my $in_class = 0;

    while ($i < $len) {
        my $rest = substr($text, $i);

        # Escapes first, so that a backslashed construct is never read as
        # the construct itself.
        if ($rest =~ /\A\\(.)/s) {
            my $esc = $1;
            _pattern_croak($where, $text, $_PATTERN_BAD_ESCAPE{$esc})
                if exists $_PATTERN_BAD_ESCAPE{$esc};
            _pattern_croak($where, $text,
                q{\k{...} or \k'...' (Perl-only; ECMA262 spells it \k<name>)})
                if $esc eq 'k' && $rest !~ /\A\\k</;

            if ($esc eq 'A' || $esc eq 'z') {
                # Inside a character class these are not anchors at all
                # (Perl itself warns), so there is nothing to translate
                # them into -- croak rather than emit either reading.
                _pattern_croak($where, $text, "\\$esc inside a character class")
                    if $in_class;
                $out .= ($esc eq 'A' ? '^' : '$');
                $i += 2;
                next;
            }

            # Copied whole, so the braces they carry are never read as a
            # {n,m} quantifier by the possessive check further down
            # (\x{31}+ is one escape plus a '+', not '{31}' made
            # possessive).
            if ($rest =~ /\A(\\[pPx]\{[^}]*\})/) {
                $out .= $1;
                $i   += length $1;
                next;
            }

            $out .= substr($text, $i, 2);
            $i   += 2;
            next;
        }

        my $c = substr($text, $i, 1);

        if ($in_class) {
            _pattern_croak($where, $text,
                'a POSIX character class ([[:alpha:]] and friends, Perl-only)')
                if $c eq '[' && $rest =~ /\A\[:\^?[a-z]+:\]/;
            $in_class = 0 if $c eq ']';
            $out .= $c;
            $i++;
            next;
        }

        if ($c eq '[') {
            # A ']' straight after '[' or '[^' is a literal, not the close,
            # so it is consumed with the opener and $in_class can then
            # close on the very next ']' it sees.
            my ($open) = $rest =~ /\A(\[\^?\]?)/;
            $out .= $open;
            $i   += length $open;
            $in_class = 1;
            next;
        }

        if ($c eq '(') {
            if (substr($text, $i, 2) eq '(?') {
                # Whitelist, not a blacklist: everything ECMA262 has is
                # listed here, so atomic groups (?>...), code blocks
                # (?{...})/(??{...}), comments (?#...), conditionals
                # (?(...)...), branch reset (?|...), recursion
                # (?R)/(?1)/(?&name), the (?'name'...)/(?P<name>...)
                # spellings, inline modifiers (?i)/(?-i:...) and a nested
                # qr//'s own (?^u:...) wrapper all land in the croak
                # without needing a rule each.
                if ($rest =~ /\A(\(\?(?::|=|!|<[=!]|<[A-Za-z_]\w*>))/) {
                    $out .= $1;
                    $i   += length $1;
                    next;
                }
                my ($shown) = $rest =~ /\A(\(\?.{0,3})/s;
                _pattern_croak($where, $text, "the group construct '$shown'"
                    . ' (ECMA262 has only (?:...), lookaround and (?<name>...))');
            }
            $out .= '(';
            $i++;
            next;
        }

        if ($rest =~ /\A(\*|\+|\?|\{\d+(?:,\d*)?\})/) {
            my $quant = $1;
            $out .= $quant;
            $i   += length $quant;
            my $mod = $i < $len ? substr($text, $i, 1) : '';
            _pattern_croak($where, $text, "the possessive quantifier '$quant+' (Perl-only)")
                if $mod eq '+';
            if ($mod eq '?') {   # lazy: valid ECMA262, but consume it so it
                $out .= '?';     # is not re-read as a quantifier of its own
                $i++;
            }
            next;
        }

        $out .= $c;
        $i++;
    }

    return $out;
}

# One level of copying for a 'default' option that might be an array/hash
# ref -- the registry never copies 'default' itself (only 'enum'; see
# IO::K8s::Resource::_k8s), so a plain assignment here would alias the
# class's own stored default the same way k54 warns against elsewhere.
# Duplicated from IO::K8s::Role::Resource::_copy_one_level rather than
# called cross-package, for the same reason that one gives for not calling
# IO::K8s.pm's version: this file must not force-load IO::K8s at compile
# time (see crd_for_class's own lazy 'require IO::K8s' above).
sub _copy_one_level {
    my ($value) = @_;
    return [ @$value ] if ref $value eq 'ARRAY';
    return { %$value } if ref $value eq 'HASH';
    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CRD - Turn CustomResourceDefinition manifests into IO::K8s classes

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    use IO::K8s;
    my $k8s = IO::K8s->new;
    $k8s->add_crd('crds/knobs.yaml');          # a path, YAML/JSON text, a hashref,
                                               # a CustomResourceDefinition object,
                                               # or an arrayref of those
    my $knob = $k8s->new_object('Knob', ...);   # storage version
    my $old  = $k8s->new_object('opts.example.com/v1alpha1/Knob', ...);

    # The pieces, for callers that want them separately:
    my $crds     = IO::K8s::CRD->load($input);            # plain hashrefs
    my $versions = IO::K8s::CRD->served_versions($crds->[0]);
    my $classes  = IO::K8s::CRD->generate($crds->[0], 'My::Namespace');

    # Class-to-CRD (D9), the other direction:
    my $crd = My::StaticWebSite->to_crd;                                   # single-version
    my $crd = IO::K8s::CRD->new(                                           # multi-version
        classes => [ My::StaticWebSite::V1beta1, My::StaticWebSite::V1 ],
        storage => 'v1',
    );

=head1 DESCRIPTION

The manifest-to-class half of D10 in the CRD design: a
C<CustomResourceDefinition> is loaded from whatever form the caller has,
every B<served> version of it becomes one L<IO::K8s::AutoGen> class (with
nested classes for every object below C<spec>), and L<IO::K8s/add_crd>
registers them the way a provider's resource map is registered. Nothing
here writes files; L<IO::K8s::CRD::Emitter> renders the same classes as
source for the checked-in case.

=head2 load

    my $crds = IO::K8s::CRD->load($input);

Normalizes C<$input> to an arrayref of plain CRD hashrefs. Accepts a
C<CustomResourceDefinition> object (anything with C<TO_JSON>), a hashref,
YAML or JSON text (multi-document YAML yields several), a path to such a
file, or an arrayref of any of those. Dies on a document that is not a
C<CustomResourceDefinition> or lacks C<spec.group>, C<spec.names.kind> or
C<spec.versions>.

=head2 served_versions

    my $versions = IO::K8s::CRD->served_versions($crd);

The served versions of one loaded CRD, in manifest order, each as
C<< { name, api_version, storage, schema } >> where C<schema> is the
version's C<openAPIV3Schema> (an empty C<type: object> when the manifest has
none). Dies when no version is served.

=head2 generate

    my $classes = IO::K8s::CRD->generate($crd, $namespace);
    my $classes = IO::K8s::CRD->generate($crd, $namespace, reuse_core => 0);

Generates one L<IO::K8s::AutoGen> class per served version under
C<$namespace> and returns C<< { $api_version => $class, ..., storage =>
$api_version } >>. C<%opts> is forwarded to
L<IO::K8s::AutoGen/get_or_generate> as-is; C<reuse_core> (D5, default 1) is
the option most callers touch, controlling whether a nested schema that
matches a shipped core class's shape is typed as that class instead of a
generated nested one. The storage version is the one the manifest marks; when
none is marked (an invalid manifest, but a common one in hand-written
fixtures) the last served version is used. Each class carries the CRD's
C<kind>, C<names.plural> and scope, and every object with C<properties>
below it is a nested class (see L<IO::K8s::AutoGen>).

Classes are generated under C<$namespace\::_CRD>, never C<$namespace>
itself. L<IO::K8s::AutoGen> caches by class name, and the class name is
derived from the namespace plus the group/version/Kind (see
L<IO::K8s::AutoGen/get_or_generate>) -- not from the schema, and not
differently for a CRD manifest than for an C<openapi_spec> definition of
the same GVK. Under a shared namespace the two paths would therefore build
the identical class name for the identical GVK and alias in AutoGen's
cache: whichever ran first would win the slot, and the CRD's own
schema-derived class would silently be discarded (or would silently
clobber the C<openapi_spec> one) while C<< $k8s->add_crd >> still reported
success. The C<::_CRD> sub-namespace rules that out.

Calling C<generate> a second time for the same group/version/Kind under
the same C<$namespace> returns the class generated the first time,
silently, even when the schema in C<$crd> has since changed -- the
sub-namespace does not change that, it only stops the CRD path from
colliding with a different one. Iterating on an edited manifest needs a
fresh C<$namespace> (in practice: a fresh L<IO::K8s> instance, since
L<IO::K8s/add_crd> always passes its own C<_autogen_namespace>). Generated
classes live for the life of the process regardless -- see
L<IO::K8s/add_crd>'s POD for what that costs a long-running caller that
reloads manifests in a loop.

=head2 crd_for_class

    my $crd = IO::K8s::CRD::crd_for_class($class);
    my $crd = $class->to_crd;   # installed on every APIObject class, see IO::K8s::Role::APIObject

D9's DSL-to-schema direction. Builds a single-version
C<CustomResourceDefinition> object from a top-level C<$class>'s own attribute
registry: C<spec.group> and the one C<spec.versions[]> entry's C<name> come
from splitting C<< $class->api_version >>
on the last C</>; C<spec.scope> is C<Namespaced> when C<$class> composes
L<IO::K8s::Role::Namespaced>, else C<Cluster>; C<spec.names> comes from
C<< $class->kind >>, C<< $class->resource_plural >> (C<singular> is
C<lc(kind)>, C<listKind> is C<"${kind}List">); C<metadata.name> is
C<"$plural.$group">. The schema itself is L</_schema_for_class>.

The schema is generated from the registry, but it is not a lossless
DSL-to-schema-to-DSL round-trip through C<add_crd>. C<Quantity> and
C<[Quantity]> export only C<type: string> (or string array items), so the
Quantity constraint cannot be reconstructed. During the reverse
L<IO::K8s::AutoGen> inference, typed maps whose values are C<Int>, C<Num>,
C<Bool>, C<Quantity>, C<Time> or C<IntOrStr> re-import as the opaque
C<< { Str => 1 } >> form. Scalar arrays C<[Num]>, C<[Quantity]>, C<[Time]>
and C<[IntOrStr]> re-import as C<[Str]>; C<[Str]>, C<[Int]> and C<[Bool]>
retain their scalar element type.

The single-version shorthand for L</new>: C<< IO::K8s::CRD::crd_for_class($class) >>
is exactly C<< IO::K8s::CRD->new(classes => [$class], storage => $version) >>
where C<$version> is C<$class>'s own version (split out of C<api_version> the
same way). See L</new> for the object this returns -- a real, fully typed
C<CustomResourceDefinition>, not a bare hashref.

=head2 new

    my $crd = IO::K8s::CRD->new(
        classes => [ $class_v1, $class_v1beta1 ],   # one class per version
        storage => 'v1',                            # names one of their versions
    );

D9: assembles ONE multi-version C<CustomResourceDefinition> object from one
typed class per version -- the assembly layer over L</crd_for_class>/
C<< $class->to_crd >>, which is now exactly
C<< IO::K8s::CRD->new(classes => [$class], storage => $version) >> under the
hood (see L</crd_for_class>).

Every class in C<classes> is one API version of the SAME CRD, so they must
agree on C<spec.group>, C<< names.kind >> (from C<< $class->kind >>),
C<< names.plural >> (from C<< $class->resource_plural >>) and C<spec.scope>
(L<IO::K8s::Role::Namespaced> or not) -- a mismatch on any of those croaks,
naming the field and which class supplied which value. They must also each
be a genuinely distinct version: two classes naming the same version (e.g.
two whose C<api_version> both end C<.../v1>) would otherwise produce two
identically-named C<spec.versions[]> entries -- a shape the apiserver
rejects -- so that croaks too, naming the repeated version. Each class
becomes one C<spec.versions[]> entry (schema from L</_schema_for_class>,
applied per class): every entry is C<served => true>, and exactly the one
whose C<name> matches C<storage> gets C<storage => true> (the rest
C<storage => false>). C<storage> is required and must name one of the given
classes' own versions, or the call croaks.

Versions land in C<spec.versions> in the order C<classes> was given, not
re-sorted by a Kubernetes-style version precedence -- the caller already
chose an order (oldest-first is conventional, but not enforced), and
silently reordering it would be a surprise, not a service. Pass C<classes>
in whatever order the manifest should show.

C<classes> must be a non-empty arrayref, or the call croaks.

=head2 _schema_for_class

    my $schema = IO::K8s::CRD::_schema_for_class($class);

The C<openAPIV3Schema> for one version of C<$class> (D9): walks
C<< $class->_k8s_attr_info >> and mirrors L<IO::K8s::AutoGen>'s
schema-to-DSL mapping (C<_schema_to_type_spec>) field by field, in
reverse, keyed by each field's C<json_key>.

For a top-level Kind (C<< $class->can('_is_resource') >>) the registry's
own C<metadata> entry is skipped and C<apiVersion>/C<kind>/C<metadata>
get the standard envelope stubs instead -- the same three fields
L<IO::K8s::AutoGen>'s C<%role_supplied> excludes when building attributes
FROM a schema (see C<_generate_class> there), lined up here in the
opposite direction. A nested class reached through a field is walked
exactly the same way, minus the stubs (it is never itself C<_is_resource>).

Recursion guards against cycles by tracking the classes already on the
CURRENT path (the second, internal C<$seen> argument -- never pass it from
outside): a class that references itself, directly or through a reused
core class, becomes an opaque
C<< { type => 'object', 'x-kubernetes-preserve-unknown-fields' => true } >>
stub at the repeat instead of recursing forever, the same stub the opaque
C<< { Str => 1 } >> map gets. This is deliberately PATH-scoped, not global:
a class that legitimately appears more than once as unrelated siblings
(C<LabelSelector>, reused all over a real CRD schema per D5) must not be
flattened to that stub on its second, unrelated appearance.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
