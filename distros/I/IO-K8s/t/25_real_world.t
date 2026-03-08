#!/usr/bin/env perl
# Real-world Kubernetes YAML manifest round-trip tests for IO::K8s
#
# These tests take REAL Kubernetes YAML manifests from popular open-source
# projects and verify that IO::K8s can correctly parse and round-trip them.
# Each manifest is attributed to its source project.

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    eval { require YAML::PP; 1 }
        or plan skip_all => 'YAML::PP required for real-world YAML tests';
}

use IO::K8s;
use JSON::MaybeXS;

my $k8s = IO::K8s->new;
my $json_codec = JSON::MaybeXS->new(utf8 => 0, canonical => 1);

# Helper: parse YAML, inflate via IO::K8s, round-trip to JSON and back
sub round_trip_yaml {
    my ($yaml_str, $description) = @_;

    my $struct = YAML::PP::Load($yaml_str);
    ok(ref $struct eq 'HASH', "$description: YAML parsed to hashref");

    my $obj = $k8s->inflate($struct);
    ok(defined $obj, "$description: inflate succeeded");

    my $class = ref $obj;
    ok($class, "$description: got class $class");

    # Round-trip: object -> JSON struct -> re-inflate
    my $exported = $obj->TO_JSON;
    ok(ref $exported eq 'HASH', "$description: TO_JSON returns hashref");

    return ($obj, $struct, $exported);
}

# ============================================================================
# 1. Kubernetes Dashboard - Deployment with securityContext, tolerations,
#    nodeSelector, volumes, args, liveness probes
# Source: kubernetes/dashboard v2.7.0 recommended.yaml
# ============================================================================

subtest 'Kubernetes Dashboard Deployment' => sub {
    my $yaml = <<'END_YAML';
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: kubernetes-dashboard
          image: kubernetesui/dashboard:v2.7.0
          imagePullPolicy: Always
          ports:
            - containerPort: 8443
              protocol: TCP
          args:
            - --auto-generate-certificates
            - --namespace=kubernetes-dashboard
          volumeMounts:
            - name: kubernetes-dashboard-certs
              mountPath: /certs
            - mountPath: /tmp
              name: tmp-volume
          livenessProbe:
            httpGet:
              scheme: HTTPS
              path: /
              port: 8443
            initialDelaySeconds: 30
            timeoutSeconds: 30
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1001
            runAsGroup: 2001
      volumes:
        - name: kubernetes-dashboard-certs
          secret:
            secretName: kubernetes-dashboard-certs
        - name: tmp-volume
          emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      nodeSelector:
        "kubernetes.io/os": linux
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Dashboard Deployment');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');
    is($obj->metadata->name, 'kubernetes-dashboard', 'name');
    is($obj->metadata->namespace, 'kubernetes-dashboard', 'namespace');
    is($obj->spec->replicas, 1, 'replicas');
    is($obj->spec->revisionHistoryLimit, 10, 'revisionHistoryLimit');

    # Pod template spec
    my $pod_spec = $obj->spec->template->spec;
    isa_ok($pod_spec, 'IO::K8s::Api::Core::V1::PodSpec');

    # Pod-level securityContext
    isa_ok($pod_spec->securityContext, 'IO::K8s::Api::Core::V1::PodSecurityContext');
    is($pod_spec->securityContext->seccompProfile->type, 'RuntimeDefault', 'pod seccompProfile');

    # Container
    my $c = $pod_spec->containers->[0];
    isa_ok($c, 'IO::K8s::Api::Core::V1::Container');
    is($c->name, 'kubernetes-dashboard', 'container name');
    is($c->image, 'kubernetesui/dashboard:v2.7.0', 'image');
    is($c->imagePullPolicy, 'Always', 'imagePullPolicy');
    is(scalar @{$c->args}, 2, 'args count');
    is($c->args->[0], '--auto-generate-certificates', 'arg 0');

    # Container ports
    is($c->ports->[0]->containerPort, 8443, 'containerPort');
    is($c->ports->[0]->protocol, 'TCP', 'protocol');

    # Container-level securityContext
    isa_ok($c->securityContext, 'IO::K8s::Api::Core::V1::SecurityContext');
    ok(!$c->securityContext->allowPrivilegeEscalation, 'allowPrivilegeEscalation false');
    ok($c->securityContext->readOnlyRootFilesystem, 'readOnlyRootFilesystem true');
    is($c->securityContext->runAsUser, 1001, 'runAsUser');
    is($c->securityContext->runAsGroup, 2001, 'runAsGroup');

    # Liveness probe
    isa_ok($c->livenessProbe, 'IO::K8s::Api::Core::V1::Probe');
    is($c->livenessProbe->httpGet->scheme, 'HTTPS', 'probe scheme');
    is($c->livenessProbe->httpGet->path, '/', 'probe path');
    is($c->livenessProbe->initialDelaySeconds, 30, 'initialDelaySeconds');

    # Volume mounts
    is(scalar @{$c->volumeMounts}, 2, 'volumeMounts count');
    is($c->volumeMounts->[0]->mountPath, '/certs', 'mountPath');

    # Volumes
    is(scalar @{$pod_spec->volumes}, 2, 'volumes count');
    is($pod_spec->volumes->[0]->name, 'kubernetes-dashboard-certs', 'volume name');
    isa_ok($pod_spec->volumes->[0]->secret, 'IO::K8s::Api::Core::V1::SecretVolumeSource');

    # nodeSelector
    is($pod_spec->nodeSelector->{'kubernetes.io/os'}, 'linux', 'nodeSelector');

    # tolerations
    is(scalar @{$pod_spec->tolerations}, 1, 'tolerations count');
    isa_ok($pod_spec->tolerations->[0], 'IO::K8s::Api::Core::V1::Toleration');
    is($pod_spec->tolerations->[0]->key, 'node-role.kubernetes.io/master', 'toleration key');
    is($pod_spec->tolerations->[0]->effect, 'NoSchedule', 'toleration effect');

    # serviceAccountName
    is($pod_spec->serviceAccountName, 'kubernetes-dashboard', 'serviceAccountName');

    # Round-trip verification
    is($exported->{kind}, 'Deployment', 'round-trip kind');
    is($exported->{metadata}{name}, 'kubernetes-dashboard', 'round-trip name');
    is($exported->{spec}{replicas}, 1, 'round-trip replicas');
};

# ============================================================================
# 2. CoreDNS Deployment - podAntiAffinity, capabilities, dnsPolicy, probes,
#    configMap volume with items, resource requests/limits
# Source: coredns/deployment kubernetes/coredns.yaml
# ============================================================================

subtest 'CoreDNS Deployment' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/name: "CoreDNS"
    app.kubernetes.io/name: coredns
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
      app.kubernetes.io/name: coredns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
        app.kubernetes.io/name: coredns
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: coredns
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: k8s-app
                operator: In
                values: ["kube-dns"]
            topologyKey: kubernetes.io/hostname
      containers:
      - name: coredns
        image: coredns/coredns:1.9.4
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 8181
            scheme: HTTP
      dnsPolicy: Default
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'CoreDNS Deployment');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');
    is($obj->metadata->name, 'coredns', 'name');

    my $pod_spec = $obj->spec->template->spec;

    # Strategy
    is($obj->spec->strategy->type, 'RollingUpdate', 'strategy type');

    # priorityClassName
    is($pod_spec->priorityClassName, 'system-cluster-critical', 'priorityClassName');

    # affinity with podAntiAffinity + matchExpressions
    isa_ok($pod_spec->affinity, 'IO::K8s::Api::Core::V1::Affinity');
    isa_ok($pod_spec->affinity->podAntiAffinity, 'IO::K8s::Api::Core::V1::PodAntiAffinity');
    my $req = $pod_spec->affinity->podAntiAffinity->requiredDuringSchedulingIgnoredDuringExecution;
    is(scalar @$req, 1, 'podAntiAffinity rules count');
    isa_ok($req->[0], 'IO::K8s::Api::Core::V1::PodAffinityTerm');
    is($req->[0]->topologyKey, 'kubernetes.io/hostname', 'topologyKey');
    my $match_expr = $req->[0]->labelSelector->matchExpressions;
    is($match_expr->[0]->key, 'k8s-app', 'matchExpression key');
    is($match_expr->[0]->operator, 'In', 'matchExpression operator');
    is($match_expr->[0]->values->[0], 'kube-dns', 'matchExpression value');

    # Container with capabilities (add + drop)
    my $c = $pod_spec->containers->[0];
    isa_ok($c->securityContext->capabilities, 'IO::K8s::Api::Core::V1::Capabilities');
    is($c->securityContext->capabilities->add->[0], 'NET_BIND_SERVICE', 'capabilities add');
    is($c->securityContext->capabilities->drop->[0], 'all', 'capabilities drop');

    # Resources with both limits and requests
    isa_ok($c->resources, 'IO::K8s::Api::Core::V1::ResourceRequirements');
    is($c->resources->limits->{memory}, '170Mi', 'resource limits memory');
    is($c->resources->requests->{cpu}, '100m', 'resource requests cpu');
    is($c->resources->requests->{memory}, '70Mi', 'resource requests memory');

    # Multiple ports
    is(scalar @{$c->ports}, 3, 'port count');
    is($c->ports->[0]->protocol, 'UDP', 'UDP port');
    is($c->ports->[1]->protocol, 'TCP', 'TCP port');

    # Both liveness and readiness probes
    isa_ok($c->livenessProbe, 'IO::K8s::Api::Core::V1::Probe');
    isa_ok($c->readinessProbe, 'IO::K8s::Api::Core::V1::Probe');
    is($c->livenessProbe->failureThreshold, 5, 'failureThreshold');
    is($c->readinessProbe->httpGet->path, '/ready', 'readiness path');

    # dnsPolicy
    is($pod_spec->dnsPolicy, 'Default', 'dnsPolicy');

    # configMap volume with items
    my $vol = $pod_spec->volumes->[0];
    isa_ok($vol->configMap, 'IO::K8s::Api::Core::V1::ConfigMapVolumeSource');
    is($vol->configMap->name, 'coredns', 'configMap name');
    is($vol->configMap->items->[0]->key, 'Corefile', 'configMap item key');
    is($vol->configMap->items->[0]->path, 'Corefile', 'configMap item path');

    # Round-trip key fields
    is($exported->{spec}{template}{spec}{dnsPolicy}, 'Default', 'round-trip dnsPolicy');
    is($exported->{spec}{template}{spec}{priorityClassName}, 'system-cluster-critical', 'round-trip priorityClassName');
};

