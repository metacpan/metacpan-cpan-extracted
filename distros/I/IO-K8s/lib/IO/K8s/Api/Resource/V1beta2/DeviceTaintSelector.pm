package IO::K8s::Api::Resource::V1beta2::DeviceTaintSelector;
# ABSTRACT: DeviceTaintSelector defines which device(s) a DeviceTaintRule applies to. The empty selector matches all devices. Without a selector, no devices are matched.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s device => Str;


k8s driver => Str;


k8s pool => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta2::DeviceTaintSelector - DeviceTaintSelector defines which device(s) a DeviceTaintRule applies to. The empty selector matches all devices. Without a selector, no devices are matched.

=head1 VERSION

version 1.106

=head2 device

If device is set, only devices with that name are selected. This field corresponds to slice.spec.devices[].name. Setting also driver and pool may be required to avoid ambiguity, but is not required.

=head2 driver

If driver is set, only devices from that driver are selected. This fields corresponds to slice.spec.driver.

=head2 pool

If pool is set, only devices in that pool are selected. Also setting the driver name may be useful to avoid ambiguity when different drivers use the same pool name, but this is not required because selecting pools from different drivers may also be useful, for example when drivers with node-local devices use the node name as their pool name.

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
