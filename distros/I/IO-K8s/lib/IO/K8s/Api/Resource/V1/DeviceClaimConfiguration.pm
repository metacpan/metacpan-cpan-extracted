package IO::K8s::Api::Resource::V1::DeviceClaimConfiguration;
# ABSTRACT: DeviceClaimConfiguration is used for configuration parameters in DeviceClaim.
our $VERSION = '1.105';
use IO::K8s::Resource;

k8s opaque => 'Resource::V1::OpaqueDeviceConfiguration';


k8s requests => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::DeviceClaimConfiguration - DeviceClaimConfiguration is used for configuration parameters in DeviceClaim.

=head1 VERSION

version 1.105

=head2 opaque

Opaque provides driver-specific configuration parameters.

=head2 requests

Requests lists the names of requests where the configuration applies. If empty, it applies to all requests. References to subrequests must include the name of the main request and may include the subrequest using the format C<<main request>/<subrequest>>. If just the main request is given, the configuration applies to all subrequests.

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
