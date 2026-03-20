package IO::K8s::Api::Certificates::V1alpha1::ClusterTrustBundle;
# ABSTRACT: ClusterTrustBundle is a cluster-scoped container for X.509 trust anchors (root certificates).
our $VERSION = '1.009';
use IO::K8s::APIObject;


k8s spec => 'Certificates::V1alpha1::ClusterTrustBundleSpec', 'required';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Certificates::V1alpha1::ClusterTrustBundle - ClusterTrustBundle is a cluster-scoped container for X.509 trust anchors (root certificates).

=head1 VERSION

version 1.009

=head1 DESCRIPTION

ClusterTrustBundle is a cluster-scoped container for X.509 trust anchors (root certificates).

ClusterTrustBundle objects are considered to be readable by any authenticated user in the cluster, because they can be mounted by pods using the C<clusterTrustBundle> projection.  All service accounts have read access to ClusterTrustBundles by default.  Users who only have namespace-level access to a cluster can read ClusterTrustBundles by impersonating a serviceaccount that they have access to.

It can be optionally associated with a particular assigner, in which case it contains one valid set of trust anchors for that signer. Signers may have multiple associated ClusterTrustBundles; each is an independent set of trust anchors for that signer. Admission control is used to enforce that only users with permissions on the signer can create or modify the corresponding bundle.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

spec contains the signer (if any) and trust anchors.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#clustertrustbundle-v1alpha1-certificates.k8s.io>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
