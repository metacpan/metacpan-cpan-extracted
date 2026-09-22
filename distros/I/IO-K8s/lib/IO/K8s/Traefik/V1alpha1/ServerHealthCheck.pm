package IO::K8s::Traefik::V1alpha1::ServerHealthCheck;
# ABSTRACT: Healthcheck defines health checks for ExternalName services.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s followRedirects   => Bool;
k8s headers           => { Str => 1 };
k8s hostname          => Str;
k8s interval          => IntOrStr;
k8s method            => Str;
k8s mode              => Str;
k8s path              => Str;
k8s port              => Int;
k8s scheme            => Str;
k8s status            => Int;
k8s timeout           => IntOrStr;
k8s unhealthyInterval => IntOrStr;













1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ServerHealthCheck - Healthcheck defines health checks for ExternalName services.

=head1 VERSION

version 1.108

=head2 followRedirects

FollowRedirects defines whether redirects should be followed during the health check calls.
Default: true

=head2 headers

Headers defines custom headers to be sent to the health check endpoint.

=head2 hostname

Hostname defines the value of hostname in the Host header of the health check request.

=head2 interval

Interval defines the frequency of the health check calls for healthy targets.
Default: 30s

=head2 method

Method defines the healthcheck method.

=head2 mode

Mode defines the health check mode.
If defined to grpc, will use the gRPC health check protocol to probe the server.
Default: http

=head2 path

Path defines the server URL path for the health check endpoint.

=head2 port

Port defines the server URL port for the health check endpoint.

=head2 scheme

Scheme replaces the server URL scheme for the health check endpoint.

=head2 status

Status defines the expected HTTP status code of the response to the health check request.

=head2 timeout

Timeout defines the maximum duration Traefik will wait for a health check request before considering the server unhealthy.
Default: 5s

=head2 unhealthyInterval

UnhealthyInterval defines the frequency of the health check calls for unhealthy targets.
When UnhealthyInterval is not defined, it defaults to the Interval value.
Default: 30s

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
