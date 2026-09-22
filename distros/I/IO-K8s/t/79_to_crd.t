#!/usr/bin/env perl
# D9: Class->to_crd builds a CustomResourceDefinition from a typed class's
# attribute registry -- the exact inverse of IO::K8s::AutoGen's
# schema-to-DSL mapping (_schema_to_type_spec). See docs/superpowers/specs/
# 2026-09-03-crd-design.md, decision D9.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw( blessed reftype );
use re ();

use IO::K8s;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;
use IO::K8s::CertManager::V1::Order;

# --- fixture: every branch of the reverse mapping -------------------------

{
    package Test79::Item;
    use IO::K8s::Resource;

    k8s label  => Str, 'required';
    k8s weight => Int;

    1;
}

{
    package Test79::Widget;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1',
        resource_plural => 'widgets';
    with 'IO::K8s::Role::Namespaced';

    k8s name      => Str, { required => 1, description => 'Name of the widget' };
    k8s replicas  => Int, { minimum => 0, maximum => 5 };
    k8s ratio     => Num;
    k8s ready     => Bool;
    k8s flexible  => IntOrStr;
    k8s cpu       => Quantity;
    k8s startedAt => Time;
    k8s tags      => [Str];
    k8s ports     => [Int];
    k8s flags     => [Bool];
    k8s weights   => [Num];
    k8s limits    => [Quantity];
    k8s stamps    => [Time];
    k8s sizes     => [IntOrStr];
    k8s rows      => [ {} ];
    k8s matrix    => [ [] ];
    k8s limit     => '+Test79::Item';
    k8s items     => ['+Test79::Item'];
    k8s scores    => { Int => 1 };
    k8s extras    => { '+Test79::Item' => 1 };
    k8s labels    => { Str => 1 };
    k8s mode      => Str, { enum => [qw(fast safe)], pattern => qr/\A[a-z]+\z/ };
    k8s note      => Str, { nullable => 1 };
    k8s blob      => Str, { preserve_unknown => 1 };
    k8s greeting  => Str, { default => 'hi' };

    1;
}

{
    package Test79::ClusterThing;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1',
        resource_plural => 'clusterthings';

    k8s note => Str;

    1;
}

{
    package Test79::Cycle;
    use IO::K8s::Resource;

    k8s self => '+Test79::Cycle';

    1;
}

# JSON::MaybeXS booleans are blessed scalar refs; flatten them to plain 1/0
# on both sides of is_deeply so the comparison does not depend on whichever
# backend (Cpanel::JSON::XS, JSON::XS, JSON::PP) MaybeXS picked, or on
# singleton identity.
sub _flatten_bools {
    my ($val) = @_;
    return { map { $_ => _flatten_bools($val->{$_}) } keys %$val } if ref $val eq 'HASH';
    return [ map { _flatten_bools($_) } @$val ]                    if ref $val eq 'ARRAY';
    return ($val ? 1 : 0) if blessed($val) && (reftype($val) // '') eq 'SCALAR';
    return $val;
}

my $ITEM_SCHEMA = {
    type       => 'object',
    properties => {
        label  => { type => 'string' },
        weight => { type => 'integer' },
    },
    required => ['label'],
};

subtest '_schema_for_class mirrors every AutoGen branch in reverse' => sub {
    my $schema = IO::K8s::CRD::_schema_for_class('Test79::Widget');
    my $expected = {
        type       => 'object',
        required   => ['name'],
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            metadata   => { type => 'object' },
            name       => { type => 'string', description => 'Name of the widget' },
            replicas   => { type => 'integer', minimum => 0, maximum => 5 },
            ratio      => { type => 'number' },
            ready      => { type => 'boolean' },
            flexible   => { 'x-kubernetes-int-or-string' => 1 },
            cpu        => { type => 'string' },   # is_quantity -> string: documented lossy edge
            startedAt  => { type => 'string', format => 'date-time' },
            tags       => { type => 'array', items => { type => 'string' } },
            ports      => { type => 'array', items => { type => 'integer' } },
            flags      => { type => 'array', items => { type => 'boolean' } },
            # k96 task-2 review (Critical): before the fix, an array of
            # Num/Quantity/Time/IntOrStr recorded NO is_array_of_* flag at
            # all (Resource.pm's array branch only classified Str/Int/Bool),
            # so _schema_for_class croaked "no recognizable is_* flag" on
            # every shipped Kind carrying one -- e.g.
            # IO::K8s::Api::Resource::V1::ResourceSlice via
            # DeviceCapacity.validValues => [Quantity].
            weights    => { type => 'array', items => { type => 'number' } },
            limits     => { type => 'array', items => { type => 'string' } },   # [Quantity]: same documented lossy edge as scalar is_quantity
            stamps     => { type => 'array', items => { type => 'string', format => 'date-time' } },   # [Time]: lossless
            sizes      => { type => 'array', items => { 'x-kubernetes-int-or-string' => 1 } },
            rows       => { type => 'array', items => { type => 'object', 'x-kubernetes-preserve-unknown-fields' => 1 } },
            matrix     => { type => 'array', items => { type => 'array' } },
            limit      => $ITEM_SCHEMA,
            items      => { type => 'array', items => $ITEM_SCHEMA },
            scores     => { type => 'object', additionalProperties => { type => 'integer' } },
            extras     => { type => 'object', additionalProperties => $ITEM_SCHEMA },
            labels     => { type => 'object', 'x-kubernetes-preserve-unknown-fields' => 1 },
            # k110: a qr// is TRANSLATED to ECMA262 on emit, not passed
            # through as its Perl source -- \A/\z become ^/$, which is what
            # openAPIV3Schema.pattern is specified in. Before k110 this
            # asserted the raw '\A[a-z]+\z', a pattern no apiserver accepts.
            mode       => { type => 'string', enum => [qw(fast safe)], pattern => '^[a-z]+$' },
            note       => { type => 'string', nullable => 1 },
            blob       => { type => 'string', 'x-kubernetes-preserve-unknown-fields' => 1 },
            greeting   => { type => 'string', default => 'hi' },
        },
    };
    is_deeply(_flatten_bools($schema), $expected, 'openAPIV3Schema matches the registry, field for field');
};

