package IO::K8s::PrometheusOperator::V1alpha1::EC2SDConfig;
# ABSTRACT: EC2SDConfig allow retrieving scrape targets from AWS EC2 instances.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessKey            => 'Core::V1::ConfigMapKeySelector';
k8s enableHTTP2          => Bool;
k8s filters              => ['+IO::K8s::PrometheusOperator::V1alpha1::Filter'];
k8s followRedirects      => Bool;
k8s noProxy              => Str;
k8s port                 => Int, { minimum => 0, maximum => 65535 };
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s refreshInterval      => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s region               => Str;
k8s roleARN              => Str;
k8s secretKey            => 'Core::V1::ConfigMapKeySelector';
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1alpha1::SafeTLSConfig';















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::EC2SDConfig - EC2SDConfig allow retrieving scrape targets from AWS EC2 instances.

=head1 VERSION

version 1.108

=head2 accessKey

accessKey defines the AWS API key.

=head2 enableHTTP2

enableHTTP2 defines whether to enable HTTP2.
It requires Prometheus >= v2.41.0

=head2 filters

filters can be used optionally to filter the instance list by other criteria.
Available filter criteria can be found here:
https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html
Filter API documentation: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Filter.html
It requires Prometheus >= v2.3.0

=head2 followRedirects

followRedirects defines whether HTTP requests follow HTTP 3xx redirects.
It requires Prometheus >= v2.41.0

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 port

port defines the port to scrape metrics from. If using the public IP address, this must
instead be specified in the relabeling rule.

=head2 proxyConnectHeader

proxyConnectHeader optionally specifies headers to send to
proxies during CONNECT requests.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyFromEnvironment

proxyFromEnvironment defines whether to use the proxy configuration defined by environment variables (HTTP_PROXY, HTTPS_PROXY, and NO_PROXY).

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyUrl

proxyUrl defines the HTTP proxy server to use.

=head2 refreshInterval

refreshInterval defines the time after which the provided names are refreshed.
If not set, Prometheus uses its default value.

=head2 region

region defines the AWS region.

=head2 roleARN

roleARN defines an alternative to using AWS API keys.

=head2 secretKey

secretKey defines the AWS API secret.

=head2 tlsConfig

tlsConfig defines the TLS configuration to connect to the EC2 API.
It requires Prometheus >= v2.41.0

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
