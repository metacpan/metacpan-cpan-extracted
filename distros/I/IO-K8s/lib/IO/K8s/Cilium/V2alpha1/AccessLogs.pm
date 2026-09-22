package IO::K8s::Cilium::V2alpha1::AccessLogs;
# ABSTRACT: AccessLogs defines an Envoy access log configuration, including its output format and the generated proxy components that should emit it.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s format  => Str, { required => 'schema', enum => [qw(JSON Text)] };
k8s json    => { Str => 1 }, { default => {'authority' => '%REQUEST_HEADER(:AUTHORITY)%','bytes_received' => '%BYTES_RECEIVED%','bytes_sent' => '%BYTES_SENT%','duration' => '%DURATION%','method' => '%REQUEST_HEADER(:METHOD)%','path' => '%REQUEST_HEADER(X-ENVOY-ORIGINAL-PATH?:PATH)%','protocol' => '%PROTOCOL%','request_id' => '%REQUEST_HEADER(X-REQUEST-ID)%','response_code' => '%RESPONSE_CODE%','response_flags' => '%RESPONSE_FLAGS%','start_time' => '%START_TIME%','upstream_host' => '%UPSTREAM_HOST%','upstream_service_time' => '%RESPONSE_HEADER(X-ENVOY-UPSTREAM-SERVICE-TIME)%','user_agent' => '%REQUEST_HEADER(USER-AGENT)%','x_forwarded_for' => '%REQUEST_HEADER(X-FORWARDED-FOR)%'} };
k8s targets => [Str], { enum => [qw(HTTP TCP)], default => [qw(HTTP)] };
k8s text    => Str, { default => '[%START_TIME%] "%REQUEST_HEADER(:METHOD)% %REQUEST_HEADER(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%" %RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESPONSE_HEADER(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQUEST_HEADER(X-FORWARDED-FOR)%" "%REQUEST_HEADER(USER-AGENT)%" "%REQUEST_HEADER(X-REQUEST-ID)%" "%REQUEST_HEADER(:AUTHORITY)%" "%UPSTREAM_HOST%"' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::AccessLogs - AccessLogs defines an Envoy access log configuration, including its output format and the generated proxy components that should emit it.

=head1 VERSION

version 1.108

=head2 format

Format specifies the access log output format.

=head2 json

JSON maps access log field names to Envoy command operators.
It is used when Format is "JSON".
For available format specifiers, see the Envoy documentation:
- https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage
Note: Always refer to the documentation matching the specific Envoy version you are running.
The following Cilium-specific formatters are also supported:
- %CILIUM_GATEWAY_NAME% -- replaced with the Gateway resource name.
- %CILIUM_GATEWAY_NAMESPACE% -- replaced with the Gateway resource namespace.

=head2 targets

Targets specifies the generated Envoy proxy components where access logs
are emitted. If omitted, access logs are emitted for HTTP traffic only.
HTTP targets Envoy HTTP connection managers. TCP targets Envoy TCP proxies,
including TLS passthrough.

=head2 text

Text specifies the Envoy access log format string.
It is used when Format is "Text".
For available format specifiers, see the Envoy documentation:
- https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage
Note: Always refer to the documentation matching the specific Envoy version you are running.
The following Cilium-specific formatters are also supported:
- %CILIUM_GATEWAY_NAME% -- replaced with the Gateway resource name.
- %CILIUM_GATEWAY_NAMESPACE% -- replaced with the Gateway resource namespace.

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
