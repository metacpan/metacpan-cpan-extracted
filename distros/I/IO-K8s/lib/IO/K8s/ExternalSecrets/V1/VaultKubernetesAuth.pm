package IO::K8s::ExternalSecrets::V1::VaultKubernetesAuth;
# ABSTRACT: Kubernetes authenticates with Vault by passing the ServiceAccount token stored in the named Secret resource to the Vault server.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s mountPath         => Str, { required => 'schema', default => 'kubernetes' };
k8s role              => Str, { required => 'schema' };
k8s secretRef         => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::VaultKubernetesAuth - Kubernetes authenticates with Vault by passing the ServiceAccount token stored in the named Secret resource to the Vault server.

=head1 VERSION

version 1.108

=head2 mountPath

Path where the Kubernetes authentication backend is mounted in Vault, e.g:
"kubernetes"

=head2 role

A required field containing the Vault Role to assume. A Role binds a
Kubernetes ServiceAccount with a set of Vault policies.

=head2 secretRef

Optional secret field containing a Kubernetes ServiceAccount JWT used
for authenticating with Vault. If a name is specified without a key,
`token` is the default. If one is not specified, the one bound to
the controller will be used.

=head2 serviceAccountRef

Optional service account field containing the name of a kubernetes ServiceAccount.
If the service account is specified, the service account secret token JWT will be used
for authenticating with Vault. If the service account selector is not supplied,
the secretRef will be used instead.

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
