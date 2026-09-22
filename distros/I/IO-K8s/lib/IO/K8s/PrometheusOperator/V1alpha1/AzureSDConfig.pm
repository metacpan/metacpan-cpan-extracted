package IO::K8s::PrometheusOperator::V1alpha1::AzureSDConfig;
# ABSTRACT: AzureSDConfig allow retrieving scrape targets from Azure VMs.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authenticationMethod => Str, { enum => [qw(OAuth ManagedIdentity SDK WorkloadIdentity)] };
k8s authorization        => '+IO::K8s::PrometheusOperator::V1alpha1::SafeAuthorization';
k8s basicAuth            => '+IO::K8s::PrometheusOperator::V1alpha1::BasicAuth';
k8s clientID             => Str;
k8s clientSecret         => 'Core::V1::ConfigMapKeySelector';
k8s enableHTTP2          => Bool;
k8s environment          => Str;
k8s followRedirects      => Bool;
k8s noProxy              => Str;
k8s oauth2               => '+IO::K8s::PrometheusOperator::V1alpha1::OAuth2';
k8s port                 => Int, { minimum => 0, maximum => 65535 };
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s refreshInterval      => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s resourceGroup        => Str;
k8s subscriptionID       => Str, { required => 'schema' };
k8s tenantID             => Str;
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1alpha1::SafeTLSConfig';




















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::AzureSDConfig - AzureSDConfig allow retrieving scrape targets from Azure VMs.

=head1 VERSION

version 1.108

=head2 authenticationMethod

authenticationMethod defines the authentication method, either `OAuth` or `ManagedIdentity` or `SDK`.
See https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview
SDK authentication method uses environment variables by default.
See https://learn.microsoft.com/en-us/azure/developer/go/azure-sdk-authentication

=head2 authorization

authorization defines the authorization header configuration to authenticate against the target HTTP endpoint.
Cannot be set at the same time as `oAuth2`, or `basicAuth`.

=head2 basicAuth

basicAuth defines the information to authenticate against the target HTTP endpoint.
More info: https://prometheus.io/docs/operating/configuration/#endpoints
Cannot be set at the same time as `authorization`, or `oAuth2`.

=head2 clientID

clientID defines client ID. Only required with the OAuth authentication method.

=head2 clientSecret

clientSecret defines client secret. Only required with the OAuth authentication method.

=head2 enableHTTP2

enableHTTP2 defines whether to enable HTTP2.

=head2 environment

environment defines the Azure environment.

=head2 followRedirects

followRedirects defines whether HTTP requests follow HTTP 3xx redirects.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 oauth2

oauth2 defines the configuration to use on every scrape request.

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

=head2 resourceGroup

resourceGroup defines resource group name. Limits discovery to this resource group.
Requires  Prometheus v2.35.0 and above

=head2 subscriptionID

subscriptionID defines subscription ID. Always required.

=head2 tenantID

tenantID defines tenant ID. Only required with the OAuth authentication method.

=head2 tlsConfig

tlsConfig defines the TLS configuration applying to the target HTTP endpoint.

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
