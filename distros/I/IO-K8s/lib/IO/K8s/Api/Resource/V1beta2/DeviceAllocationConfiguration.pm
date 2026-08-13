package IO::K8s::Api::Resource::V1beta2::DeviceAllocationConfiguration;
# ABSTRACT: DeviceAllocationConfiguration gets embedded in an AllocationResult.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s opaque => 'Resource::V1beta2::OpaqueDeviceConfiguration';


k8s requests => [Str];


k8s source => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta2::DeviceAllocationConfiguration - DeviceAllocationConfiguration gets embedded in an AllocationResult.

=head1 VERSION

version 1.106

=head2 opaque

Opaque provides driver-specific configuration parameters.

=head2 requests

Requests lists the names of requests where the configuration applies. If empty, its applies to all requests.  References to subrequests must include the name of the main request and may include the subrequest using the format <main request>[/<subrequest>]. If just the main request is given, the configuration applies to all subrequests.

=head2 source

Source records whether the configuration comes from a class and thus is not something that a normal user would have been able to set or from a claim.

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