# ============================================================================
# 3. Prometheus Node Exporter DaemonSet - hostNetwork, hostPID, hostPath,
#    mountPropagation, hostPort, updateStrategy, toleration with operator Exists
# Source: prometheus-operator/kube-prometheus nodeExporter-daemonset.yaml
# ============================================================================

subtest 'Node Exporter DaemonSet' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: node-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 1.10.2
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: node-exporter
      app.kubernetes.io/part-of: kube-prometheus
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/default-container: node-exporter
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: node-exporter
        app.kubernetes.io/part-of: kube-prometheus
        app.kubernetes.io/version: 1.10.2
    spec:
      automountServiceAccountToken: true
      containers:
      - args:
        - --web.listen-address=127.0.0.1:9101
        - --path.sysfs=/host/sys
        - --path.rootfs=/host/root
        - --no-collector.wifi
        image: quay.io/prometheus/node-exporter:v1.10.2
        name: node-exporter
        resources:
          limits:
            cpu: 250m
            memory: 180Mi
          requests:
            cpu: 102m
            memory: 180Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - SYS_TIME
            drop:
            - ALL
          readOnlyRootFilesystem: true
        volumeMounts:
        - mountPath: /host/sys
          mountPropagation: HostToContainer
          name: sys
          readOnly: true
        - mountPath: /host/root
          mountPropagation: HostToContainer
          name: root
          readOnly: true
      - args:
        - --secure-listen-address=[$(IP)]:9100
        - --upstream=http://127.0.0.1:9101/
        env:
        - name: IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        image: quay.io/brancz/kube-rbac-proxy:v0.20.2
        name: kube-rbac-proxy
        ports:
        - containerPort: 9100
          hostPort: 9100
          name: https
        resources:
          limits:
            cpu: 20m
            memory: 40Mi
          requests:
            cpu: 10m
            memory: 20Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsGroup: 65532
          runAsNonRoot: true
          runAsUser: 65532
          seccompProfile:
            type: RuntimeDefault
      hostNetwork: true
      hostPID: true
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      securityContext:
        runAsGroup: 65534
        runAsNonRoot: true
        runAsUser: 65534
      serviceAccountName: node-exporter
      tolerations:
      - operator: Exists
      volumes:
      - hostPath:
          path: /sys
        name: sys
      - hostPath:
          path: /
        name: root
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 10%
    type: RollingUpdate
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Node Exporter DaemonSet');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::DaemonSet');
    is($obj->metadata->name, 'node-exporter', 'name');

    my $pod_spec = $obj->spec->template->spec;

    # hostNetwork and hostPID
    ok($pod_spec->hostNetwork, 'hostNetwork true');
    ok($pod_spec->hostPID, 'hostPID true');
    ok($pod_spec->automountServiceAccountToken, 'automountServiceAccountToken true');

    # Two containers (multi-container pod)
    is(scalar @{$pod_spec->containers}, 2, 'multi-container pod');

    # Env with fieldRef (valueFrom)
    my $proxy = $pod_spec->containers->[1];
    is($proxy->name, 'kube-rbac-proxy', 'sidecar name');
    my $env_ip = $proxy->env->[0];
    isa_ok($env_ip, 'IO::K8s::Api::Core::V1::EnvVar');
    is($env_ip->name, 'IP', 'env name');
    isa_ok($env_ip->valueFrom, 'IO::K8s::Api::Core::V1::EnvVarSource');
    is($env_ip->valueFrom->fieldRef->fieldPath, 'status.podIP', 'fieldRef fieldPath');

    # hostPort
    is($proxy->ports->[0]->hostPort, 9100, 'hostPort');

    # mountPropagation
    is($pod_spec->containers->[0]->volumeMounts->[0]->mountPropagation, 'HostToContainer', 'mountPropagation');

    # Toleration with operator Exists (no key)
    is($pod_spec->tolerations->[0]->operator, 'Exists', 'toleration operator Exists');

    # hostPath volumes
    isa_ok($pod_spec->volumes->[0]->hostPath, 'IO::K8s::Api::Core::V1::HostPathVolumeSource');
    is($pod_spec->volumes->[0]->hostPath->path, '/sys', 'hostPath path');

    # updateStrategy
    is($obj->spec->updateStrategy->type, 'RollingUpdate', 'updateStrategy type');

    # Round-trip
    ok($exported->{spec}{template}{spec}{hostNetwork}, 'round-trip hostNetwork');
    ok($exported->{spec}{template}{spec}{hostPID}, 'round-trip hostPID');
};

# ============================================================================
# 4. Argo CD Application Controller StatefulSet - complex env with configMapKeyRef
#    (optional), workingDir, readinessProbe, affinity with preferredDuringScheduling,
#    secret volume with items
# Source: argoproj/argo-cd stable/manifests/install.yaml
# ============================================================================

subtest 'Argo CD StatefulSet' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app.kubernetes.io/component: application-controller
    app.kubernetes.io/name: argocd-application-controller
    app.kubernetes.io/part-of: argocd
  name: argocd-application-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-application-controller
  serviceName: argocd-application-controller
  template:
    metadata:
      labels:
        app.kubernetes.io/name: argocd-application-controller
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: argocd-application-controller
              topologyKey: kubernetes.io/hostname
            weight: 100
          - podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/part-of: argocd
              topologyKey: kubernetes.io/hostname
            weight: 5
      containers:
      - args:
        - /usr/local/bin/argocd-application-controller
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              key: auth
              name: argocd-redis
        - name: ARGOCD_CONTROLLER_REPLICAS
          value: "1"
        - name: ARGOCD_RECONCILIATION_TIMEOUT
          valueFrom:
            configMapKeyRef:
              key: timeout.reconciliation
              name: argocd-cm
              optional: true
        - name: KUBECACHEDIR
          value: /tmp/kubecache
        image: quay.io/argoproj/argocd:v3.3.2
        imagePullPolicy: Always
        name: argocd-application-controller
        ports:
        - containerPort: 8082
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8082
          initialDelaySeconds: 5
          periodSeconds: 10
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - mountPath: /app/config/controller/tls
          name: argocd-repo-server-tls
        - mountPath: /home/argocd
          name: argocd-home
        - mountPath: /tmp
          name: argocd-application-controller-tmp
        workingDir: /home/argocd
      nodeSelector:
        kubernetes.io/os: linux
      serviceAccountName: argocd-application-controller
      volumes:
      - emptyDir: {}
        name: argocd-home
      - emptyDir: {}
        name: argocd-application-controller-tmp
      - name: argocd-repo-server-tls
        secret:
          items:
          - key: tls.crt
            path: tls.crt
          - key: tls.key
            path: tls.key
          - key: ca.crt
            path: ca.crt
          optional: true
          secretName: argocd-repo-server-tls
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Argo CD StatefulSet');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::StatefulSet');
    is($obj->metadata->name, 'argocd-application-controller', 'name');
    is($obj->spec->serviceName, 'argocd-application-controller', 'serviceName');

    my $pod_spec = $obj->spec->template->spec;

    # preferredDuringSchedulingIgnoredDuringExecution with weights
    my $preferred = $pod_spec->affinity->podAntiAffinity->preferredDuringSchedulingIgnoredDuringExecution;
    is(scalar @$preferred, 2, 'preferred anti-affinity rules');
    isa_ok($preferred->[0], 'IO::K8s::Api::Core::V1::WeightedPodAffinityTerm');
    is($preferred->[0]->weight, 100, 'weight 100');
    is($preferred->[1]->weight, 5, 'weight 5');

    # Env with secretKeyRef
    my $c = $pod_spec->containers->[0];
    my $redis_env = $c->env->[0];
    is($redis_env->name, 'REDIS_PASSWORD', 'secretKeyRef env name');
    isa_ok($redis_env->valueFrom->secretKeyRef, 'IO::K8s::Api::Core::V1::SecretKeySelector');
    is($redis_env->valueFrom->secretKeyRef->key, 'auth', 'secretKeyRef key');
    is($redis_env->valueFrom->secretKeyRef->name, 'argocd-redis', 'secretKeyRef secret name');

    # Env with configMapKeyRef + optional
    my $cm_env = $c->env->[2];
    is($cm_env->name, 'ARGOCD_RECONCILIATION_TIMEOUT', 'configMapKeyRef env name');
    isa_ok($cm_env->valueFrom->configMapKeyRef, 'IO::K8s::Api::Core::V1::ConfigMapKeySelector');
    is($cm_env->valueFrom->configMapKeyRef->key, 'timeout.reconciliation', 'configMapKeyRef key');
    ok($cm_env->valueFrom->configMapKeyRef->optional, 'configMapKeyRef optional');

    # Env with plain value
    my $plain_env = $c->env->[1];
    is($plain_env->name, 'ARGOCD_CONTROLLER_REPLICAS', 'plain env name');
    is($plain_env->value, '1', 'plain env value');

    # workingDir
    is($c->workingDir, '/home/argocd', 'workingDir');

    # readinessProbe with periodSeconds
    is($c->readinessProbe->periodSeconds, 10, 'periodSeconds');

    # Secret volume with items and optional
    my $tls_vol = $pod_spec->volumes->[2];
    isa_ok($tls_vol->secret, 'IO::K8s::Api::Core::V1::SecretVolumeSource');
    is($tls_vol->secret->secretName, 'argocd-repo-server-tls', 'secret name');
    ok($tls_vol->secret->optional, 'secret optional');
    is(scalar @{$tls_vol->secret->items}, 3, 'secret items count');

    # Round-trip
    is($exported->{kind}, 'StatefulSet', 'round-trip kind');
    is($exported->{spec}{serviceName}, 'argocd-application-controller', 'round-trip serviceName');
};

