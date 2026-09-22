package IO::K8s::PrometheusOperator::V1::RemoteWriteSpec;
# ABSTRACT: RemoteWriteSpec defines the configuration to write samples from Prometheus to a remote endpoint.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authorization        => '+IO::K8s::PrometheusOperator::V1::Authorization';
k8s azureAd              => '+IO::K8s::PrometheusOperator::V1::AzureAD';
k8s basicAuth            => '+IO::K8s::PrometheusOperator::V1::BasicAuth';
k8s bearerToken          => Str;
k8s bearerTokenFile      => Str;
k8s enableHTTP2          => Bool;
k8s followRedirects      => Bool;
k8s headers              => { Str => 1 };
k8s messageVersion       => Str, { enum => [qw(V1.0 V2.0)] };
k8s metadataConfig       => '+IO::K8s::PrometheusOperator::V1::MetadataConfig';
k8s name                 => Str;
k8s noProxy              => Str;
k8s oauth2               => '+IO::K8s::PrometheusOperator::V1::OAuth2';
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s queueConfig          => '+IO::K8s::PrometheusOperator::V1::QueueConfig';
k8s remoteTimeout        => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s roundRobinDNS        => Bool;
k8s sendExemplars        => Bool;
k8s sendNativeHistograms => Bool;
k8s sigv4                => '+IO::K8s::PrometheusOperator::V1::Sigv4';
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1::TLSConfig';
k8s url                  => Str, { required => 'schema', pattern => qr/^(http|https):\/\/.+$/ };
k8s writeRelabelConfigs  => ['+IO::K8s::PrometheusOperator::V1::RelabelConfig'];


























1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::RemoteWriteSpec - RemoteWriteSpec defines the configuration to write samples from Prometheus to a remote endpoint.

=head1 VERSION

version 1.108

=head2 authorization

authorization section for the URL.

It requires Prometheus >= v2.26.0 or Thanos >= v0.24.0.

Cannot be set at the same time as `sigv4`, `basicAuth`, `oauth2`, or `azureAd`.

=head2 azureAd

azureAd for the URL.

It requires Prometheus >= v2.45.0 or Thanos >= v0.31.0.

Cannot be set at the same time as `authorization`, `basicAuth`, `oauth2`, or `sigv4`.

=head2 basicAuth

basicAuth configuration for the URL.

Cannot be set at the same time as `sigv4`, `authorization`, `oauth2`, or `azureAd`.

=head2 bearerToken

bearerToken is deprecated: this will be removed in a future release.
*Warning: this field shouldn't be used because the token value appears
in clear-text. Prefer using `authorization`.*

=head2 bearerTokenFile

bearerTokenFile defines the file from which to read bearer token for the URL.

Deprecated: this will be removed in a future release. Prefer using `authorization`.

=head2 enableHTTP2

enableHTTP2 defines whether to enable HTTP2.

=head2 followRedirects

followRedirects defines whether HTTP requests follow HTTP 3xx redirects.

It requires Prometheus >= v2.26.0 or Thanos >= v0.24.0.

=head2 headers

headers defines the custom HTTP headers to be sent along with each remote write request.
Be aware that headers that are set by Prometheus itself can't be overwritten.

It requires Prometheus >= v2.25.0 or Thanos >= v0.24.0.

=head2 messageVersion

messageVersion defines the Remote Write message's version to use when writing to the endpoint.

`Version1.0` corresponds to the `prometheus.WriteRequest` protobuf message introduced in Remote Write 1.0.
`Version2.0` corresponds to the `io.prometheus.write.v2.Request` protobuf message introduced in Remote Write 2.0.

When `Version2.0` is selected, Prometheus will automatically be
configured to append the metadata of scraped metrics to the WAL.

Before setting this field, consult with your remote storage provider
what message version it supports.

It requires Prometheus >= v2.54.0 or Thanos >= v0.37.0.

=head2 metadataConfig

metadataConfig defines how to send a series metadata to the remote storage.

When the field is empty, **no metadata** is sent. But when the field is
null, metadata is sent.

=head2 name

name of the remote write queue, it must be unique if specified. The
name is used in metrics and logging in order to differentiate queues.

It requires Prometheus >= v2.15.0 or Thanos >= 0.24.0.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 oauth2

oauth2 configuration for the URL.

It requires Prometheus >= v2.27.0 or Thanos >= v0.24.0.

Cannot be set at the same time as `sigv4`, `authorization`, `basicAuth`, or `azureAd`.

=head2 proxyConnectHeader

proxyConnectHeader optionally specifies headers to send to
proxies during CONNECT requests.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyFromEnvironment

proxyFromEnvironment defines whether to use the proxy configuration defined by environment variables (HTTP_PROXY, HTTPS_PROXY, and NO_PROXY).

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyUrl

proxyUrl defines the HTTP proxy server to use.

=head2 queueConfig

queueConfig allows tuning of the remote write queue parameters.

=head2 remoteTimeout

remoteTimeout defines the timeout for requests to the remote write endpoint.

=head2 roundRobinDNS

roundRobinDNS controls the DNS resolution behavior for remote-write connections.
When enabled:
  - The remote-write mechanism will resolve the hostname via DNS.
  - It will randomly select one of the resolved IP addresses and connect to it.

When disabled (default behavior):
  - The Go standard library will handle hostname resolution.
  - It will attempt connections to each resolved IP address sequentially.

Note: The connection timeout applies to the entire resolution and connection process.

	If disabled, the timeout is distributed across all connection attempts.

It requires Prometheus >= v3.1.0 or Thanos >= v0.38.0.

=head2 sendExemplars

sendExemplars enables sending of exemplars over remote write. Note that
exemplar-storage itself must be enabled using the `spec.enableFeatures`
option for exemplars to be scraped in the first place.

It requires Prometheus >= v2.27.0 or Thanos >= v0.24.0.

=head2 sendNativeHistograms

sendNativeHistograms enables sending of native histograms, also known as sparse histograms
over remote write.

It requires Prometheus >= v2.40.0 or Thanos >= v0.30.0.

=head2 sigv4

sigv4 defines the AWS's Signature Verification 4 for the URL.

It requires Prometheus >= v2.26.0 or Thanos >= v0.24.0.

Cannot be set at the same time as `authorization`, `basicAuth`, `oauth2`, or `azureAd`.

=head2 tlsConfig

tlsConfig to use for the URL.

=head2 url

url defines the URL of the endpoint to send samples to.

It must use the HTTP or HTTPS scheme.

=head2 writeRelabelConfigs

writeRelabelConfigs defines the list of remote write relabel configurations.

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
