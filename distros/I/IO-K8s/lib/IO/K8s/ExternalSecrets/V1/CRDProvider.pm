package IO::K8s::ExternalSecrets::V1::CRDProvider;
# ABSTRACT: CRD configures this store to sync secrets from arbitrary Kubernetes resources, including both custom resources (CRDs) and core API resources.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth      => '+IO::K8s::ExternalSecrets::V1::KubernetesAuth';
k8s authRef   => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s resource  => '+IO::K8s::ExternalSecrets::V1::CRDProviderResource', { required => 'schema' };
k8s server    => '+IO::K8s::ExternalSecrets::V1::KubernetesServer';
k8s whitelist => '+IO::K8s::ExternalSecrets::V1::CRDProviderWhitelist';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::CRDProvider - CRD configures this store to sync secrets from arbitrary Kubernetes resources, including both custom resources (CRDs) and core API resources.

=head1 VERSION

version 1.108

=head2 auth

Auth configures authentication to the Kubernetes API, same as the
Kubernetes provider. Required when Server.URL is set (unless using AuthRef).

=head2 authRef

AuthRef references a Secret containing a kubeconfig. Same semantics as the
Kubernetes provider.

=head2 resource

Resource identifies the CRD by its API group, version and kind.

=head2 server

Server configures the Kubernetes API address and TLS trust, same as the
Kubernetes provider. When omitted, the URL defaults to the in-cluster API.

=head2 whitelist

Whitelist optionally restricts which object names and requested properties
are allowed to be read.

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
