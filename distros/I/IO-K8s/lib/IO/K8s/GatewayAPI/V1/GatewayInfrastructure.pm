package IO::K8s::GatewayAPI::V1::GatewayInfrastructure;
# ABSTRACT: Infrastructure defines infrastructure level attributes about this Gateway instance.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s annotations   => { Str => 1 };
k8s labels        => { Str => 1 };
k8s parametersRef => '+IO::K8s::GatewayAPI::V1::LocalParametersReference';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::GatewayInfrastructure - Infrastructure defines infrastructure level attributes about this Gateway instance.

=head1 VERSION

version 1.108

=head2 annotations

Annotations that SHOULD be applied to any resources created in response to this Gateway.

For implementations creating other Kubernetes objects, this should be the `metadata.annotations` field on resources.
For other implementations, this refers to any relevant (implementation specific) "annotations" concepts.

An implementation may chose to add additional implementation-specific annotations as they see fit.

Support: Extended

=head2 labels

Labels that SHOULD be applied to any resources created in response to this Gateway.

For implementations creating other Kubernetes objects, this should be the `metadata.labels` field on resources.
For other implementations, this refers to any relevant (implementation specific) "labels" concepts.

An implementation may chose to add additional implementation-specific labels as they see fit.

If an implementation maps these labels to Pods, or any other resource that would need to be recreated when labels
change, it SHOULD clearly warn about this behavior in documentation.

Support: Extended

=head2 parametersRef

ParametersRef is a reference to a resource that contains the configuration
parameters corresponding to the Gateway. This is optional if the
controller does not require any additional configuration.

This follows the same semantics as GatewayClass's `parametersRef`, but on a per-Gateway basis

The Gateway's GatewayClass may provide its own `parametersRef`. When both are specified,
the merging behavior is implementation specific.
It is generally recommended that GatewayClass provides defaults that can be overridden by a Gateway.

If the referent cannot be found, refers to an unsupported kind, or when
the data within that resource is malformed, the Gateway SHOULD be
rejected with the "Accepted" status condition set to "False" and an
"InvalidParameters" reason.

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
