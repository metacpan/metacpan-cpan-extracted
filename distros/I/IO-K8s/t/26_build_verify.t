#!/usr/bin/env perl
# Build-and-verify tests for IO::K8s
#
# These tests construct Kubernetes manifests using the IO::K8s Perl API
# and verify that the resulting JSON/YAML output matches what kubectl
# and real-world tooling would produce. This is the "andersrum" complement
# to t/25_real_world.t which parses YAML into objects.
#
# Each test builds a manifest in Perl, exports via TO_JSON, and checks
# that every field matches the expected Kubernetes-canonical structure.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;

use IO::K8s;
use JSON::MaybeXS;

my $k8s = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1, convert_blessed => 1);

# Helper: build object, export, compare against expected structure
sub build_and_verify {
    my ($kind, $params, $expected, $description) = @_;

    my $obj = $k8s->new_object($kind, $params);
    ok(defined $obj, "$description: object created");

    my $got = $obj->TO_JSON;
    ok(ref $got eq 'HASH', "$description: TO_JSON returns hashref");

    # Check apiVersion and kind are set correctly
    ok(exists $got->{apiVersion}, "$description: apiVersion present");
    is($got->{kind}, $kind, "$description: kind is $kind");

    # Deep comparison of the full structure
    cmp_deeply($got, superhashof($expected), "$description: output matches expected");

    return ($obj, $got);
}

# ============================================================================
# 1. NGINX Deployment — the classic "kubectl create deployment nginx"
# ============================================================================

subtest 'NGINX Deployment (kubectl create deployment)' => sub {
    my ($obj, $got) = build_and_verify('Deployment', {
        metadata => {
            name      => 'nginx',
            namespace => 'default',
            labels    => { app => 'nginx' },
        },
        spec => {
            replicas => 1,
            selector => {
                matchLabels => { app => 'nginx' },
            },
            template => {
                metadata => {
                    labels => { app => 'nginx' },
                },
                spec => {
                    containers => [{
                        name  => 'nginx',
                        image => 'nginx:1.27',
                        ports => [{ containerPort => 80 }],
                    }],
                },
            },
        },
    }, {
        apiVersion => 'apps/v1',
        kind       => 'Deployment',
        metadata   => superhashof({
            name      => 'nginx',
            namespace => 'default',
            labels    => { app => 'nginx' },
        }),
        spec => superhashof({
            replicas => 1,
            selector => superhashof({
                matchLabels => { app => 'nginx' },
            }),
            template => superhashof({
                metadata => superhashof({
                    labels => { app => 'nginx' },
                }),
                spec => superhashof({
                    containers => [superhashof({
                        name  => 'nginx',
                        image => 'nginx:1.27',
                        ports => [superhashof({ containerPort => 80 })],
                    })],
                }),
            }),
        }),
    }, 'NGINX Deployment');

    # Verify it can round-trip through JSON
    my $json_str = $json->encode($got);
    my $re_parsed = $json->decode($json_str);
    my $re_inflated = $k8s->inflate($re_parsed);
    is(ref $re_inflated, ref $obj, 'Round-trip preserves class');
    is($re_inflated->metadata->name, 'nginx', 'Round-trip preserves name');
};

# ============================================================================
# 2. ClusterIP Service with named ports
# ============================================================================

subtest 'ClusterIP Service with named ports' => sub {
    build_and_verify('Service', {
        metadata => {
            name      => 'my-service',
            namespace => 'production',
            labels    => { app => 'my-app', tier => 'backend' },
        },
        spec => {
            type     => 'ClusterIP',
            selector => { app => 'my-app', tier => 'backend' },
            ports    => [
                { name => 'http',  port => 80,   targetPort => 8080, protocol => 'TCP' },
                { name => 'https', port => 443,  targetPort => 8443, protocol => 'TCP' },
                { name => 'grpc',  port => 9090, targetPort => 9090, protocol => 'TCP' },
            ],
        },
    }, {
        apiVersion => 'v1',
        kind       => 'Service',
        metadata   => superhashof({
            name      => 'my-service',
            namespace => 'production',
        }),
        spec => superhashof({
            type  => 'ClusterIP',
            ports => bag(
                superhashof({ name => 'http',  port => 80,  targetPort => 8080 }),
                superhashof({ name => 'https', port => 443, targetPort => 8443 }),
                superhashof({ name => 'grpc',  port => 9090, targetPort => 9090 }),
            ),
        }),
    }, 'ClusterIP Service');
};

# ============================================================================
# 3. NodePort + LoadBalancer Service
# ============================================================================

subtest 'LoadBalancer Service' => sub {
    build_and_verify('Service', {
        metadata => {
            name        => 'lb-service',
            namespace   => 'default',
            annotations => {
                'service.beta.kubernetes.io/aws-load-balancer-type' => 'nlb',
            },
        },
        spec => {
            type                  => 'LoadBalancer',
            externalTrafficPolicy => 'Local',
            selector              => { app => 'frontend' },
            ports => [{
                port       => 443,
                targetPort => 8443,
                protocol   => 'TCP',
                nodePort   => 30443,
            }],
        },
    }, {
        apiVersion => 'v1',
        kind       => 'Service',
        spec       => superhashof({
            type                  => 'LoadBalancer',
            externalTrafficPolicy => 'Local',
            ports => [superhashof({ port => 443, nodePort => 30443 })],
        }),
    }, 'LoadBalancer Service');
};

# ============================================================================
# 4. ConfigMap with multiline data
# ============================================================================

subtest 'ConfigMap with multiline config' => sub {
    my $nginx_conf = <<'CONF';
server {
    listen 80;
    server_name example.com;
    location / {
        proxy_pass http://backend:8080;
    }
}
CONF

    build_and_verify('ConfigMap', {
        metadata => {
            name      => 'nginx-config',
            namespace => 'default',
        },
        data => {
            'nginx.conf'       => $nginx_conf,
            'ENVIRONMENT'      => 'production',
            'MAX_CONNECTIONS'   => '1000',
        },
    }, {
        apiVersion => 'v1',
        kind       => 'ConfigMap',
        data       => {
            'nginx.conf'     => $nginx_conf,
            'ENVIRONMENT'    => 'production',
            'MAX_CONNECTIONS' => '1000',
        },
    }, 'ConfigMap with nginx.conf');
};

# ============================================================================
# 5. Secret (Opaque)
# ============================================================================