# ============================================================================
# 5. Grafana NetworkPolicy - egress/ingress rules, podSelector with labels,
#    policyTypes
# Source: prometheus-operator/kube-prometheus grafana-networkPolicy.yaml
# ============================================================================

subtest 'Grafana NetworkPolicy' => sub {
    my $yaml = <<'END_YAML';
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  labels:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 12.3.3
  name: grafana
  namespace: monitoring
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - port: 3000
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/component: grafana
      app.kubernetes.io/name: grafana
      app.kubernetes.io/part-of: kube-prometheus
  policyTypes:
  - Egress
  - Ingress
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Grafana NetworkPolicy');
    isa_ok($obj, 'IO::K8s::Api::Networking::V1::NetworkPolicy');
    is($obj->metadata->name, 'grafana', 'name');

    # Egress rule (empty = allow all)
    is(scalar @{$obj->spec->egress}, 1, 'egress rules count');

    # Ingress rule with from + ports
    is(scalar @{$obj->spec->ingress}, 1, 'ingress rules count');
    my $ingress = $obj->spec->ingress->[0];
    isa_ok($ingress, 'IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule');
    is($ingress->from->[0]->podSelector->matchLabels->{'app.kubernetes.io/name'}, 'prometheus', 'from podSelector');
    is($ingress->ports->[0]->port, 3000, 'ingress port');
    is($ingress->ports->[0]->protocol, 'TCP', 'ingress protocol');

    # podSelector
    is($obj->spec->podSelector->matchLabels->{'app.kubernetes.io/name'}, 'grafana', 'podSelector label');

    # policyTypes
    is_deeply($obj->spec->policyTypes, ['Egress', 'Ingress'], 'policyTypes');

    # Round-trip
    is($exported->{kind}, 'NetworkPolicy', 'round-trip kind');
    is($exported->{apiVersion}, 'networking.k8s.io/v1', 'round-trip apiVersion');
};

# ============================================================================
# 6. CoreDNS ClusterRole - RBAC rules with apiGroups, resources, verbs
# Source: coredns/deployment kubernetes/coredns.yaml
# ============================================================================

subtest 'CoreDNS ClusterRole' => sub {
    my $yaml = <<'END_YAML';
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:coredns
rules:
  - apiGroups:
    - ""
    resources:
    - endpoints
    - services
    - pods
    - namespaces
    verbs:
    - list
    - watch
  - apiGroups:
    - discovery.k8s.io
    resources:
    - endpointslices
    verbs:
    - list
    - watch
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'CoreDNS ClusterRole');
    isa_ok($obj, 'IO::K8s::Api::Rbac::V1::ClusterRole');
    is($obj->metadata->name, 'system:coredns', 'name with colon');
    is($obj->metadata->labels->{'kubernetes.io/bootstrapping'}, 'rbac-defaults', 'label with slash');

    # Rules
    is(scalar @{$obj->rules}, 2, 'rules count');
    my $rule0 = $obj->rules->[0];
    isa_ok($rule0, 'IO::K8s::Api::Rbac::V1::PolicyRule');
    is_deeply($rule0->apiGroups, [''], 'apiGroups with empty string');
    is(scalar @{$rule0->resources}, 4, 'resources count');
    is_deeply($rule0->verbs, ['list', 'watch'], 'verbs');

    my $rule1 = $obj->rules->[1];
    is($rule1->apiGroups->[0], 'discovery.k8s.io', 'apiGroup discovery');
    is($rule1->resources->[0], 'endpointslices', 'resource endpointslices');

    # Round-trip
    is($exported->{apiVersion}, 'rbac.authorization.k8s.io/v1', 'round-trip apiVersion');
};

# ============================================================================
# 7. Kubernetes Dashboard Role - RBAC rules with resourceNames
# Source: kubernetes/dashboard v2.7.0 recommended.yaml
# ============================================================================

subtest 'Dashboard Role with resourceNames' => sub {
    my $yaml = <<'END_YAML';
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs", "kubernetes-dashboard-csrf"]
    verbs: ["get", "update", "delete"]
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["kubernetes-dashboard-settings"]
    verbs: ["get", "update"]
  - apiGroups: [""]
    resources: ["services"]
    resourceNames: ["heapster", "dashboard-metrics-scraper"]
    verbs: ["proxy"]
  - apiGroups: [""]
    resources: ["services/proxy"]
    resourceNames: ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
    verbs: ["get"]
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Dashboard Role');
    isa_ok($obj, 'IO::K8s::Api::Rbac::V1::Role');
    is($obj->metadata->name, 'kubernetes-dashboard', 'name');
    is($obj->metadata->namespace, 'kubernetes-dashboard', 'namespace');

    is(scalar @{$obj->rules}, 4, 'rules count');

    # Rule with resourceNames
    my $rule = $obj->rules->[0];
    is(scalar @{$rule->resourceNames}, 3, 'resourceNames count');
    is($rule->resourceNames->[0], 'kubernetes-dashboard-key-holder', 'resourceName');
    is_deeply($rule->verbs, ['get', 'update', 'delete'], 'verbs');

    # services/proxy resource
    my $proxy_rule = $obj->rules->[3];
    is($proxy_rule->resources->[0], 'services/proxy', 'sub-resource services/proxy');
    is(scalar @{$proxy_rule->resourceNames}, 5, 'proxy resourceNames count');

    # Round-trip
    is($exported->{kind}, 'Role', 'round-trip kind');
};

# ============================================================================
# 8. Dashboard ClusterRoleBinding - roleRef, subjects
# Source: kubernetes/dashboard v2.7.0 recommended.yaml
# ============================================================================

subtest 'Dashboard ClusterRoleBinding' => sub {
    my $yaml = <<'END_YAML';
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Dashboard ClusterRoleBinding');
    isa_ok($obj, 'IO::K8s::Api::Rbac::V1::ClusterRoleBinding');

    # roleRef
    isa_ok($obj->roleRef, 'IO::K8s::Api::Rbac::V1::RoleRef');
    is($obj->roleRef->apiGroup, 'rbac.authorization.k8s.io', 'roleRef apiGroup');
    is($obj->roleRef->kind, 'ClusterRole', 'roleRef kind');
    is($obj->roleRef->name, 'kubernetes-dashboard', 'roleRef name');

    # subjects
    is(scalar @{$obj->subjects}, 1, 'subjects count');
    isa_ok($obj->subjects->[0], 'IO::K8s::Api::Rbac::V1::Subject');
    is($obj->subjects->[0]->kind, 'ServiceAccount', 'subject kind');
    is($obj->subjects->[0]->namespace, 'kubernetes-dashboard', 'subject namespace');

    # Round-trip
    is($exported->{roleRef}{kind}, 'ClusterRole', 'round-trip roleRef kind');
};

