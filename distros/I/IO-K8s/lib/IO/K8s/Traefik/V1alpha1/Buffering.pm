package IO::K8s::Traefik::V1alpha1::Buffering;
# ABSTRACT: Buffering holds the buffering middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s maxRequestBodyBytes  => Int;
k8s maxResponseBodyBytes => Int;
k8s memRequestBodyBytes  => Int;
k8s memResponseBodyBytes => Int;
k8s retryExpression      => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Buffering - Buffering holds the buffering middleware configuration.

=head1 VERSION

version 1.108

=head2 maxRequestBodyBytes

MaxRequestBodyBytes defines the maximum allowed body size for the request (in bytes).
If the request exceeds the allowed size, it is not forwarded to the service, and the client gets a 413 (Request Entity Too Large) response.
Default: 0 (no maximum).

=head2 maxResponseBodyBytes

MaxResponseBodyBytes defines the maximum allowed response size from the service (in bytes).
If the response exceeds the allowed size, it is not forwarded to the client. The client gets a 500 (Internal Server Error) response instead.
Default: 0 (no maximum).

=head2 memRequestBodyBytes

MemRequestBodyBytes defines the threshold (in bytes) from which the request will be buffered on disk instead of in memory.
Default: 1048576 (1Mi).

=head2 memResponseBodyBytes

MemResponseBodyBytes defines the threshold (in bytes) from which the response will be buffered on disk instead of in memory.
Default: 1048576 (1Mi).

=head2 retryExpression

RetryExpression defines the retry conditions.
It is a logical combination of functions with operators AND (&&) and OR (||).
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/buffering/#retryexpression

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
