package IO::K8s::PrometheusOperator::V1alpha1::OVHCloudSDConfig;
# ABSTRACT: OVHCloudSDConfig configurations allow retrieving scrape targets from OVHcloud's dedicated servers and VPS using their API.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s applicationKey    => Str, { required => 'schema' };
k8s applicationSecret => 'Core::V1::ConfigMapKeySelector', { required => 'schema' };
k8s consumerKey       => 'Core::V1::ConfigMapKeySelector', { required => 'schema' };
k8s endpoint          => Str;
k8s refreshInterval   => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s service           => Str, { required => 'schema', enum => [qw(VPS DedicatedServer)] };







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::OVHCloudSDConfig - OVHCloudSDConfig configurations allow retrieving scrape targets from OVHcloud's dedicated servers and VPS using their API.

=head1 VERSION

version 1.108

=head2 applicationKey

applicationKey defines the access key to use for OVHCloud API authentication.
This is obtained from the OVHCloud API credentials at https://api.ovh.com.

=head2 applicationSecret

applicationSecret defines the secret key for OVHCloud API authentication.
This contains the application secret obtained during OVHCloud API credential creation.

=head2 consumerKey

consumerKey defines the consumer key for OVHCloud API authentication.
This is the third component of OVHCloud's three-key authentication system.

=head2 endpoint

endpoint defines a custom API endpoint to be used.
When not specified, defaults to the standard OVHCloud API endpoint for the region.

=head2 refreshInterval

refreshInterval defines the time after which the provided names are refreshed.
If not set, Prometheus uses its default value.

=head2 service

service defines the service type of the targets to retrieve.
Must be either `VPS` or `DedicatedServer` to specify which OVHCloud resources to discover.

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
