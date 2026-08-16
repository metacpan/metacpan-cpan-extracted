package IO::K8s::Api::Resource::V1::DeviceClassSpec;
# ABSTRACT: DeviceClassSpec is used in a [DeviceClass] to define what can be allocated and how to configure it.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s config => ['Resource::V1::DeviceClassConfiguration'];


k8s extendedResourceName => Str;


k8s selectors => ['Resource::V1::DeviceSelector'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::DeviceClassSpec - DeviceClassSpec is used in a [DeviceClass] to define what can be allocated and how to configure it.

=head1 VERSION

version 1.107

=head2 config

Config defines configuration parameters that apply to each device that is claimed via this class. Some classses may potentially be satisfied by multiple drivers, so each instance of a vendor configuration applies to exactly one driver.

They are passed to the driver, but are not considered while allocating the claim.

=head2 extendedResourceName

ExtendedResourceName is the extended resource name for the devices of this class. The devices of this class can be used to satisfy a pod's extended resource requests. It has the same format as the name of a pod's extended resource. It should be unique among all the device classes in a cluster. If two device classes have the same name, then the class created later is picked to satisfy a pod's extended resource requests. If two classes are created at the same time, then the name of the class lexicographically sorted first is picked.

This is a beta field.

=head2 selectors

Each selector must be satisfied by a device which is claimed via this class.

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
