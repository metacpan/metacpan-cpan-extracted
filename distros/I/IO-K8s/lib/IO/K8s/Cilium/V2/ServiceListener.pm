package IO::K8s::Cilium::V2::ServiceListener;
# ABSTRACT: ServiceListener
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s listener  => Str;
k8s name      => Str, { required => 'schema' };
k8s namespace => Str;
k8s ports     => [Int];





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::ServiceListener - ServiceListener

=head1 VERSION

version 1.108

=head2 listener

Listener specifies the name of the Envoy listener the
service traffic is redirected to. The listener must be
specified in the Envoy 'resources' of the same
CiliumEnvoyConfig.

If omitted, the first listener specified in 'resources' is
used.

=head2 name

Name is the name of a destination Kubernetes service that identifies traffic
to be redirected.

=head2 namespace

Namespace is the Kubernetes service namespace.
In CiliumEnvoyConfig namespace this is overridden to the namespace of the CEC,
In CiliumClusterwideEnvoyConfig namespace defaults to "default".

=head2 ports

Ports is a set of service's frontend ports that should be redirected to the Envoy
listener. By default all frontend ports of the service are redirected.

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