subtest 'cycle guard: a self-referencing class does not recurse forever' => sub {
    my $schema = IO::K8s::CRD::_schema_for_class('Test79::Cycle');
    is_deeply(_flatten_bools($schema), {
        type       => 'object',
        properties => {
            self => { type => 'object', 'x-kubernetes-preserve-unknown-fields' => 1 },
        },
    }, 'the repeat on the recursion path becomes an opaque stub instead of looping');
};

subtest 'Class->to_crd: identity, scope, envelope' => sub {
    my $ns_crd = Test79::Widget->to_crd;
    isa_ok($ns_crd, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition');
    is($ns_crd->spec->scope, 'Namespaced', 'Namespaced Kind -> spec.scope Namespaced');
    is($ns_crd->spec->group, 'crdstep5.example.com', 'spec.group from api_version');
    is($ns_crd->spec->names->plural, 'widgets', 'spec.names.plural from resource_plural');
    is($ns_crd->spec->names->kind, 'Widget', 'spec.names.kind from kind');
    is($ns_crd->spec->names->singular, 'widget', 'spec.names.singular lc(kind)');
    is($ns_crd->spec->names->listKind, 'WidgetList', 'spec.names.listKind');
    is($ns_crd->metadata->name, 'widgets.crdstep5.example.com', 'metadata.name is plural.group');

    my $version = $ns_crd->spec->versions->[0];
    is($version->name, 'v1', 'version name from api_version');
    is($version->served, 1, 'served true');
    is($version->storage, 1, 'storage true');
    isa_ok($version->schema->openAPIV3Schema,
        'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps',
        'the schema is a real typed JSONSchemaProps object, not a bare hashref');
    ok(exists $version->schema->openAPIV3Schema->TO_JSON->{properties}{name}, 'schema content reachable through the typed object');

    my $cluster_crd = Test79::ClusterThing->to_crd;
    is($cluster_crd->spec->scope, 'Cluster', 'no Namespaced role -> spec.scope Cluster');
};

subtest 'round trip: a shipped provider Kind survives to_crd -> add_crd' => sub {
    my $crd = IO::K8s::CertManager::V1::Order->to_crd;
    my $k8s = IO::K8s->new;
    my $reg = $k8s->add_crd($crd);
    my $regen_class = $reg->{Order}{ $reg->{Order}{storage} };
    ok($regen_class, 'add_crd(Class->to_crd) registers the Kind again');

    my $orig_spec_class  = IO::K8s::CertManager::V1::Order->_k8s_attr_info->{spec}{class};
    my $regen_spec_class = $regen_class->_k8s_attr_info->{spec}{class};
    is_deeply(
        [ sort keys %{ $orig_spec_class->_k8s_attr_info } ],
        [ sort keys %{ $regen_spec_class->_k8s_attr_info } ],
        'regenerated spec field set matches the original',
    );

    my $orig_status_class  = IO::K8s::CertManager::V1::Order->_k8s_attr_info->{status}{class};
    my $regen_status_class = $regen_class->_k8s_attr_info->{status}{class};
    is_deeply(
        [ sort keys %{ $orig_status_class->_k8s_attr_info } ],
        [ sort keys %{ $regen_status_class->_k8s_attr_info } ],
        'regenerated status field set matches the original',
    );
    is($regen_status_class->_k8s_attr_info->{failureTime}{is_time}, 1,
        'failureTime is still typed Time after the round trip (format: date-time round-trips losslessly)');
    is_deeply($regen_status_class->_k8s_attr_info->{state}{options}{enum},
        [qw(valid ready pending processing invalid expired errored)],
        'the enum on status.state survives the round trip');

    ok($regen_class->does('IO::K8s::Role::Namespaced'), 'Namespaced scope preserved through the round trip');
};

subtest 'regression: arrays of Num/Quantity/Time/IntOrStr are flagged and schema-able (k96 review, Critical)' => sub {
    require IO::K8s::Api::Resource::V1::CapacityRequestPolicy;
    my $info = IO::K8s::Api::Resource::V1::CapacityRequestPolicy->_k8s_attr_info;
    is($info->{validValues}{is_array_of_quantity}, 1,
        'DeviceCapacity/CapacityRequestPolicy.validValues ([Quantity]) is registered as is_array_of_quantity');

    require IO::K8s::Api::Resource::V1::ResourceSlice;
    my $crd;
    lives_ok { $crd = IO::K8s::Api::Resource::V1::ResourceSlice->to_crd }
        'ResourceSlice->to_crd no longer dies (was: "registry entry with no recognizable is_* flag")';
    isa_ok($crd, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition');
};

# --- k110: openAPIV3Schema.pattern is ECMA262, not Perl -------------------

{
    package Test79::AnchoredItem;
    use IO::K8s::Resource;

    k8s label => Str, { pattern => qr/\Aitem-[0-9]+\z/ };

    1;
}

{
    package Test79::Anchored;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1',
        resource_plural => 'anchoreds';
    with 'IO::K8s::Role::Namespaced';

    k8s name     => Str, { pattern => qr/\A[a-z0-9-]+\z/ };
    k8s lazy     => Str, { pattern => qr/^(?:a|b)+?[]x-]{1,3}$/ };
    k8s verbatim => Str, { pattern => '\Astill-perl\z' };
    k8s item     => '+Test79::AnchoredItem';

    1;
}

{ package Test79::PatFlag;       use IO::K8s::Resource; k8s mode => Str, { pattern => qr/\Aabort\z/i };     1; }
{ package Test79::PatPossessive; use IO::K8s::Resource; k8s mode => Str, { pattern => qr/\Aa++\z/ };        1; }
{ package Test79::PatAtomic;     use IO::K8s::Resource; k8s mode => Str, { pattern => qr/\A(?>ab)\z/ };     1; }
{ package Test79::PatKeep;       use IO::K8s::Resource; k8s mode => Str, { pattern => qr/\Aa\Kb\z/ };       1; }
{ package Test79::PatBigZ;       use IO::K8s::Resource; k8s mode => Str, { pattern => qr/\Aa\Z/ };          1; }
{ package Test79::PatPosix;      use IO::K8s::Resource; k8s mode => Str, { pattern => qr/\A[[:alpha:]]+\z/ }; 1; }

subtest 'k110: a qr// pattern is emitted as ECMA262' => sub {
    my $props = IO::K8s::CRD::_schema_for_class('Test79::Anchored')->{properties};

    is($props->{name}{pattern}, '^[a-z0-9-]+$',
        '\A and \z become the ECMA262 whole-input anchors ^ and $');
    is($props->{lazy}{pattern}, '^(?:a|b)+?[]x-]{1,3}$',
        'everything both flavors spell the same way is copied verbatim '
        . '(non-capturing group, lazy quantifier, leading ] in a class, {n,m})');
    is($props->{item}{properties}{label}{pattern}, '^item-[0-9]+$',
        'a nested class below the top level is translated too');

    # The bounded half of the rule: a pattern the author wrote as a plain
    # string is the wire pattern already, however Perl-looking it is. We do
    # not parse other people's regexes.
    is($props->{verbatim}{pattern}, '\Astill-perl\z',
        'a plain-string pattern is passed through untouched, not translated');
};

subtest 'k110: a qr// that cannot be translated croaks, naming field and construct' => sub {
    throws_ok { IO::K8s::CRD::_schema_for_class('Test79::PatFlag') }
        qr/pattern for Test79::PatFlag\.mode cannot be emitted as ECMA262: it uses case-insensitive matching \(\/i\)/,
        'a /i flag croaks, naming the field path and the flag';
    throws_ok { IO::K8s::CRD::_schema_for_class('Test79::PatFlag') }
        qr{Pattern: qr/\\Aabort\\z/},
        'and quotes the offending pattern back';

    throws_ok { IO::K8s::CRD::_schema_for_class('Test79::PatPossessive') }
        qr/Test79::PatPossessive\.mode .*possessive quantifier '\+\+'/s,
        'possessive quantifier';
    throws_ok { IO::K8s::CRD::_schema_for_class('Test79::PatAtomic') }
        qr/Test79::PatAtomic\.mode .*group construct '\(\?>/s,
        'atomic group';
    throws_ok { IO::K8s::CRD::_schema_for_class('Test79::PatKeep') }
        qr/Test79::PatKeep\.mode .*\\K \(keep, Perl-only\)/s,
        '\K';
    # \Z is not $: Perl's \Z also matches before a final newline, so it is
    # rejected rather than quietly equated with the anchor \z maps to.
    throws_ok { IO::K8s::CRD::_schema_for_class('Test79::PatBigZ') }
        qr/Test79::PatBigZ\.mode .*\\Z \(Perl end-of-string/s,
        '\Z is not silently turned into $';
    throws_ok { IO::K8s::CRD::_schema_for_class('Test79::PatPosix') }
        qr/Test79::PatPosix\.mode .*POSIX character class/s,
        'POSIX character class';
};

subtest 'k110: the shipped provider patterns still emit exactly as before' => sub {
    require IO::K8s::Cilium::V2::LogConfig;
    my $log = IO::K8s::CRD::_schema_for_class('IO::K8s::Cilium::V2::LogConfig');
    is($log->{properties}{value}{pattern}, '^\PC*$',
        'Cilium LogConfig.value keeps its \P{...} property class -- upstream ships it '
        . 'and the apiserver takes it, so it is not rejected in ECMA262\'s name');

    require IO::K8s::PrometheusOperator::V1::RuleGroup;
    my $rg = IO::K8s::CRD::_schema_for_class('IO::K8s::PrometheusOperator::V1::RuleGroup');
    is($rg->{properties}{partial_response_strategy}{pattern}, '^(?i)(abort|warn)?$',
        'the inline modifier upstream ships survives as the plain string it is stored as');
};

subtest 'smoke: every shipped, resource_plural-bearing Kind survives to_crd' => sub {
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

# Runs after the smoke subtest above on purpose -- that one is what has
# already loaded every shipped class, and the registry is only populated by
# the `k8s` calls a class makes at load time.
subtest 'k110: no shipped qr// pattern croaks or changes on emit' => sub {
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

# k114: the same sweep one step further out, and over the string patterns
# too. What IO::K8s::CRD::Emitter would RENDER for a shipped pattern, read
# back in the way the rendered file's own `k8s` line would, must reach a
# CRD as the same text. That is the drift k106 and k110 each had to clean
# up: a shipped class and the emitter's output for it disagree, and nothing
# notices until somebody re-renders the provider.
sub _crd_pattern {
    my ($p, $where) = @_;
    return ref $p eq 'Regexp' ? IO::K8s::CRD::_pattern_to_ecma262($p, $where) : $p;
}

subtest 'k114: the emitter is a fixed point on every shipped pattern' => sub {
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

subtest 'scope: Cluster-scoped shipped Kind' => sub {
    # ClusterIssuer is cert-manager's cluster-scoped counterpart to Issuer.
    require IO::K8s::CertManager::V1::ClusterIssuer;
    my $crd = IO::K8s::CertManager::V1::ClusterIssuer->to_crd;
    is($crd->spec->scope, 'Cluster', 'ClusterIssuer -> spec.scope Cluster');
};

done_testing;
