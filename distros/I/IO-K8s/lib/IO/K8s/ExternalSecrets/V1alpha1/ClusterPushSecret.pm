package IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecret;
# ABSTRACT: ClusterPushSecret is the Schema for the ClusterPushSecrets API that enables cluster-wide management of pushing Kubernetes secrets to external providers.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'external-secrets.io/v1alpha1',
    resource_plural => 'clusterpushsecrets';

k8s spec   => '+IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretSpec';
k8s status => '+IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecret - ClusterPushSecret is the Schema for the ClusterPushSecrets API that enables cluster-wide management of pushing Kubernetes secrets to external providers.

=head1 VERSION

version 1.108

=head2 spec

ClusterPushSecretSpec defines the configuration for a ClusterPushSecret resource.

=head2 status

ClusterPushSecretStatus contains the status information for the ClusterPushSecret resource.

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
