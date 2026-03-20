---
name: io-k8s
description: "IO::K8s — How to create and use typed Kubernetes objects in Perl"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# IO::K8s — Using Kubernetes Objects in Perl

## Create Objects

```perl
my $k8s = IO::K8s->new;

# Short name — auto-resolves to full class
my $pod = $k8s->new_object('Pod',
    metadata => { name => 'test', namespace => 'default' },
    spec => { containers => [{ name => 'app', image => 'nginx' }] },
);

# With CRD providers
my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium', 'IO::K8s::GatewayAPI']);
my $gw = $k8s->new_object('Gateway', { ... });
```

Nested hashes are automatically inflated to typed objects.

## Serialize / Deserialize

```perl
$pod->TO_JSON;           # → hashref (correct K8s types)
$pod->to_json;           # → JSON string
$pod->to_yaml;           # → YAML string
$pod->save('pod.yaml');  # → write file

my $obj = $k8s->inflate($json_string);  # Auto-detect kind from JSON
my $obj = $k8s->json_to_object('Pod', $json);
```

## Attribute DSL (`k8s` function)

For writing new IO::K8s classes:

```perl
package IO::K8s::Api::Core::V1::MyResource;
use IO::K8s::APIObject;    # Top-level (has metadata, kind, apiVersion)
# or: use IO::K8s::Resource;  # Nested (no metadata)

k8s name => Str, 'required';
k8s replicas => Int;
k8s ready => Bool;
k8s spec => 'Core::V1::PodSpec';           # Single nested object
k8s containers => ['Core::V1::Container']; # Array of objects
k8s labels => { Str => 1 };                # Hash of strings
```

## CRD Provider Pattern

```perl
package IO::K8s::MyCRD;
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub resource_map {{
    MyResource => 'MyCRD::V1::MyResource',
}}
```

## Key Types

`Str`, `Int`, `Bool`, `IntOrStr` (K8s quantity), `Quantity`, `Time` (RFC3339)

## Common Short Names

`Pod`, `Service`, `Deployment`, `StatefulSet`, `Job`, `CronJob`, `ConfigMap`, `Secret`, `PersistentVolumeClaim`, `ServiceAccount`, `Role`, `RoleBinding`, `ClusterRole`, `Namespace`, `Node`, `Ingress`, `NetworkPolicy`, `Gateway`, `HTTPRoute`
