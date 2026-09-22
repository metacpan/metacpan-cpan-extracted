#!/usr/bin/env perl
# Regression test for k45: embedded *TemplateSpec classes compose
# IO::K8s::APIObject and stamp a spurious apiVersion/kind into their TO_JSON
# output, even though the upstream schema (io.k8s.api.core.v1.PodTemplateSpec,
# io.k8s.api.batch.v1.JobTemplateSpec, ...) carries no such keys -- only
# 'metadata' and 'spec'.
#
# t/25_real_world.t and t/26_build_verify.t already round-trip Deployment and
# CronJob manifests, but their assertions only spot-check individual leaf
# values (is($exported->{spec}{replicas}, ...)) or use superhashof(), which
# ignores extra keys by design. Neither can fail when TO_JSON *adds* a key
# the input never had -- which is exactly this bug. This file adds that
# missing assertion class: a recursive "the output must not introduce any
# key the input didn't have" check, run over a full manifest round-trip.
#
# Contrast case: io.k8s.api.core.v1.PersistentVolumeClaim (embedded in
# StatefulSetSpec.volumeClaimTemplates) really does carry inline TypeMeta per
# the upstream schema, so it is correct for it to keep emitting apiVersion/
# kind. That is asserted here too, as a control, so that a future fix for the
# seven buggy classes below does not overcorrect and strip PVC's GVK as well.

use strict;
use warnings;
use Test::More;

use IO::K8s;

my $k8s = IO::K8s->new;

# Recursively collect every key path present in $got but absent from $orig
# at the same path. Only hash keys are compared -- array elements are walked
# pairwise by index, but a length mismatch or a non-hash/non-array value is
# not itself flagged (this helper exists to catch *added* keys, not general
# structural drift). Returns a list of dotted/bracketed paths, e.g.
# 'spec.template.apiVersion' or 'spec.jobTemplate.spec.template.kind'.
sub extra_keys {
    my ($orig, $got, $path) = @_;
    $path = '' unless defined $path;
    my @extra;

    if (ref $got eq 'HASH') {
        if (ref $orig ne 'HASH') {
            push @extra, "$path (expected hash in input)";
            return @extra;
        }
        for my $key (sort keys %$got) {
            my $subpath = length($path) ? "$path.$key" : $key;
            if (!exists $orig->{$key}) {
                push @extra, $subpath;
                next;
            }
            push @extra, extra_keys($orig->{$key}, $got->{$key}, $subpath);
        }
    }
    elsif (ref $got eq 'ARRAY') {
        if (ref $orig ne 'ARRAY') {
            push @extra, "$path (expected array in input)";
            return @extra;
        }
        for my $i (0 .. $#$got) {
            next unless exists $orig->[$i];
            push @extra, extra_keys($orig->[$i], $got->[$i], "$path\[$i\]");
        }
    }

    return @extra;
}

# ============================================================================
# 1. Deployment: spec.template is a bare PodTemplateSpec (no GVK in schema)
# ============================================================================

subtest 'Deployment round-trip introduces no keys beyond the input manifest' => sub {
    my $deployment_manifest = {
        apiVersion => 'apps/v1',
        kind       => 'Deployment',
        metadata   => {
            name      => 'web',
            namespace => 'default',
            labels    => { app => 'web' },
        },
        spec => {
            replicas => 3,
            selector => { matchLabels => { app => 'web' } },
            template => {
                metadata => { labels => { app => 'web' } },
                spec     => {
                    containers => [{
                        name  => 'web',
                        image => 'nginx:1.27',
                        ports => [{ containerPort => 80 }],
                    }],
                },
            },
        },
    };

    my $obj = $k8s->struct_to_object($deployment_manifest);
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');

    my $exported = $obj->TO_JSON;

    my @extra = extra_keys($deployment_manifest, $exported);
    is_deeply(\@extra, [],
        'no keys in TO_JSON output that the input manifest did not have '
      . '(spec.template must not gain apiVersion/kind)');
};

# ============================================================================
# 2. CronJob: spec.jobTemplate is a bare JobTemplateSpec, and it nests a
#    second PodTemplateSpec at spec.jobTemplate.spec.template -- both must
#    stay GVK-free.
# ============================================================================

subtest 'CronJob round-trip introduces no keys beyond the input manifest' => sub {
    my $cronjob_manifest = {
        apiVersion => 'batch/v1',
        kind       => 'CronJob',
        metadata   => {
            name      => 'db-backup',
            namespace => 'databases',
        },
        spec => {
            schedule                   => '0 2 * * *',
            concurrencyPolicy          => 'Forbid',
            successfulJobsHistoryLimit => 3,
            jobTemplate                => {
                metadata => { labels => { app => 'db-backup' } },
                spec     => {
                    backoffLimit => 2,
                    template     => {
                        metadata => { labels => { app => 'db-backup' } },
                        spec     => {
                            restartPolicy => 'OnFailure',
                            containers    => [{
                                name    => 'backup',
                                image   => 'postgres:16',
                                command => ['/bin/sh', '-c', 'pg_dump -h postgresql -U postgres > /backup/dump.sql'],
                            }],
                        },
                    },
                },
            },
        },
    };

    my $obj = $k8s->struct_to_object($cronjob_manifest);
    isa_ok($obj, 'IO::K8s::Api::Batch::V1::CronJob');

    my $exported = $obj->TO_JSON;

    my @extra = extra_keys($cronjob_manifest, $exported);
    is_deeply(\@extra, [],
        'no keys in TO_JSON output that the input manifest did not have '
      . '(spec.jobTemplate and spec.jobTemplate.spec.template must not gain apiVersion/kind)');
};

# ============================================================================
# 3. Control case: StatefulSet.spec.volumeClaimTemplates really does carry
#    inline TypeMeta per the upstream schema. This must keep emitting
#    apiVersion/kind -- a fix for k45 must not touch PersistentVolumeClaim.
# ============================================================================

subtest 'PersistentVolumeClaim template keeps apiVersion/kind (control, not part of k45)' => sub {
    my $statefulset_manifest = {
        apiVersion => 'apps/v1',
        kind       => 'StatefulSet',
        metadata   => {
            name      => 'redis',
            namespace => 'cache',
        },
        spec => {
            serviceName => 'redis',
            replicas    => 3,
            selector    => { matchLabels => { app => 'redis' } },
            template    => {
                metadata => { labels => { app => 'redis' } },
                spec     => {
                    containers => [{
                        name         => 'redis',
                        image        => 'redis:7',
                        volumeMounts => [{ name => 'data', mountPath => '/data' }],
                    }],
                },
            },
            volumeClaimTemplates => [{
                metadata => { name => 'data' },
                spec     => {
                    accessModes => ['ReadWriteOnce'],
                    resources   => { requests => { storage => '10Gi' } },
                },
            }],
        },
    };

    my $obj = $k8s->struct_to_object($statefulset_manifest);
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::StatefulSet');

    my $vct = $obj->spec->volumeClaimTemplates->[0];
    isa_ok($vct, 'IO::K8s::Api::Core::V1::PersistentVolumeClaim');

    my $exported = $vct->TO_JSON;
    is($exported->{apiVersion}, 'v1',
        'PersistentVolumeClaim template keeps apiVersion (schema carries inline TypeMeta)');
    is($exported->{kind}, 'PersistentVolumeClaim',
        'PersistentVolumeClaim template keeps kind');
};

done_testing;
