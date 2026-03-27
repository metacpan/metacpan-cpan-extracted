# IO::K8s

Perl objects representing the Kubernetes API (v1.31).

## Description

This module provides Perl objects and serialization/deserialization methods that represent the structures found in the Kubernetes API (v1.31).

Kubernetes API is strict about input types. When a value is expected to be an integer, sending it as a string will cause rejection. This module ensures correct value types in JSON that can be sent to Kubernetes.

It also inflates JSON returned by Kubernetes into typed Perl objects.

## Installation

From CPAN:

```bash
cpanm IO::K8s
```

From source:

```bash
cpanm --installdeps .
dzil build
dzil test
dzil install
```

## Usage

```perl
use IO::K8s;

my $k8s = IO::K8s->new;

# Create objects with short names
my $pod = $k8s->new_object('Pod',
    metadata => { name => 'my-pod', namespace => 'default' },
    spec => { containers => [{ name => 'app', image => 'nginx' }] }
);

# Load and validate YAML manifests
my $resources = $k8s->load_yaml('deployment.yaml');

# Save to YAML file
$pod->save('pod.yaml');

# Inflate JSON/struct into typed objects (auto-detect class from 'kind')
my $svc = $k8s->json_to_object('Service', '{"kind":"Service"}');
my $obj = $k8s->inflate({ kind => 'Pod', metadata => { name => 'test' } });

# Serialize back to JSON
my $json = $k8s->object_to_json($svc);
my $struct = $k8s->object_to_struct($pod);
```

## Bundled CRD Providers

IO::K8s ships with CRD classes for popular Kubernetes ecosystem projects. None are loaded by default - opt in at construction:

```perl
my $k8s = IO::K8s->new(with => [
    'IO::K8s::Cilium',
    'IO::K8s::Traefik',
    'IO::K8s::CertManager',
    'IO::K8s::K3s',
    'IO::K8s::GatewayAPI',
    'IO::K8s::AgentSandbox',
]);
```

### Cilium (21 CRDs)

`IO::K8s::Cilium` covers `cilium.io/v2` and `cilium.io/v2alpha1` (upstream v1.19.2):

```perl
my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
my $cnp = $k8s->new_object('CiliumNetworkPolicy',
    metadata => { name => 'allow-dns', namespace => 'kube-system' },
    spec => { endpointSelector => {} },
);
```

### Traefik (10 CRDs)

`IO::K8s::Traefik` covers `traefik.io/v1alpha1`:

```perl
my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
my $ir = $k8s->new_object('IngressRoute',
    metadata => { name => 'my-route', namespace => 'default' },
    spec => { entryPoints => ['web'], routes => [{ match => 'Host(`example.com`)' }] },
);
```

### cert-manager (6 CRDs)

`IO::K8s::CertManager` covers `cert-manager.io/v1` and `acme.cert-manager.io/v1`:

```perl
my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);
my $cert = $k8s->new_object('Certificate',
    metadata => { name => 'my-cert', namespace => 'default' },
    spec => { secretName => 'my-cert-tls', issuerRef => { name => 'letsencrypt' } },
);
```

### K3s (4 CRDs)

`IO::K8s::K3s` covers `helm.cattle.io/v1` and `k3s.cattle.io/v1` (upstream v1.35.1+k3s1):

```perl
my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);
my $hc = $k8s->new_object('HelmChart',
    metadata => { name => 'traefik', namespace => 'kube-system' },
    spec => { chart => 'traefik' },
);
```

### Gateway API (5 CRDs)

`IO::K8s::GatewayAPI` covers `gateway.networking.k8s.io/v1` and `gateway.networking.k8s.io/v1beta1`:

```perl
my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
my $gw = $k8s->new_object('Gateway',
    metadata => { name => 'my-gateway', namespace => 'default' },
    spec => { gatewayClassName => 'istio', listeners => [{ name => 'http', port => 80 }] },
);
```

### AgentSandbox (4 CRDs)

`IO::K8s::AgentSandbox` covers `agents.x-k8s.io/v1alpha1` and `extensions.agents.x-k8s.io/v1alpha1` (upstream v0.2.1):

```perl
my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
my $sandbox = $k8s->new_object('Sandbox',
    metadata => { name => 'my-sandbox', namespace => 'default' },
    spec => { replicas => 1, shutdownPolicy => 'Retain' },
);
```

## Convenience Roles

All API objects automatically get label, annotation, condition, and owner reference methods:

```perl
# Labels & annotations (all API objects)
$pod->add_label(app => 'web');
$pod->add_labels(app => 'web', tier => 'frontend');
$pod->has_label('app');            # true
$pod->match_labels(app => 'web');  # true
$pod->add_annotation('prometheus.io/scrape' => 'true');

# Status conditions (objects with status)
$deploy->is_ready;
$deploy->is_condition_true('Available');
$deploy->condition_message('Progressing');

# Owner references
$pod->set_owner($deployment);
$pod->is_owned_by($deployment);
```

CRD classes automatically get deep-path spec manipulation via `SpecBuilder`:

