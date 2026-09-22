package IO::K8s::ExternalSecrets::V1::ClusterExternalSecret;
# ABSTRACT: ClusterExternalSecret is the Schema for the clusterexternalsecrets API.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'external-secrets.io/v1',
    resource_plural => 'clusterexternalsecrets';

k8s spec   => '+IO::K8s::ExternalSecrets::V1::ClusterExternalSecretSpec';
k8s status => '+IO::K8s::ExternalSecrets::V1::ClusterExternalSecretStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ClusterExternalSecret - ClusterExternalSecret is the Schema for the clusterexternalsecrets API.

=head1 VERSION

version 1.108

=head2 spec

ClusterExternalSecretSpec defines the desired state of ClusterExternalSecret.

=head2 status

ClusterExternalSecretStatus defines the observed state of ClusterExternalSecret.

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
