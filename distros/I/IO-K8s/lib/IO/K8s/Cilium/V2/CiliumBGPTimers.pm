package IO::K8s::Cilium::V2::CiliumBGPTimers;
# ABSTRACT: Timers defines the BGP timers for the peer.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s connectRetryTimeSeconds => Int, { minimum => 1, maximum => 2147483647, default => 120 };
k8s holdTimeSeconds         => Int, { minimum => 3, maximum => 65535, default => 90 };
k8s keepAliveTimeSeconds    => Int, { minimum => 1, maximum => 65535, default => 30 };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumBGPTimers - Timers defines the BGP timers for the peer.

=head1 VERSION

version 1.108

=head2 connectRetryTimeSeconds

ConnectRetryTimeSeconds defines the initial value for the BGP ConnectRetryTimer (RFC 4271, Section 8).

If not specified, defaults to 120 seconds.

=head2 holdTimeSeconds

HoldTimeSeconds defines the initial value for the BGP HoldTimer (RFC 4271, Section 4.2).
Updating this value will cause a session reset.

If not specified, defaults to 90 seconds.

=head2 keepAliveTimeSeconds

KeepaliveTimeSeconds defines the initial value for the BGP KeepaliveTimer (RFC 4271, Section 8).
It can not be larger than HoldTimeSeconds. Updating this value will cause a session reset.

If not specified, defaults to 30 seconds.

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
