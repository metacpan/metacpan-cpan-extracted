package IO::K8s::Api::Resource::V1::DeviceRequestAllocationResult;
# ABSTRACT: DeviceRequestAllocationResult contains the allocation result for one request.
our $VERSION = '1.105';
use IO::K8s::Resource;

k8s adminAccess => Bool;


k8s bindingConditions => [Str];


k8s bindingFailureConditions => [Str];


k8s consumedCapacity => { Str => 1 };


k8s device => Str, 'required';


k8s driver => Str, 'required';


k8s pool => Str, 'required';


k8s request => Str, 'required';


k8s shareID => Str;


k8s tolerations => ['Resource::V1::DeviceToleration'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::DeviceRequestAllocationResult - DeviceRequestAllocationResult contains the allocation result for one request.

=head1 VERSION

version 1.105

=head2 adminAccess

AdminAccess indicates that this device was allocated for administrative access. See the corresponding request field for a definition of mode.

Admin access is disabled if this field is unset or set to false, otherwise it is enabled.

=head2 bindingConditions

BindingConditions contains a copy of the BindingConditions from the corresponding ResourceSlice at the time of allocation. This is a beta field and requires enabling the DRADeviceBindingConditions and DRAResourceClaimDeviceStatus feature gates.

=head2 bindingFailureConditions

BindingFailureConditions contains a copy of the BindingFailureConditions from the corresponding ResourceSlice at the time of allocation. This is a beta field and requires enabling the DRADeviceBindingConditions and DRAResourceClaimDeviceStatus feature gates.

=head2 consumedCapacity

ConsumedCapacity tracks the amount of capacity consumed per device as part of the claim request. The consumed amount may differ from the requested amount: it is rounded up to the nearest valid value based on the device's requestPolicy if applicable (i.e., may not be less than the requested amount). The total consumed capacity for each device must not exceed the DeviceCapacity's Value.

This field is populated only for devices that allow multiple allocations. All capacity entries are included, even if the consumed amount is zero.

=head2 device

Device references one device instance via its name in the driver's resource pool. It must be a DNS label.

=head2 driver

Driver specifies the name of the DRA driver whose kubelet plugin should be invoked to process the allocation once the claim is needed on a node.

Must be a DNS subdomain and should end with a DNS domain owned by the vendor of the driver. It should use only lower case characters.

=head2 pool

This name together with the driver name and the device name field identify which device was allocated (C<E<lt>driver nameE<gt>/E<lt>pool nameE<gt>/E<lt>device nameE<gt>>).

Must not be longer than 253 characters and may contain one or more DNS sub-domains separated by slashes.

=head2 request

Request is the name of the request in the claim which caused this device to be allocated. If it references a subrequest in the firstAvailable list on a DeviceRequest, this field must include both the name of the main request and the subrequest using the format C<<main request>/<subrequest>>.

Multiple devices may have been allocated per request.

=head2 shareID

ShareID uniquely identifies an individual allocation share of the device, used when the device supports multiple simultaneous allocations. It serves as an additional map key to differentiate concurrent shares of the same device.

=head2 tolerations

A copy of all tolerations specified in the request at the time when the device got allocated. The maximum number of tolerations is 16. This is a beta field and requires enabling the DRADeviceTaints feature gate.

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