subtest 'Opaque Secret' => sub {
    use MIME::Base64 ();
    build_and_verify('Secret', {
        metadata => {
            name      => 'db-credentials',
            namespace => 'production',
        },
        type => 'Opaque',
        data => {
            username => MIME::Base64::encode_base64('admin', ''),
            password => MIME::Base64::encode_base64('s3cret!Pass', ''),
        },
    }, {
        apiVersion => 'v1',
        kind       => 'Secret',
        type       => 'Opaque',
        data       => {
            username => 'YWRtaW4=',
            password => 'czNjcmV0IVBhc3M=',
        },
    }, 'Opaque Secret');
};

# ============================================================================
# 6. ServiceAccount
# ============================================================================

subtest 'ServiceAccount' => sub {
    build_and_verify('ServiceAccount', {
        metadata => {
            name      => 'app-sa',
            namespace => 'default',
            annotations => {
                'eks.amazonaws.com/role-arn' =>
                    'arn:aws:iam::123456789012:role/app-role',
            },
        },
    }, {
        apiVersion => 'v1',
        kind       => 'ServiceAccount',
        metadata   => superhashof({
            name => 'app-sa',
            annotations => {
                'eks.amazonaws.com/role-arn' =>
                    'arn:aws:iam::123456789012:role/app-role',
            },
        }),
    }, 'ServiceAccount with IAM annotation');
};

# ============================================================================
# 7. RBAC: ClusterRole + ClusterRoleBinding
# ============================================================================

subtest 'RBAC ClusterRole and ClusterRoleBinding' => sub {
    # ClusterRole
    my ($role, $role_json) = build_and_verify('ClusterRole', {
        metadata => {
            name   => 'pod-reader',
            labels => { 'rbac.example.com/aggregate-to-monitoring' => 'true' },
        },
        rules => [
            {
                apiGroups => [''],
                resources => ['pods', 'pods/log'],
                verbs     => ['get', 'list', 'watch'],
            },
            {
                apiGroups => ['apps'],
                resources => ['deployments', 'replicasets'],
                verbs     => ['get', 'list'],
            },
        ],
    }, {
        kind  => 'ClusterRole',
        rules => [
            superhashof({
                apiGroups => [''],
                resources => bag('pods', 'pods/log'),
                verbs     => bag('get', 'list', 'watch'),
            }),
            superhashof({
                apiGroups => ['apps'],
                resources => bag('deployments', 'replicasets'),
                verbs     => bag('get', 'list'),
            }),
        ],
    }, 'ClusterRole pod-reader');

    # ClusterRoleBinding
    build_and_verify('ClusterRoleBinding', {
        metadata => { name => 'read-pods' },
        subjects => [
            {
                kind      => 'ServiceAccount',
                name      => 'monitoring',
                namespace => 'monitoring',
            },
            {
                kind     => 'Group',
                name     => 'developers',
                apiGroup => 'rbac.authorization.k8s.io',
            },
        ],
        roleRef => {
            kind     => 'ClusterRole',
            name     => 'pod-reader',
            apiGroup => 'rbac.authorization.k8s.io',
        },
    }, {
        kind     => 'ClusterRoleBinding',
        subjects => [
            superhashof({ kind => 'ServiceAccount', name => 'monitoring' }),
            superhashof({ kind => 'Group', name => 'developers' }),
        ],
        roleRef => superhashof({
            kind => 'ClusterRole',
            name => 'pod-reader',
        }),
    }, 'ClusterRoleBinding read-pods');
};

# ============================================================================
# 8. Namespace-scoped Role + RoleBinding
# ============================================================================

subtest 'Role and RoleBinding' => sub {
    build_and_verify('Role', {
        metadata => {
            name      => 'secret-reader',
            namespace => 'my-app',
        },
        rules => [{
            apiGroups => [''],
            resources => ['secrets'],
            verbs     => ['get', 'list'],
        }],
    }, {
        kind  => 'Role',
        rules => [superhashof({
            resources => ['secrets'],
        })],
    }, 'Role secret-reader');

    build_and_verify('RoleBinding', {
        metadata => {
            name      => 'read-secrets',
            namespace => 'my-app',
        },
        subjects => [{
            kind      => 'ServiceAccount',
            name      => 'my-app-sa',
            namespace => 'my-app',
        }],
        roleRef => {
            kind     => 'Role',
            name     => 'secret-reader',
            apiGroup => 'rbac.authorization.k8s.io',
        },
    }, {
        kind    => 'RoleBinding',
        roleRef => superhashof({ kind => 'Role', name => 'secret-reader' }),
    }, 'RoleBinding read-secrets');
};

# ============================================================================
# 9. DaemonSet (like Fluentd/Promtail log collector)
# ============================================================================

subtest 'DaemonSet log collector' => sub {
    build_and_verify('DaemonSet', {
        metadata => {
            name      => 'fluentd',
            namespace => 'kube-system',
            labels    => { app => 'fluentd', 'kubernetes.io/cluster-service' => 'true' },
        },
        spec => {
            selector => { matchLabels => { app => 'fluentd' } },
            template => {
                metadata => {
                    labels => { app => 'fluentd' },
                },
                spec => {
                    serviceAccountName => 'fluentd',
                    tolerations => [
                        { key => 'node-role.kubernetes.io/control-plane', effect => 'NoSchedule' },
                        { key => 'node-role.kubernetes.io/master',        effect => 'NoSchedule' },
                    ],
                    containers => [{
                        name  => 'fluentd',
                        image => 'fluent/fluentd-kubernetes-daemonset:v1.16',
                        resources => {
                            limits   => { memory => '512Mi' },
                            requests => { cpu => '100m', memory => '200Mi' },
                        },
                        volumeMounts => [
                            { name => 'varlog',       mountPath => '/var/log' },
                            { name => 'dockerlogs',   mountPath => '/var/lib/docker/containers', readOnly => 1 },
                        ],
                        env => [
                            { name => 'FLUENT_ELASTICSEARCH_HOST', value => 'elasticsearch.logging' },
                            { name => 'FLUENT_ELASTICSEARCH_PORT', value => '9200' },
                        ],
                    }],
                    volumes => [
                        { name => 'varlog',     hostPath => { path => '/var/log' } },
                        { name => 'dockerlogs', hostPath => { path => '/var/lib/docker/containers' } },
                    ],
                },
            },
        },
    }, {
        apiVersion => 'apps/v1',
        kind       => 'DaemonSet',
        spec       => superhashof({
            template => superhashof({
                spec => superhashof({
                    tolerations => bag(
                        superhashof({ key => 'node-role.kubernetes.io/control-plane' }),
                        superhashof({ key => 'node-role.kubernetes.io/master' }),
                    ),
                    containers => [superhashof({
                        name      => 'fluentd',
                        resources => superhashof({
                            limits => { memory => '512Mi' },
                        }),
                    })],
                    volumes => bag(
                        superhashof({ name => 'varlog' }),
                        superhashof({ name => 'dockerlogs' }),
                    ),
                }),
            }),
        }),
    }, 'DaemonSet fluentd');
};

