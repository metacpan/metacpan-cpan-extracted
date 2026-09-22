package IO::K8s::Traefik::V1alpha1::Headers;
# ABSTRACT: Headers holds the headers middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessControlAllowCredentials     => Bool;
k8s accessControlAllowHeaders         => [Str];
k8s accessControlAllowMethods         => [Str];
k8s accessControlAllowOriginList      => [Str];
k8s accessControlAllowOriginListRegex => [Str];
k8s accessControlExposeHeaders        => [Str];
k8s accessControlMaxAge               => Int;
k8s addVaryHeader                     => Bool;
k8s allowedHosts                      => [Str];
k8s browserXssFilter                  => Bool;
k8s contentSecurityPolicy             => Str;
k8s contentSecurityPolicyReportOnly   => Str;
k8s contentTypeNosniff                => Bool;
k8s customBrowserXSSValue             => Str;
k8s customFrameOptionsValue           => Str;
k8s customRequestHeaders              => { Str => 1 };
k8s customResponseHeaders             => { Str => 1 };
k8s featurePolicy                     => Str;
k8s forceSTSHeader                    => Bool;
k8s frameDeny                         => Bool;
k8s hostsProxyHeaders                 => [Str];
k8s isDevelopment                     => Bool;
k8s permissionsPolicy                 => Str;
k8s publicKey                         => Str;
k8s referrerPolicy                    => Str;
k8s sslForceHost                      => Bool;
k8s sslHost                           => Str;
k8s sslProxyHeaders                   => { Str => 1 };
k8s sslRedirect                       => Bool;
k8s sslTemporaryRedirect              => Bool;
k8s stsIncludeSubdomains              => Bool;
k8s stsPreload                        => Bool;
k8s stsSeconds                        => Int, { minimum => 0 };


































1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Headers - Headers holds the headers middleware configuration.

=head1 VERSION

version 1.108

=head2 accessControlAllowCredentials

AccessControlAllowCredentials defines whether the request can include user credentials.

=head2 accessControlAllowHeaders

AccessControlAllowHeaders defines the Access-Control-Request-Headers values sent in preflight response.

=head2 accessControlAllowMethods

AccessControlAllowMethods defines the Access-Control-Request-Method values sent in preflight response.

=head2 accessControlAllowOriginList

AccessControlAllowOriginList is a list of allowable origins. Can also be a wildcard origin "*".

=head2 accessControlAllowOriginListRegex

AccessControlAllowOriginListRegex is a list of allowable origins written following the Regular Expression syntax (https://golang.org/pkg/regexp/).

=head2 accessControlExposeHeaders

AccessControlExposeHeaders defines the Access-Control-Expose-Headers values sent in preflight response.

=head2 accessControlMaxAge

AccessControlMaxAge defines the time that a preflight request may be cached.

=head2 addVaryHeader

AddVaryHeader defines whether the Vary header is automatically added/updated when the AccessControlAllowOriginList is set.

=head2 allowedHosts

AllowedHosts defines the fully qualified list of allowed domain names.

=head2 browserXssFilter

BrowserXSSFilter defines whether to add the X-XSS-Protection header with the value 1; mode=block.

=head2 contentSecurityPolicy

ContentSecurityPolicy defines the Content-Security-Policy header value.

=head2 contentSecurityPolicyReportOnly

ContentSecurityPolicyReportOnly defines the Content-Security-Policy-Report-Only header value.

=head2 contentTypeNosniff

ContentTypeNosniff defines whether to add the X-Content-Type-Options header with the nosniff value.

=head2 customBrowserXSSValue

CustomBrowserXSSValue defines the X-XSS-Protection header value.
This overrides the BrowserXssFilter option.

=head2 customFrameOptionsValue

CustomFrameOptionsValue defines the X-Frame-Options header value.
This overrides the FrameDeny option.

=head2 customRequestHeaders

CustomRequestHeaders defines the header names and values to apply to the request.

=head2 customResponseHeaders

CustomResponseHeaders defines the header names and values to apply to the response.

=head2 featurePolicy

Deprecated: FeaturePolicy option is deprecated, please use PermissionsPolicy instead.

=head2 forceSTSHeader

ForceSTSHeader defines whether to add the STS header even when the connection is HTTP.

=head2 frameDeny

FrameDeny defines whether to add the X-Frame-Options header with the DENY value.

=head2 hostsProxyHeaders

HostsProxyHeaders defines the header keys that may hold a proxied hostname value for the request.

=head2 isDevelopment

IsDevelopment defines whether to mitigate the unwanted effects of the AllowedHosts, SSL, and STS options when developing.
Usually testing takes place using HTTP, not HTTPS, and on localhost, not your production domain.
If you would like your development environment to mimic production with complete Host blocking, SSL redirects,
and STS headers, leave this as false.

=head2 permissionsPolicy

PermissionsPolicy defines the Permissions-Policy header value.
This allows sites to control browser features.

=head2 publicKey

PublicKey is the public key that implements HPKP to prevent MITM attacks with forged certificates.

=head2 referrerPolicy

ReferrerPolicy defines the Referrer-Policy header value.
This allows sites to control whether browsers forward the Referer header to other sites.

=head2 sslForceHost

Deprecated: SSLForceHost option is deprecated, please use RedirectRegex instead.

=head2 sslHost

Deprecated: SSLHost option is deprecated, please use RedirectRegex instead.

=head2 sslProxyHeaders

SSLProxyHeaders defines the header keys with associated values that would indicate a valid HTTPS request.
It can be useful when using other proxies (example: "X-Forwarded-Proto": "https").

=head2 sslRedirect

Deprecated: SSLRedirect option is deprecated, please use EntryPoint redirection or RedirectScheme instead.

=head2 sslTemporaryRedirect

Deprecated: SSLTemporaryRedirect option is deprecated, please use EntryPoint redirection or RedirectScheme instead.

=head2 stsIncludeSubdomains

STSIncludeSubdomains defines whether the includeSubDomains directive is appended to the Strict-Transport-Security header.

=head2 stsPreload

STSPreload defines whether the preload flag is appended to the Strict-Transport-Security header.

=head2 stsSeconds

STSSeconds defines the max-age of the Strict-Transport-Security header.
If set to 0, the header is not set.

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
