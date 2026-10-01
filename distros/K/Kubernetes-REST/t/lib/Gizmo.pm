package Gizmo;
# A CRD class with a single-segment package name, registered as '+Gizmo'. A
# bare 'Gizmo' reads as a Kind to IO::K8s, so the class only resolves through
# the '+'. Used by t/48_exact_class_handoff.t (karr k42).

use IO::K8s::APIObject
    api_version     => 'k42.example.com/v1',
    resource_plural => 'gizmos';

with 'IO::K8s::Role::Namespaced';

k8s spec => { Str => 1 };

1;