# ============================================================================
# 10. StatefulSet with volumeClaimTemplates (e.g. PostgreSQL)
# ============================================================================

subtest 'StatefulSet PostgreSQL' => sub {
    my ($obj, $got) = build_and_verify('StatefulSet', {
        metadata => {
            name      => 'postgresql',
            namespace => 'databases',
        },
        spec => {
            serviceName => 'postgresql-headless',
            replicas    => 3,
            selector    => { matchLabels => { app => 'postgresql' } },
            template    => {
                metadata => { labels => { app => 'postgresql' } },
                spec     => {
                    containers => [{
                        name  => 'postgres',
                        image => 'postgres:16',
                        ports => [{ containerPort => 5432, name => 'postgres' }],
                        env   => [
                            { name => 'POSTGRES_PASSWORD', valueFrom => {
                                secretKeyRef => { name => 'pg-secret', key => 'password' },
                            }},
                            { name => 'PGDATA', value => '/var/lib/postgresql/data/pgdata' },
                        ],
                        volumeMounts => [{
                            name      => 'data',
                            mountPath => '/var/lib/postgresql/data',
                        }],
                        readinessProbe => {
                            exec    => { command => ['pg_isready', '-U', 'postgres'] },
                            initialDelaySeconds => 5,
                            periodSeconds       => 10,
                        },
                    }],
                },
            },
            volumeClaimTemplates => [{
                metadata => { name => 'data' },
                spec => {
                    accessModes      => ['ReadWriteOnce'],
                    storageClassName => 'standard',
                    resources        => { requests => { storage => '10Gi' } },
                },
            }],
        },
    }, {
        apiVersion => 'apps/v1',
        kind       => 'StatefulSet',
        spec       => superhashof({
            serviceName => 'postgresql-headless',
            replicas    => 3,
            volumeClaimTemplates => [superhashof({
                metadata => superhashof({ name => 'data' }),
                spec     => superhashof({
                    accessModes => ['ReadWriteOnce'],
                    resources   => { requests => { storage => '10Gi' } },
                }),
            })],
        }),
    }, 'StatefulSet PostgreSQL');

    # Verify VCT is a real PVC object, not empty
    my $vcts = $got->{spec}{volumeClaimTemplates};
    ok($vcts && @$vcts == 1, 'Has one VCT');
    is($vcts->[0]{metadata}{name}, 'data', 'VCT name preserved');
    cmp_deeply($vcts->[0]{spec}{accessModes}, ['ReadWriteOnce'], 'VCT accessModes preserved');
    is($vcts->[0]{spec}{resources}{requests}{storage}, '10Gi', 'VCT storage preserved');
};

# ============================================================================
# 11. CronJob (e.g. database backup)
# ============================================================================

subtest 'CronJob database backup' => sub {
    build_and_verify('CronJob', {
        metadata => {
            name      => 'db-backup',
            namespace => 'databases',
        },
        spec => {
            schedule                   => '0 2 * * *',
            concurrencyPolicy          => 'Forbid',
            successfulJobsHistoryLimit => 3,
            failedJobsHistoryLimit     => 1,
            jobTemplate                => {
                spec => {
                    backoffLimit => 2,
                    template     => {
                        spec => {
                            restartPolicy => 'OnFailure',
                            containers    => [{
                                name    => 'backup',
                                image   => 'postgres:16',
                                command => ['/bin/sh', '-c', 'pg_dump -h postgresql -U postgres > /backup/dump.sql'],
                                env     => [{
                                    name      => 'PGPASSWORD',
                                    valueFrom => {
                                        secretKeyRef => { name => 'pg-secret', key => 'password' },
                                    },
                                }],
                                volumeMounts => [{
                                    name      => 'backup-volume',
                                    mountPath => '/backup',
                                }],
                            }],
                            volumes => [{
                                name => 'backup-volume',
                                persistentVolumeClaim => { claimName => 'backup-pvc' },
                            }],
                        },
                    },
                },
            },
        },
    }, {
        apiVersion => 'batch/v1',
        kind       => 'CronJob',
        spec       => superhashof({
            schedule          => '0 2 * * *',
            concurrencyPolicy => 'Forbid',
            jobTemplate       => superhashof({
                spec => superhashof({
                    template => superhashof({
                        spec => superhashof({
                            restartPolicy => 'OnFailure',
                        }),
                    }),
                }),
            }),
        }),
    }, 'CronJob db-backup');
};

# ============================================================================
# 12. Job (batch)
# ============================================================================

subtest 'Job batch migration' => sub {
    build_and_verify('Job', {
        metadata => {
            name      => 'db-migrate',
            namespace => 'production',
            labels    => { app => 'migrator' },
        },
        spec => {
            parallelism  => 1,
            completions  => 1,
            backoffLimit => 3,
            template     => {
                spec => {
                    restartPolicy => 'Never',
                    containers    => [{
                        name    => 'migrate',
                        image   => 'my-app:v2.1',
                        command => ['./migrate', '--target', 'latest'],
                    }],
                },
            },
        },
    }, {
        apiVersion => 'batch/v1',
        kind       => 'Job',
        spec       => superhashof({
            parallelism  => 1,
            completions  => 1,
            backoffLimit => 3,
        }),
    }, 'Job db-migrate');
};

# ============================================================================
# 13. Ingress with TLS and multiple paths
# ============================================================================

subtest 'Ingress with TLS' => sub {
    build_and_verify('Ingress', {
        metadata => {
            name      => 'app-ingress',
            namespace => 'production',
            annotations => {
                'nginx.ingress.kubernetes.io/rewrite-target' => '/',
                'cert-manager.io/cluster-issuer'             => 'letsencrypt-prod',
            },
        },
        spec => {
            ingressClassName => 'nginx',
            tls => [{
                hosts      => ['app.example.com', 'api.example.com'],
                secretName => 'app-tls',
            }],
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
                                        name => 'frontend',
                                        port => { number => 80 },
                                    },
                                },
                            },
                            {
                                path     => '/api',
                                pathType => 'Prefix',
                                backend  => {
                                    service => {
                                        name => 'backend',
                                        port => { number => 8080 },
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
                            path     => '/',
                            pathType => 'Prefix',
                            backend  => {
                                service => {
                                    name => 'api-gateway',
                                    port => { name => 'grpc' },
                                },
                            },
                        }],
                    },
                },
            ],
        },
    }, {
        apiVersion => 'networking.k8s.io/v1',
        kind       => 'Ingress',
        spec       => superhashof({
            ingressClassName => 'nginx',
            tls   => [superhashof({ secretName => 'app-tls' })],
            rules => [
                superhashof({ host => 'app.example.com' }),
                superhashof({ host => 'api.example.com' }),
            ],
        }),
    }, 'Ingress with TLS');
};

