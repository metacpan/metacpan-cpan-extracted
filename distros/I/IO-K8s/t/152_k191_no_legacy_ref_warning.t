#!/usr/bin/env perl
# k191 spec test 8: loading and serializing the SHIPPED classes must never
# trigger the legacy-{ Str => 1 } deprecation warning ("declare it as Opaque or
# HashRef[...]"), and every shipped core field that is a string map must be a
# real map[string]string upstream.
#
# The runtime smoke (subtest 1 and 2) only catches a wrongly classified field
# when some fixture happens to carry a ref value in it. The static check
# (subtest 3) does not depend on that: for every core class field whose
# registry entry says is_hash_of_str it looks the property up in
# spec/v1.37.0.json (falling back to v1.36.3.json for classes
# only older clusters know) and demands additionalProperties { type: string }. A
# field that upstream types as map[string][]string, a ResourceList, a
# RawExtension, ... and that is still declared { Str => 1 } fails here.
#
# Local fixtures only (lib/, t/25_real_world.t's own manifests, spec/), no
# network, no cluster.

use strict;
use warnings;
use Test::More;
use File::Find;
use FindBin;
use JSON::MaybeXS ();
use Path::Tiny qw( path );

BEGIN {
    eval { require YAML::PP; 1 }
        or plan skip_all => 'YAML::PP required for the real-world manifests';
}

use IO::K8s;

my $ROOT = path($FindBin::Bin)->parent;

my @warnings;
my $LEGACY = qr/Opaque|HashRef\[|deprecat/i;

sub legacy_warnings { grep { /$LEGACY/ } @warnings }

# ----------------------------------------------------------------------------
# 1. Load every shipped class (the t/02_compile_all.t walk), catching warnings
# ----------------------------------------------------------------------------

subtest 'loading every shipped class raises no legacy-map warning' => sub {
    my @modules;
    find(sub {
        return unless /\.pm$/;
        my $mod = $File::Find::name;
        $mod =~ s{^\Q$ROOT\E/lib/}{};
        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm$}{};
        push @modules, $mod;
    }, "$ROOT/lib");

    local $SIG{__WARN__} = sub { push @warnings, "@_" };
    my @failed;
    for my $mod (sort @modules) {
        eval "require $mod; 1" or push @failed, "$mod: $@";
    }
    cmp_ok(scalar @modules, '>', 800, 'walked the whole tree (' . scalar(@modules) . ' modules)');
    is(scalar @failed, 0, 'every module loads') or diag explain \@failed;
    is(scalar(legacy_warnings()), 0, 'no legacy-map warning while loading')
        or diag explain [ legacy_warnings() ];
};

# ----------------------------------------------------------------------------
# 2. Inflate and serialize real manifests (t/25's own heredocs) and a built one
# ----------------------------------------------------------------------------

subtest 'real-world manifests inflate and serialize without a legacy-map warning' => sub {
    my $src = $ROOT->child('t', '25_real_world.t')->slurp_utf8;
    my @docs;
    while ($src =~ /<<'(END_YAML)';\n(.*?)\n\1\n/sg) {
        push @docs, YAML::PP->new->load_string($2);
    }
    cmp_ok(scalar @docs, '>=', 10, 'picked up the t/25 manifests (' . scalar(@docs) . ')');

    my $k8s = IO::K8s->new;
    my @objects;
    local $SIG{__WARN__} = sub { push @warnings, "@_" };
    my $before = @warnings;

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

    my @mine = @warnings[ $before .. $#warnings ];
    is(scalar(grep { /$LEGACY/ } @mine), 0, 'no legacy-map warning while inflating/serializing')
        or diag explain \@mine;
};

# ----------------------------------------------------------------------------
# 3. Static: every shipped core string map is map[string]string upstream
# ----------------------------------------------------------------------------

sub defkey_to_perl_class {
    my ($key) = @_;
    return unless $key =~ /^io\.k8s\./;
    my @parts = split /\./, substr($key, length 'io.k8s.');
    my $kind  = pop @parts;
    return join '::', 'IO::K8s',
        ( map { join '', map { ucfirst } grep { length } split /-/, $_ } @parts ), $kind;
}

subtest 'every core is_hash_of_str field is additionalProperties {type: string} upstream' => sub {
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

    my $CORE = qr/^IO::K8s::(?:Api|Apimachinery|ApiextensionsApiserver|KubeAggregator)::/;
    my $registry = \%IO::K8s::Resource::_attr_registry;
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

done_testing;