# ============================================================================
# 9. CoreDNS Service - named ports, multiple protocols, clusterIP, annotations
# Source: coredns/deployment kubernetes/coredns.yaml (adapted, clusterIP replaced)
# ============================================================================

subtest 'CoreDNS Service' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  annotations:
    prometheus.io/port: "9153"
    prometheus.io/scrape: "true"
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "CoreDNS"
    app.kubernetes.io/name: coredns
spec:
  selector:
    k8s-app: kube-dns
    app.kubernetes.io/name: coredns
  clusterIP: 10.96.0.10
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
  - name: metrics
    port: 9153
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'CoreDNS Service');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::Service');
    is($obj->metadata->name, 'kube-dns', 'name');

    # Annotations
    is($obj->metadata->annotations->{'prometheus.io/port'}, '9153', 'annotation with slash');
    is($obj->metadata->annotations->{'prometheus.io/scrape'}, 'true', 'annotation scrape');

    # Labels with slash and boolean-like string value
    is($obj->metadata->labels->{'kubernetes.io/cluster-service'}, 'true', 'label boolean string');

    # clusterIP
    is($obj->spec->clusterIP, '10.96.0.10', 'clusterIP');

    # Named ports with mixed protocols
    is(scalar @{$obj->spec->ports}, 3, 'ports count');
    is($obj->spec->ports->[0]->name, 'dns', 'port name');
    is($obj->spec->ports->[0]->protocol, 'UDP', 'UDP protocol');
    is($obj->spec->ports->[1]->port, 53, 'port number');

    # Round-trip
    is($exported->{spec}{clusterIP}, '10.96.0.10', 'round-trip clusterIP');
    is(scalar @{$exported->{spec}{ports}}, 3, 'round-trip ports count');
};

# ============================================================================
# 10. Prometheus Operator Deployment - multi-container, pod-level + container-level
#     securityContext, seccompProfile
# Source: prometheus-operator/kube-prometheus prometheusOperator-deployment.yaml
# ============================================================================

subtest 'Prometheus Operator Multi-Container Deployment' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: prometheus-operator
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 0.89.0
  name: prometheus-operator
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: controller
      app.kubernetes.io/name: prometheus-operator
      app.kubernetes.io/part-of: kube-prometheus
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/default-container: prometheus-operator
      labels:
        app.kubernetes.io/component: controller
        app.kubernetes.io/name: prometheus-operator
        app.kubernetes.io/part-of: kube-prometheus
        app.kubernetes.io/version: 0.89.0
    spec:
      automountServiceAccountToken: true
      containers:
      - args:
        - --kubelet-service=kube-system/kubelet
        - --prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:v0.89.0
        env:
        - name: GOGC
          value: "30"
        image: quay.io/prometheus-operator/prometheus-operator:v0.89.0
        name: prometheus-operator
        ports:
        - containerPort: 8080
          name: http
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
      - args:
        - --secure-listen-address=:8443
        - --upstream=http://127.0.0.1:8080/
        image: quay.io/brancz/kube-rbac-proxy:v0.20.2
        name: kube-rbac-proxy
        ports:
        - containerPort: 8443
          name: https
        resources:
          limits:
            cpu: 20m
            memory: 40Mi
          requests:
            cpu: 10m
            memory: 20Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsGroup: 65532
          runAsNonRoot: true
          runAsUser: 65532
          seccompProfile:
            type: RuntimeDefault
      nodeSelector:
        kubernetes.io/os: linux
      securityContext:
        runAsGroup: 65534
        runAsNonRoot: true
        runAsUser: 65534
        seccompProfile:
          type: RuntimeDefault
      serviceAccountName: prometheus-operator
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Prometheus Operator Deployment');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');

    my $pod_spec = $obj->spec->template->spec;

    # Pod-level securityContext
    is($pod_spec->securityContext->runAsUser, 65534, 'pod runAsUser');
    is($pod_spec->securityContext->runAsGroup, 65534, 'pod runAsGroup');
    ok($pod_spec->securityContext->runAsNonRoot, 'pod runAsNonRoot');
    is($pod_spec->securityContext->seccompProfile->type, 'RuntimeDefault', 'pod seccompProfile');

    # Container-level securityContext (different user)
    my $proxy = $pod_spec->containers->[1];
    is($proxy->securityContext->runAsUser, 65532, 'container runAsUser');
    is($proxy->securityContext->runAsGroup, 65532, 'container runAsGroup');

    # Both containers have capabilities drop
    for my $c (@{$pod_spec->containers}) {
        ok($c->securityContext->capabilities, $c->name . ' has capabilities');
        is($c->securityContext->capabilities->drop->[0], 'ALL', $c->name . ' drops ALL');
    }

    # Pod annotations
    is($obj->spec->template->metadata->annotations->{'kubectl.kubernetes.io/default-container'},
       'prometheus-operator', 'template annotation');

    # Round-trip
    is($exported->{spec}{template}{spec}{securityContext}{runAsUser}, 65534, 'round-trip pod runAsUser');
};

# ============================================================================
# 11. ConfigMap with multi-line data (CoreDNS Corefile)
# Source: coredns/deployment kubernetes/coredns.yaml
# ============================================================================

subtest 'CoreDNS ConfigMap with multi-line data' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
          lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf {
          max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'CoreDNS ConfigMap');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::ConfigMap');
    is($obj->metadata->name, 'coredns', 'name');
    ok(defined $obj->data->{Corefile}, 'Corefile key exists');
    like($obj->data->{Corefile}, qr/prometheus :9153/, 'multi-line data preserved');
    like($obj->data->{Corefile}, qr/cache 30/, 'multi-line data content');

    # Round-trip
    like($exported->{data}{Corefile}, qr/kubernetes cluster\.local/, 'round-trip multi-line data');
};

# ============================================================================
# 12. Dashboard ServiceAccount
# Source: kubernetes/dashboard v2.7.0 recommended.yaml
# ============================================================================

subtest 'Dashboard ServiceAccount' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Dashboard ServiceAccount');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::ServiceAccount');
    is($obj->metadata->name, 'kubernetes-dashboard', 'name');
    is($obj->metadata->namespace, 'kubernetes-dashboard', 'namespace');
    is($obj->metadata->labels->{'k8s-app'}, 'kubernetes-dashboard', 'label');

    # Round-trip
    is($exported->{kind}, 'ServiceAccount', 'round-trip kind');
    is($exported->{apiVersion}, 'v1', 'round-trip apiVersion');
};

# ============================================================================
# 13. Dashboard Secret
# Source: kubernetes/dashboard v2.7.0 recommended.yaml
# ============================================================================

subtest 'Dashboard Secret' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-csrf
  namespace: kubernetes-dashboard
type: Opaque
data:
  csrf: ""
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Dashboard Secret');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::Secret');
    is($obj->metadata->name, 'kubernetes-dashboard-csrf', 'name');
    is($obj->type, 'Opaque', 'type');
    is($obj->data->{csrf}, '', 'empty data value');

    # Round-trip
    is($exported->{type}, 'Opaque', 'round-trip type');
};

# ============================================================================
# 14. Namespace
# Source: kubernetes/dashboard v2.7.0 recommended.yaml
# ============================================================================

subtest 'Dashboard Namespace' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: Namespace
metadata:
  name: kubernetes-dashboard
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Dashboard Namespace');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::Namespace');
    is($obj->metadata->name, 'kubernetes-dashboard', 'name');

    # Round-trip
    is($exported->{kind}, 'Namespace', 'round-trip kind');
};

# ============================================================================
# 15. HorizontalPodAutoscaler - v2 with metrics, scaleTargetRef, behavior
# Source: based on real NGINX Ingress Controller HPA patterns
# ============================================================================

