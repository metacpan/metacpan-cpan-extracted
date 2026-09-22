package IO::K8s::ExternalSecrets::V1::OpenBaoKubernetesAuth;
# ABSTRACT: Kubernetes authenticates with OpenBao by passing a ServiceAccount token to the [Kubernetes auth mechanism].
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s path              => Str, { required => 'schema', default => 'kubernetes' };
k8s role              => Str, { required => 'schema' };
k8s secretRef         => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OpenBaoKubernetesAuth - Kubernetes authenticates with OpenBao by passing a ServiceAccount token to the [Kubernetes auth mechanism].

=head1 VERSION

version 1.108

=head2 path

Path where the Kubernetes authentication backend is mounted in OpenBao, e.g:
"kubernetes"

=head2 role

A required field containing the OpenBao Role to assume. A Role binds a
Kubernetes ServiceAccount with a set of OpenBao policies.

=head2 secretRef

Optional secret field containing a Kubernetes ServiceAccount JWT used
for authenticating with OpenBao. If a name is specified without a key,
`token` is the default.

=head2 serviceAccountRef

Optional service account field containing the name of a Kubernetes ServiceAccount.
If the service account is specified, a token will be requested from the Kubernetes
TokenRequest API for authenticating with OpenBao.
Any configured audiences will be passed to the TokenRequest as-is.

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
