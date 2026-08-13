package IO::K8s::Api::Resource::V1beta2::AllocationResult;
# ABSTRACT: AllocationResult contains attributes of an allocated resource.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s allocationTimestamp => Time;


k8s devices => 'Resource::V1beta2::DeviceAllocationResult';


k8s nodeSelector => 'Core::V1::NodeSelector';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta2::AllocationResult - AllocationResult contains attributes of an allocated resource.

=head1 VERSION

version 1.106

=head2 allocationTimestamp

AllocationTimestamp stores the time when the resources were allocated. This field is not guaranteed to be set, in which case that time is unknown.  This is a beta field and requires enabling the DRADeviceBindingConditions and DRAResourceClaimDeviceStatus feature gate.

=head2 devices

Devices is the result of allocating devices.

=head2 nodeSelector

NodeSelector defines where the allocated resources are available. If unset, they are available everywhere.

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
