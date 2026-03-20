package IO::K8s::Api::Resource::V1alpha3::DeviceClassSpec;
# ABSTRACT: DeviceClassSpec is used in a [DeviceClass] to define what can be allocated and how to configure it.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s config => ['Resource::V1alpha3::DeviceClassConfiguration'];


k8s selectors => ['Resource::V1alpha3::DeviceSelector'];


k8s suitableNodes => 'Core::V1::NodeSelector';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::DeviceClassSpec - DeviceClassSpec is used in a [DeviceClass] to define what can be allocated and how to configure it.

=head1 VERSION

version 1.009

=head2 config

Config defines configuration parameters that apply to each device that is claimed via this class. Some classses may potentially be satisfied by multiple drivers, so each instance of a vendor configuration applies to exactly one driver.

They are passed to the driver, but are not considered while allocating the claim.

=head2 selectors

Each selector must be satisfied by a device which is claimed via this class.

=head2 suitableNodes

Only nodes matching the selector will be considered by the scheduler when trying to find a Node that fits a Pod when that Pod uses a claim that has not been allocated yet *and* that claim gets allocated through a control plane controller. It is ignored when the claim does not use a control plane controller for allocation.

Setting this field is optional. If unset, all Nodes are candidates.

This is an alpha field and requires enabling the DRAControlPlaneController feature gate.

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
