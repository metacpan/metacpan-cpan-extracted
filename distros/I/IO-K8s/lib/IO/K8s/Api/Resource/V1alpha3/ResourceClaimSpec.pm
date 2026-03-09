package IO::K8s::Api::Resource::V1alpha3::ResourceClaimSpec;
# ABSTRACT: ResourceClaimSpec defines what is being requested in a ResourceClaim and how to configure it.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s controller => Str;


k8s devices => 'Resource::V1alpha3::DeviceClaim';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::ResourceClaimSpec - ResourceClaimSpec defines what is being requested in a ResourceClaim and how to configure it.

=head1 VERSION

version 1.008

=head2 controller

Controller is the name of the DRA driver that is meant to handle allocation of this claim. If empty, allocation is handled by the scheduler while scheduling a pod.

Must be a DNS subdomain and should end with a DNS domain owned by the vendor of the driver.

This is an alpha field and requires enabling the DRAControlPlaneController feature gate.

=head2 devices

Devices defines how to request devices.

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
