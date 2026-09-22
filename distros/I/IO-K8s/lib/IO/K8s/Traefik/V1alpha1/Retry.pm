package IO::K8s::Traefik::V1alpha1::Retry;
# ABSTRACT: Retry holds the retry middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s attempts                   => Int, { minimum => 0 };
k8s disableRetryOnNetworkError => Bool;
k8s initialInterval            => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s maxRequestBodyBytes        => Int, { minimum => -1 };
k8s retryNonIdempotentMethod   => Bool;
k8s status                     => [Str], { pattern => qr/^([1-5][0-9]{2}[,-]?)+$/ };
k8s timeout                    => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Retry - Retry holds the retry middleware configuration.

=head1 VERSION

version 1.108

=head2 attempts

Attempts defines how many times the request should be retried.

=head2 disableRetryOnNetworkError

DisableRetryOnNetworkError defines whether to disable the retry if an error occurs when transmitting the request to the server.

=head2 initialInterval

InitialInterval defines the first wait time in the exponential backoff series.
The maximum interval is calculated as twice the initialInterval.
If unspecified, requests will be retried immediately.
The value of initialInterval should be provided in seconds or as a valid duration format,
see https://pkg.go.dev/time#ParseDuration.

=head2 maxRequestBodyBytes

MaxRequestBodyBytes defines the maximum size for the request body.
Default is `-1`, which means no limit.

=head2 retryNonIdempotentMethod

RetryNonIdempotentMethod activates the retry for non-idempotent methods (POST, LOCK, PATCH)

=head2 status

Status defines the range of HTTP status codes to retry on.

=head2 timeout

Timeout defines how much time the middleware is allowed to retry the request.
The value of timeout should be provided in seconds or as a valid duration format,
see https://pkg.go.dev/time#ParseDuration.

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
