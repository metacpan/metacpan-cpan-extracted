package IO::K8s::PrometheusOperator::V1::ProberSpec;
# ABSTRACT: prober defines the specification for the prober to use for probing targets.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s noProxy              => Str;
k8s path                 => Str, { default => '/probe' };
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s scheme               => Str, { enum => [qw(http https HTTP HTTPS)] };
k8s url                  => Str, { required => 'schema' };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ProberSpec - prober defines the specification for the prober to use for probing targets.

=head1 VERSION

version 1.108

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 path

path to collect metrics from.
Defaults to `/probe`.

=head2 proxyConnectHeader

proxyConnectHeader optionally specifies headers to send to
proxies during CONNECT requests.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyFromEnvironment

proxyFromEnvironment defines whether to use the proxy configuration defined by environment variables (HTTP_PROXY, HTTPS_PROXY, and NO_PROXY).

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyUrl

proxyUrl defines the HTTP proxy server to use.

=head2 scheme

scheme defines the HTTP scheme to use when scraping the prober.

=head2 url

url defines the address of the prober.

Unlike what the name indicates, the value should be in the form of
`address:port` without any scheme which should be specified in the
`scheme` field.

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