```perl
$ir->spec_set('tls.secretName', 'my-cert');
$ir->spec_get('routes.0.match');
$ir->spec_push('routes', { match => 'Host(`api.example.com`)' });
$ir->spec_merge(entryPoints => ['web', 'websecure']);
$ir->spec_delete('tls');
```

Domain-specific builder roles provide fluent APIs for common tasks:

```perl
# Network policies (core K8s + Cilium)
$netpol->select_pods(app => 'web')
       ->allow_ingress_from_pods({ app => 'nginx' }, ports => [{ port => 8080 }])
       ->allow_egress_to_dns
       ->deny_all_egress;

# HTTP routing (Ingress, HTTPRoute, IngressRoute)
$route->add_hostname('example.com')
      ->add_backend('api-v1', port => 8080, weight => 90)
      ->add_path_match('/api', type => 'Prefix');

# cert-manager
$cert->for_domains('example.com', '*.example.com')
     ->with_issuer('letsencrypt-prod', kind => 'ClusterIssuer')
     ->store_in_secret('example-tls');

# K3s Helm charts
$chart->from_repo('https://traefik.github.io/charts', 'traefik')
      ->set_version('25.0.0')
      ->set_values(replicas => 3);

# Traefik middleware
$mw->rate_limit(average => 100, burst => 200)
   ->strip_prefix('/api')
   ->redirect_https;
```

### IP Type Validation

`IO::K8s::Types::Net` provides Net::IP-backed type constraints:

```perl
use IO::K8s::Types::Net qw( IPv4 IPv6 IPAddress CIDR NetIP );
use IO::K8s::Types::Net qw( parse_ip cidr_contains is_rfc1918 );

cidr_contains('10.0.0.0/8', '10.1.2.3');  # true
is_rfc1918('192.168.1.1');                 # true
```

## External Resource Maps

Merge resource maps from external packages (e.g. `IO::K8s::Cilium` or your own CRD packages):

```perl
# At construction time
my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

# Or at runtime
$k8s->add('IO::K8s::Cilium');

# Disambiguate colliding kind names with domain-qualified strings
$k8s->new_object('cilium.io/v2/CiliumNetworkPolicy', { ... });

# Or with api_version parameter
$k8s->new_object('CiliumNetworkPolicy', { ... }, 'cilium.io/v2');

# inflate() auto-uses apiVersion from JSON data
$k8s->inflate('{"kind":"CiliumNetworkPolicy","apiVersion":"cilium.io/v2",...}');
```

### pk8s DSL

In `.pk8s` manifest files, Cilium kinds work directly:

```perl
CiliumNetworkPolicy {
    name => 'allow-dns',
    namespace => 'kube-system',
    spec => { endpointSelector => {} },
};

CiliumNode {
    name => 'worker-1',
    spec => { addresses => [{ type => 'InternalIP', ip => '10.0.0.1' }] },
};
```

## Custom Resource Definitions (CRDs)

Write your own CRD classes using `IO::K8s::APIObject`:

```perl
package My::StaticWebSite;
use IO::K8s::APIObject
    api_version     => 'homelab.example.com/v1',
    resource_plural => 'staticwebsites';
with 'IO::K8s::Role::Namespaced';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };
1;
```

Or generate them dynamically from an OpenAPI schema using `IO::K8s::AutoGen`.

See the full POD documentation for details on the class architecture and CRD support.

## Features

- Support for Kubernetes v1.31 API objects
- Type-safe object creation and serialization
- Lightweight Moo-based implementation
- Handles all Kubernetes resource types (Pods, Services, Deployments, etc.)
- Custom Resource Definition (CRD) support with `IO::K8s::APIObject` import parameters
- External resource map support with collision handling (`add()`, `with` constructor param)
- Domain-qualified resource names for disambiguation (`api_version/Kind`)
- Dynamic class generation from OpenAPI schemas via `IO::K8s::AutoGen`
- Convenience methods: labels, annotations, conditions, owner references on all API objects
- Deep-path spec manipulation for CRD classes via `SpecBuilder`
- Domain-specific builder roles for network policies, routing, certificates, Helm, and more
- Net::IP-backed IP/CIDR type constraints (`IO::K8s::Types::Net`)
- Proper handling of namespaced resources
- Canonical JSON output for consistent API requests

## Links

- CPAN: https://metacpan.org/pod/IO::K8s
- GitHub: https://github.com/pplu/io-k8s-p5
- Issues: https://github.com/pplu/io-k8s-p5/issues
- Kubernetes API Reference: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/

## Authors

- Torsten Raudssus <torsten@raudssus.de>
- Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

## License

Copyright (c) 2018 by Jose Luis Martinez

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

## Support

- IRC: #kubernetes on irc.perl.org
- Issues: https://github.com/pplu/io-k8s-p5/issues

## See Also

- [Kubernetes::REST](https://metacpan.org/pod/Kubernetes::REST) - Kubernetes REST API client
- [IO::K8s::Resource](https://metacpan.org/pod/IO::K8s::Resource) - Base class for all Kubernetes resources
