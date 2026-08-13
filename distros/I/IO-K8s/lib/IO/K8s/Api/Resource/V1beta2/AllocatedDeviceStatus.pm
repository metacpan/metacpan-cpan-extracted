package IO::K8s::Api::Resource::V1beta2::AllocatedDeviceStatus;
# ABSTRACT: AllocatedDeviceStatus contains the status of an allocated device, if the driver chooses to report it. This may include driver-specific information.  The combination of Driver, Pool, Device, and ShareID must match the corresponding key in Status.Allocation.Devices.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


k8s data => { Str => 1 };


k8s device => Str, 'required';


k8s driver => Str, 'required';


k8s networkData => 'Resource::V1beta2::NetworkDeviceData';


k8s pool => Str, 'required';


k8s shareID => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta2::AllocatedDeviceStatus - AllocatedDeviceStatus contains the status of an allocated device, if the driver chooses to report it. This may include driver-specific information.  The combination of Driver, Pool, Device, and ShareID must match the corresponding key in Status.Allocation.Devices.

=head1 VERSION

version 1.106

=head2 conditions

Conditions contains the latest observation of the device's state. If the device has been configured according to the class and claim config references, the `Ready` condition should be True.  Must not contain more than 8 entries.

=head2 data

Data contains arbitrary driver-specific data.  The length of the raw data must be smaller or equal to 10 Ki.

=head2 device

Device references one device instance via its name in the driver's resource pool. It must be a DNS label.

=head2 driver

Driver specifies the name of the DRA driver whose kubelet plugin should be invoked to process the allocation once the claim is needed on a node.  Must be a DNS subdomain and should end with a DNS domain owned by the vendor of the driver. It should use only lower case characters.

=head2 networkData

NetworkData contains network-related information specific to the device.

=head2 pool

This name together with the driver name and the device name field identify which device was allocated (`<driver name>/<pool name>/<device name>`).  Must not be longer than 253 characters and may contain one or more DNS sub-domains separated by slashes.

=head2 shareID

ShareID uniquely identifies an individual allocation share of the device.

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
