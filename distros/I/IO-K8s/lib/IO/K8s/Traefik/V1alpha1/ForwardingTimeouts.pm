package IO::K8s::Traefik::V1alpha1::ForwardingTimeouts;
# ABSTRACT: ForwardingTimeouts defines the timeouts for requests forwarded to the backend servers.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s dialTimeout           => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s idleConnTimeout       => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s pingTimeout           => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s readIdleTimeout       => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s responseHeaderTimeout => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ForwardingTimeouts - ForwardingTimeouts defines the timeouts for requests forwarded to the backend servers.

=head1 VERSION

version 1.108

=head2 dialTimeout

DialTimeout is the amount of time to wait until a connection to a backend server can be established.

=head2 idleConnTimeout

IdleConnTimeout is the maximum period for which an idle HTTP keep-alive connection will remain open before closing itself.

=head2 pingTimeout

PingTimeout is the timeout after which the HTTP/2 connection will be closed if a response to ping is not received.

=head2 readIdleTimeout

ReadIdleTimeout is the timeout after which a health check using ping frame will be carried out if no frame is received on the HTTP/2 connection.

=head2 responseHeaderTimeout

ResponseHeaderTimeout is the amount of time to wait for a server's response headers after fully writing the request (including its body, if any).

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
