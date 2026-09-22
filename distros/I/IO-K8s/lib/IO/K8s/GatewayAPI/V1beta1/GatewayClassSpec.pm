package IO::K8s::GatewayAPI::V1beta1::GatewayClassSpec;
# ABSTRACT: Spec defines the desired state of GatewayClass.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s controllerName => Str, { required => 'schema', pattern => '^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\\/[A-Za-z0-9\\/\\-._~%!$&\'()*+,;=:]+$' };
k8s description    => Str;
k8s parametersRef  => '+IO::K8s::GatewayAPI::V1beta1::ParametersReference';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::GatewayClassSpec - Spec defines the desired state of GatewayClass.

=head1 VERSION

version 1.108

=head2 controllerName

ControllerName is the name of the controller that is managing Gateways of
this class. The value of this field MUST be a domain prefixed path.

Example: "example.net/gateway-controller".

This field is not mutable and cannot be empty.

Support: Core

=head2 description

Description helps describe a GatewayClass with more details.

=head2 parametersRef

ParametersRef is a reference to a resource that contains the configuration
parameters corresponding to the GatewayClass. This is optional if the
controller does not require any additional configuration.

ParametersRef can reference a standard Kubernetes resource, i.e. ConfigMap,
or an implementation-specific custom resource. The resource can be
cluster-scoped or namespace-scoped.

If the referent cannot be found, refers to an unsupported kind, or when
the data within that resource is malformed, the GatewayClass SHOULD be
rejected with the "Accepted" status condition set to "False" and an
"InvalidParameters" reason.

A Gateway for this GatewayClass may provide its own `parametersRef`. When both are specified,
the merging behavior is implementation specific.
It is generally recommended that GatewayClass provides defaults that can be overridden by a Gateway.

Support: Implementation-specific

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
