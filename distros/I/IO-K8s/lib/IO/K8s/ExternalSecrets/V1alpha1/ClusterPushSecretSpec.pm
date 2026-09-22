package IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretSpec;
# ABSTRACT: ClusterPushSecretSpec defines the configuration for a ClusterPushSecret resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s namespaceSelectors => ['Meta::V1::LabelSelector'];
k8s pushSecretMetadata => '+IO::K8s::ExternalSecrets::V1alpha1::PushSecretMetadata';
k8s pushSecretName     => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s pushSecretSpec     => '+IO::K8s::ExternalSecrets::V1alpha1::PushSecretSpec', { required => 'schema' };
k8s refreshTime        => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretSpec - ClusterPushSecretSpec defines the configuration for a ClusterPushSecret resource.

=head1 VERSION

version 1.108

=head2 namespaceSelectors

A list of labels to select by to find the Namespaces to create the ExternalSecrets in. The selectors are ORed.

=head2 pushSecretMetadata

The metadata of the external secrets to be created

=head2 pushSecretName

The name of the push secrets to be created.
Defaults to the name of the ClusterPushSecret

=head2 pushSecretSpec

PushSecretSpec defines what to do with the secrets.

=head2 refreshTime

The time in which the controller should reconcile its objects and recheck namespaces for labels.

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
