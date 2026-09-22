package IO::K8s::PrometheusOperator::V1alpha1::DNSSDConfig;
# ABSTRACT: DNSSDConfig allows specifying a set of DNS domain names which are periodically queried to discover a list of targets.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s names           => [Str], { required => 'schema' };
k8s port            => Int, { minimum => 0, maximum => 65535 };
k8s refreshInterval => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s type            => Str, { enum => [qw(A AAAA MX NS SRV)] };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::DNSSDConfig - DNSSDConfig allows specifying a set of DNS domain names which are periodically queried to discover a list of targets.

=head1 VERSION

version 1.108

=head2 names

names defines a list of DNS domain names to be queried.

=head2 port

port defines the port to scrape metrics from. If using the public IP address, this must
Ignored for SRV records

=head2 refreshInterval

refreshInterval defines the time after which the provided names are refreshed.
If not set, Prometheus uses its default value.

=head2 type

type defines the type of DNS query to perform. One of SRV, A, AAAA, MX or NS.
If not set, Prometheus uses its default value.

When set to NS, it requires Prometheus >= v2.49.0.
When set to MX, it requires Prometheus >= v2.38.0

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
