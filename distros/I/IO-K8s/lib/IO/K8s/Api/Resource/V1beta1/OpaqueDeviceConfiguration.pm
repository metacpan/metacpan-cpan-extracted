package IO::K8s::Api::Resource::V1beta1::OpaqueDeviceConfiguration;
# ABSTRACT: OpaqueDeviceConfiguration contains configuration parameters for a driver in a format defined by the driver vendor.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s driver => Str, 'required';


k8s parameters => { Str => 1 }, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta1::OpaqueDeviceConfiguration - OpaqueDeviceConfiguration contains configuration parameters for a driver in a format defined by the driver vendor.

=head1 VERSION

version 1.107

=head2 driver

Driver is used to determine which kubelet plugin needs to be passed these configuration parameters.  An admission policy provided by the driver developer could use this to decide whether it needs to validate them.  Must be a DNS subdomain and should end with a DNS domain owned by the vendor of the driver. It should use only lower case characters.

=head2 parameters

Parameters can contain arbitrary data. It is the responsibility of the driver developer to handle validation and versioning. Typically this includes self-identification and a version ("kind" + "apiVersion" for Kubernetes types), with conversion between different versions.  The length of the raw data must be smaller or equal to 10 Ki.

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
