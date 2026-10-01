package My::GatewayApi::Gateway;
# Stand-in for the Gateway API's Gateway (gateway.networking.k8s.io), kept
# independent of the optional IO::K8s::GatewayAPI provider. Shares its Kind
# name with Istio's Gateway (My::Istio::Gateway). Used by t/47_ensure_only.t
# (karr k39).

use IO::K8s::APIObject
    api_version     => 'gateway.networking.k8s.io/v1',
    resource_plural => 'gateways';

with 'IO::K8s::Role::Namespaced';

k8s spec => { Str => 1 };

1;
