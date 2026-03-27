package IO::K8s::Api::Resource::V1alpha3::AllocationResult;
# ABSTRACT: AllocationResult contains attributes of an allocated resource.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s controller => Str;


k8s devices => 'Resource::V1alpha3::DeviceAllocationResult';


k8s nodeSelector => 'Core::V1::NodeSelector';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::AllocationResult - AllocationResult contains attributes of an allocated resource.

=head1 VERSION

version 1.100

=head2 controller

Controller is the name of the DRA driver which handled the allocation. That driver is also responsible for deallocating the claim. It is empty when the claim can be deallocated without involving a driver.

A driver may allocate devices provided by other drivers, so this driver name here can be different from the driver names listed for the results.

This is an alpha field and requires enabling the DRAControlPlaneController feature gate.

=head2 devices

Devices is the result of allocating devices.

=head2 nodeSelector

NodeSelector defines where the allocated resources are available. If unset, they are available everywhere.

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