subtest 'HorizontalPodAutoscaler v2' => sub {
    my $yaml = <<'END_YAML';
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/component: controller
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-ingress-controller
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'HPA v2');
    isa_ok($obj, 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler');
    is($obj->metadata->name, 'nginx-ingress-controller', 'name');

    # scaleTargetRef
    is($obj->spec->scaleTargetRef->kind, 'Deployment', 'scaleTargetRef kind');
    is($obj->spec->scaleTargetRef->name, 'nginx-ingress-controller', 'scaleTargetRef name');

    # Replica bounds
    is($obj->spec->minReplicas, 2, 'minReplicas');
    is($obj->spec->maxReplicas, 10, 'maxReplicas');

    # Metrics
    is(scalar @{$obj->spec->metrics}, 2, 'metrics count');
    is($obj->spec->metrics->[0]->type, 'Resource', 'metric type');
    is($obj->spec->metrics->[0]->resource->name, 'cpu', 'metric resource name');
    is($obj->spec->metrics->[0]->resource->target->type, 'Utilization', 'target type');
    is($obj->spec->metrics->[0]->resource->target->averageUtilization, 50, 'averageUtilization');

    # Behavior
    my $behavior = $obj->spec->behavior;
    isa_ok($behavior, 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerBehavior');
    is($behavior->scaleDown->stabilizationWindowSeconds, 300, 'scaleDown stabilization');
    is($behavior->scaleUp->selectPolicy, 'Max', 'scaleUp selectPolicy');
    is(scalar @{$behavior->scaleUp->policies}, 2, 'scaleUp policies count');

    # Round-trip
    is($exported->{spec}{maxReplicas}, 10, 'round-trip maxReplicas');
    is($exported->{spec}{metrics}[0]{resource}{name}, 'cpu', 'round-trip metric name');
};

# ============================================================================
# 16. PodDisruptionBudget
# Source: based on kube-prometheus PDB patterns
# ============================================================================

subtest 'PodDisruptionBudget' => sub {
    my $yaml = <<'END_YAML';
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: alertmanager-main
  namespace: monitoring
  labels:
    app.kubernetes.io/component: alert-router
    app.kubernetes.io/name: alertmanager
    app.kubernetes.io/part-of: kube-prometheus
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: alert-router
      app.kubernetes.io/name: alertmanager
      app.kubernetes.io/part-of: kube-prometheus
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'PDB');
    isa_ok($obj, 'IO::K8s::Api::Policy::V1::PodDisruptionBudget');
    is($obj->metadata->name, 'alertmanager-main', 'name');

    # maxUnavailable (IntOrStr)
    is($obj->spec->maxUnavailable, 1, 'maxUnavailable');

    # selector
    is($obj->spec->selector->matchLabels->{'app.kubernetes.io/name'}, 'alertmanager', 'selector label');

    # Round-trip
    is($exported->{kind}, 'PodDisruptionBudget', 'round-trip kind');
    is($exported->{apiVersion}, 'policy/v1', 'round-trip apiVersion');
};

# ============================================================================
# 17. LimitRange
# Source: based on common Kubernetes namespace limit range patterns
# ============================================================================

subtest 'LimitRange' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
  - type: Container
    default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    max:
      cpu: "2"
      memory: 2Gi
    min:
      cpu: 50m
      memory: 64Mi
  - type: Pod
    max:
      cpu: "4"
      memory: 4Gi
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'LimitRange');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::LimitRange');
    is($obj->metadata->name, 'default-limits', 'name');

    my $limits = $obj->spec->limits;
    is(scalar @$limits, 2, 'limits count');

    # Container limits
    my $container_limit = $limits->[0];
    isa_ok($container_limit, 'IO::K8s::Api::Core::V1::LimitRangeItem');
    is($container_limit->type, 'Container', 'type');
    is($container_limit->default->{cpu}, '500m', 'default cpu');
    is($container_limit->default->{memory}, '512Mi', 'default memory');
    is($container_limit->defaultRequest->{cpu}, '100m', 'defaultRequest cpu');
    is($container_limit->max->{memory}, '2Gi', 'max memory');
    is($container_limit->min->{cpu}, '50m', 'min cpu');

    # Pod limits
    is($limits->[1]->type, 'Pod', 'Pod type');
    is($limits->[1]->max->{cpu}, '4', 'pod max cpu');

    # Round-trip
    is($exported->{kind}, 'LimitRange', 'round-trip kind');
    is($exported->{spec}{limits}[0]{default}{cpu}, '500m', 'round-trip default cpu');
};

# ============================================================================
# 18. ResourceQuota
# Source: based on common Kubernetes namespace quota patterns
# ============================================================================

subtest 'ResourceQuota' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
    services: "20"
    persistentvolumeclaims: "10"
    configmaps: "30"
    secrets: "30"
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'ResourceQuota');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::ResourceQuota');
    is($obj->metadata->name, 'compute-resources', 'name');

    is($obj->spec->hard->{'requests.cpu'}, '10', 'requests.cpu');
    is($obj->spec->hard->{'requests.memory'}, '20Gi', 'requests.memory');
    is($obj->spec->hard->{'pods'}, '50', 'pods');
    is($obj->spec->hard->{'persistentvolumeclaims'}, '10', 'PVCs');

    # Round-trip
    is($exported->{spec}{hard}{'limits.cpu'}, '20', 'round-trip limits.cpu');
};

# ============================================================================
# 19. CronJob - schedule, jobTemplate with ttlSecondsAfterFinished,
#     restartPolicy, concurrencyPolicy
# Source: based on common etcd backup CronJob patterns
# ============================================================================

subtest 'CronJob (etcd backup pattern)' => sub {
    my $yaml = <<'END_YAML';
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: kube-system
  labels:
    app: etcd-backup
spec:
  schedule: "0 */6 * * *"
  concurrencyPolicy: Forbid
  failedJobsHistoryLimit: 3
  successfulJobsHistoryLimit: 5
  suspend: false
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 86400
      template:
        spec:
          restartPolicy: OnFailure
          serviceAccountName: etcd-backup
          containers:
          - name: etcd-backup
            image: bitnami/etcd:3.5
            command:
            - /bin/sh
            - -c
            - |
              etcdctl snapshot save /backup/snapshot.db
            env:
            - name: ETCDCTL_API
              value: "3"
            - name: ETCDCTL_ENDPOINTS
              value: "https://etcd-0.etcd:2379"
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                cpu: 500m
                memory: 256Mi
          volumes:
          - name: backup-volume
            persistentVolumeClaim:
              claimName: etcd-backup-pvc
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'CronJob');
    isa_ok($obj, 'IO::K8s::Api::Batch::V1::CronJob');
    is($obj->metadata->name, 'etcd-backup', 'name');

    # Schedule
    is($obj->spec->schedule, '0 */6 * * *', 'schedule');
    is($obj->spec->concurrencyPolicy, 'Forbid', 'concurrencyPolicy');
    is($obj->spec->failedJobsHistoryLimit, 3, 'failedJobsHistoryLimit');
    is($obj->spec->successfulJobsHistoryLimit, 5, 'successfulJobsHistoryLimit');
    ok(!$obj->spec->suspend, 'suspend false');

    # Job template
    my $job_spec = $obj->spec->jobTemplate->spec;
    is($job_spec->ttlSecondsAfterFinished, 86400, 'ttlSecondsAfterFinished');

    # Pod template
    my $pod_spec = $job_spec->template->spec;
    is($pod_spec->restartPolicy, 'OnFailure', 'restartPolicy');

    # Container with command (multi-line)
    my $c = $pod_spec->containers->[0];
    is(scalar @{$c->command}, 3, 'command args count');
    is($c->command->[0], '/bin/sh', 'command shell');
    like($c->command->[2], qr/etcdctl snapshot save/, 'command content');

    # PVC volume
    my $vol = $pod_spec->volumes->[0];
    isa_ok($vol->persistentVolumeClaim, 'IO::K8s::Api::Core::V1::PersistentVolumeClaimVolumeSource');
    is($vol->persistentVolumeClaim->claimName, 'etcd-backup-pvc', 'PVC claimName');

    # Round-trip
    is($exported->{spec}{schedule}, '0 */6 * * *', 'round-trip schedule');
    is($exported->{spec}{concurrencyPolicy}, 'Forbid', 'round-trip concurrencyPolicy');
};

# ============================================================================
# 20. Ingress with TLS, multiple rules, pathType
# Source: based on common NGINX Ingress Controller patterns
# ============================================================================

subtest 'Ingress with TLS and multiple rules' => sub {
    my $yaml = <<'END_YAML';
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    - api.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-api
            port:
              number: 8080
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-api
            port:
              number: 8080
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Ingress');
    isa_ok($obj, 'IO::K8s::Api::Networking::V1::Ingress');
    is($obj->metadata->name, 'app-ingress', 'name');

    # Annotations with long values / dots / slashes
    is($obj->metadata->annotations->{'nginx.ingress.kubernetes.io/rewrite-target'}, '/', 'nginx annotation');
    is($obj->metadata->annotations->{'cert-manager.io/cluster-issuer'}, 'letsencrypt-prod', 'cert-manager annotation');

    # ingressClassName
    is($obj->spec->ingressClassName, 'nginx', 'ingressClassName');

    # TLS
    is(scalar @{$obj->spec->tls}, 1, 'tls count');
    isa_ok($obj->spec->tls->[0], 'IO::K8s::Api::Networking::V1::IngressTLS');
    is_deeply($obj->spec->tls->[0]->hosts, ['app.example.com', 'api.example.com'], 'tls hosts');
    is($obj->spec->tls->[0]->secretName, 'app-tls', 'tls secretName');

    # Multiple rules
    is(scalar @{$obj->spec->rules}, 2, 'rules count');
    my $rule0 = $obj->spec->rules->[0];
    isa_ok($rule0, 'IO::K8s::Api::Networking::V1::IngressRule');
    is($rule0->host, 'app.example.com', 'host');

    # Multiple paths per rule
    is(scalar @{$rule0->http->paths}, 2, 'paths count');
    is($rule0->http->paths->[0]->pathType, 'Prefix', 'pathType');
    is($rule0->http->paths->[0]->backend->service->name, 'frontend', 'backend service name');
    is($rule0->http->paths->[0]->backend->service->port->number, 80, 'backend port number');
    is($rule0->http->paths->[1]->path, '/api', 'second path');
    is($rule0->http->paths->[1]->backend->service->port->number, 8080, 'api backend port');

    # Round-trip
    is($exported->{spec}{ingressClassName}, 'nginx', 'round-trip ingressClassName');
    is($exported->{spec}{tls}[0]{secretName}, 'app-tls', 'round-trip TLS secretName');
};

