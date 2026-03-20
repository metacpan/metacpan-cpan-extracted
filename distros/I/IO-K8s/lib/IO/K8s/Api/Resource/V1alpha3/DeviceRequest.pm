package IO::K8s::Api::Resource::V1alpha3::DeviceRequest;
# ABSTRACT: DeviceRequest is a request for devices required for a claim. This is typically a request for a single resource like a device, but can also ask for several identical devices. A DeviceClassName is currently required. Clients must check that it is indeed set. It's absence indicates that something changed in a way that is not supported by the client yet, in which case it must refuse to handle the request.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s adminAccess => Bool;


k8s allocationMode => Str;


k8s count => Int;


k8s deviceClassName => Str, 'required';


k8s name => Str, 'required';


k8s selectors => ['Resource::V1alpha3::DeviceSelector'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::DeviceRequest - DeviceRequest is a request for devices required for a claim. This is typically a request for a single resource like a device, but can also ask for several identical devices. A DeviceClassName is currently required. Clients must check that it is indeed set. It's absence indicates that something changed in a way that is not supported by the client yet, in which case it must refuse to handle the request.

=head1 VERSION

version 1.009

=head2 adminAccess

AdminAccess indicates that this is a claim for administrative access to the device(s). Claims with AdminAccess are expected to be used for monitoring or other management services for a device.  They ignore all ordinary claims to the device with respect to access modes and any resource allocations.

=head2 allocationMode

AllocationMode and its related fields define how devices are allocated to satisfy this request. Supported values are:

- ExactCount: This request is for a specific number of devices.
  This is the default. The exact number is provided in the
  count field.

- All: This request is for all of the matching devices in a pool.
  Allocation will fail if some devices are already allocated,
  unless adminAccess is requested.

If AlloctionMode is not specified, the default mode is ExactCount. If the mode is ExactCount and count is not specified, the default count is one. Any other requests must specify this field.

More modes may get added in the future. Clients must refuse to handle requests with unknown modes.

=head2 count

Count is used only when the count mode is "ExactCount". Must be greater than zero. If AllocationMode is ExactCount and this field is not specified, the default is one.

=head2 deviceClassName

DeviceClassName references a specific DeviceClass, which can define additional configuration and selectors to be inherited by this request.

A class is required. Which classes are available depends on the cluster.

Administrators may use this to restrict which devices may get requested by only installing classes with selectors for permitted devices. If users are free to request anything without restrictions, then administrators can create an empty DeviceClass for users to reference.

=head2 name

Name can be used to reference this request in a pod.spec.containers[].resources.claims entry and in a constraint of the claim.

Must be a DNS label.

=head2 selectors

Selectors define criteria which must be satisfied by a specific device in order for that device to be considered for this request. All selectors must be satisfied for a device to be considered.

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