# ============================================================================
# 14. NetworkPolicy (deny all + allow specific)
# ============================================================================

subtest 'NetworkPolicy deny-all + allow' => sub {
    # Deny all ingress
    build_and_verify('NetworkPolicy', {
        metadata => {
            name      => 'deny-all',
            namespace => 'production',
        },
        spec => {
            podSelector => {},
            policyTypes => ['Ingress'],
        },
    }, {
        apiVersion => 'networking.k8s.io/v1',
        kind       => 'NetworkPolicy',
        spec       => superhashof({
            policyTypes => ['Ingress'],
        }),
    }, 'NetworkPolicy deny-all');

    # Allow from specific namespace + pod
    build_and_verify('NetworkPolicy', {
        metadata => {
            name      => 'allow-monitoring',
            namespace => 'production',
        },
        spec => {
            podSelector => { matchLabels => { app => 'web' } },
            policyTypes => ['Ingress'],
            ingress => [{
                from => [
                    {
                        namespaceSelector => {
                            matchLabels => { 'kubernetes.io/metadata.name' => 'monitoring' },
                        },
                    },
                    {
                        podSelector => {
                            matchLabels => { app => 'prometheus' },
                        },
                    },
                ],
                ports => [
                    { protocol => 'TCP', port => 9090 },
                ],
            }],
        },
    }, {
        kind => 'NetworkPolicy',
        spec => superhashof({
            ingress => [superhashof({
                from => bag(
                    superhashof({ namespaceSelector => ignore() }),
                    superhashof({ podSelector => ignore() }),
                ),
            })],
        }),
    }, 'NetworkPolicy allow-monitoring');
};

# ============================================================================
# 15. PersistentVolumeClaim
# ============================================================================

subtest 'PersistentVolumeClaim' => sub {
    build_and_verify('PersistentVolumeClaim', {
        metadata => {
            name      => 'data-pvc',
            namespace => 'default',
        },
        spec => {
            accessModes      => ['ReadWriteOnce'],
            storageClassName => 'local-path',
            resources        => {
                requests => { storage => '50Gi' },
            },
        },
    }, {
        apiVersion => 'v1',
        kind       => 'PersistentVolumeClaim',
        spec       => {
            accessModes      => ['ReadWriteOnce'],
            storageClassName => 'local-path',
            resources        => {
                requests => { storage => '50Gi' },
            },
        },
    }, 'PVC 50Gi local-path');
};

# ============================================================================
# 16. PersistentVolume (hostPath for local dev)
# ============================================================================

subtest 'PersistentVolume hostPath' => sub {
    build_and_verify('PersistentVolume', {
        metadata => {
            name   => 'local-pv',
            labels => { type => 'local' },
        },
        spec => {
            capacity => { storage => '100Gi' },
            accessModes => ['ReadWriteOnce'],
            persistentVolumeReclaimPolicy => 'Retain',
            hostPath => { path => '/mnt/data' },
        },
    }, {
        apiVersion => 'v1',
        kind       => 'PersistentVolume',
        spec       => superhashof({
            capacity    => { storage => '100Gi' },
            accessModes => ['ReadWriteOnce'],
            persistentVolumeReclaimPolicy => 'Retain',
        }),
    }, 'PV local hostPath');
};

# ============================================================================
# 17. Namespace with labels
# ============================================================================

subtest 'Namespace with labels' => sub {
    build_and_verify('Namespace', {
        metadata => {
            name   => 'my-team',
            labels => {
                'pod-security.kubernetes.io/enforce' => 'restricted',
                team => 'platform',
            },
        },
    }, {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => superhashof({
            name   => 'my-team',
            labels => superhashof({
                'pod-security.kubernetes.io/enforce' => 'restricted',
            }),
        }),
    }, 'Namespace my-team');
};

# ============================================================================
# 18. PodDisruptionBudget
# ============================================================================

subtest 'PodDisruptionBudget' => sub {
    build_and_verify('PodDisruptionBudget', {
        metadata => {
            name      => 'web-pdb',
            namespace => 'production',
        },
        spec => {
            minAvailable => '50%',
            selector     => {
                matchLabels => { app => 'web' },
            },
        },
    }, {
        apiVersion => 'policy/v1',
        kind       => 'PodDisruptionBudget',
        spec       => {
            minAvailable => '50%',
            selector     => {
                matchLabels => { app => 'web' },
            },
        },
    }, 'PDB web-pdb');
};

# ============================================================================
# 19. HorizontalPodAutoscaler
# ============================================================================

subtest 'HorizontalPodAutoscaler' => sub {
    build_and_verify('HorizontalPodAutoscaler', {
        metadata => {
            name      => 'web-hpa',
            namespace => 'production',
        },
        spec => {
            scaleTargetRef => {
                apiVersion => 'apps/v1',
                kind       => 'Deployment',
                name       => 'web',
            },
            minReplicas => 2,
            maxReplicas => 10,
            metrics => [{
                type => 'Resource',
                resource => {
                    name   => 'cpu',
                    target => {
                        type               => 'Utilization',
                        averageUtilization => 70,
                    },
                },
            }],
        },
    }, {
        kind => 'HorizontalPodAutoscaler',
        spec => superhashof({
            minReplicas => 2,
            maxReplicas => 10,
            scaleTargetRef => superhashof({
                kind => 'Deployment',
                name => 'web',
            }),
        }),
    }, 'HPA web-hpa');
};

# ============================================================================
# 20. Full-stack app: Deployment + Service + ConfigMap + Secret combined
# ============================================================================

