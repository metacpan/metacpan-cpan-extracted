package IO::K8s::GatewayAPI::V1::BackendTLSPolicyValidation;
# ABSTRACT: Validation contains backend TLS validation configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s caCertificateRefs       => ['+IO::K8s::GatewayAPI::V1::LocalObjectReference'];
k8s hostname                => Str, { required => 'schema', pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s subjectAltNames         => ['+IO::K8s::GatewayAPI::V1::SubjectAltName'];
k8s wellKnownCACertificates => Str, { pattern => qr/^(System|([a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\/([A-Za-z0-9][-A-Za-z0-9_.]{0,61})?[A-Za-z0-9]))$/ };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::BackendTLSPolicyValidation - Validation contains backend TLS validation configuration.

=head1 VERSION

version 1.108

=head2 caCertificateRefs

CACertificateRefs contains one or more references to Kubernetes objects that
contain a PEM-encoded TLS CA certificate bundle, which is used to
validate a TLS handshake between the Gateway and backend Pod.

If CACertificateRefs is empty or unspecified, then WellKnownCACertificates must be
specified. Only one of CACertificateRefs or WellKnownCACertificates may be specified,
not both. If CACertificateRefs is empty or unspecified, the configuration for
WellKnownCACertificates MUST be honored instead if supported by the implementation.

A CACertificateRef is invalid if:

* It refers to a resource that cannot be resolved (e.g., the referenced resource
  does not exist) or is misconfigured (e.g., a ConfigMap does not contain a key
  named `ca.crt`). In this case, the Reason must be set to `InvalidCACertificateRef`
  and the Message of the Condition must indicate which reference is invalid and why.

* It refers to an unknown or unsupported kind of resource. In this case, the Reason
  must be set to `InvalidKind` and the Message of the Condition must explain which
  kind of resource is unknown or unsupported.

* It refers to a resource in another namespace. This may change in future
  spec updates.

Implementations MAY choose to perform further validation of the certificate
content (e.g., checking expiry or enforcing specific formats). In such cases,
an implementation-specific Reason and Message must be set for the invalid reference.

In all cases, the implementation MUST ensure the `ResolvedRefs` Condition on
the BackendTLSPolicy is set to `status: False`, with a Reason and Message
that indicate the cause of the error. Connections using an invalid
CACertificateRef MUST fail, and the client MUST receive an HTTP 5xx error
response. If ALL CACertificateRefs are invalid, the implementation MUST also
ensure the `Accepted` Condition on the BackendTLSPolicy is set to
`status: False`, with a Reason `NoValidCACertificate`.

A single CACertificateRef to a Kubernetes ConfigMap kind has "Core" support.
Implementations MAY choose to support attaching multiple certificates to
a backend, but this behavior is implementation-specific.

Support: Core - An optional single reference to a Kubernetes ConfigMap,
with the CA certificate in a key named `ca.crt`.

Support: Implementation-specific - More than one reference, other kinds
of resources, or a single reference that includes multiple certificates.

=head2 hostname

Hostname is used for two purposes in the connection between Gateways and
backends:

1. Hostname MUST be used as the SNI to connect to the backend (RFC 6066).
2. Hostname MUST be used for authentication and MUST match the certificate
   served by the matching backend, unless SubjectAltNames is specified.
3. If SubjectAltNames are specified, Hostname can be used for certificate selection
   but MUST NOT be used for authentication. If you want to use the value
   of the Hostname field for authentication, you MUST add it to the SubjectAltNames list.

Support: Core

=head2 subjectAltNames

SubjectAltNames contains one or more Subject Alternative Names.
When specified the certificate served from the backend MUST
have at least one Subject Alternate Name matching one of the specified SubjectAltNames.

Support: Extended

=head2 wellKnownCACertificates

WellKnownCACertificates specifies whether a well-known set of CA certificates
may be used in the TLS handshake between the gateway and backend pod.

If WellKnownCACertificates is unspecified or empty (""), then CACertificateRefs
must be specified with at least one entry for a valid configuration. Only one of
CACertificateRefs or WellKnownCACertificates may be specified, not both.
If an implementation does not support the WellKnownCACertificates field, or
the supplied value is not recognized, the implementation MUST ensure the
`Accepted` Condition on the BackendTLSPolicy is set to `status: False`, with
a Reason `Invalid`.

Valid values include:
* "System" - indicates that well-known system CA certificates should be used.

Implementations MAY define their own sets of CA certificates. Such definitions
MUST use an implementation-specific, prefixed name, such as
`mycompany.com/my-custom-ca-certificates`.

Support: Implementation-specific

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
