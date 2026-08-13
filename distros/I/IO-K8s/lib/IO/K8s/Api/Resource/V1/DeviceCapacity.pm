package IO::K8s::Api::Resource::V1::DeviceCapacity;
# ABSTRACT: DeviceCapacity describes a quantity associated with a device.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s requestPolicy => 'Resource::V1::CapacityRequestPolicy';


k8s value => Quantity, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::DeviceCapacity - DeviceCapacity describes a quantity associated with a device.

=head1 VERSION

version 1.106

=head2 requestPolicy

RequestPolicy defines how this DeviceCapacity must be consumed when the device is allowed to be shared by multiple allocations. The Device must have allowMultipleAllocations set to true in order to set a requestPolicy. If unset, capacity requests are unconstrained: requests can consume any amount of capacity, as long as the total consumed across all allocations does not exceed the device's defined capacity. If request is also unset, default is the full capacity value.

=head2 value

Value defines how much of a certain capacity that device has. This field reflects the fixed total capacity and does not change. The consumed amount is tracked separately by scheduler and does not affect this value.

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
