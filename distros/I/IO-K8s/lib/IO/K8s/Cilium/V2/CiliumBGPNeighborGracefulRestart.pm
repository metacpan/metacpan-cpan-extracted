package IO::K8s::Cilium::V2::CiliumBGPNeighborGracefulRestart;
# ABSTRACT: GracefulRestart defines graceful restart parameters which are negotiated with this peer.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s enabled            => Bool, { required => 'schema' };
k8s restartTimeSeconds => Int, { minimum => 1, maximum => 4095, default => 120 };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumBGPNeighborGracefulRestart - GracefulRestart defines graceful restart parameters which are negotiated with this peer.

=head1 VERSION

version 1.108

=head2 enabled

Enabled flag, when set enables graceful restart capability.

=head2 restartTimeSeconds

RestartTimeSeconds is the estimated time it will take for the BGP
session to be re-established with peer after a restart.
After this period, peer will remove stale routes. This is
described RFC 4724 section 4.2.

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
