package IO::K8s::Traefik::V1alpha1::Redis;
# ABSTRACT: Redis hold the configs of Redis as bucket in rate limiter.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s db             => Int;
k8s dialTimeout    => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s endpoints      => [Str];
k8s maxActiveConns => Int;
k8s minIdleConns   => Int;
k8s poolSize       => Int;
k8s readTimeout    => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s secret         => Str;
k8s tls            => '+IO::K8s::Traefik::V1alpha1::ClientTLS';
k8s writeTimeout   => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Redis - Redis hold the configs of Redis as bucket in rate limiter.

=head1 VERSION

version 1.108

=head2 db

DB defines the Redis database that will be selected after connecting to the server.

=head2 dialTimeout

DialTimeout sets the timeout for establishing new connections.
Default value is 5 seconds.

=head2 endpoints

Endpoints contains either a single address or a seed list of host:port addresses.
Default value is ["localhost:6379"].

=head2 maxActiveConns

MaxActiveConns defines the maximum number of connections allocated by the pool at a given time.
Default value is 0, meaning there is no limit.

=head2 minIdleConns

MinIdleConns defines the minimum number of idle connections.
Default value is 0, and idle connections are not closed by default.

=head2 poolSize

PoolSize defines the initial number of socket connections.
If the pool runs out of available connections, additional ones will be created beyond PoolSize.
This can be limited using MaxActiveConns.
// Default value is 0, meaning 10 connections per every available CPU as reported by runtime.GOMAXPROCS.

=head2 readTimeout

ReadTimeout defines the timeout for socket read operations.
Default value is 3 seconds.

=head2 secret

Secret defines the name of the referenced Kubernetes Secret containing Redis credentials.

=head2 tls

TLS defines TLS-specific configurations, including the CA, certificate, and key,
which can be provided as a file path or file content.

=head2 writeTimeout

WriteTimeout defines the timeout for socket write operations.
Default value is 3 seconds.

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