subtest 'Full-stack: build all components and cross-reference' => sub {
    # ConfigMap
    my $cm = $k8s->new_object('ConfigMap', {
        metadata => {
            name      => 'app-config',
            namespace => 'staging',
            labels    => { app => 'fullstack' },
        },
        data => {
            DATABASE_URL => 'postgres://db:5432/app',
            REDIS_URL    => 'redis://redis:6379',
            LOG_LEVEL    => 'info',
        },
    });
    my $cm_json = $cm->TO_JSON;
    is($cm_json->{kind}, 'ConfigMap', 'ConfigMap kind');
    is($cm_json->{data}{DATABASE_URL}, 'postgres://db:5432/app', 'ConfigMap data preserved');

    # Secret
    my $secret = $k8s->new_object('Secret', {
        metadata => {
            name      => 'app-secrets',
            namespace => 'staging',
            labels    => { app => 'fullstack' },
        },
        type       => 'Opaque',
        stringData => {
            API_KEY    => 'abc123xyz',
            JWT_SECRET => 'super-secret-key',
        },
    });
    my $secret_json = $secret->TO_JSON;
    is($secret_json->{kind}, 'Secret', 'Secret kind');
    is($secret_json->{stringData}{API_KEY}, 'abc123xyz', 'Secret stringData preserved');

    # Deployment referencing both
    my $deploy = $k8s->new_object('Deployment', {
        metadata => {
            name      => 'fullstack-app',
            namespace => 'staging',
            labels    => { app => 'fullstack' },
        },
        spec => {
            replicas => 2,
            selector => { matchLabels => { app => 'fullstack' } },
            template => {
                metadata => { labels => { app => 'fullstack' } },
                spec     => {
                    containers => [{
                        name  => 'app',
                        image => 'my-app:v1.0',
                        ports => [{ containerPort => 3000 }],
                        envFrom => [
                            { configMapRef => { name => 'app-config' } },
                            { secretRef    => { name => 'app-secrets' } },
                        ],
                    }],
                },
            },
        },
    });
    my $deploy_json = $deploy->TO_JSON;
    is($deploy_json->{kind}, 'Deployment', 'Deployment kind');

    my $env_from = $deploy_json->{spec}{template}{spec}{containers}[0]{envFrom};
    is(scalar @$env_from, 2, 'envFrom has 2 sources');
    is($env_from->[0]{configMapRef}{name}, 'app-config', 'envFrom references ConfigMap');
    is($env_from->[1]{secretRef}{name}, 'app-secrets', 'envFrom references Secret');

    # Service
    my $svc = $k8s->new_object('Service', {
        metadata => {
            name      => 'fullstack-app',
            namespace => 'staging',
            labels    => { app => 'fullstack' },
        },
        spec => {
            selector => { app => 'fullstack' },
            ports    => [{ port => 80, targetPort => 3000, protocol => 'TCP' }],
        },
    });
    my $svc_json = $svc->TO_JSON;
    is($svc_json->{kind}, 'Service', 'Service kind');
    is($svc_json->{spec}{ports}[0]{targetPort}, 3000, 'Service targets app port');

    # All share the same namespace and labels
    for my $obj_json ($cm_json, $secret_json, $deploy_json, $svc_json) {
        is($obj_json->{metadata}{namespace}, 'staging', 'All in staging ns');
        is($obj_json->{metadata}{labels}{app}, 'fullstack', 'All have app=fullstack');
    }
};

# ============================================================================
# 21. Deployment with init containers, probes, and resource limits
# ============================================================================

subtest 'Deployment with init containers and full probe config' => sub {
    my ($obj, $got) = build_and_verify('Deployment', {
        metadata => {
            name      => 'web',
            namespace => 'production',
        },
        spec => {
            replicas => 3,
            selector => { matchLabels => { app => 'web' } },
            template => {
                metadata => { labels => { app => 'web' } },
                spec => {
                    initContainers => [{
                        name    => 'wait-for-db',
                        image   => 'busybox:1.36',
                        command => ['sh', '-c', 'until nc -z db 5432; do sleep 1; done'],
                    }],
                    containers => [{
                        name  => 'web',
                        image => 'web-app:v3',
                        ports => [{ containerPort => 8080, name => 'http' }],
                        resources => {
                            requests => { cpu => '100m', memory => '128Mi' },
                            limits   => { cpu => '500m', memory => '512Mi' },
                        },
                        livenessProbe => {
                            httpGet => { path => '/healthz', port => 8080 },
                            initialDelaySeconds => 15,
                            periodSeconds       => 20,
                            failureThreshold    => 3,
                        },
                        readinessProbe => {
                            httpGet => { path => '/ready', port => 8080 },
                            initialDelaySeconds => 5,
                            periodSeconds       => 10,
                        },
                        startupProbe => {
                            httpGet => { path => '/healthz', port => 8080 },
                            failureThreshold => 30,
                            periodSeconds    => 10,
                        },
                    }],
                },
            },
        },
    }, {
        kind => 'Deployment',
        spec => superhashof({
            template => superhashof({
                metadata => ignore(),
                spec => superhashof({
                    initContainers => [superhashof({ name => 'wait-for-db' })],
                    containers     => [superhashof({
                        name => 'web',
                        livenessProbe  => superhashof({ httpGet => superhashof({ path => '/healthz' }) }),
                        readinessProbe => superhashof({ httpGet => superhashof({ path => '/ready' }) }),
                        startupProbe   => superhashof({ httpGet => superhashof({ path => '/healthz' }) }),
                    })],
                }),
            }),
        }),
    }, 'Deployment with probes');

    # Verify resource values are preserved exactly
    my $container = $got->{spec}{template}{spec}{containers}[0];
    is($container->{resources}{requests}{cpu}, '100m', 'CPU request preserved');
    is($container->{resources}{limits}{memory}, '512Mi', 'Memory limit preserved');
};

# ============================================================================
# 22. Pod with multiple containers (sidecar pattern)
# ============================================================================

subtest 'Pod with sidecar containers' => sub {
    build_and_verify('Pod', {
        metadata => {
            name      => 'app-with-sidecar',
            namespace => 'default',
            labels    => { app => 'web' },
        },
        spec => {
            containers => [
                {
                    name  => 'app',
                    image => 'my-app:latest',
                    ports => [{ containerPort => 8080 }],
                },
                {
                    name  => 'envoy',
                    image => 'envoyproxy/envoy:v1.30',
                    ports => [{ containerPort => 9901, name => 'admin' }],
                    volumeMounts => [{
                        name      => 'envoy-config',
                        mountPath => '/etc/envoy',
                    }],
                },
                {
                    name  => 'fluentbit',
                    image => 'fluent/fluent-bit:3.0',
                    volumeMounts => [{
                        name      => 'shared-logs',
                        mountPath => '/var/log/app',
                    }],
                },
            ],
            volumes => [
                {
                    name      => 'envoy-config',
                    configMap => { name => 'envoy-config' },
                },
                {
                    name     => 'shared-logs',
                    emptyDir => {},
                },
            ],
        },
    }, {
        apiVersion => 'v1',
        kind       => 'Pod',
        spec       => superhashof({
            containers => [
                superhashof({ name => 'app' }),
                superhashof({ name => 'envoy' }),
                superhashof({ name => 'fluentbit' }),
            ],
            volumes => bag(
                superhashof({ name => 'envoy-config' }),
                superhashof({ name => 'shared-logs' }),
            ),
        }),
    }, 'Pod with sidecars');
};

