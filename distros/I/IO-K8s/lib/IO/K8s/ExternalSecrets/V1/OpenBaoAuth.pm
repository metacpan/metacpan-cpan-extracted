package IO::K8s::ExternalSecrets::V1::OpenBaoAuth;
# ABSTRACT: Auth configures how secret-manager authenticates with the OpenBao server.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s appRole        => '+IO::K8s::ExternalSecrets::V1::OpenBaoAppRole';
k8s kubernetes     => '+IO::K8s::ExternalSecrets::V1::OpenBaoKubernetesAuth';
k8s namespace      => Str;
k8s tokenSecretRef => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s userPass       => '+IO::K8s::ExternalSecrets::V1::OpenBaoUserPassAuth';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OpenBaoAuth - Auth configures how secret-manager authenticates with the OpenBao server.

=head1 VERSION

version 1.108

=head2 appRole

AppRole authenticates with OpenBao using the [App Role auth mechanism],
with the role and secret stored in a Kubernetes Secret resource.

[App Role auth mechanism]: https://openbao.org/docs/auth/approle/

=head2 kubernetes

Kubernetes authenticates with OpenBao by passing a ServiceAccount
token to the [Kubernetes auth mechanism].

[Kubernetes auth mechanism]: https://openbao.org/docs/auth/kubernetes/

=head2 namespace

Name of the [OpenBao Namespace] to authenticate to. This can be different
than the namespace your secret is in. Namespaces is a set of features
within OpenBao that allows OpenBao environments to support secure
multi-tenancy. e.g: "ns1". This will default to OpenBao.Namespace field
if set, or empty otherwise

[OpenBao Namespace]: https://openbao.org/docs/concepts/namespaces/

=head2 tokenSecretRef

TokenSecretRef authenticates with OpenBao by presenting a token.

=head2 userPass

UserPass authenticates with OpenBao by passing a username/password pair

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
