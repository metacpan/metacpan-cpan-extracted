package IO::K8s::Cilium::V2::ServiceInfo;
# ABSTRACT: ServiceMatcher specifies Kubernetes service and port that matches traffic to be redirected.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s namespace   => Str, { required => 'schema' };
k8s serviceName => Str, { required => 'schema' };
k8s toPorts     => ['+IO::K8s::Cilium::V2::PortInfo'];




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::ServiceInfo - ServiceMatcher specifies Kubernetes service and port that matches traffic to be redirected.

=head1 VERSION

version 1.108

=head2 namespace

Namespace is the Kubernetes service namespace.
The service namespace must match the namespace of the parent Local
Redirect Policy.  For Cluster-wide Local Redirect Policy, this
can be any namespace.

=head2 serviceName

Name is the name of a destination Kubernetes service that identifies traffic
to be redirected.
The service type needs to be ClusterIP.

Example:
When this field is populated with 'serviceName:myService', all the traffic
destined to the cluster IP of this service at the (specified)
service port(s) will be redirected.

=head2 toPorts

ToPorts is a list of destination service L4 ports with protocol for
traffic to be redirected. If not specified, traffic for all the service
ports will be redirected.
When multiple ports are specified, the ports must be named.

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