# ============================================================================
# 23. Deployment with affinity, tolerations, topologySpreadConstraints
# ============================================================================

subtest 'Deployment with scheduling constraints' => sub {
    my ($obj, $got) = build_and_verify('Deployment', {
        metadata => {
            name      => 'ha-app',
            namespace => 'production',
        },
        spec => {
            replicas => 5,
            selector => { matchLabels => { app => 'ha-app' } },
            template => {
                metadata => { labels => { app => 'ha-app' } },
                spec => {
                    affinity => {
                        podAntiAffinity => {
                            preferredDuringSchedulingIgnoredDuringExecution => [{
                                weight => 100,
                                podAffinityTerm => {
                                    labelSelector => {
                                        matchExpressions => [{
                                            key      => 'app',
                                            operator => 'In',
                                            values   => ['ha-app'],
                                        }],
                                    },
                                    topologyKey => 'kubernetes.io/hostname',
                                },
                            }],
                        },
                        nodeAffinity => {
                            requiredDuringSchedulingIgnoredDuringExecution => {
                                nodeSelectorTerms => [{
                                    matchExpressions => [{
                                        key      => 'node.kubernetes.io/instance-type',
                                        operator => 'In',
                                        values   => ['m5.xlarge', 'm5.2xlarge'],
                                    }],
                                }],
                            },
                        },
                    },
                    topologySpreadConstraints => [{
                        maxSkew           => 1,
                        topologyKey       => 'topology.kubernetes.io/zone',
                        whenUnsatisfiable => 'DoNotSchedule',
                        labelSelector     => {
                            matchLabels => { app => 'ha-app' },
                        },
                    }],
                    tolerations => [{
                        key      => 'dedicated',
                        operator => 'Equal',
                        value    => 'high-memory',
                        effect   => 'NoSchedule',
                    }],
                    containers => [{
                        name  => 'app',
                        image => 'ha-app:v1',
                    }],
                },
            },
        },
    }, {
        kind => 'Deployment',
        spec => superhashof({
            replicas => 5,
        }),
    }, 'HA Deployment with scheduling');

    # Verify deep nested affinity
    my $pod_spec = $got->{spec}{template}{spec};
    ok(exists $pod_spec->{affinity}, 'affinity present');
    ok(exists $pod_spec->{affinity}{podAntiAffinity}, 'podAntiAffinity present');
    ok(exists $pod_spec->{affinity}{nodeAffinity}, 'nodeAffinity present');

    my $tsc = $pod_spec->{topologySpreadConstraints};
    ok($tsc && @$tsc == 1, 'topologySpreadConstraints present');
    is($tsc->[0]{topologyKey}, 'topology.kubernetes.io/zone', 'TSC topologyKey');
    is($tsc->[0]{maxSkew}, 1, 'TSC maxSkew');
};

# ============================================================================
# 24. Deployment with volumes: configMap, secret, emptyDir, projected
# ============================================================================

subtest 'Deployment with mixed volume types' => sub {
    my ($obj, $got) = build_and_verify('Deployment', {
        metadata => {
            name      => 'vol-app',
            namespace => 'default',
        },
        spec => {
            replicas => 1,
            selector => { matchLabels => { app => 'vol-app' } },
            template => {
                metadata => { labels => { app => 'vol-app' } },
                spec => {
                    containers => [{
                        name  => 'app',
                        image => 'app:v1',
                        volumeMounts => [
                            { name => 'config-vol',  mountPath => '/etc/config' },
                            { name => 'secret-vol',  mountPath => '/etc/secret', readOnly => 1 },
                            { name => 'cache',        mountPath => '/tmp/cache' },
                            { name => 'token',        mountPath => '/var/run/secrets/tokens' },
                        ],
                    }],
                    volumes => [
                        {
                            name      => 'config-vol',
                            configMap => {
                                name  => 'app-config',
                                items => [{ key => 'config.yaml', path => 'config.yaml' }],
                            },
                        },
                        {
                            name   => 'secret-vol',
                            secret => {
                                secretName  => 'app-secret',
                                defaultMode => 256,  # 0400 octal
                            },
                        },
                        {
                            name     => 'cache',
                            emptyDir => { sizeLimit => '1Gi' },
                        },
                        {
                            name      => 'token',
                            projected => {
                                sources => [{
                                    serviceAccountToken => {
                                        path              => 'token',
                                        expirationSeconds => 3600,
                                        audience          => 'api',
                                    },
                                }],
                            },
                        },
                    ],
                },
            },
        },
    }, {
        kind => 'Deployment',
    }, 'Deployment mixed volumes');

    my $vols = $got->{spec}{template}{spec}{volumes};
    ok($vols && @$vols == 4, 'Has 4 volumes');

    # Check each volume type
    my %by_name = map { $_->{name} => $_ } @$vols;
    ok(exists $by_name{'config-vol'}{configMap}, 'configMap volume');
    ok(exists $by_name{'secret-vol'}{secret}, 'secret volume');
    ok(exists $by_name{'cache'}{emptyDir}, 'emptyDir volume');
    ok(exists $by_name{'token'}{projected}, 'projected volume');
    is($by_name{'secret-vol'}{secret}{defaultMode}, 256, 'secret defaultMode=0400');
};

# ============================================================================
# 25. Deployment with securityContext (pod + container level)
# ============================================================================