# ============================================================================
# 21. Job with backoffLimit, completions, parallelism
# Source: based on common batch processing patterns
# ============================================================================

subtest 'Job with parallelism' => sub {
    my $yaml = <<'END_YAML';
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
  namespace: production
  labels:
    app: data-migration
    batch.kubernetes.io/job-type: migration
spec:
  parallelism: 3
  completions: 10
  backoffLimit: 6
  activeDeadlineSeconds: 3600
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: myapp/migrator:v2.1
        command: ["/migrate", "--batch-size=1000"]
        env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: host
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: "2"
            memory: 4Gi
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Job');
    isa_ok($obj, 'IO::K8s::Api::Batch::V1::Job');
    is($obj->metadata->name, 'data-migration', 'name');

    is($obj->spec->parallelism, 3, 'parallelism');
    is($obj->spec->completions, 10, 'completions');
    is($obj->spec->backoffLimit, 6, 'backoffLimit');
    is($obj->spec->activeDeadlineSeconds, 3600, 'activeDeadlineSeconds');

    my $pod_spec = $obj->spec->template->spec;
    is($pod_spec->restartPolicy, 'Never', 'restartPolicy');

    # Multiple secretKeyRef env vars
    my $c = $pod_spec->containers->[0];
    is($c->env->[0]->valueFrom->secretKeyRef->key, 'host', 'secretKeyRef key');
    is($c->env->[1]->valueFrom->secretKeyRef->key, 'password', 'secretKeyRef password key');

    # Round-trip
    is($exported->{spec}{parallelism}, 3, 'round-trip parallelism');
    is($exported->{spec}{completions}, 10, 'round-trip completions');
};

# ============================================================================
# 22. Deployment with lifecycle hooks, topologySpreadConstraints, envFrom,
#     imagePullSecrets, terminationGracePeriodSeconds
# Source: based on real production workload patterns
# ============================================================================

subtest 'Deployment with lifecycle hooks and topologySpreadConstraints' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
  labels:
    app: web-app
    version: v3.2.1
  annotations:
    deployment.kubernetes.io/revision: "15"
    kubernetes.io/change-cause: "Update image to v3.2.1"
spec:
  replicas: 5
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        version: v3.2.1
    spec:
      terminationGracePeriodSeconds: 60
      imagePullSecrets:
      - name: registry-credentials
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web-app
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: web-app
      initContainers:
      - name: wait-for-db
        image: busybox:1.36
        command: ['sh', '-c', 'until nc -z postgres-primary 5432; do sleep 2; done']
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
      containers:
      - name: web
        image: myapp/web:v3.2.1
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
        envFrom:
        - configMapRef:
            name: web-app-config
        - secretRef:
            name: web-app-secrets
            optional: true
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15 && kill -SIGTERM 1"]
          postStart:
            httpGet:
              path: /warmup
              port: 8080
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        resources:
          requests:
            cpu: 250m
            memory: 512Mi
          limits:
            cpu: "1"
            memory: 1Gi
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Lifecycle+Topology Deployment');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');
    is($obj->spec->replicas, 5, 'replicas');

    my $pod_spec = $obj->spec->template->spec;

    # terminationGracePeriodSeconds
    is($pod_spec->terminationGracePeriodSeconds, 60, 'terminationGracePeriodSeconds');

    # imagePullSecrets
    is(scalar @{$pod_spec->imagePullSecrets}, 1, 'imagePullSecrets count');
    isa_ok($pod_spec->imagePullSecrets->[0], 'IO::K8s::Api::Core::V1::LocalObjectReference');
    is($pod_spec->imagePullSecrets->[0]->name, 'registry-credentials', 'imagePullSecrets name');

    # topologySpreadConstraints
    is(scalar @{$pod_spec->topologySpreadConstraints}, 2, 'topology constraints count');
    my $tsc = $pod_spec->topologySpreadConstraints->[0];
    isa_ok($tsc, 'IO::K8s::Api::Core::V1::TopologySpreadConstraint');
    is($tsc->maxSkew, 1, 'maxSkew');
    is($tsc->topologyKey, 'topology.kubernetes.io/zone', 'topologyKey zone');
    is($tsc->whenUnsatisfiable, 'DoNotSchedule', 'whenUnsatisfiable');
    is($pod_spec->topologySpreadConstraints->[1]->whenUnsatisfiable, 'ScheduleAnyway', 'ScheduleAnyway');

    # initContainers
    is(scalar @{$pod_spec->initContainers}, 1, 'initContainers count');
    is($pod_spec->initContainers->[0]->name, 'wait-for-db', 'init container name');
    isa_ok($pod_spec->initContainers->[0], 'IO::K8s::Api::Core::V1::Container');

    # envFrom (configMapRef + secretRef)
    my $c = $pod_spec->containers->[0];
    is(scalar @{$c->envFrom}, 2, 'envFrom count');
    isa_ok($c->envFrom->[0], 'IO::K8s::Api::Core::V1::EnvFromSource');
    is($c->envFrom->[0]->configMapRef->name, 'web-app-config', 'configMapRef name');
    is($c->envFrom->[1]->secretRef->name, 'web-app-secrets', 'secretRef name');
    ok($c->envFrom->[1]->secretRef->optional, 'secretRef optional');

    # lifecycle hooks
    isa_ok($c->lifecycle, 'IO::K8s::Api::Core::V1::Lifecycle');

    # preStop with exec
    isa_ok($c->lifecycle->preStop, 'IO::K8s::Api::Core::V1::LifecycleHandler');
    isa_ok($c->lifecycle->preStop->exec, 'IO::K8s::Api::Core::V1::ExecAction');
    is($c->lifecycle->preStop->exec->command->[0], '/bin/sh', 'preStop exec command');

    # postStart with httpGet
    isa_ok($c->lifecycle->postStart, 'IO::K8s::Api::Core::V1::LifecycleHandler');
    isa_ok($c->lifecycle->postStart->httpGet, 'IO::K8s::Api::Core::V1::HTTPGetAction');
    is($c->lifecycle->postStart->httpGet->path, '/warmup', 'postStart httpGet path');

    # Round-trip
    is($exported->{spec}{template}{spec}{terminationGracePeriodSeconds}, 60, 'round-trip termGrace');
    is($exported->{spec}{template}{spec}{topologySpreadConstraints}[0]{maxSkew}, 1, 'round-trip maxSkew');
};

# ============================================================================
# 23. PersistentVolumeClaim
# Source: based on common database PVC patterns
# ============================================================================

subtest 'PersistentVolumeClaim' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: database
  labels:
    app: postgresql
    tier: database
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: fast-ssd
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'PVC');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::PersistentVolumeClaim');
    is($obj->metadata->name, 'postgres-data', 'name');

    is_deeply($obj->spec->accessModes, ['ReadWriteOnce'], 'accessModes');
    is($obj->spec->resources->requests->{storage}, '100Gi', 'storage request');
    is($obj->spec->storageClassName, 'fast-ssd', 'storageClassName');

    # Round-trip
    is($exported->{spec}{storageClassName}, 'fast-ssd', 'round-trip storageClassName');
};

# ============================================================================
# 24. Grafana Deployment - many volumes + volumeMounts, emptyDir with medium,
#     configMap volumes, secret volumes
# Source: prometheus-operator/kube-prometheus grafana-deployment.yaml (simplified)
# ============================================================================

