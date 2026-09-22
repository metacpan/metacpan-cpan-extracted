package IO::K8s::ExternalSecrets::V1::GCPWorkloadIdentity;
# ABSTRACT: Specify a service account with Workload Identity
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clusterLocation   => Str;
k8s clusterName       => Str;
k8s clusterProjectID  => Str;
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector', { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::GCPWorkloadIdentity - Specify a service account with Workload Identity

=head1 VERSION

version 1.108

=head2 clusterLocation

ClusterLocation is the location of the cluster
If not specified, it fetches information from the metadata server

=head2 clusterName

ClusterName is the name of the cluster
If not specified, it fetches information from the metadata server

=head2 clusterProjectID

ClusterProjectID is the project ID of the cluster
If not specified, it fetches information from the metadata server

=head2 serviceAccountRef

ServiceAccountSelector is a reference to a ServiceAccount resource.

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