subtest 'Deployment with securityContext' => sub {
    my ($obj, $got) = build_and_verify('Deployment', {
        metadata => {
            name      => 'secure-app',
            namespace => 'production',
        },
        spec => {
            replicas => 1,
            selector => { matchLabels => { app => 'secure-app' } },
            template => {
                metadata => { labels => { app => 'secure-app' } },
                spec => {
                    securityContext => {
                        runAsNonRoot => 1,
                        runAsUser    => 1000,
                        runAsGroup   => 3000,
                        fsGroup      => 2000,
                    },
                    containers => [{
                        name  => 'app',
                        image => 'app:v1',
                        securityContext => {
                            allowPrivilegeEscalation => 0,
                            readOnlyRootFilesystem   => 1,
                            capabilities             => {
                                drop => ['ALL'],
                                add  => ['NET_BIND_SERVICE'],
                            },
                        },
                    }],
                },
            },
        },
    }, {
        kind => 'Deployment',
    }, 'Secure Deployment');

    my $pod_sec = $got->{spec}{template}{spec}{securityContext};
    is($pod_sec->{runAsUser}, 1000, 'Pod runAsUser');
    is($pod_sec->{fsGroup}, 2000, 'Pod fsGroup');

    my $ctr_sec = $got->{spec}{template}{spec}{containers}[0]{securityContext};
    cmp_deeply($ctr_sec->{capabilities}{drop}, ['ALL'], 'Drop ALL capabilities');
    cmp_deeply($ctr_sec->{capabilities}{add}, ['NET_BIND_SERVICE'], 'Add NET_BIND_SERVICE');
};

# ============================================================================
# 26. Pre-built objects nested in parents (passthrough verification)
# ============================================================================

subtest 'Pre-built objects nested in parent construction' => sub {
    # Build a PVC, then embed it in a StatefulSet
    my $pvc = $k8s->new_object('PersistentVolumeClaim', {
        metadata => { name => 'data' },
        spec => {
            accessModes      => ['ReadWriteOnce'],
            storageClassName => 'ssd',
            resources        => { requests => { storage => '20Gi' } },
        },
    });
    isa_ok($pvc, 'IO::K8s::Api::Core::V1::PersistentVolumeClaim');

    my $sts = $k8s->new_object('StatefulSet', {
        metadata => { name => 'redis', namespace => 'cache' },
        spec => {
            serviceName => 'redis',
            replicas    => 3,
            selector    => { matchLabels => { app => 'redis' } },
            template    => {
                metadata => { labels => { app => 'redis' } },
                spec     => {
                    containers => [{
                        name  => 'redis',
                        image => 'redis:7',
                        ports => [{ containerPort => 6379 }],
                        volumeMounts => [{ name => 'data', mountPath => '/data' }],
                    }],
                },
            },
            volumeClaimTemplates => [$pvc],
        },
    });

    my $got = $sts->TO_JSON;
    my $vcts = $got->{spec}{volumeClaimTemplates};
    ok($vcts && @$vcts == 1, 'VCT present');
    is($vcts->[0]{metadata}{name}, 'data', 'Pre-built PVC name preserved in STS');
    is($vcts->[0]{spec}{storageClassName}, 'ssd', 'Pre-built PVC storageClass preserved');
    is($vcts->[0]{spec}{resources}{requests}{storage}, '20Gi', 'Pre-built PVC storage preserved');
};

# ============================================================================
# 27. JSON round-trip fidelity: build -> JSON -> parse -> JSON must match
# ============================================================================

subtest 'JSON round-trip fidelity' => sub {
    my $original = $k8s->new_object('Deployment', {
        metadata => {
            name      => 'roundtrip',
            namespace => 'test',
            labels    => { app => 'test', version => 'v1' },
            annotations => { 'note' => 'testing round-trip' },
        },
        spec => {
            replicas => 2,
            selector => { matchLabels => { app => 'test' } },
            strategy => {
                type          => 'RollingUpdate',
                rollingUpdate => { maxSurge => '25%', maxUnavailable => 0 },
            },
            template => {
                metadata => { labels => { app => 'test', version => 'v1' } },
                spec     => {
                    terminationGracePeriodSeconds => 30,
                    containers => [{
                        name  => 'app',
                        image => 'app:v1',
                        ports => [
                            { containerPort => 8080, name => 'http' },
                            { containerPort => 9090, name => 'metrics' },
                        ],
                        env => [
                            { name => 'ENV', value => 'test' },
                            { name => 'SECRET', valueFrom => {
                                secretKeyRef => { name => 'my-secret', key => 'val' },
                            }},
                        ],
                        resources => {
                            requests => { cpu => '250m', memory => '256Mi' },
                            limits   => { cpu => '1',    memory => '1Gi' },
                        },
                    }],
                },
            },
        },
    });

    my $json1 = $json->encode($original->TO_JSON);
    my $parsed = $json->decode($json1);
    my $rebuilt = $k8s->inflate($parsed);
    my $json2 = $json->encode($rebuilt->TO_JSON);

    is($json1, $json2, 'JSON output is identical after round-trip');
    is(ref $rebuilt, ref $original, 'Class preserved through round-trip');
};

# ============================================================================
# 28. YAML output verification (if YAML::PP available)
# ============================================================================

subtest 'YAML output matches expected' => sub {
    eval { require YAML::PP; 1 }
        or do { plan skip_all => 'YAML::PP needed'; return };

    my $svc = $k8s->new_object('Service', {
        metadata => {
            name      => 'web',
            namespace => 'default',
        },
        spec => {
            type     => 'ClusterIP',
            selector => { app => 'web' },
            ports    => [{ port => 80, targetPort => 8080 }],
        },
    });

    my $yaml_str = $svc->to_yaml;
    ok(length($yaml_str) > 50, 'to_yaml produces non-trivial output');

    # Re-parse the YAML and verify structure
    my $reparsed = YAML::PP::Load($yaml_str);
    is($reparsed->{kind}, 'Service', 'YAML kind correct');
    is($reparsed->{apiVersion}, 'v1', 'YAML apiVersion correct');
    is($reparsed->{metadata}{name}, 'web', 'YAML metadata.name correct');
    is($reparsed->{spec}{type}, 'ClusterIP', 'YAML spec.type correct');
    is($reparsed->{spec}{ports}[0]{port}, 80, 'YAML port correct');

    # Re-inflate and verify it matches original
    my $re_obj = $k8s->inflate($reparsed);
    is(ref $re_obj, ref $svc, 'YAML round-trip preserves class');
    is($re_obj->metadata->name, 'web', 'YAML round-trip preserves name');
};

# ============================================================================
# 29. Construct objects class-directly (not through $k8s->new_object)
# ============================================================================