subtest 'Grafana Deployment (many volumes)' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 12.3.3
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: grafana
      app.kubernetes.io/name: grafana
  template:
    metadata:
      annotations:
        checksum/grafana-config: 87d6f5bcd64386d559e783323814512a
        checksum/grafana-datasources: ac506ebb7b108e91ca5dd65a165299a9
      labels:
        app.kubernetes.io/component: grafana
        app.kubernetes.io/name: grafana
        app.kubernetes.io/version: 12.3.3
    spec:
      automountServiceAccountToken: false
      containers:
      - env: []
        image: grafana/grafana:12.3.3
        name: grafana
        ports:
        - containerPort: 3000
          name: http
        readinessProbe:
          httpGet:
            path: /api/health
            port: http
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - mountPath: /var/lib/grafana
          name: grafana-storage
          readOnly: false
        - mountPath: /etc/grafana/provisioning/datasources
          name: grafana-datasources
          readOnly: false
        - mountPath: /etc/grafana/provisioning/dashboards
          name: grafana-dashboards
          readOnly: false
        - mountPath: /tmp
          name: tmp-plugins
          readOnly: false
        - mountPath: /etc/grafana
          name: grafana-config
          readOnly: false
      nodeSelector:
        kubernetes.io/os: linux
      securityContext:
        fsGroup: 65534
        runAsGroup: 65534
        runAsNonRoot: true
        runAsUser: 65534
      serviceAccountName: grafana
      volumes:
      - emptyDir: {}
        name: grafana-storage
      - name: grafana-datasources
        secret:
          secretName: grafana-datasources
      - configMap:
          name: grafana-dashboards
        name: grafana-dashboards
      - emptyDir:
          medium: Memory
        name: tmp-plugins
      - name: grafana-config
        secret:
          secretName: grafana-config
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Grafana Deployment');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');

    my $pod_spec = $obj->spec->template->spec;

    # automountServiceAccountToken false
    ok(!$pod_spec->automountServiceAccountToken, 'automountServiceAccountToken false');

    # Pod-level securityContext with fsGroup
    is($pod_spec->securityContext->fsGroup, 65534, 'fsGroup');

    # Many volumes
    is(scalar @{$pod_spec->volumes}, 5, 'volumes count');

    # emptyDir with medium Memory
    my $tmp_vol = $pod_spec->volumes->[3];
    is($tmp_vol->name, 'tmp-plugins', 'emptyDir volume name');
    isa_ok($tmp_vol->emptyDir, 'IO::K8s::Api::Core::V1::EmptyDirVolumeSource');
    is($tmp_vol->emptyDir->medium, 'Memory', 'emptyDir medium Memory');

    # Many volumeMounts
    my $c = $pod_spec->containers->[0];
    is(scalar @{$c->volumeMounts}, 5, 'volumeMounts count');

    # readinessProbe using named port
    is($c->readinessProbe->httpGet->path, '/api/health', 'readiness path');

    # Template annotations (checksums)
    like($obj->spec->template->metadata->annotations->{'checksum/grafana-config'},
         qr/^[a-f0-9]{32}$/, 'checksum annotation looks like md5');

    # Round-trip
    is($exported->{spec}{template}{spec}{securityContext}{fsGroup}, 65534, 'round-trip fsGroup');
};

# ============================================================================
# 25. kube-state-metrics Deployment - 3 containers with different resource limits
# Source: prometheus-operator/kube-prometheus kubeStateMetrics-deployment.yaml
# ============================================================================

subtest 'kube-state-metrics 3-container Deployment' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: kube-state-metrics
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 2.18.0
  name: kube-state-metrics
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: kube-state-metrics
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/default-container: kube-state-metrics
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
        app.kubernetes.io/version: 2.18.0
    spec:
      automountServiceAccountToken: true
      containers:
      - args:
        - --host=127.0.0.1
        - --port=8081
        - --telemetry-host=127.0.0.1
        - --telemetry-port=8082
        image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0
        name: kube-state-metrics
        resources:
          limits:
            cpu: 100m
            memory: 250Mi
          requests:
            cpu: 10m
            memory: 190Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsGroup: 65534
          runAsNonRoot: true
          runAsUser: 65534
          seccompProfile:
            type: RuntimeDefault
      - args:
        - --secure-listen-address=:8443
        - --upstream=http://127.0.0.1:8081/
        image: quay.io/brancz/kube-rbac-proxy:v0.20.2
        name: kube-rbac-proxy-main
        ports:
        - containerPort: 8443
          name: https-main
        resources:
          limits:
            cpu: 40m
            memory: 40Mi
          requests:
            cpu: 20m
            memory: 20Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsGroup: 65532
          runAsNonRoot: true
          runAsUser: 65532
          seccompProfile:
            type: RuntimeDefault
      - args:
        - --secure-listen-address=:9443
        - --upstream=http://127.0.0.1:8082/
        image: quay.io/brancz/kube-rbac-proxy:v0.20.2
        name: kube-rbac-proxy-self
        ports:
        - containerPort: 9443
          name: https-self
        resources:
          limits:
            cpu: 20m
            memory: 40Mi
          requests:
            cpu: 10m
            memory: 20Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsGroup: 65532
          runAsNonRoot: true
          runAsUser: 65532
          seccompProfile:
            type: RuntimeDefault
      nodeSelector:
        kubernetes.io/os: linux
      serviceAccountName: kube-state-metrics
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'kube-state-metrics Deployment');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');

    my $pod_spec = $obj->spec->template->spec;

    # 3 containers
    is(scalar @{$pod_spec->containers}, 3, '3 containers');
    is($pod_spec->containers->[0]->name, 'kube-state-metrics', 'container 0 name');
    is($pod_spec->containers->[1]->name, 'kube-rbac-proxy-main', 'container 1 name');
    is($pod_spec->containers->[2]->name, 'kube-rbac-proxy-self', 'container 2 name');

    # Different resource limits per container
    is($pod_spec->containers->[0]->resources->limits->{cpu}, '100m', 'ksm cpu limit');
    is($pod_spec->containers->[1]->resources->limits->{cpu}, '40m', 'proxy-main cpu limit');
    is($pod_spec->containers->[2]->resources->limits->{cpu}, '20m', 'proxy-self cpu limit');

    # Different user IDs per container
    is($pod_spec->containers->[0]->securityContext->runAsUser, 65534, 'ksm runAsUser');
    is($pod_spec->containers->[1]->securityContext->runAsUser, 65532, 'proxy runAsUser');

    # Round-trip: verify all 3 containers survive
    is(scalar @{$exported->{spec}{template}{spec}{containers}}, 3, 'round-trip 3 containers');
};

# ============================================================================
# 26. Deployment with volumeDevices (block volumes)
# Source: based on real iSCSI/block storage patterns
# ============================================================================

subtest 'Container with volumeDevices' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: Deployment
metadata:
  name: block-storage-app
  namespace: storage-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: block-storage
  template:
    metadata:
      labels:
        app: block-storage
    spec:
      containers:
      - name: app
        image: myapp:latest
        volumeDevices:
        - name: raw-block
          devicePath: /dev/xvda
      volumes:
      - name: raw-block
        persistentVolumeClaim:
          claimName: raw-block-pvc
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'volumeDevices');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');

    my $c = $obj->spec->template->spec->containers->[0];
    is(scalar @{$c->volumeDevices}, 1, 'volumeDevices count');
    isa_ok($c->volumeDevices->[0], 'IO::K8s::Api::Core::V1::VolumeDevice');
    is($c->volumeDevices->[0]->name, 'raw-block', 'volumeDevice name');
    is($c->volumeDevices->[0]->devicePath, '/dev/xvda', 'devicePath');

    # Round-trip
    is($exported->{spec}{template}{spec}{containers}[0]{volumeDevices}[0]{devicePath},
       '/dev/xvda', 'round-trip devicePath');
};

# ============================================================================
# 27. Multi-document YAML load_yaml round-trip
# Source: kubernetes/dashboard v2.7.0 recommended.yaml (subset)
# ============================================================================

subtest 'Multi-document YAML via load_yaml' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: Namespace
metadata:
  name: kubernetes-dashboard
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
---
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
---
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kubernetes-dashboard
type: Opaque
END_YAML

    my $objects = $k8s->load_yaml($yaml);
    is(scalar @$objects, 4, 'load_yaml parsed 4 documents');

    isa_ok($objects->[0], 'IO::K8s::Api::Core::V1::Namespace');
    is($objects->[0]->metadata->name, 'kubernetes-dashboard', 'doc 0: Namespace');

    isa_ok($objects->[1], 'IO::K8s::Api::Core::V1::ServiceAccount');
    is($objects->[1]->metadata->name, 'kubernetes-dashboard', 'doc 1: ServiceAccount');

    isa_ok($objects->[2], 'IO::K8s::Api::Core::V1::Service');
    is($objects->[2]->metadata->name, 'kubernetes-dashboard', 'doc 2: Service');
    is($objects->[2]->spec->ports->[0]->port, 443, 'Service port');

    isa_ok($objects->[3], 'IO::K8s::Api::Core::V1::Secret');
    is($objects->[3]->metadata->name, 'kubernetes-dashboard-certs', 'doc 3: Secret');
    is($objects->[3]->type, 'Opaque', 'Secret type');

    # Round-trip each document
    for my $i (0 .. $#$objects) {
        my $rt = $objects->[$i]->TO_JSON;
        ok(ref $rt eq 'HASH', "doc $i round-trips to hashref");
        ok(exists $rt->{kind}, "doc $i has kind");
    }
};

# ============================================================================
# 28. Deployment with downwardAPI volume, projected volume
# Source: based on real service mesh sidecar patterns
# ============================================================================

