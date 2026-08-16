package IO::K8s::Api::Resource::V1alpha3::PoolStatus;
# ABSTRACT: PoolStatus contains status information for a single resource pool.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s allocatedDevices => Int;


k8s availableDevices => Int;


k8s driver => Str, 'required';


k8s generation => Int, 'required';


k8s nodeName => Str;


k8s poolName => Str, 'required';


k8s resourceSliceCount => Int;


k8s totalDevices => Int;


k8s unavailableDevices => Int;


k8s validationError => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::PoolStatus - PoolStatus contains status information for a single resource pool.

=head1 VERSION

version 1.107

=head2 allocatedDevices

AllocatedDevices is the number of devices currently allocated to claims. A value of 0 means no devices are allocated. May be unset when validationError is set.

=head2 availableDevices

AvailableDevices is the number of devices available for allocation. This equals TotalDevices - AllocatedDevices - UnavailableDevices. A value of 0 means no devices are currently available. May be unset when validationError is set.

=head2 driver

Driver is the DRA driver name for this pool. Must be a DNS subdomain (e.g., "gpu.example.com").

=head2 generation

Generation is the pool generation observed across all ResourceSlices in this pool. Only the latest generation is reported. During a generation rollout, if not all slices at the latest generation have been published, the pool is included with a validationError and device counts unset.

=head2 nodeName

NodeName is the node this pool is associated with. When omitted, the pool is not associated with a specific node. Must be a valid DNS subdomain name (RFC1123).

=head2 poolName

PoolName is the name of the pool. Must be a valid resource pool name (DNS subdomains separated by "/").

=head2 resourceSliceCount

ResourceSliceCount is the number of ResourceSlices that make up this pool. May be unset when validationError is set.

=head2 totalDevices

TotalDevices is the total number of devices in the pool across all slices. A value of 0 means the pool has no devices. May be unset when validationError is set.

=head2 unavailableDevices

UnavailableDevices is the number of devices that are not available due to taints or other conditions, but are not allocated. A value of 0 means all unallocated devices are available. May be unset when validationError is set.

=head2 validationError

ValidationError is set when the pool's data could not be fully validated (e.g., incomplete slice publication). When set, device count fields and ResourceSliceCount may be unset.

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