subtest 'Direct class construction' => sub {
    require IO::K8s::Api::Core::V1::ConfigMap;
    require IO::K8s::Api::Core::V1::Service;
    require IO::K8s::Api::Apps::V1::Deployment;
    require IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

    # Build metadata object directly
    my $meta = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
        name      => 'direct-build',
        namespace => 'default',
        labels    => { app => 'direct' },
    );
    isa_ok($meta, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($meta->name, 'direct-build', 'Direct meta name');

    # Use pre-built metadata in ConfigMap
    my $cm = IO::K8s::Api::Core::V1::ConfigMap->new(
        metadata => $meta,
        data     => { key => 'value' },
    );
    is($cm->kind, 'ConfigMap', 'Direct ConfigMap kind');
    is($cm->metadata->name, 'direct-build', 'Direct ConfigMap uses pre-built metadata');

    my $cm_json = $cm->TO_JSON;
    is($cm_json->{metadata}{name}, 'direct-build', 'Direct build TO_JSON preserves metadata');
    is($cm_json->{data}{key}, 'value', 'Direct build TO_JSON preserves data');
};

# ============================================================================
# 30. Endpoints object (often forgotten, important for headless services)
# ============================================================================

subtest 'Endpoints object' => sub {
    build_and_verify('Endpoints', {
        metadata => {
            name      => 'external-db',
            namespace => 'default',
        },
        subsets => [{
            addresses => [
                { ip => '10.0.0.1' },
                { ip => '10.0.0.2' },
            ],
            ports => [
                { port => 5432, name => 'postgres', protocol => 'TCP' },
            ],
        }],
    }, {
        apiVersion => 'v1',
        kind       => 'Endpoints',
        subsets    => [superhashof({
            addresses => bag(
                superhashof({ ip => '10.0.0.1' }),
                superhashof({ ip => '10.0.0.2' }),
            ),
        })],
    }, 'Endpoints for external DB');
};

# ============================================================================
# 31. MutatingWebhookConfiguration
# ============================================================================

subtest 'MutatingWebhookConfiguration' => sub {
    build_and_verify('MutatingWebhookConfiguration', {
        metadata => {
            name   => 'pod-injector',
            labels => { app => 'sidecar-injector' },
        },
        webhooks => [{
            name                    => 'inject.sidecar.example.com',
            admissionReviewVersions => ['v1', 'v1beta1'],
            sideEffects             => 'None',
            failurePolicy           => 'Fail',
            clientConfig            => {
                service => {
                    name      => 'sidecar-injector',
                    namespace => 'kube-system',
                    path      => '/inject',
                },
                caBundle => 'base64encodedCA==',
            },
            rules => [{
                apiGroups   => [''],
                apiVersions => ['v1'],
                operations  => ['CREATE'],
                resources   => ['pods'],
                scope       => 'Namespaced',
            }],
            namespaceSelector => {
                matchLabels => { 'inject-sidecar' => 'true' },
            },
        }],
    }, {
        kind     => 'MutatingWebhookConfiguration',
        webhooks => [superhashof({
            name          => 'inject.sidecar.example.com',
            sideEffects   => 'None',
            failurePolicy => 'Fail',
        })],
    }, 'MutatingWebhookConfiguration');
};

# ============================================================================
# 32. Lease (leader election)
# ============================================================================

subtest 'Lease for leader election' => sub {
    build_and_verify('Lease', {
        metadata => {
            name      => 'my-controller',
            namespace => 'kube-system',
        },
        spec => {
            holderIdentity       => 'controller-pod-abc123',
            leaseDurationSeconds => 15,
            renewTime            => '2026-03-01T12:00:00Z',
        },
    }, {
        apiVersion => 'coordination.k8s.io/v1',
        kind       => 'Lease',
        spec       => superhashof({
            holderIdentity       => 'controller-pod-abc123',
            leaseDurationSeconds => 15,
        }),
    }, 'Lease leader election');
};

# ============================================================================
# 33. StorageClass
# ============================================================================

subtest 'StorageClass' => sub {
    build_and_verify('StorageClass', {
        metadata => {
            name        => 'fast-ssd',
            annotations => {
                'storageclass.kubernetes.io/is-default-class' => 'false',
            },
        },
        provisioner       => 'kubernetes.io/aws-ebs',
        parameters        => { type => 'gp3', iopsPerGB => '50' },
        reclaimPolicy     => 'Delete',
        volumeBindingMode => 'WaitForFirstConsumer',
    }, {
        kind              => 'StorageClass',
        provisioner       => 'kubernetes.io/aws-ebs',
        reclaimPolicy     => 'Delete',
        volumeBindingMode => 'WaitForFirstConsumer',
    }, 'StorageClass fast-ssd');
};

# ============================================================================
# 34. PriorityClass
# ============================================================================

subtest 'PriorityClass' => sub {
    build_and_verify('PriorityClass', {
        metadata    => { name => 'high-priority' },
        value       => 1000000,
        globalDefault => 0,
        description => 'Priority class for critical workloads',
    }, {
        kind          => 'PriorityClass',
        value         => 1000000,
        description   => 'Priority class for critical workloads',
    }, 'PriorityClass high-priority');
};

# ============================================================================
# 35. ResourceQuota
# ============================================================================

subtest 'ResourceQuota' => sub {
    build_and_verify('ResourceQuota', {
        metadata => {
            name      => 'team-quota',
            namespace => 'team-a',
        },
        spec => {
            hard => {
                'requests.cpu'    => '10',
                'requests.memory' => '20Gi',
                'limits.cpu'      => '20',
                'limits.memory'   => '40Gi',
                pods              => '50',
                services          => '10',
            },
        },
    }, {
        apiVersion => 'v1',
        kind       => 'ResourceQuota',
        spec       => {
            hard => superhashof({
                pods => '50',
                'requests.cpu' => '10',
            }),
        },
    }, 'ResourceQuota team-quota');
};

# ============================================================================
# 36. LimitRange
# ============================================================================

subtest 'LimitRange' => sub {
    build_and_verify('LimitRange', {
        metadata => {
            name      => 'default-limits',
            namespace => 'team-a',
        },
        spec => {
            limits => [
                {
                    type => 'Container',
                    default        => { cpu => '500m', memory => '256Mi' },
                    defaultRequest => { cpu => '100m', memory => '128Mi' },
                    max            => { cpu => '2',    memory => '2Gi' },
                    min            => { cpu => '50m',  memory => '64Mi' },
                },
                {
                    type => 'Pod',
                    max  => { cpu => '4', memory => '4Gi' },
                },
            ],
        },
    }, {
        apiVersion => 'v1',
        kind       => 'LimitRange',
        spec       => {
            limits => [
                superhashof({ type => 'Container' }),
                superhashof({ type => 'Pod' }),
            ],
        },
    }, 'LimitRange default-limits');
};

done_testing;
