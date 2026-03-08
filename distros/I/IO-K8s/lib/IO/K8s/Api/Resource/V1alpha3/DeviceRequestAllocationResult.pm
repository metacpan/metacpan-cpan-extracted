package IO::K8s::Api::Resource::V1alpha3::DeviceRequestAllocationResult;
# ABSTRACT: DeviceRequestAllocationResult contains the allocation result for one request.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s device => Str, 'required';


k8s driver => Str, 'required';


k8s pool => Str, 'required';


k8s request => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::DeviceRequestAllocationResult - DeviceRequestAllocationResult contains the allocation result for one request.

=head1 VERSION

version 1.006

=head2 device

Device references one device instance via its name in the driver's resource pool. It must be a DNS label.

=head2 driver

Driver specifies the name of the DRA driver whose kubelet plugin should be invoked to process the allocation once the claim is needed on a node.

Must be a DNS subdomain and should end with a DNS domain owned by the vendor of the driver.

=head2 pool

This name together with the driver name and the device name field identify which device was allocated (C<E<lt>driver nameE<gt>/E<lt>pool nameE<gt>/E<lt>device nameE<gt>>).

Must not be longer than 253 characters and may contain one or more DNS sub-domains separated by slashes.

=head2 request

Request is the name of the request in the claim which caused this device to be allocated. Multiple devices may have been allocated per request.

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
