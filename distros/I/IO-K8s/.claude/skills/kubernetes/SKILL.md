---
name: kubernetes
description: "Kubernetes concepts, architecture, resource relationships, networking, storage, RBAC — the big picture without language-specific typing"
user-invocable: true
allowed-tools: Read, Grep, Glob, WebSearch, WebFetch
model: sonnet
---

# Kubernetes — Big Picture Reference

This skill covers Kubernetes concepts and architecture. For Perl typed objects use the `io-k8s` skill. For REST API calls use `kubernetes-rest`. For container builds use `container-k8s`.

## Architecture

### Control Plane

- **kube-apiserver**: All cluster communication goes through the API server. RESTful, the only component that talks to etcd.
- **etcd**: Distributed key-value store. Single source of truth for cluster state. Back it up.
- **kube-scheduler**: Assigns Pods to Nodes based on resource requests, affinity, taints/tolerations, topology.
- **kube-controller-manager**: Runs control loops (Deployment controller, ReplicaSet controller, Job controller, etc.). Each reconciles desired state → actual state.
- **cloud-controller-manager**: Cloud-specific logic (LoadBalancer provisioning, Node lifecycle, routes).

### Node Components

- **kubelet**: Agent on each node. Ensures containers in PodSpecs are running. Talks to container runtime via CRI.
- **kube-proxy**: Network rules (iptables/IPVS/eBPF) for Service → Pod routing. Replaced by Cilium in eBPF mode.
- **Container runtime**: containerd (standard), CRI-O (OpenShift/RKE2). Docker is deprecated as runtime.

### Add-ons

- **CoreDNS**: Cluster DNS. `<svc>.<ns>.svc.cluster.local` resolution.
- **CNI plugin**: Pod networking (Cilium, Calico, Flannel). Assigns Pod IPs, enforces NetworkPolicy.
- **Ingress/Gateway controller**: External traffic → Services. Gateway API is the successor to Ingress.

## Resource Hierarchy & Relationships

```
Namespace (scope boundary)
├── Deployment (declarative updates)
│   └── ReplicaSet (maintains N replicas)
│       └── Pod (smallest schedulable unit)
│           ├── Container(s) + Init Containers + Sidecar Containers
│           ├── Volumes (mounted storage)
│           └── ServiceAccount (identity)
├── StatefulSet → Pods with stable identity + PVCs
├── DaemonSet → one Pod per Node
├── Job / CronJob → run-to-completion Pods
├── Service (stable endpoint for Pods)
│   ├── ClusterIP (internal only, default)
│   ├── NodePort (exposes on each Node)
│   ├── LoadBalancer (external, cloud or LB-IPAM)
│   └── Headless (no ClusterIP, DNS returns Pod IPs)
├── ConfigMap / Secret → config injection (env or volume)
├── PersistentVolumeClaim → requests storage
├── NetworkPolicy → Pod-level firewall rules
├── Role + RoleBinding → namespaced RBAC
└── ServiceAccount → Pod identity for RBAC
ClusterRole + ClusterRoleBinding → cluster-wide RBAC
PersistentVolume → actual storage (provisioned by StorageClass or admin)
StorageClass → dynamic provisioning template
Node → worker machine
CustomResourceDefinition → extends the API
```

## Labels, Selectors & Ownership

Everything connects via **label selectors**:

- Deployment → ReplicaSet → Pod: `matchLabels` in `.spec.selector`
- Service → Pod: `.spec.selector` matches Pod labels
- NetworkPolicy → Pod: `podSelector` in spec

**Owner references** create the deletion chain: delete a Deployment → its ReplicaSets → their Pods all get garbage collected.

Recommended labels (from k8s.io conventions):
```yaml
app.kubernetes.io/name: myapp
app.kubernetes.io/instance: myapp-prod
app.kubernetes.io/component: frontend
app.kubernetes.io/part-of: platform
app.kubernetes.io/version: "1.2.3"
```

## Networking Model

### The Four Rules

1. Every Pod gets its own IP (no NAT between Pods)
2. Pods on any Node can reach Pods on any other Node (flat network)
3. Services get a virtual IP (ClusterIP) load-balanced across Pods
4. DNS resolves Service names automatically

### Service Discovery

```
my-svc                          → my-svc.<current-ns>.svc.cluster.local
my-svc.other-ns                 → my-svc.other-ns.svc.cluster.local
my-svc.other-ns.svc.cluster.local  → full FQDN
```

Headless Service (clusterIP: None): DNS returns all Pod IPs. Used by StatefulSets for stable DNS per Pod: `pod-0.my-svc.ns.svc.cluster.local`.

### External Access

```
Internet → Ingress/Gateway → Service → Pods
Internet → LoadBalancer Service → Pods
Internet → NodePort Service → Pods (not recommended for production)
```

Gateway API resources: `GatewayClass` → `Gateway` → `HTTPRoute`/`TCPRoute`/etc.

## Storage

### The PV/PVC Model

```
StorageClass (how to provision)
    ↓ dynamic provisioning
PersistentVolume (actual disk/NFS/etc)
    ↕ bound
PersistentVolumeClaim (Pod's request)
    ↓ mounted
Pod → volumeMounts
```

**Access modes**:
- `ReadWriteOnce` (RWO): single node. Most block storage. Use `Strategy: Recreate` for Deployments.
- `ReadWriteMany` (RWX): multiple nodes. NFS, CephFS.
- `ReadOnlyMany` (ROX): multiple nodes, read-only.

**Reclaim policies**: `Retain` (keep data), `Delete` (destroy with PVC).

