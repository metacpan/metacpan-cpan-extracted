package IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersion;
# ABSTRACT: Storage version of a specific resource.
our $VERSION = '1.008';
use IO::K8s::APIObject;


k8s spec => 'Apiserverinternal::V1alpha1::StorageVersionSpec', 'required';


k8s status => 'Apiserverinternal::V1alpha1::StorageVersionStatus', 'required';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersion - Storage version of a specific resource.

=head1 VERSION

version 1.008

=head1 DESCRIPTION

Storage version of a specific resource.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Spec is an empty spec. It is here to comply with Kubernetes API style.

=head2 status

API server instances report the version they can decode and the version they encode objects to when persisting objects in the backend.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#storageversion-v1alpha1-apiserver.internal.k8s.io>

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