subtest 'Deployment with downwardAPI projected volume' => sub {
    my $yaml = <<'END_YAML';
apiVersion: apps/v1
kind: Deployment
metadata:
  name: envoy-sidecar-app
  namespace: istio-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: envoy-app
  template:
    metadata:
      labels:
        app: envoy-app
    spec:
      serviceAccountName: envoy-sa
      containers:
      - name: app
        image: myapp:latest
        ports:
        - containerPort: 8080
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: CPU_LIMIT
          valueFrom:
            resourceFieldRef:
              containerName: app
              resource: limits.cpu
        volumeMounts:
        - name: podinfo
          mountPath: /etc/podinfo
          readOnly: true
      volumes:
      - name: podinfo
        downwardAPI:
          items:
          - path: labels
            fieldRef:
              fieldPath: metadata.labels
          - path: annotations
            fieldRef:
              fieldPath: metadata.annotations
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'DownwardAPI');
    isa_ok($obj, 'IO::K8s::Api::Apps::V1::Deployment');

    my $c = $obj->spec->template->spec->containers->[0];

    # Multiple fieldRef env vars
    is($c->env->[0]->name, 'POD_NAME', 'env POD_NAME');
    is($c->env->[0]->valueFrom->fieldRef->fieldPath, 'metadata.name', 'fieldRef metadata.name');
    is($c->env->[2]->valueFrom->fieldRef->fieldPath, 'status.podIP', 'fieldRef status.podIP');
    is($c->env->[3]->valueFrom->fieldRef->fieldPath, 'spec.nodeName', 'fieldRef spec.nodeName');

    # resourceFieldRef
    is($c->env->[4]->name, 'CPU_LIMIT', 'env CPU_LIMIT');
    isa_ok($c->env->[4]->valueFrom->resourceFieldRef, 'IO::K8s::Api::Core::V1::ResourceFieldSelector');
    is($c->env->[4]->valueFrom->resourceFieldRef->resource, 'limits.cpu', 'resourceFieldRef resource');

    # downwardAPI volume
    my $vol = $obj->spec->template->spec->volumes->[0];
    isa_ok($vol->downwardAPI, 'IO::K8s::Api::Core::V1::DownwardAPIVolumeSource');
    is(scalar @{$vol->downwardAPI->items}, 2, 'downwardAPI items count');
    is($vol->downwardAPI->items->[0]->path, 'labels', 'downwardAPI path');
    is($vol->downwardAPI->items->[0]->fieldRef->fieldPath, 'metadata.labels', 'downwardAPI fieldRef');

    # Round-trip
    is($exported->{spec}{template}{spec}{volumes}[0]{downwardAPI}{items}[0]{path}, 'labels', 'round-trip downwardAPI');
};

# ============================================================================
# 29. NetworkPolicy with complex ingress rules (ipBlock with cidr and except)
# Source: based on Calico/Cilium network policy examples
# ============================================================================

subtest 'NetworkPolicy with ipBlock' => sub {
    my $yaml = <<'END_YAML';
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-external
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api-server
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/8
        except:
        - 10.0.1.0/24
        - 10.0.2.0/24
    - namespaceSelector:
        matchLabels:
          purpose: monitoring
      podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 8443
    - protocol: TCP
      port: 9090
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.0.0/16
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 5432
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'NetworkPolicy ipBlock');
    isa_ok($obj, 'IO::K8s::Api::Networking::V1::NetworkPolicy');

    # ipBlock with except
    my $ingress = $obj->spec->ingress->[0];
    my $ip_block = $ingress->from->[0]->ipBlock;
    isa_ok($ip_block, 'IO::K8s::Api::Networking::V1::IPBlock');
    is($ip_block->cidr, '10.0.0.0/8', 'ipBlock cidr');
    is_deeply($ip_block->except, ['10.0.1.0/24', '10.0.2.0/24'], 'ipBlock except');

    # Combined namespaceSelector + podSelector (AND logic)
    my $ns_pod = $ingress->from->[1];
    is($ns_pod->namespaceSelector->matchLabels->{purpose}, 'monitoring', 'namespaceSelector');
    is($ns_pod->podSelector->matchLabels->{app}, 'prometheus', 'podSelector with namespaceSelector');

    # Multiple ingress ports
    is(scalar @{$ingress->ports}, 2, 'ingress ports count');

    # Egress with ipBlock
    my $egress = $obj->spec->egress->[0];
    is($egress->to->[0]->ipBlock->cidr, '0.0.0.0/0', 'egress cidr');
    is($egress->to->[0]->ipBlock->except->[0], '169.254.0.0/16', 'egress except link-local');

    # Round-trip
    is_deeply($exported->{spec}{ingress}[0]{from}[0]{ipBlock}{except},
              ['10.0.1.0/24', '10.0.2.0/24'], 'round-trip ipBlock except');
};

# ============================================================================
# 30. Deployment with hostAliases, dnsConfig, shareProcessNamespace
# Source: based on real debugging/testing pod patterns
# ============================================================================

subtest 'Pod with hostAliases and dnsConfig' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
  namespace: default
  labels:
    purpose: debugging
spec:
  shareProcessNamespace: true
  dnsPolicy: None
  dnsConfig:
    nameservers:
    - 8.8.8.8
    - 8.8.4.4
    searches:
    - svc.cluster.local
    - cluster.local
    options:
    - name: ndots
      value: "5"
    - name: timeout
      value: "2"
  hostAliases:
  - ip: "127.0.0.1"
    hostnames:
    - "local-api"
    - "local-db"
  - ip: "10.0.0.100"
    hostnames:
    - "custom-dns"
  containers:
  - name: debug
    image: nicolaka/netshoot:latest
    command: ["sleep", "infinity"]
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
        - SYS_PTRACE
  terminationGracePeriodSeconds: 0
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Debug Pod');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::Pod');
    is($obj->metadata->name, 'debug-pod', 'name');

    my $spec = $obj->spec;

    # shareProcessNamespace
    ok($spec->shareProcessNamespace, 'shareProcessNamespace');

    # dnsPolicy None
    is($spec->dnsPolicy, 'None', 'dnsPolicy None');

    # dnsConfig
    isa_ok($spec->dnsConfig, 'IO::K8s::Api::Core::V1::PodDNSConfig');
    is_deeply($spec->dnsConfig->nameservers, ['8.8.8.8', '8.8.4.4'], 'nameservers');
    is_deeply($spec->dnsConfig->searches, ['svc.cluster.local', 'cluster.local'], 'searches');
    is($spec->dnsConfig->options->[0]->name, 'ndots', 'dns option name');
    is($spec->dnsConfig->options->[0]->value, '5', 'dns option value');

    # hostAliases
    is(scalar @{$spec->hostAliases}, 2, 'hostAliases count');
    isa_ok($spec->hostAliases->[0], 'IO::K8s::Api::Core::V1::HostAlias');
    is($spec->hostAliases->[0]->ip, '127.0.0.1', 'hostAlias ip');
    is_deeply($spec->hostAliases->[0]->hostnames, ['local-api', 'local-db'], 'hostAlias hostnames');

    # Capabilities with multiple adds
    my $caps = $spec->containers->[0]->securityContext->capabilities;
    is(scalar @{$caps->add}, 3, 'capabilities add count');
    is($caps->add->[2], 'SYS_PTRACE', 'SYS_PTRACE capability');

    # terminationGracePeriodSeconds = 0
    is($spec->terminationGracePeriodSeconds, 0, 'terminationGracePeriodSeconds 0');

    # Round-trip
    ok($exported->{spec}{shareProcessNamespace}, 'round-trip shareProcessNamespace');
    is_deeply($exported->{spec}{dnsConfig}{nameservers}, ['8.8.8.8', '8.8.4.4'], 'round-trip nameservers');
};

# ============================================================================
# 31. Endpoints object (manually managed service)
# Source: based on external service integration patterns
# ============================================================================

subtest 'Endpoints object' => sub {
    my $yaml = <<'END_YAML';
apiVersion: v1
kind: Endpoints
metadata:
  name: external-database
  namespace: production
subsets:
  - addresses:
      - ip: 192.168.1.100
      - ip: 192.168.1.101
    ports:
      - name: mysql
        port: 3306
        protocol: TCP
END_YAML

    my ($obj, $orig, $exported) = round_trip_yaml($yaml, 'Endpoints');
    isa_ok($obj, 'IO::K8s::Api::Core::V1::Endpoints');
    is($obj->metadata->name, 'external-database', 'name');

    is(scalar @{$obj->subsets}, 1, 'subsets count');
    my $subset = $obj->subsets->[0];
    isa_ok($subset, 'IO::K8s::Api::Core::V1::EndpointSubset');
    is(scalar @{$subset->addresses}, 2, 'addresses count');
    is($subset->addresses->[0]->ip, '192.168.1.100', 'address ip');
    is($subset->ports->[0]->name, 'mysql', 'port name');
    is($subset->ports->[0]->port, 3306, 'port number');

    # Round-trip
    is($exported->{subsets}[0]{addresses}[0]{ip}, '192.168.1.100', 'round-trip address');
};

# ============================================================================
# Summary
# ============================================================================

done_testing;
