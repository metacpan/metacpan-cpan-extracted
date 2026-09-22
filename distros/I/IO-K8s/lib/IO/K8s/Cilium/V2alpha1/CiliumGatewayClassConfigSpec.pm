package IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfigSpec;
# ABSTRACT: Spec is a human-readable of a GatewayClass configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s description => Str;
k8s envoy       => '+IO::K8s::Cilium::V2alpha1::EnvoyConfig';
k8s httpOptions => '+IO::K8s::Cilium::V2alpha1::HTTPOptions';
k8s service     => '+IO::K8s::Cilium::V2alpha1::ServiceConfig';
k8s telemetry   => '+IO::K8s::Cilium::V2alpha1::Telemetry';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfigSpec - Spec is a human-readable of a GatewayClass configuration.

=head1 VERSION

version 1.108

=head2 description

Description helps describe a GatewayClass configuration with more details.

=head2 envoy

Envoy specifies proxy configuration options.
These settings control Envoy-specific behavior that is not part of the Gateway API standard.

=head2 httpOptions

HTTPOptions specifies HTTP connection manager options.

=head2 service

Service specifies the configuration for the generated Service.
Note that not all fields from upstream Service.Spec are supported

=head2 telemetry

Telemetry specifies observability options for Gateways using this
GatewayClass configuration.

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
