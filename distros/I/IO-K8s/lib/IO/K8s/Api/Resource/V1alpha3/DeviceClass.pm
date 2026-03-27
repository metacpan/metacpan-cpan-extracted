package IO::K8s::Api::Resource::V1alpha3::DeviceClass;
# ABSTRACT: DeviceClass is a vendor- or admin-provided resource that contains device configuration and selectors. It can be referenced in the device requests of a claim to apply these presets. Cluster scoped. This is an alpha type and requires enabling the DynamicResourceAllocation feature gate.
our $VERSION = '1.100';
use IO::K8s::APIObject;


k8s spec => 'Resource::V1alpha3::DeviceClassSpec', 'required';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::DeviceClass - DeviceClass is a vendor- or admin-provided resource that contains device configuration and selectors. It can be referenced in the device requests of a claim to apply these presets. Cluster scoped. This is an alpha type and requires enabling the DynamicResourceAllocation feature gate.

=head1 VERSION

version 1.100

=head1 DESCRIPTION

DeviceClass is a vendor- or admin-provided resource that contains device configuration and selectors. It can be referenced in the device requests of a claim to apply these presets. Cluster scoped. This is an alpha type and requires enabling the DynamicResourceAllocation feature gate.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Spec defines what can be allocated and how to configure it.

This is mutable. Consumers have to be prepared for classes changing at any time, either because they get updated or replaced. Claim allocations are done once based on whatever was set in classes at the time of allocation.

Changing the spec automatically increments the metadata.generation number.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#deviceclass-v1alpha3-resource.k8s.io>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
