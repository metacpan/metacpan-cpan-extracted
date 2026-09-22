package IO::K8s::GatewayAPI::V1beta1::GatewayBackendTLS;
# ABSTRACT: Backend describes TLS configuration for gateway when connecting to backends.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientCertificateRef => '+IO::K8s::GatewayAPI::V1beta1::SecretObjectReference';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::GatewayBackendTLS - Backend describes TLS configuration for gateway when connecting to backends.

=head1 VERSION

version 1.108

=head2 clientCertificateRef

ClientCertificateRef references an object that contains a client certificate
and its associated private key. It can reference standard Kubernetes resources,
i.e., Secret, or implementation-specific custom resources.

A ClientCertificateRef is considered invalid if:

* It refers to a resource that cannot be resolved (e.g., the referenced resource
  does not exist) or is misconfigured (e.g., a Secret does not contain the keys
  named `tls.crt` and `tls.key`). In this case, the `ResolvedRefs` condition
  on the Gateway MUST be set to False with the Reason `InvalidClientCertificateRef`
  and the Message of the Condition MUST indicate why the reference is invalid.

* It refers to a resource in another namespace UNLESS there is a ReferenceGrant
  in the target namespace that allows the certificate to be attached.
  If a ReferenceGrant does not allow this reference, the `ResolvedRefs` condition
  on the Gateway MUST be set to False with the Reason `RefNotPermitted`.

Implementations MAY choose to perform further validation of the certificate
content (e.g., checking expiry or enforcing specific formats). In such cases,
an implementation-specific Reason and Message MUST be set.

Support: Core - Reference to a Kubernetes TLS Secret (with the type `kubernetes.io/tls`).
Support: Implementation-specific - Other resource kinds or Secrets with a
different type (e.g., `Opaque`).

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
