package IO::K8s::Api::Networking::V1::IngressServiceBackend;
# ABSTRACT: IngressServiceBackend references a Kubernetes Service as a Backend.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s name => Str, 'required';


k8s port => 'Networking::V1::ServiceBackendPort';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Networking::V1::IngressServiceBackend - IngressServiceBackend references a Kubernetes Service as a Backend.

=head1 VERSION

version 1.107

=head2 name

name is the referenced service. The service must exist in the same namespace as the Ingress object.

=head2 port

port of the referenced service. A port name or port number is required for a IngressServiceBackend.

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
