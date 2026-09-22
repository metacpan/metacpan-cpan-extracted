package IO::K8s::PrometheusOperator::V1::PodMetricsEndpoint;
# ABSTRACT: PodMetricsEndpoint defines an endpoint serving Prometheus metrics to be scraped by Prometheus.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authorization            => '+IO::K8s::PrometheusOperator::V1::SafeAuthorization';
k8s basicAuth                => '+IO::K8s::PrometheusOperator::V1::BasicAuth';
k8s bearerTokenSecret        => 'Core::V1::ConfigMapKeySelector';
k8s enableHttp2              => Bool;
k8s filterRunning            => Bool;
k8s followRedirects          => Bool;
k8s honorLabels              => Bool;
k8s honorTimestamps          => Bool;
k8s interval                 => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s metricRelabelings        => ['+IO::K8s::PrometheusOperator::V1::RelabelConfig'];
k8s noProxy                  => Str;
k8s oauth2                   => '+IO::K8s::PrometheusOperator::V1::OAuth2';
k8s params                   => { Str => 1 };
k8s path                     => Str;
k8s port                     => Str;
k8s portNumber               => Int, { minimum => 1, maximum => 65535 };
k8s proxyConnectHeader       => { Str => 1 };
k8s proxyFromEnvironment     => Bool;
k8s proxyUrl                 => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s relabelings              => ['+IO::K8s::PrometheusOperator::V1::RelabelConfig'];
k8s scheme                   => Str, { enum => [qw(http https HTTP HTTPS)] };
k8s scrapeTimeout            => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s targetPort               => IntOrStr;
k8s tlsConfig                => '+IO::K8s::PrometheusOperator::V1::SafeTLSConfig';
k8s trackTimestampsStaleness => Bool;


























1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::PodMetricsEndpoint - PodMetricsEndpoint defines an endpoint serving Prometheus metrics to be scraped by Prometheus.

=head1 VERSION

version 1.108

=head2 authorization

authorization configures the Authorization header credentials used by
the client.

Cannot be set at the same time as `basicAuth`, `bearerTokenSecret` or `oauth2`.

=head2 basicAuth

basicAuth defines the Basic Authentication credentials used by the
client.

Cannot be set at the same time as `authorization`, `bearerTokenSecret` or `oauth2`.

=head2 bearerTokenSecret

bearerTokenSecret defines a key of a Secret containing the bearer token
used by the client for authentication. The secret needs to be in the
same namespace as the custom resource and readable by the Prometheus
Operator.

Cannot be set at the same time as `authorization`, `basicAuth` or `oauth2`.

Deprecated: use `authorization` instead.

=head2 enableHttp2

enableHttp2 can be used to disable HTTP2.

=head2 filterRunning

filterRunning when true, the pods which are not running (e.g. either in Failed or
Succeeded state) are dropped during the target discovery.

If unset, the filtering is enabled.

More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase

=head2 followRedirects

followRedirects defines whether the client should follow HTTP 3xx
redirects.

=head2 honorLabels

honorLabels when true preserves the metric's labels when they collide
with the target's labels.

=head2 honorTimestamps

honorTimestamps defines whether Prometheus preserves the timestamps
when exposed by the target.

=head2 interval

interval at which Prometheus scrapes the metrics from the target.

If empty, Prometheus uses the global scrape interval.

=head2 metricRelabelings

metricRelabelings defines the relabeling rules to apply to the
samples before ingestion.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 oauth2

oauth2 defines the OAuth2 settings used by the client.

It requires Prometheus >= 2.27.0.

Cannot be set at the same time as `authorization`, `basicAuth` or `bearerTokenSecret`.

=head2 params

params define optional HTTP URL parameters.

=head2 path

path defines the HTTP path from which to scrape for metrics.

If empty, Prometheus uses the default value (e.g. `/metrics`).

=head2 port

port defines the `Pod` port name which exposes the endpoint.

If the pod doesn't expose a port with the same name, it will result
in no targets being discovered.

If a `Pod` has multiple `Port`s with the same name (which is not
recommended), one target instance per unique port number will be
generated.

It takes precedence over the `portNumber` and `targetPort` fields.

=head2 portNumber

portNumber defines the `Pod` port number which exposes the endpoint.

The `Pod` must declare the specified `Port` in its spec or the
target will be dropped by Prometheus.

This cannot be used to enable scraping of an undeclared port.
To scrape targets on a port which isn't exposed, you need to use
relabeling to override the `__address__` label (but beware of
duplicate targets if the `Pod` has other declared ports).

In practice Prometheus will select targets for which the
matches the target's __meta_kubernetes_pod_container_port_number.

=head2 proxyConnectHeader

proxyConnectHeader optionally specifies headers to send to
proxies during CONNECT requests.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyFromEnvironment

proxyFromEnvironment defines whether to use the proxy configuration defined by environment variables (HTTP_PROXY, HTTPS_PROXY, and NO_PROXY).

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyUrl

proxyUrl defines the HTTP proxy server to use.

=head2 relabelings

relabelings defines the relabeling rules to apply the target's
metadata labels.

The Operator automatically adds relabelings for a few standard Kubernetes fields.

The original scrape job's name is available via the `__tmp_prometheus_job_name` label.

More info: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config

=head2 scheme

scheme defines the HTTP scheme to use for scraping.

=head2 scrapeTimeout

scrapeTimeout defines the timeout after which Prometheus considers the scrape to be failed.

If empty, Prometheus uses the global scrape timeout unless it is less
than the target's scrape interval value in which the latter is used.
The value cannot be greater than the scrape interval otherwise the operator will reject the resource.

=head2 targetPort

targetPort defines the name or number of the target port of the `Pod` object behind the Service, the
port must be specified with container port property.

Deprecated: use 'port' or 'portNumber' instead.

=head2 tlsConfig

tlsConfig defines the TLS configuration used by the client.

=head2 trackTimestampsStaleness

trackTimestampsStaleness defines whether Prometheus tracks staleness of
the metrics that have an explicit timestamp present in scraped data.
Has no effect if `honorTimestamps` is false.

It requires Prometheus >= v2.48.0.

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
