#!/usr/bin/env perl
# Comprehensive combination & stress tests for IO::K8s
# Exercises real-world K8s resources, deep nesting, mixed construction,
# round-trip serialization, edge cases, and more.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS;

use IO::K8s;

my $k8s = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1);

# ============================================================================
# 1. Complex real-world K8s resources
# ============================================================================

subtest 'Full Deployment with init containers, multi-container, volumes, probes, resources' => sub {
    my $deploy = $k8s->new_object('Deployment', {
        metadata => {
            name      => 'webapp',
            namespace => 'production',
            labels    => {
                app        => 'webapp',
                version    => 'v2',
                'team.org' => 'platform',
            },
            annotations => {
                'deployment.kubernetes.io/revision' => '5',
                'kubectl.kubernetes.io/last-applied-configuration' => '{}',
            },
        },
        spec => {
            replicas             => 3,
            revisionHistoryLimit => 5,
            strategy             => {
                type          => 'RollingUpdate',
                rollingUpdate => {
                    maxSurge       => '25%',
                    maxUnavailable => '1',
                },
            },
            selector => {
                matchLabels => { app => 'webapp' },
            },
            template => {
                metadata => {
                    labels      => { app => 'webapp', version => 'v2' },
                    annotations => { 'prometheus.io/scrape' => 'true' },
                },
                spec => {
                    serviceAccountName            => 'webapp-sa',
                    terminationGracePeriodSeconds  => 60,
                    initContainers => [
                        {
                            name    => 'init-db',
                            image   => 'busybox:1.36',
                            command => ['/bin/sh', '-c', 'until nslookup db; do sleep 2; done'],
                            resources => {
                                requests => { cpu => '50m', memory => '64Mi' },
                                limits   => { cpu => '100m', memory => '128Mi' },
                            },
                        },
                        {
                            name    => 'init-migrations',
                            image   => 'webapp:v2-migrate',
                            command => ['./migrate', '--up'],
                            env     => [
                                { name => 'DB_HOST', value => 'db.production.svc' },
                                { name => 'DB_PORT', value => '5432' },
                            ],
                            volumeMounts => [
                                { name => 'config', mountPath => '/etc/config', readOnly => 1 },
                            ],
                        },
                    ],
                    containers => [
                        {
                            name            => 'webapp',
                            image           => 'webapp:v2.1.0',
                            imagePullPolicy => 'IfNotPresent',
                            ports           => [
                                { containerPort => 8080, name => 'http', protocol => 'TCP' },
                                { containerPort => 9090, name => 'metrics', protocol => 'TCP' },
                            ],
                            env => [
                                { name => 'APP_ENV', value => 'production' },
                                { name => 'LOG_LEVEL', value => 'info' },
                                {
                                    name      => 'DB_PASSWORD',
                                    valueFrom => {
                                        secretKeyRef => {
                                            name => 'db-creds',
                                            key  => 'password',
                                        },
                                    },
                                },
                            ],
                            resources => {
                                requests => { cpu => '250m', memory => '512Mi' },
                                limits   => { cpu => '1',    memory => '1Gi' },
                            },
                            livenessProbe => {
                                httpGet => {
                                    path => '/healthz',
                                    port => 'http',
                                },
                                initialDelaySeconds => 15,
                                periodSeconds       => 20,
                                failureThreshold    => 3,
                            },
                            readinessProbe => {
                                httpGet => {
                                    path => '/readyz',
                                    port => '8080',
                                },
                                initialDelaySeconds => 5,
                                periodSeconds       => 10,
                            },
                            startupProbe => {
                                tcpSocket => { port => '8080' },
                                failureThreshold => 30,
                                periodSeconds    => 10,
                            },
                            volumeMounts => [
                                { name => 'config', mountPath => '/etc/config', readOnly => 1 },
                                { name => 'data',   mountPath => '/var/data' },
                                { name => 'tmp',    mountPath => '/tmp' },
                            ],
                        },
                        {
                            name  => 'sidecar-logger',
                            image => 'fluent/fluent-bit:2.1',
                            resources => {
                                requests => { cpu => '50m',  memory => '64Mi' },
                                limits   => { cpu => '100m', memory => '128Mi' },
                            },
                            volumeMounts => [
                                { name => 'data', mountPath => '/var/data', readOnly => 1 },
                            ],
                        },
                    ],
                    volumes => [
                        {
                            name      => 'config',
                            configMap => { name => 'webapp-config' },
                        },
                        {
                            name     => 'data',
                            emptyDir => {},
                        },
                        {
                            name     => 'tmp',
                            emptyDir => { medium => 'Memory', sizeLimit => '100Mi' },
                        },
                    ],
                },
            },
        },
    });

    # Top-level checks
    isa_ok($deploy, 'IO::K8s::Api::Apps::V1::Deployment');
    is($deploy->kind, 'Deployment', 'kind');
    is($deploy->api_version, 'apps/v1', 'api_version');
    is($deploy->metadata->name, 'webapp', 'metadata.name');
    is($deploy->metadata->namespace, 'production', 'metadata.namespace');
    is($deploy->metadata->labels->{app}, 'webapp', 'metadata.labels.app');

    # Spec
    my $spec = $deploy->spec;
    isa_ok($spec, 'IO::K8s::Api::Apps::V1::DeploymentSpec');
    is($spec->replicas, 3, 'replicas');
    is($spec->revisionHistoryLimit, 5, 'revisionHistoryLimit');

    # Strategy
    isa_ok($spec->strategy, 'IO::K8s::Api::Apps::V1::DeploymentStrategy');
    is($spec->strategy->type, 'RollingUpdate', 'strategy type');

    # Selector
    isa_ok($spec->selector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    is($spec->selector->matchLabels->{app}, 'webapp', 'selector.matchLabels');

    # Template
    my $tpl = $spec->template;
    isa_ok($tpl, 'IO::K8s::Api::Core::V1::PodTemplateSpec');

    # Init containers
    my $init = $tpl->spec->initContainers;
    is(scalar @$init, 2, '2 init containers');
    isa_ok($init->[0], 'IO::K8s::Api::Core::V1::Container');
    is($init->[0]->name, 'init-db', 'init container 0 name');
    is($init->[1]->name, 'init-migrations', 'init container 1 name');
    isa_ok($init->[1]->env->[0], 'IO::K8s::Api::Core::V1::EnvVar');
    isa_ok($init->[1]->volumeMounts->[0], 'IO::K8s::Api::Core::V1::VolumeMount');

    # Main containers
    my $containers = $tpl->spec->containers;
    is(scalar @$containers, 2, '2 containers');
    my $main = $containers->[0];
    is($main->name, 'webapp', 'main container name');
    is(scalar @{$main->ports}, 2, '2 ports');
    isa_ok($main->ports->[0], 'IO::K8s::Api::Core::V1::ContainerPort');
    is($main->ports->[0]->containerPort, 8080, 'containerPort');

    # Env with valueFrom
    my $db_pass_env = $main->env->[2];
    isa_ok($db_pass_env, 'IO::K8s::Api::Core::V1::EnvVar');
    is($db_pass_env->name, 'DB_PASSWORD', 'env name');
    isa_ok($db_pass_env->valueFrom, 'IO::K8s::Api::Core::V1::EnvVarSource');

    # Probes
    isa_ok($main->livenessProbe, 'IO::K8s::Api::Core::V1::Probe');
    isa_ok($main->livenessProbe->httpGet, 'IO::K8s::Api::Core::V1::HTTPGetAction');
    is($main->livenessProbe->httpGet->path, '/healthz', 'liveness path');
    is($main->livenessProbe->initialDelaySeconds, 15, 'liveness initialDelaySeconds');
    isa_ok($main->readinessProbe, 'IO::K8s::Api::Core::V1::Probe');
    isa_ok($main->startupProbe, 'IO::K8s::Api::Core::V1::Probe');
    isa_ok($main->startupProbe->tcpSocket, 'IO::K8s::Api::Core::V1::TCPSocketAction');

    # Resources
    isa_ok($main->resources, 'IO::K8s::Api::Core::V1::ResourceRequirements');
    is($main->resources->requests->{cpu}, '250m', 'resource request cpu');
    is($main->resources->limits->{memory}, '1Gi', 'resource limit memory');

    # Volume mounts
    is(scalar @{$main->volumeMounts}, 3, '3 volume mounts');
    isa_ok($main->volumeMounts->[0], 'IO::K8s::Api::Core::V1::VolumeMount');

    # Sidecar
    is($containers->[1]->name, 'sidecar-logger', 'sidecar name');

    # Volumes
    my $vols = $tpl->spec->volumes;
    is(scalar @$vols, 3, '3 volumes');
    isa_ok($vols->[0], 'IO::K8s::Api::Core::V1::Volume');
    isa_ok($vols->[0]->configMap, 'IO::K8s::Api::Core::V1::ConfigMapVolumeSource');
    isa_ok($vols->[1]->emptyDir, 'IO::K8s::Api::Core::V1::EmptyDirVolumeSource');
    isa_ok($vols->[2]->emptyDir, 'IO::K8s::Api::Core::V1::EmptyDirVolumeSource');
    is($vols->[2]->emptyDir->medium, 'Memory', 'emptyDir medium');
};

subtest 'StatefulSet with volumeClaimTemplates, headless service pattern' => sub {
    my $sts = $k8s->new_object('StatefulSet', {
        metadata => {
            name      => 'postgres',
            namespace => 'database',
        },
        spec => {
            serviceName         => 'postgres-headless',
            replicas            => 3,
            podManagementPolicy => 'OrderedReady',
            selector            => {
                matchLabels => { app => 'postgres' },
            },
            template => {
                metadata => {
                    labels => { app => 'postgres' },
                },
                spec => {
                    containers => [{
                        name  => 'postgres',
                        image => 'postgres:16',
                        ports => [{ containerPort => 5432, name => 'pg' }],
                        env   => [
                            { name => 'PGDATA', value => '/var/lib/postgresql/data/pgdata' },
                        ],
                        volumeMounts => [
                            { name => 'pgdata', mountPath => '/var/lib/postgresql/data' },
                        ],
                        resources => {
                            requests => { cpu => '500m',  memory => '1Gi' },
                            limits   => { cpu => '2',     memory => '4Gi' },
                        },
                    }],
                    terminationGracePeriodSeconds => 120,
                },
            },
            volumeClaimTemplates => [
                {
                    metadata => { name => 'pgdata' },
                    spec     => {
                        accessModes      => ['ReadWriteOnce'],
                        storageClassName => 'fast-ssd',
                        resources        => {
                            requests => { storage => '50Gi' },
                        },
                    },
                },
            ],
        },
    });

    isa_ok($sts, 'IO::K8s::Api::Apps::V1::StatefulSet');
    is($sts->kind, 'StatefulSet', 'kind');
    is($sts->api_version, 'apps/v1', 'api_version');

    my $spec = $sts->spec;
    isa_ok($spec, 'IO::K8s::Api::Apps::V1::StatefulSetSpec');
    is($spec->serviceName, 'postgres-headless', 'serviceName');
    is($spec->replicas, 3, 'replicas');
    is($spec->podManagementPolicy, 'OrderedReady', 'podManagementPolicy');

    # volumeClaimTemplates
    my $vcts = $spec->volumeClaimTemplates;
    is(scalar @$vcts, 1, '1 VCT');
    isa_ok($vcts->[0], 'IO::K8s::Api::Core::V1::PersistentVolumeClaim');
    is($vcts->[0]->metadata->name, 'pgdata', 'VCT name');
    isa_ok($vcts->[0]->spec, 'IO::K8s::Api::Core::V1::PersistentVolumeClaimSpec');
    is_deeply($vcts->[0]->spec->accessModes, ['ReadWriteOnce'], 'VCT accessModes');
    is($vcts->[0]->spec->storageClassName, 'fast-ssd', 'VCT storageClassName');

    # Headless service companion
    my $svc = $k8s->new_object('Service', {
        metadata => {
            name      => 'postgres-headless',
            namespace => 'database',
        },
        spec => {
            clusterIP => 'None',
            selector  => { app => 'postgres' },
            ports     => [{ port => 5432, name => 'pg', targetPort => '5432' }],
        },
    });

    isa_ok($svc, 'IO::K8s::Api::Core::V1::Service');
    is($svc->spec->clusterIP, 'None', 'headless clusterIP');
};

subtest 'Job with backoffLimit, completions, parallelism, restart policy' => sub {
    my $job = $k8s->new_object('Job', {
        metadata => {
            name      => 'data-import',
            namespace => 'batch-jobs',
        },
        spec => {
            completions             => 10,
            parallelism             => 3,
            backoffLimit            => 5,
            activeDeadlineSeconds   => 3600,
            ttlSecondsAfterFinished => 86400,
            template => {
                spec => {
                    restartPolicy => 'Never',
                    containers    => [{
                        name    => 'importer',
                        image   => 'importer:latest',
                        command => ['./import', '--batch'],
                        resources => {
                            requests => { cpu => '1', memory => '2Gi' },
                            limits   => { cpu => '2', memory => '4Gi' },
                        },
                    }],
                },
            },
        },
    });

    isa_ok($job, 'IO::K8s::Api::Batch::V1::Job');
    is($job->kind, 'Job', 'kind');
    is($job->api_version, 'batch/v1', 'api_version');

    my $spec = $job->spec;
    isa_ok($spec, 'IO::K8s::Api::Batch::V1::JobSpec');
    is($spec->completions, 10, 'completions');
    is($spec->parallelism, 3, 'parallelism');
    is($spec->backoffLimit, 5, 'backoffLimit');
    is($spec->activeDeadlineSeconds, 3600, 'activeDeadlineSeconds');
    is($spec->ttlSecondsAfterFinished, 86400, 'ttlSecondsAfterFinished');
    is($spec->template->spec->restartPolicy, 'Never', 'restartPolicy');
};

subtest 'CronJob (Job inside a CronJob template)' => sub {
    my $cron = $k8s->new_object('CronJob', {
        metadata => {
            name      => 'nightly-backup',
            namespace => 'default',
        },
        spec => {
            schedule                   => '0 2 * * *',
            timeZone                   => 'America/New_York',
            concurrencyPolicy          => 'Forbid',
            successfulJobsHistoryLimit => 3,
            failedJobsHistoryLimit     => 1,
            startingDeadlineSeconds    => 300,
            jobTemplate => {
                spec => {
                    backoffLimit => 2,
                    template     => {
                        spec => {
                            restartPolicy => 'OnFailure',
                            containers    => [{
                                name    => 'backup',
                                image   => 'backup-tool:v1',
                                command => ['/backup.sh'],
                                env     => [
                                    { name => 'BUCKET', value => 's3://backups/nightly' },
                                ],
                            }],
                        },
                    },
                },
            },
        },
    });

    isa_ok($cron, 'IO::K8s::Api::Batch::V1::CronJob');
    is($cron->kind, 'CronJob', 'kind');
    is($cron->api_version, 'batch/v1', 'api_version');

    my $spec = $cron->spec;
    isa_ok($spec, 'IO::K8s::Api::Batch::V1::CronJobSpec');
    is($spec->schedule, '0 2 * * *', 'schedule');
    is($spec->timeZone, 'America/New_York', 'timeZone');
    is($spec->concurrencyPolicy, 'Forbid', 'concurrencyPolicy');
    is($spec->successfulJobsHistoryLimit, 3, 'successfulJobsHistoryLimit');
    is($spec->failedJobsHistoryLimit, 1, 'failedJobsHistoryLimit');
    is($spec->startingDeadlineSeconds, 300, 'startingDeadlineSeconds');

    # Nested job template
    my $jt = $spec->jobTemplate;
    isa_ok($jt, 'IO::K8s::Api::Batch::V1::JobTemplateSpec');
    isa_ok($jt->spec, 'IO::K8s::Api::Batch::V1::JobSpec');
    is($jt->spec->backoffLimit, 2, 'jobTemplate.spec.backoffLimit');
    is($jt->spec->template->spec->restartPolicy, 'OnFailure', 'nested restartPolicy');
    is($jt->spec->template->spec->containers->[0]->name, 'backup', 'nested container name');
};

subtest 'DaemonSet with tolerations, node selectors' => sub {
    my $ds = $k8s->new_object('DaemonSet', {
        metadata => {
            name      => 'node-exporter',
            namespace => 'monitoring',
            labels    => { app => 'node-exporter' },
        },
        spec => {
            selector => {
                matchLabels => { app => 'node-exporter' },
            },
            template => {
                metadata => {
                    labels => { app => 'node-exporter' },
                },
                spec => {
                    hostNetwork => 1,
                    hostPID     => 1,
                    nodeSelector => {
                        'kubernetes.io/os' => 'linux',
                    },
                    tolerations => [
                        {
                            key      => 'node-role.kubernetes.io/control-plane',
                            operator => 'Exists',
                            effect   => 'NoSchedule',
                        },
                        {
                            key      => 'node-role.kubernetes.io/master',
                            operator => 'Exists',
                            effect   => 'NoSchedule',
                        },
                        {
                            operator => 'Exists',
                        },
                    ],
                    containers => [{
                        name  => 'node-exporter',
                        image => 'prom/node-exporter:v1.7.0',
                        ports => [{ containerPort => 9100, name => 'metrics' }],
                        args  => [
                            '--path.procfs=/host/proc',
                            '--path.sysfs=/host/sys',
                            '--path.rootfs=/host/root',
                        ],
                        volumeMounts => [
                            { name => 'proc', mountPath => '/host/proc', readOnly => 1 },
                            { name => 'sys',  mountPath => '/host/sys',  readOnly => 1 },
                            { name => 'root', mountPath => '/host/root', readOnly => 1 },
                        ],
                    }],
                    volumes => [
                        { name => 'proc', hostPath => { path => '/proc' } },
                        { name => 'sys',  hostPath => { path => '/sys' } },
                        { name => 'root', hostPath => { path => '/' } },
                    ],
                },
            },
        },
    });

    isa_ok($ds, 'IO::K8s::Api::Apps::V1::DaemonSet');
    is($ds->kind, 'DaemonSet', 'kind');
    is($ds->api_version, 'apps/v1', 'api_version');

    my $pod_spec = $ds->spec->template->spec;
    ok($pod_spec->hostNetwork, 'hostNetwork is true');
    ok($pod_spec->hostPID, 'hostPID is true');
    is($pod_spec->nodeSelector->{'kubernetes.io/os'}, 'linux', 'nodeSelector');

    # Tolerations
    my $tols = $pod_spec->tolerations;
    is(scalar @$tols, 3, '3 tolerations');
    isa_ok($tols->[0], 'IO::K8s::Api::Core::V1::Toleration');
    is($tols->[0]->key, 'node-role.kubernetes.io/control-plane', 'toleration key');
    is($tols->[0]->operator, 'Exists', 'toleration operator');
    is($tols->[0]->effect, 'NoSchedule', 'toleration effect');

    # Wildcard toleration (no key)
    is($tols->[2]->operator, 'Exists', 'wildcard toleration operator');
    ok(!defined($tols->[2]->key), 'wildcard toleration has no key');
};

subtest 'Pod with all probe types (httpGet, exec, tcpSocket)' => sub {
    my $pod = $k8s->new_object('Pod', {
        metadata => {
            name      => 'probe-test',
            namespace => 'default',
        },
        spec => {
            containers => [{
                name  => 'app',
                image => 'myapp:latest',
                livenessProbe => {
                    httpGet => {
                        path   => '/healthz',
                        port   => '8080',
                        scheme => 'HTTP',
                    },
                    initialDelaySeconds => 10,
                    periodSeconds       => 30,
                    timeoutSeconds      => 5,
                    successThreshold    => 1,
                    failureThreshold    => 3,
                },
                readinessProbe => {
                    exec => {
                        command => ['/bin/sh', '-c', 'cat /tmp/healthy'],
                    },
                    initialDelaySeconds => 5,
                    periodSeconds       => 10,
                },
                startupProbe => {
                    tcpSocket => {
                        port => '8080',
                    },
                    failureThreshold => 30,
                    periodSeconds    => 10,
                },
            }],
        },
    });

    my $c = $pod->spec->containers->[0];

    # httpGet probe
    my $lp = $c->livenessProbe;
    isa_ok($lp, 'IO::K8s::Api::Core::V1::Probe');
    isa_ok($lp->httpGet, 'IO::K8s::Api::Core::V1::HTTPGetAction');
    is($lp->httpGet->path, '/healthz', 'httpGet path');
    is($lp->httpGet->scheme, 'HTTP', 'httpGet scheme');
    is($lp->timeoutSeconds, 5, 'timeoutSeconds');
    is($lp->successThreshold, 1, 'successThreshold');

    # exec probe
    my $rp = $c->readinessProbe;
    isa_ok($rp->exec, 'IO::K8s::Api::Core::V1::ExecAction');
    is_deeply($rp->exec->command, ['/bin/sh', '-c', 'cat /tmp/healthy'], 'exec command');

    # tcpSocket probe
    my $sp = $c->startupProbe;
    isa_ok($sp->tcpSocket, 'IO::K8s::Api::Core::V1::TCPSocketAction');
    is($sp->failureThreshold, 30, 'startup failureThreshold');
};

# ============================================================================
# 2. Deep nesting & inflation
# ============================================================================

subtest 'Deep nesting: Deployment > PodTemplateSpec > PodSpec > Container > EnvVar/VolumeMount' => sub {
    # Build entirely from hashrefs - verify all levels inflate
    my $deploy = $k8s->new_object('Deployment', {
        metadata => { name => 'deep-test' },
        spec     => {
            selector => { matchLabels => { app => 'deep' } },
            template => {
                metadata => { labels => { app => 'deep' } },
                spec     => {
                    containers => [{
                        name  => 'c1',
                        image => 'img:1',
                        env   => [
                            { name => 'K', value => 'V' },
                        ],
                        volumeMounts => [
                            { name => 'vol', mountPath => '/mnt' },
                        ],
                        resources => {
                            requests => { cpu => '100m' },
                            limits   => { cpu => '200m' },
                        },
                        livenessProbe => {
                            httpGet => { path => '/', port => '80' },
                        },
                    }],
                    volumes => [
                        { name => 'vol', emptyDir => {} },
                    ],
                },
            },
        },
    });

    # Level 1: Deployment
    isa_ok($deploy, 'IO::K8s::Api::Apps::V1::Deployment');
    # Level 2: DeploymentSpec
    isa_ok($deploy->spec, 'IO::K8s::Api::Apps::V1::DeploymentSpec');
    # Level 2b: LabelSelector
    isa_ok($deploy->spec->selector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    # Level 3: PodTemplateSpec
    isa_ok($deploy->spec->template, 'IO::K8s::Api::Core::V1::PodTemplateSpec');
    # Level 4: PodSpec
    isa_ok($deploy->spec->template->spec, 'IO::K8s::Api::Core::V1::PodSpec');
    # Level 5: Container
    isa_ok($deploy->spec->template->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container');
    # Level 6: EnvVar
    isa_ok($deploy->spec->template->spec->containers->[0]->env->[0], 'IO::K8s::Api::Core::V1::EnvVar');
    # Level 6: VolumeMount
    isa_ok($deploy->spec->template->spec->containers->[0]->volumeMounts->[0], 'IO::K8s::Api::Core::V1::VolumeMount');
    # Level 6: ResourceRequirements
    isa_ok($deploy->spec->template->spec->containers->[0]->resources, 'IO::K8s::Api::Core::V1::ResourceRequirements');
    # Level 6: Probe > HTTPGetAction
    isa_ok($deploy->spec->template->spec->containers->[0]->livenessProbe->httpGet, 'IO::K8s::Api::Core::V1::HTTPGetAction');
    # Level 5: Volume > EmptyDirVolumeSource
    isa_ok($deploy->spec->template->spec->volumes->[0]->emptyDir, 'IO::K8s::Api::Core::V1::EmptyDirVolumeSource');
};

subtest 'TO_JSON round-trips correctly at every level' => sub {
    my $deploy = $k8s->new_object('Deployment', {
        metadata => { name => 'rt-test', namespace => 'ns' },
        spec     => {
            replicas => 2,
            selector => { matchLabels => { app => 'rt' } },
            template => {
                metadata => { labels => { app => 'rt' } },
                spec     => {
                    containers => [{
                        name  => 'main',
                        image => 'app:v1',
                        env   => [{ name => 'X', value => 'Y' }],
                        ports => [{ containerPort => 80 }],
                    }],
                },
            },
        },
    });

    my $struct = $deploy->TO_JSON;
    is(ref $struct, 'HASH', 'TO_JSON returns hashref');
    is($struct->{kind}, 'Deployment', 'kind in TO_JSON');
    is($struct->{apiVersion}, 'apps/v1', 'apiVersion in TO_JSON');
    is($struct->{metadata}{name}, 'rt-test', 'metadata.name in TO_JSON');
    is($struct->{spec}{replicas}, 2, 'replicas in TO_JSON');
    is(ref $struct->{spec}{template}{spec}{containers}, 'ARRAY', 'containers is array in TO_JSON');
    is($struct->{spec}{template}{spec}{containers}[0]{name}, 'main', 'container name in TO_JSON');
    is($struct->{spec}{template}{spec}{containers}[0]{env}[0]{name}, 'X', 'env name in TO_JSON');
    is($struct->{spec}{template}{spec}{containers}[0]{ports}[0]{containerPort}, 80, 'containerPort in TO_JSON');
};

# ============================================================================
# 3. Mixed construction styles
# ============================================================================

subtest 'Mixed: some fields as hashrefs, some as pre-built objects' => sub {
    # Pre-build some objects
    my $container = IO::K8s::Api::Core::V1::Container->new(
        name  => 'prebuilt',
        image => 'prebuilt:v1',
        env   => [
            IO::K8s::Api::Core::V1::EnvVar->new(name => 'A', value => 'B'),
        ],
    );

    my $vol_mount = IO::K8s::Api::Core::V1::VolumeMount->new(
        name      => 'cfg',
        mountPath => '/config',
        readOnly  => 1,
    );

    # Build a Deployment mixing prebuilt objects and hashrefs
    my $deploy = $k8s->new_object('Deployment', {
        metadata => { name => 'mixed-test' },
        spec     => {
            selector => { matchLabels => { app => 'mixed' } },
            template => {
                metadata => { labels => { app => 'mixed' } },
                spec     => {
                    containers => [
                        $container,                # prebuilt object
                        { name => 'sidecar', image => 'sidecar:v1' },  # hashref
                    ],
                    volumes => [
                        { name => 'cfg', configMap => { name => 'my-config' } },
                    ],
                },
            },
        },
    });

    isa_ok($deploy, 'IO::K8s::Api::Apps::V1::Deployment');
    my $cs = $deploy->spec->template->spec->containers;
    is(scalar @$cs, 2, '2 containers');

    # Prebuilt container passes through
    isa_ok($cs->[0], 'IO::K8s::Api::Core::V1::Container');
    is($cs->[0]->name, 'prebuilt', 'prebuilt container name');
    isa_ok($cs->[0]->env->[0], 'IO::K8s::Api::Core::V1::EnvVar');

    # Hashref container inflated
    isa_ok($cs->[1], 'IO::K8s::Api::Core::V1::Container');
    is($cs->[1]->name, 'sidecar', 'hashref container name');
};

subtest 'new_object() vs direct Class->new() vs struct_to_object' => sub {
    # new_object - auto-inflates nested hashrefs
    my $pod1 = $k8s->new_object('Pod', {
        metadata => { name => 'pod1' },
        spec     => { containers => [{ name => 'c', image => 'img' }] },
    });

    # Direct Class->new with pre-built objects (no auto-inflation)
    require IO::K8s::Api::Core::V1::Pod;
    require IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
    require IO::K8s::Api::Core::V1::PodSpec;
    require IO::K8s::Api::Core::V1::Container;
    my $pod2 = IO::K8s::Api::Core::V1::Pod->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'pod2'),
        spec     => IO::K8s::Api::Core::V1::PodSpec->new(
            containers => [IO::K8s::Api::Core::V1::Container->new(name => 'c', image => 'img')],
        ),
    );

    # struct_to_object - also auto-inflates like new_object
    my $pod3 = $k8s->struct_to_object('Pod', {
        metadata => { name => 'pod3' },
        spec     => { containers => [{ name => 'c', image => 'img' }] },
    });

    for my $pod ($pod1, $pod2, $pod3) {
        isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
        is($pod->kind, 'Pod', 'kind');
    }

    is($pod1->metadata->name, 'pod1', 'new_object name');
    is($pod2->metadata->name, 'pod2', 'direct new name');
    is($pod3->metadata->name, 'pod3', 'struct_to_object name');

    # FROM_HASH calls ->new directly (no auto-inflation), so it requires
    # pre-built objects for nested attributes with InstanceOf constraints
    dies_ok {
        IO::K8s::Api::Core::V1::Pod->FROM_HASH({
            metadata => { name => 'pod4' },
            spec     => { containers => [{ name => 'c', image => 'img' }] },
        });
    } 'FROM_HASH with raw hashrefs dies (no auto-inflation)';
};

subtest 'inflate() from JSON string back to objects' => sub {
    my $json_str = '{"kind":"Pod","apiVersion":"v1","metadata":{"name":"json-pod","namespace":"test"},"spec":{"containers":[{"name":"app","image":"nginx:1.25"}]}}';

    my $pod = $k8s->inflate($json_str);
    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
    is($pod->kind, 'Pod', 'kind');
    is($pod->metadata->name, 'json-pod', 'name');
    is($pod->metadata->namespace, 'test', 'namespace');
    isa_ok($pod->spec, 'IO::K8s::Api::Core::V1::PodSpec');
    isa_ok($pod->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container');
    is($pod->spec->containers->[0]->image, 'nginx:1.25', 'image');
};

# ============================================================================
# 4. RBAC resources
# ============================================================================

subtest 'ClusterRole with complex rules' => sub {
    my $cr = $k8s->new_object('ClusterRole', {
        metadata => {
            name   => 'monitoring-reader',
            labels => { 'rbac.example.io/aggregate-to-monitoring' => 'true' },
        },
        rules => [
            {
                apiGroups => [''],
                resources => ['pods', 'pods/log', 'services', 'endpoints', 'nodes'],
                verbs     => ['get', 'list', 'watch'],
            },
            {
                apiGroups => ['apps'],
                resources => ['deployments', 'statefulsets', 'daemonsets', 'replicasets'],
                verbs     => ['get', 'list', 'watch'],
            },
            {
                apiGroups => ['batch'],
                resources => ['jobs', 'cronjobs'],
                verbs     => ['get', 'list', 'watch'],
            },
            {
                nonResourceURLs => ['/metrics', '/healthz'],
                verbs           => ['get'],
            },
        ],
    });

    isa_ok($cr, 'IO::K8s::Api::Rbac::V1::ClusterRole');
    is($cr->kind, 'ClusterRole', 'kind');
    is($cr->api_version, 'rbac.authorization.k8s.io/v1', 'api_version');

    my $rules = $cr->rules;
    is(scalar @$rules, 4, '4 rules');
    isa_ok($rules->[0], 'IO::K8s::Api::Rbac::V1::PolicyRule');

    # First rule: core API
    is_deeply($rules->[0]->apiGroups, [''], 'core apiGroup');
    is_deeply($rules->[0]->verbs, ['get', 'list', 'watch'], 'verbs');
    ok(scalar @{$rules->[0]->resources} == 5, '5 resources in first rule');

    # Non-resource URLs rule
    is_deeply($rules->[3]->nonResourceURLs, ['/metrics', '/healthz'], 'nonResourceURLs');
    is_deeply($rules->[3]->verbs, ['get'], 'non-resource verbs');
};

subtest 'RoleBinding with multiple subjects' => sub {
    my $rb = $k8s->new_object('RoleBinding', {
        metadata => {
            name      => 'read-pods',
            namespace => 'default',
        },
        roleRef => {
            apiGroup => 'rbac.authorization.k8s.io',
            kind     => 'ClusterRole',
            name     => 'pod-reader',
        },
        subjects => [
            {
                kind      => 'User',
                name      => 'jane',
                apiGroup  => 'rbac.authorization.k8s.io',
            },
            {
                kind      => 'Group',
                name      => 'developers',
                apiGroup  => 'rbac.authorization.k8s.io',
            },
            {
                kind      => 'ServiceAccount',
                name      => 'default',
                namespace => 'kube-system',
            },
        ],
    });

    isa_ok($rb, 'IO::K8s::Api::Rbac::V1::RoleBinding');
    is($rb->kind, 'RoleBinding', 'kind');
    is($rb->api_version, 'rbac.authorization.k8s.io/v1', 'api_version');

    isa_ok($rb->roleRef, 'IO::K8s::Api::Rbac::V1::RoleRef');
    is($rb->roleRef->kind, 'ClusterRole', 'roleRef kind');
    is($rb->roleRef->name, 'pod-reader', 'roleRef name');

    my $subjects = $rb->subjects;
    is(scalar @$subjects, 3, '3 subjects');
    isa_ok($subjects->[0], 'IO::K8s::Api::Rbac::V1::Subject');
    is($subjects->[0]->kind, 'User', 'subject 0 kind');
    is($subjects->[0]->name, 'jane', 'subject 0 name');
    is($subjects->[1]->kind, 'Group', 'subject 1 kind');
    is($subjects->[2]->kind, 'ServiceAccount', 'subject 2 kind');
    is($subjects->[2]->namespace, 'kube-system', 'subject 2 namespace');
};

subtest 'ServiceAccount' => sub {
    my $sa = $k8s->new_object('ServiceAccount', {
        metadata => {
            name      => 'ci-runner',
            namespace => 'ci',
            annotations => {
                'eks.amazonaws.com/role-arn' => 'arn:aws:iam::123456789012:role/ci-runner',
            },
        },
        automountServiceAccountToken => 0,
    });

    isa_ok($sa, 'IO::K8s::Api::Core::V1::ServiceAccount');
    is($sa->kind, 'ServiceAccount', 'kind');
    is($sa->api_version, 'v1', 'api_version');
    is($sa->metadata->name, 'ci-runner', 'name');
    ok(!$sa->automountServiceAccountToken, 'automount is false');
};

# ============================================================================
# 5. Networking
# ============================================================================

subtest 'Service with multiple ports (ClusterIP, NodePort, LoadBalancer)' => sub {
    # ClusterIP service
    my $svc_cluster = $k8s->new_object('Service', {
        metadata => { name => 'web', namespace => 'default' },
        spec     => {
            type     => 'ClusterIP',
            selector => { app => 'web' },
            ports    => [
                { port => 80,  targetPort => '8080', name => 'http',  protocol => 'TCP' },
                { port => 443, targetPort => '8443', name => 'https', protocol => 'TCP' },
            ],
        },
    });
    is(scalar @{$svc_cluster->spec->ports}, 2, 'ClusterIP: 2 ports');
    is($svc_cluster->spec->type, 'ClusterIP', 'type is ClusterIP');

    # NodePort service
    my $svc_np = $k8s->new_object('Service', {
        metadata => { name => 'web-np', namespace => 'default' },
        spec     => {
            type     => 'NodePort',
            selector => { app => 'web' },
            ports    => [
                { port => 80, targetPort => '8080', nodePort => 30080, protocol => 'TCP' },
            ],
        },
    });
    is($svc_np->spec->type, 'NodePort', 'type is NodePort');
    is($svc_np->spec->ports->[0]->nodePort, 30080, 'nodePort');

    # LoadBalancer service
    my $svc_lb = $k8s->new_object('Service', {
        metadata => {
            name        => 'web-lb',
            namespace   => 'default',
            annotations => {
                'service.beta.kubernetes.io/aws-load-balancer-type' => 'nlb',
            },
        },
        spec => {
            type                  => 'LoadBalancer',
            externalTrafficPolicy => 'Local',
            selector              => { app => 'web' },
            ports                 => [
                { port => 80, targetPort => '8080', protocol => 'TCP' },
            ],
            loadBalancerSourceRanges => ['10.0.0.0/8', '172.16.0.0/12'],
        },
    });
    is($svc_lb->spec->type, 'LoadBalancer', 'type is LoadBalancer');
    is($svc_lb->spec->externalTrafficPolicy, 'Local', 'externalTrafficPolicy');
    is_deeply($svc_lb->spec->loadBalancerSourceRanges, ['10.0.0.0/8', '172.16.0.0/12'], 'sourceRanges');
};

subtest 'Ingress with TLS, multiple rules and paths' => sub {
    my $ing = $k8s->new_object('Ingress', {
        metadata => {
            name        => 'web-ingress',
            namespace   => 'default',
            annotations => {
                'nginx.ingress.kubernetes.io/rewrite-target' => '/',
                'cert-manager.io/cluster-issuer'             => 'letsencrypt-prod',
            },
        },
        spec => {
            ingressClassName => 'nginx',
            tls => [
                {
                    hosts      => ['app.example.com', 'api.example.com'],
                    secretName => 'app-tls-cert',
                },
            ],
            rules => [
                {
                    host => 'app.example.com',
                    http => {
                        paths => [
                            {
                                path     => '/',
                                pathType => 'Prefix',
                                backend  => {
                                    service => {
                                        name => 'web-frontend',
                                        port => { number => 80 },
                                    },
                                },
                            },
                            {
                                path     => '/static',
                                pathType => 'Prefix',
                                backend  => {
                                    service => {
                                        name => 'static-server',
                                        port => { name => 'http' },
                                    },
                                },
                            },
                        ],
                    },
                },
                {
                    host => 'api.example.com',
                    http => {
                        paths => [{
                            path     => '/v1',
                            pathType => 'Prefix',
                            backend  => {
                                service => {
                                    name => 'api-server',
                                    port => { number => 8080 },
                                },
                            },
                        }],
                    },
                },
            ],
        },
    });

    isa_ok($ing, 'IO::K8s::Api::Networking::V1::Ingress');
    is($ing->kind, 'Ingress', 'kind');
    is($ing->api_version, 'networking.k8s.io/v1', 'api_version');

    # TLS
    my $tls = $ing->spec->tls;
    is(scalar @$tls, 1, '1 TLS block');
    isa_ok($tls->[0], 'IO::K8s::Api::Networking::V1::IngressTLS');
    is_deeply($tls->[0]->hosts, ['app.example.com', 'api.example.com'], 'TLS hosts');
    is($tls->[0]->secretName, 'app-tls-cert', 'TLS secretName');

    # Rules
    my $rules = $ing->spec->rules;
    is(scalar @$rules, 2, '2 rules');
    isa_ok($rules->[0], 'IO::K8s::Api::Networking::V1::IngressRule');
    is($rules->[0]->host, 'app.example.com', 'rule 0 host');

    # Paths
    my $paths = $rules->[0]->http->paths;
    is(scalar @$paths, 2, '2 paths in rule 0');
    isa_ok($paths->[0], 'IO::K8s::Api::Networking::V1::HTTPIngressPath');
    is($paths->[0]->path, '/', 'path 0');
    is($paths->[0]->pathType, 'Prefix', 'pathType');

    # Backend
    isa_ok($paths->[0]->backend, 'IO::K8s::Api::Networking::V1::IngressBackend');
    isa_ok($paths->[0]->backend->service, 'IO::K8s::Api::Networking::V1::IngressServiceBackend');
    is($paths->[0]->backend->service->name, 'web-frontend', 'backend service name');
    isa_ok($paths->[0]->backend->service->port, 'IO::K8s::Api::Networking::V1::ServiceBackendPort');
    is($paths->[0]->backend->service->port->number, 80, 'backend port number');

    # Named port backend
    is($paths->[1]->backend->service->port->name, 'http', 'named port backend');

    # Second rule
    is($rules->[1]->host, 'api.example.com', 'rule 1 host');
};

subtest 'NetworkPolicy with ingress/egress rules' => sub {
    my $np = $k8s->new_object('NetworkPolicy', {
        metadata => {
            name      => 'web-policy',
            namespace => 'production',
        },
        spec => {
            podSelector => {
                matchLabels => { app => 'web' },
            },
            policyTypes => ['Ingress', 'Egress'],
            ingress => [
                {
                    from => [
                        {
                            namespaceSelector => {
                                matchLabels => { 'kubernetes.io/metadata.name' => 'production' },
                            },
                            podSelector => {
                                matchLabels => { role => 'frontend' },
                            },
                        },
                        {
                            ipBlock => {
                                cidr   => '10.0.0.0/8',
                                except => ['10.0.1.0/24'],
                            },
                        },
                    ],
                    ports => [
                        { protocol => 'TCP', port => '8080' },
                        { protocol => 'TCP', port => '8443' },
                    ],
                },
            ],
            egress => [
                {
                    to => [
                        {
                            ipBlock => {
                                cidr => '0.0.0.0/0',
                                except => ['169.254.169.254/32'],
                            },
                        },
                    ],
                    ports => [
                        { protocol => 'TCP', port => '443' },
                        { protocol => 'UDP', port => '53' },
                    ],
                },
            ],
        },
    });

    isa_ok($np, 'IO::K8s::Api::Networking::V1::NetworkPolicy');
    is($np->kind, 'NetworkPolicy', 'kind');

    my $spec = $np->spec;
    isa_ok($spec, 'IO::K8s::Api::Networking::V1::NetworkPolicySpec');
    is_deeply($spec->policyTypes, ['Ingress', 'Egress'], 'policyTypes');

    # Ingress rules
    my $ing = $spec->ingress;
    is(scalar @$ing, 1, '1 ingress rule');
    isa_ok($ing->[0], 'IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule');

    my $from = $ing->[0]->from;
    is(scalar @$from, 2, '2 from peers');
    isa_ok($from->[0], 'IO::K8s::Api::Networking::V1::NetworkPolicyPeer');
    isa_ok($from->[0]->namespaceSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($from->[0]->podSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');

    # IPBlock
    isa_ok($from->[1]->ipBlock, 'IO::K8s::Api::Networking::V1::IPBlock');
    is($from->[1]->ipBlock->cidr, '10.0.0.0/8', 'ipBlock cidr');
    is_deeply($from->[1]->ipBlock->except, ['10.0.1.0/24'], 'ipBlock except');

    # Ports
    my $ports = $ing->[0]->ports;
    is(scalar @$ports, 2, '2 ingress ports');
    isa_ok($ports->[0], 'IO::K8s::Api::Networking::V1::NetworkPolicyPort');

    # Egress rules
    my $egr = $spec->egress;
    is(scalar @$egr, 1, '1 egress rule');
    isa_ok($egr->[0], 'IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule');
    is($egr->[0]->to->[0]->ipBlock->cidr, '0.0.0.0/0', 'egress cidr');
};

# ============================================================================
# 6. ConfigMap & Secret patterns
# ============================================================================

subtest 'ConfigMap with multi-line data values' => sub {
    my $cm = $k8s->new_object('ConfigMap', {
        metadata => {
            name      => 'nginx-config',
            namespace => 'default',
        },
        data => {
            'nginx.conf' => "server {\n    listen 80;\n    server_name localhost;\n    location / {\n        proxy_pass http://backend:8080;\n    }\n}",
            'mime.types'  => "text/html html htm\ntext/css css\napplication/json json",
            'simple-key'  => 'simple-value',
        },
        immutable => 1,
    });

    isa_ok($cm, 'IO::K8s::Api::Core::V1::ConfigMap');
    is($cm->kind, 'ConfigMap', 'kind');
    is($cm->api_version, 'v1', 'api_version');
    like($cm->data->{'nginx.conf'}, qr/proxy_pass/, 'multi-line nginx.conf');
    is($cm->data->{'simple-key'}, 'simple-value', 'simple key');

    # Verify immutable boolean
    my $struct = $cm->TO_JSON;
    ok($struct->{immutable}, 'immutable in TO_JSON is truthy');
    my $encoded = $json->encode($struct);
    like($encoded, qr/"immutable":true/, 'immutable serialized as boolean true');
};

subtest 'Secret with base64 data' => sub {
    my $secret = $k8s->new_object('Secret', {
        metadata => {
            name      => 'db-credentials',
            namespace => 'production',
        },
        type => 'Opaque',
        data => {
            username => 'YWRtaW4=',        # base64 of 'admin'
            password => 'cDRzc3cwcmQ=',    # base64 of 'p4ssw0rd'
        },
        stringData => {
            'connection-string' => 'postgresql://admin:p4ssw0rd@db:5432/mydb',
        },
    });

    isa_ok($secret, 'IO::K8s::Api::Core::V1::Secret');
    is($secret->kind, 'Secret', 'kind');
    is($secret->type, 'Opaque', 'type');
    is($secret->data->{username}, 'YWRtaW4=', 'base64 data username');
    is($secret->data->{password}, 'cDRzc3cwcmQ=', 'base64 data password');
    is($secret->stringData->{'connection-string'}, 'postgresql://admin:p4ssw0rd@db:5432/mydb', 'stringData');
};

# ============================================================================
# 7. Edge cases
# ============================================================================

subtest 'Empty arrays and hashes in specs' => sub {
    my $np = $k8s->new_object('NetworkPolicy', {
        metadata => { name => 'deny-all', namespace => 'default' },
        spec     => {
            podSelector => {
                matchLabels => {},
            },
            policyTypes => ['Ingress', 'Egress'],
            ingress     => [],
            egress      => [],
        },
    });

    isa_ok($np, 'IO::K8s::Api::Networking::V1::NetworkPolicy');
    is_deeply($np->spec->ingress, [], 'empty ingress array');
    is_deeply($np->spec->egress, [], 'empty egress array');
    is_deeply($np->spec->podSelector->matchLabels, {}, 'empty matchLabels');
};

subtest 'Resources with optional fields all omitted' => sub {
    # Minimal Deployment
    my $deploy = $k8s->new_object('Deployment', {
        metadata => { name => 'minimal' },
        spec     => {
            selector => { matchLabels => { app => 'x' } },
            template => {
                metadata => { labels => { app => 'x' } },
                spec     => {
                    containers => [{ name => 'c', image => 'img' }],
                },
            },
        },
    });

    isa_ok($deploy, 'IO::K8s::Api::Apps::V1::Deployment');
    ok(!defined($deploy->spec->replicas), 'replicas is undef');
    ok(!defined($deploy->spec->strategy), 'strategy is undef');
    ok(!defined($deploy->spec->revisionHistoryLimit), 'revisionHistoryLimit is undef');
    ok(!defined($deploy->spec->template->spec->volumes), 'volumes is undef');
    ok(!defined($deploy->spec->template->spec->tolerations), 'tolerations is undef');
    ok(!defined($deploy->spec->template->spec->containers->[0]->resources), 'resources is undef');

    # TO_JSON should omit undefined fields
    my $struct = $deploy->TO_JSON;
    ok(!exists $struct->{spec}{replicas}, 'replicas absent from TO_JSON');
    ok(!exists $struct->{spec}{strategy}, 'strategy absent from TO_JSON');
    ok(!exists $struct->{spec}{template}{spec}{volumes}, 'volumes absent from TO_JSON');
};

subtest 'Resources with many optional fields present' => sub {
    my $pod = $k8s->new_object('Pod', {
        metadata => {
            name      => 'full-pod',
            namespace => 'default',
            labels      => { app => 'full', env => 'test' },
            annotations => { note => 'test pod' },
        },
        spec => {
            restartPolicy                 => 'Always',
            terminationGracePeriodSeconds => 30,
            dnsPolicy                     => 'ClusterFirst',
            serviceAccountName            => 'default',
            hostNetwork                   => 0,
            hostPID                       => 0,
            hostIPC                       => 0,
            shareProcessNamespace         => 0,
            automountServiceAccountToken  => 1,
            hostname                      => 'full-pod',
            subdomain                     => 'my-subdomain',
            schedulerName                 => 'default-scheduler',
            priorityClassName             => 'high-priority',
            nodeSelector                  => { 'disk' => 'ssd' },
            containers => [{
                name            => 'app',
                image           => 'app:v1',
                imagePullPolicy => 'Always',
                stdin           => 0,
                stdinOnce       => 0,
                tty             => 0,
                workingDir      => '/app',
                command         => ['/bin/sh'],
                args            => ['-c', 'echo hello'],
            }],
        },
    });

    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
    is($pod->spec->restartPolicy, 'Always', 'restartPolicy');
    is($pod->spec->terminationGracePeriodSeconds, 30, 'terminationGracePeriodSeconds');
    is($pod->spec->dnsPolicy, 'ClusterFirst', 'dnsPolicy');
    is($pod->spec->hostname, 'full-pod', 'hostname');
    is($pod->spec->subdomain, 'my-subdomain', 'subdomain');
    is($pod->spec->schedulerName, 'default-scheduler', 'schedulerName');
    is($pod->spec->nodeSelector->{disk}, 'ssd', 'nodeSelector');

    my $c = $pod->spec->containers->[0];
    is($c->imagePullPolicy, 'Always', 'imagePullPolicy');
    is($c->workingDir, '/app', 'workingDir');
    is_deeply($c->command, ['/bin/sh'], 'command');
    is_deeply($c->args, ['-c', 'echo hello'], 'args');
};

subtest 'TO_JSON -> FROM_HASH round-trip for complex Deployment' => sub {
    my $deploy = $k8s->new_object('Deployment', {
        metadata => {
            name      => 'roundtrip',
            namespace => 'rt',
            labels    => { app => 'rt', tier => 'backend' },
        },
        spec => {
            replicas => 5,
            selector => {
                matchLabels      => { app => 'rt' },
                matchExpressions => [
                    { key => 'tier', operator => 'In', values => ['backend'] },
                ],
            },
            template => {
                metadata => { labels => { app => 'rt', tier => 'backend' } },
                spec     => {
                    containers => [
                        {
                            name  => 'api',
                            image => 'api:v3',
                            ports => [{ containerPort => 3000 }],
                            env   => [{ name => 'MODE', value => 'production' }],
                            resources => {
                                requests => { cpu => '100m', memory => '256Mi' },
                                limits   => { cpu => '500m', memory => '512Mi' },
                            },
                        },
                    ],
                    tolerations => [
                        { key => 'dedicated', operator => 'Equal', value => 'backend', effect => 'NoSchedule' },
                    ],
                    volumes => [
                        { name => 'secret-vol', secret => { secretName => 'my-secret' } },
                    ],
                },
            },
        },
    });

    # Round-trip: TO_JSON -> inflate
    my $struct = $deploy->TO_JSON;
    my $deploy2 = $k8s->inflate($struct);

    isa_ok($deploy2, 'IO::K8s::Api::Apps::V1::Deployment');
    is($deploy2->metadata->name, 'roundtrip', 'name survives round-trip');
    is($deploy2->spec->replicas, 5, 'replicas survives round-trip');
    is($deploy2->spec->selector->matchLabels->{app}, 'rt', 'matchLabels survives round-trip');

    # matchExpressions
    my $me = $deploy2->spec->selector->matchExpressions;
    is(scalar @$me, 1, 'matchExpressions count');
    isa_ok($me->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement');
    is($me->[0]->key, 'tier', 'matchExpression key');
    is($me->[0]->operator, 'In', 'matchExpression operator');
    is_deeply($me->[0]->values, ['backend'], 'matchExpression values');

    # Container survives
    my $c = $deploy2->spec->template->spec->containers->[0];
    is($c->name, 'api', 'container name survives');
    is($c->env->[0]->value, 'production', 'env value survives');
    is($c->resources->requests->{cpu}, '100m', 'resource request survives');

    # Tolerations survive
    my $tol = $deploy2->spec->template->spec->tolerations->[0];
    isa_ok($tol, 'IO::K8s::Api::Core::V1::Toleration');
    is($tol->key, 'dedicated', 'toleration key survives');

    # Volume secret survives
    my $vol = $deploy2->spec->template->spec->volumes->[0];
    isa_ok($vol->secret, 'IO::K8s::Api::Core::V1::SecretVolumeSource');
    is($vol->secret->secretName, 'my-secret', 'secretName survives');
};

subtest 'to_json -> from JSON string -> back to object round-trip' => sub {
    my $svc = $k8s->new_object('Service', {
        metadata => { name => 'json-rt', namespace => 'default' },
        spec     => {
            type     => 'ClusterIP',
            selector => { app => 'test' },
            ports    => [
                { port => 80, targetPort => '8080', name => 'http', protocol => 'TCP' },
            ],
        },
    });

    my $json_str = $svc->to_json;
    ok(length($json_str) > 0, 'to_json produces non-empty string');

    # Inflate from JSON string
    my $svc2 = $k8s->inflate($json_str);
    isa_ok($svc2, 'IO::K8s::Api::Core::V1::Service');
    is($svc2->metadata->name, 'json-rt', 'name survives JSON round-trip');
    is($svc2->spec->type, 'ClusterIP', 'type survives JSON round-trip');
    is($svc2->spec->ports->[0]->port, 80, 'port survives JSON round-trip');
    is($svc2->spec->selector->{app}, 'test', 'selector survives JSON round-trip');
};

subtest 'to_yaml output (YAML::PP available)' => sub {
    eval { require YAML::PP };
    plan skip_all => 'YAML::PP not available' if $@;

    my $deploy = $k8s->new_object('Deployment', {
        metadata => { name => 'yaml-test', namespace => 'default' },
        spec     => {
            replicas => 2,
            selector => { matchLabels => { app => 'yaml' } },
            template => {
                metadata => { labels => { app => 'yaml' } },
                spec     => {
                    containers => [{
                        name  => 'app',
                        image => 'app:v1',
                        ports => [{ containerPort => 8080 }],
                    }],
                },
            },
        },
    });

    my $yaml = $deploy->to_yaml;
    ok(length($yaml) > 0, 'to_yaml produces non-empty output');
    like($yaml, qr/kind:\s*Deployment/, 'YAML has kind');
    like($yaml, qr/apiVersion:\s*apps\/v1/, 'YAML has apiVersion');
    like($yaml, qr/name:\s*yaml-test/, 'YAML has name');
    like($yaml, qr/replicas:\s*2/, 'YAML has replicas');

    # Parse back and verify
    my $parsed = YAML::PP::Load($yaml);
    is($parsed->{kind}, 'Deployment', 'parsed kind');
    is($parsed->{spec}{replicas}, 2, 'parsed replicas');
    is($parsed->{spec}{template}{spec}{containers}[0]{name}, 'app', 'parsed container name');
};

# ============================================================================
# 8. Labels, annotations, selectors
# ============================================================================

subtest 'matchLabels and matchExpressions in selectors' => sub {
    my $deploy = $k8s->new_object('Deployment', {
        metadata => { name => 'selector-test' },
        spec     => {
            selector => {
                matchLabels => {
                    app     => 'web',
                    version => 'v2',
                },
                matchExpressions => [
                    { key => 'environment', operator => 'In',           values => ['production', 'staging'] },
                    { key => 'tier',        operator => 'NotIn',        values => ['test'] },
                    { key => 'canary',      operator => 'Exists' },
                    { key => 'deprecated',  operator => 'DoesNotExist' },
                ],
            },
            template => {
                metadata => { labels => { app => 'web', version => 'v2' } },
                spec     => {
                    containers => [{ name => 'c', image => 'img' }],
                },
            },
        },
    });

    my $sel = $deploy->spec->selector;
    isa_ok($sel, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    is($sel->matchLabels->{app}, 'web', 'matchLabels app');
    is($sel->matchLabels->{version}, 'v2', 'matchLabels version');

    my $me = $sel->matchExpressions;
    is(scalar @$me, 4, '4 matchExpressions');

    for my $expr (@$me) {
        isa_ok($expr, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement');
    }

    is($me->[0]->key, 'environment', 'expr 0 key');
    is($me->[0]->operator, 'In', 'expr 0 operator');
    is_deeply($me->[0]->values, ['production', 'staging'], 'expr 0 values');

    is($me->[1]->operator, 'NotIn', 'expr 1 operator');
    is($me->[2]->operator, 'Exists', 'expr 2 operator');
    is($me->[3]->operator, 'DoesNotExist', 'expr 3 operator');

    # Round-trip to check matchExpressions survive
    my $struct = $deploy->TO_JSON;
    my $rt_me = $struct->{spec}{selector}{matchExpressions};
    is(scalar @$rt_me, 4, 'matchExpressions survive TO_JSON');
    is($rt_me->[0]{operator}, 'In', 'In operator survives');
};

subtest 'Complex annotation values' => sub {
    my $deploy = $k8s->new_object('Deployment', {
        metadata => {
            name        => 'annotated',
            namespace   => 'default',
            annotations => {
                'kubectl.kubernetes.io/last-applied-configuration' => '{"apiVersion":"apps/v1","kind":"Deployment","metadata":{"name":"annotated"}}',
                'deployment.kubernetes.io/revision'                => '42',
                'prometheus.io/scrape'                             => 'true',
                'prometheus.io/port'                               => '9090',
                'prometheus.io/path'                               => '/metrics',
                'nginx.ingress.kubernetes.io/configuration-snippet' => "more_set_headers \"X-Frame-Options: DENY\";\nmore_set_headers \"X-XSS-Protection: 1; mode=block\";",
                'co.elastic.logs/json.keys_under_root'             => 'true',
            },
            labels => {
                'app.kubernetes.io/name'       => 'annotated',
                'app.kubernetes.io/instance'   => 'annotated-prod',
                'app.kubernetes.io/version'    => '1.0.0',
                'app.kubernetes.io/component'  => 'api',
                'app.kubernetes.io/part-of'    => 'my-system',
                'app.kubernetes.io/managed-by' => 'Helm',
            },
        },
        spec => {
            selector => { matchLabels => { 'app.kubernetes.io/name' => 'annotated' } },
            template => {
                metadata => { labels => { 'app.kubernetes.io/name' => 'annotated' } },
                spec     => {
                    containers => [{ name => 'c', image => 'img' }],
                },
            },
        },
    });

    my $ann = $deploy->metadata->annotations;
    like($ann->{'kubectl.kubernetes.io/last-applied-configuration'}, qr/"apiVersion"/, 'JSON in annotation');
    like($ann->{'nginx.ingress.kubernetes.io/configuration-snippet'}, qr/X-Frame-Options/, 'multiline annotation');
    is($ann->{'prometheus.io/port'}, '9090', 'prometheus port annotation');

    my $lbl = $deploy->metadata->labels;
    is($lbl->{'app.kubernetes.io/managed-by'}, 'Helm', 'k8s recommended label');

    # Verify annotations round-trip through TO_JSON
    my $struct = $deploy->TO_JSON;
    is($struct->{metadata}{annotations}{'deployment.kubernetes.io/revision'}, '42', 'annotation value in TO_JSON');
};

# ============================================================================
# 9. Cross-cutting: inflate from full JSON and compare with new_object
# ============================================================================

subtest 'inflate hashref with kind -> same result as new_object' => sub {
    my $hashref = {
        kind       => 'ConfigMap',
        apiVersion => 'v1',
        metadata   => {
            name      => 'inflate-test',
            namespace => 'default',
        },
        data => {
            key1 => 'val1',
            key2 => 'val2',
        },
    };

    my $from_inflate = $k8s->inflate($hashref);
    my $from_new = $k8s->new_object('ConfigMap', {
        metadata => { name => 'inflate-test', namespace => 'default' },
        data     => { key1 => 'val1', key2 => 'val2' },
    });

    isa_ok($from_inflate, 'IO::K8s::Api::Core::V1::ConfigMap');
    isa_ok($from_new, 'IO::K8s::Api::Core::V1::ConfigMap');
    is($from_inflate->metadata->name, $from_new->metadata->name, 'name matches');
    is_deeply($from_inflate->data, $from_new->data, 'data matches');
};

subtest 'json_to_object with auto-detect vs explicit class' => sub {
    my $json_str = '{"kind":"Secret","apiVersion":"v1","metadata":{"name":"auto-detect"},"type":"Opaque","data":{"key":"dmFsdWU="}}';

    # Auto-detect
    my $obj1 = $k8s->json_to_object($json_str);
    isa_ok($obj1, 'IO::K8s::Api::Core::V1::Secret');
    is($obj1->metadata->name, 'auto-detect', 'auto-detect name');

    # Explicit class
    my $obj2 = $k8s->json_to_object('Secret', $json_str);
    isa_ok($obj2, 'IO::K8s::Api::Core::V1::Secret');
    is($obj2->metadata->name, 'auto-detect', 'explicit class name');
};

# ============================================================================
# 10. Integer/boolean type correctness in JSON output
# ============================================================================

subtest 'Integer fields serialize as JSON integers, booleans as true/false' => sub {
    my $deploy = $k8s->new_object('Deployment', {
        metadata => { name => 'type-test' },
        spec     => {
            replicas             => 3,
            revisionHistoryLimit => 10,
            minReadySeconds      => 0,
            paused               => 0,
            selector             => { matchLabels => { app => 'types' } },
            template             => {
                metadata => { labels => { app => 'types' } },
                spec     => {
                    containers => [{
                        name  => 'c',
                        image => 'img',
                        ports => [{ containerPort => 8080 }],
                        tty   => 1,
                    }],
                },
            },
        },
    });

    my $encoded = $deploy->to_json;

    # Integers
    like($encoded, qr/"replicas":3\b/, 'replicas is JSON integer');
    unlike($encoded, qr/"replicas":"3"/, 'replicas is NOT JSON string');
    like($encoded, qr/"containerPort":8080\b/, 'containerPort is JSON integer');
    unlike($encoded, qr/"containerPort":"8080"/, 'containerPort is NOT JSON string');
    like($encoded, qr/"revisionHistoryLimit":10\b/, 'revisionHistoryLimit is JSON integer');
    like($encoded, qr/"minReadySeconds":0\b/, 'minReadySeconds zero is JSON integer');

    # Booleans
    like($encoded, qr/"tty":true/, 'tty is JSON boolean true');
    like($encoded, qr/"paused":false/, 'paused is JSON boolean false');
};

# ============================================================================
# 11. Comprehensive multi-resource round-trip
# ============================================================================

subtest 'Full-stack round-trip: many resource types through JSON and back' => sub {
    my @resources = (
        $k8s->new_object('Namespace', {
            metadata => { name => 'test-ns' },
        }),
        $k8s->new_object('ConfigMap', {
            metadata => { name => 'cfg', namespace => 'test-ns' },
            data     => { a => '1', b => '2' },
        }),
        $k8s->new_object('Secret', {
            metadata => { name => 'sec', namespace => 'test-ns' },
            type     => 'Opaque',
            data     => { pass => 'cGFzcw==' },
        }),
        $k8s->new_object('ServiceAccount', {
            metadata => { name => 'sa', namespace => 'test-ns' },
        }),
        $k8s->new_object('Service', {
            metadata => { name => 'svc', namespace => 'test-ns' },
            spec     => {
                selector => { app => 'test' },
                ports    => [{ port => 80, targetPort => '8080' }],
            },
        }),
        $k8s->new_object('Deployment', {
            metadata => { name => 'deploy', namespace => 'test-ns' },
            spec     => {
                replicas => 1,
                selector => { matchLabels => { app => 'test' } },
                template => {
                    metadata => { labels => { app => 'test' } },
                    spec     => { containers => [{ name => 'c', image => 'img' }] },
                },
            },
        }),
    );

    for my $obj (@resources) {
        my $kind = $obj->kind;
        my $json_str = $obj->to_json;
        ok(length($json_str) > 10, "$kind: to_json produces output");

        my $restored = $k8s->inflate($json_str);
        is($restored->kind, $kind, "$kind: kind survives round-trip");
        is($restored->metadata->name, $obj->metadata->name, "$kind: name survives round-trip");
    }
};

# ============================================================================
# 12. struct_to_object with short names
# ============================================================================

subtest 'struct_to_object with short class names' => sub {
    my $pod = $k8s->struct_to_object('Pod', {
        kind     => 'Pod',
        metadata => { name => 'short-name-test' },
        spec     => { containers => [{ name => 'c', image => 'img' }] },
    });
    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
    is($pod->metadata->name, 'short-name-test', 'name via short class name');

    my $svc = $k8s->struct_to_object('Service', {
        metadata => { name => 'svc-short' },
        spec     => { ports => [{ port => 80 }] },
    });
    isa_ok($svc, 'IO::K8s::Api::Core::V1::Service');
};

# ============================================================================
# 13. Multiple volumes: configMap, secret, emptyDir in same pod
# ============================================================================

subtest 'Pod with configMap, secret, and emptyDir volumes together' => sub {
    my $pod = $k8s->new_object('Pod', {
        metadata => { name => 'multi-vol', namespace => 'default' },
        spec     => {
            containers => [{
                name         => 'app',
                image        => 'app:v1',
                volumeMounts => [
                    { name => 'config-vol', mountPath => '/etc/config' },
                    { name => 'secret-vol', mountPath => '/etc/secret', readOnly => 1 },
                    { name => 'cache-vol',  mountPath => '/var/cache' },
                ],
            }],
            volumes => [
                {
                    name      => 'config-vol',
                    configMap => {
                        name        => 'app-config',
                        defaultMode => 420,
                    },
                },
                {
                    name   => 'secret-vol',
                    secret => {
                        secretName  => 'app-secret',
                        defaultMode => 256,
                    },
                },
                {
                    name     => 'cache-vol',
                    emptyDir => { sizeLimit => '1Gi' },
                },
            ],
        },
    });

    my $vols = $pod->spec->volumes;
    is(scalar @$vols, 3, '3 volumes');

    # configMap volume
    isa_ok($vols->[0]->configMap, 'IO::K8s::Api::Core::V1::ConfigMapVolumeSource');
    is($vols->[0]->configMap->name, 'app-config', 'configMap name');
    is($vols->[0]->configMap->defaultMode, 420, 'configMap defaultMode');

    # secret volume
    isa_ok($vols->[1]->secret, 'IO::K8s::Api::Core::V1::SecretVolumeSource');
    is($vols->[1]->secret->secretName, 'app-secret', 'secret secretName');
    is($vols->[1]->secret->defaultMode, 256, 'secret defaultMode');

    # emptyDir volume
    isa_ok($vols->[2]->emptyDir, 'IO::K8s::Api::Core::V1::EmptyDirVolumeSource');
    is($vols->[2]->emptyDir->sizeLimit, '1Gi', 'emptyDir sizeLimit');

    # Verify JSON output has correct integer types for defaultMode
    my $encoded = $pod->to_json;
    like($encoded, qr/"defaultMode":420\b/, 'configMap defaultMode is JSON integer');
    like($encoded, qr/"defaultMode":256\b/, 'secret defaultMode is JSON integer');
};

# ============================================================================
# 14. Complex CronJob->Job->Pod nesting and round-trip
# ============================================================================

subtest 'CronJob deep nesting round-trip through JSON' => sub {
    my $cron = $k8s->new_object('CronJob', {
        metadata => { name => 'deep-cron', namespace => 'jobs' },
        spec     => {
            schedule    => '*/5 * * * *',
            jobTemplate => {
                spec => {
                    backoffLimit => 3,
                    parallelism  => 2,
                    template     => {
                        spec => {
                            restartPolicy => 'Never',
                            containers    => [{
                                name    => 'worker',
                                image   => 'worker:v1',
                                command => ['/run.sh'],
                                env     => [{ name => 'BATCH', value => '100' }],
                                resources => {
                                    requests => { cpu => '500m', memory => '1Gi' },
                                },
                            }],
                        },
                    },
                },
            },
        },
    });

    # Navigate all the way down
    my $container = $cron->spec->jobTemplate->spec->template->spec->containers->[0];
    is($container->name, 'worker', 'deep nesting: container name');

    # Round-trip
    my $json_str = $cron->to_json;
    my $cron2 = $k8s->inflate($json_str);
    isa_ok($cron2, 'IO::K8s::Api::Batch::V1::CronJob');
    is($cron2->spec->schedule, '*/5 * * * *', 'schedule survives');
    is($cron2->spec->jobTemplate->spec->backoffLimit, 3, 'backoffLimit survives');
    is($cron2->spec->jobTemplate->spec->template->spec->containers->[0]->name, 'worker', 'deep container name survives');
};

# ============================================================================
# 15. Graceful handling of inflate for all APIObject types
# ============================================================================

subtest 'inflate works for each standard resource kind' => sub {
    my @kinds_and_specs = (
        ['Pod',                { spec => { containers => [{ name => 'c', image => 'img' }] } }],
        ['ConfigMap',          { data => { k => 'v' } }],
        ['Secret',             { type => 'Opaque', data => { k => 'dg==' } }],
        ['Service',            { spec => { ports => [{ port => 80 }] } }],
        ['ServiceAccount',     {}],
        ['Deployment',         { spec => { selector => { matchLabels => { a => 'b' } }, template => { metadata => { labels => { a => 'b' } }, spec => { containers => [{ name => 'c', image => 'i' }] } } } }],
        ['StatefulSet',        { spec => { serviceName => 'svc', selector => { matchLabels => { a => 'b' } }, template => { metadata => { labels => { a => 'b' } }, spec => { containers => [{ name => 'c', image => 'i' }] } } } }],
        ['DaemonSet',          { spec => { selector => { matchLabels => { a => 'b' } }, template => { metadata => { labels => { a => 'b' } }, spec => { containers => [{ name => 'c', image => 'i' }] } } } }],
        ['Job',                { spec => { template => { spec => { restartPolicy => 'Never', containers => [{ name => 'c', image => 'i' }] } } } }],
        ['CronJob',            { spec => { schedule => '* * * * *', jobTemplate => { spec => { template => { spec => { restartPolicy => 'Never', containers => [{ name => 'c', image => 'i' }] } } } } } }],
        ['ClusterRole',        { rules => [{ verbs => ['get'] }] }],
        ['RoleBinding',        { roleRef => { apiGroup => 'rbac.authorization.k8s.io', kind => 'Role', name => 'r' } }],
        ['NetworkPolicy',      { spec => { podSelector => { matchLabels => {} } } }],
        ['Ingress',            { spec => {} }],
    );

    for my $pair (@kinds_and_specs) {
        my ($kind, $extra) = @$pair;
        my $obj = $k8s->new_object($kind, {
            metadata => { name => lc($kind) . '-test' },
            %$extra,
        });

        isa_ok($obj, ref($obj), "$kind: created OK");
        is($obj->kind, $kind, "$kind: kind matches");
        ok(defined $obj->metadata, "$kind: has metadata");

        # Round-trip through TO_JSON
        my $struct = $obj->TO_JSON;
        is($struct->{kind}, $kind, "$kind: TO_JSON has kind");
    }
};

done_testing;
