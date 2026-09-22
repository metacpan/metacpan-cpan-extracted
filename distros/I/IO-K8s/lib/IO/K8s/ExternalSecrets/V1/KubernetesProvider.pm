package IO::K8s::ExternalSecrets::V1::KubernetesProvider;
# ABSTRACT: Kubernetes configures this store to sync secrets using a Kubernetes cluster provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth            => '+IO::K8s::ExternalSecrets::V1::KubernetesAuth';
k8s authRef         => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s remoteNamespace => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/, default => 'default' };
k8s server          => '+IO::K8s::ExternalSecrets::V1::KubernetesServer';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::KubernetesProvider - Kubernetes configures this store to sync secrets using a Kubernetes cluster provider

=head1 VERSION

version 1.108

=head2 auth

Auth configures how secret-manager authenticates with a Kubernetes instance.

=head2 authRef

A reference to a secret that contains the auth information.

=head2 remoteNamespace

Remote namespace to fetch the secrets from

=head2 server

configures the Kubernetes server Address.

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
