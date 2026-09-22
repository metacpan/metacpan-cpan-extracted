package IO::K8s::Traefik::V1alpha1::ResponseForwarding;
# ABSTRACT: ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s flushInterval => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ResponseForwarding - ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.

=head1 VERSION

version 1.108

=head2 flushInterval

FlushInterval defines the interval, in milliseconds, in between flushes to the client while copying the response body.
A negative value means to flush immediately after each write to the client.
This configuration is ignored when ReverseProxy recognizes a response as a streaming response;
for such responses, writes are flushed to the client immediately.
Default: 100ms

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