### Volume Types in Pods

- `persistentVolumeClaim`: backed by PV
- `configMap` / `secret`: inject config as files
- `emptyDir`: ephemeral, per-Pod scratch space
- `hostPath`: bind-mount from Node (avoid in production)
- `projected`: combine multiple sources into one mount

## Scheduling

### Resource Management

```yaml
resources:
  requests:    # Guaranteed. Used by scheduler for placement.
    cpu: "100m"      # 0.1 CPU core
    memory: "128Mi"
  limits:      # Maximum. OOM-killed if exceeded (memory). Throttled (CPU).
    cpu: "500m"
    memory: "256Mi"
```

**QoS classes** (automatic, based on requests/limits):
- `Guaranteed`: requests == limits for all containers
- `Burstable`: at least one request set, not Guaranteed
- `BestEffort`: no requests/limits (first to be evicted)

### Pod Placement

- **nodeSelector**: simple key-value match on Node labels
- **Affinity/Anti-affinity**: expressive rules (required/preferred, Pod/Node level)
- **Taints & Tolerations**: Nodes repel Pods unless Pod tolerates the taint
- **Topology spread**: distribute Pods across zones/nodes

## RBAC

```
Subject (User / Group / ServiceAccount)
    ↕ bound by
RoleBinding (namespaced) / ClusterRoleBinding (cluster-wide)
    ↕ references
Role (namespaced) / ClusterRole (cluster-wide)
    ↕ contains
Rules: apiGroups + resources + verbs
```

Common verbs: `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`

ServiceAccounts are namespaced: `system:serviceaccount:<ns>:<name>`. Pods get a token mounted automatically (opt-out with `automountServiceAccountToken: false`).

## API Versioning & Resources

### Version Progression

`v1alpha1` → `v1beta1` → `v1` (stable). Alpha: off by default, may break. Beta: on by default, migration path. Stable: guaranteed.

### API Groups

- Core (`/api/v1`): Pod, Service, ConfigMap, Secret, Namespace, Node, PV, PVC
- `apps/v1`: Deployment, StatefulSet, DaemonSet, ReplicaSet
- `batch/v1`: Job, CronJob
- `rbac.authorization.k8s.io/v1`: Role, ClusterRole, Bindings
- `networking.k8s.io/v1`: Ingress, NetworkPolicy, IngressClass
- `gateway.networking.k8s.io/v1`: Gateway, HTTPRoute, GatewayClass
- `storage.k8s.io/v1`: StorageClass, CSIDriver
- `apiextensions.k8s.io/v1`: CustomResourceDefinition

### Subresources

`/status` (separate update path), `/scale` (HPA reads this), `/log`, `/exec`, `/portforward`

## Common Patterns

### Rolling Updates (Deployment default)

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%   # How many can be down during update
    maxSurge: 25%          # How many extra Pods during update
```

### Health Checks

```yaml
livenessProbe:    # Kill container if failing (restarts it)
  httpGet: { path: /healthz, port: 8080 }
  initialDelaySeconds: 10
  periodSeconds: 10
readinessProbe:   # Remove from Service if failing (no traffic)
  httpGet: { path: /ready, port: 8080 }
startupProbe:     # Protect slow-starting containers
  httpGet: { path: /healthz, port: 8080 }
  failureThreshold: 30
  periodSeconds: 10
```

### Graceful Shutdown

1. Pod marked for deletion → removed from Service endpoints
2. `preStop` hook runs (e.g., `sleep 5` to drain connections)
3. `SIGTERM` sent to PID 1
4. `terminationGracePeriodSeconds` countdown (default 30s)
5. `SIGKILL` if still running

### Init Containers

Run sequentially before app containers start. Use for: waiting on dependencies, database migrations, config generation, permission setup.

### Sidecar Containers (v1.29+)

`restartPolicy: Always` on init containers makes them sidecars. They start before and outlive the main container. Use for: log shipping, proxy (istio/envoy), metrics export.

## Debugging

```bash
kubectl get pods -o wide                    # Pod status + Node + IP
kubectl describe pod <name>                 # Events, conditions, scheduling
kubectl logs <pod> [-c container] [-f]      # Container logs
kubectl logs <pod> --previous               # Logs from crashed container
kubectl exec -it <pod> -- /bin/sh           # Shell into container
kubectl port-forward svc/<name> 8080:80     # Local access to Service
kubectl get events --sort-by=.lastTimestamp  # Cluster events
kubectl top pods                            # Resource usage (requires metrics-server)
kubectl auth can-i <verb> <resource>        # RBAC check
```

### Common Pod States

- `Pending`: not scheduled yet. Check: resource requests, node capacity, taints, PVC binding.
- `CrashLoopBackOff`: container keeps crashing. Check: `kubectl logs --previous`, probe config.
- `ImagePullBackOff`: can't pull image. Check: image name, registry auth, `imagePullSecrets`.
- `Evicted`: Node under pressure. Check: resource limits, node conditions.
- `Terminating` (stuck): finalizers blocking deletion. Check: `kubectl get pod -o json | jq .metadata.finalizers`.

## CRDs & Operators

**CustomResourceDefinition**: Extends the API with new resource types. Defines schema (OpenAPI v3), versions, scope (Namespaced/Cluster).

**Operator pattern**: CRD + Controller that watches custom resources and reconciles state. The controller loop: Watch → Diff (desired vs actual) → Act → Update status.

Common operator frameworks: Operator SDK (Go), kubebuilder (Go), Metacontroller, kopf (Python).
